## Parallel graph algorithm implementations.
##
## Uses ``malebolgia`` for multi-threaded execution via a thread pool.
##
## When compiled without ``--threads:on``, every proc falls back to its
## sequential equivalent so the library remains usable on single-threaded
## builds.
##
## Provided algorithms:
## - ``parallelPageRank`` — parallel PageRank (power iteration)
## - ``parallelBetweennessCentrality`` — parallel Brandes' algorithm
## - ``parallelClosenessCentrality`` — parallel BFS-based closeness
## - ``parallelClustering`` — parallel local clustering coefficient
## - ``parallelJohnsons`` — parallel Johnson's all-pairs shortest paths

import std/[tables, sets, math, deques, heapqueue]
import ../types, ../graph, ../digraph

when compileOption("threads"):
  import malebolgia
  import std/cpuinfo

import std/isolation
export isolation

# ---------------------------------------------------------------------------
# helpers — precompute index-based adjacency for cache-friendly access
# ---------------------------------------------------------------------------

type
  IndexedGraph* = object
    ## Flattened, index-based adjacency representation.
    n*: int
    adj*: seq[seq[int]]
    weights*: seq[seq[float]]  # weights[i][j_idx] = weight of edge i->adj[i][j_idx]

proc toIndexed*[N](g: Graph[N]): (IndexedGraph, seq[N], Table[N, int]) =
  ## Convert a Graph[N] to a cache-friendly indexed representation.
  var nodeList: seq[N]
  for nd in g.nodes:
    nodeList.add(nd)
  let n = nodeList.len
  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i
  var ig: IndexedGraph
  ig.n = n
  ig.adj = newSeq[seq[int]](n)
  ig.weights = newSeq[seq[float]](n)
  for i, nd in nodeList:
    for nb in g.neighbors(nd):
      ig.adj[i].add(nodeIdx[nb])
      ig.weights[i].add(g.getEdgeAttr(nd, nb).getWeight())
  result = (ig, nodeList, nodeIdx)

proc toIndexedDi*[N](g: DiGraph[N]): (IndexedGraph, seq[seq[int]], seq[N], Table[N, int]) =
  ## Convert a DiGraph[N] to indexed form.
  ## Returns (forward adj, predecessor adj, nodeList, nodeIdx).
  var nodeList: seq[N]
  for nd in g.nodes:
    nodeList.add(nd)
  let n = nodeList.len
  var nodeIdx = initTable[N, int]()
  for i, nd in nodeList:
    nodeIdx[nd] = i
  var ig: IndexedGraph
  ig.n = n
  ig.adj = newSeq[seq[int]](n)
  ig.weights = newSeq[seq[float]](n)
  var predAdj = newSeq[seq[int]](n)
  for i, nd in nodeList:
    for nb in g.neighbors(nd):
      let j = nodeIdx[nb]
      ig.adj[i].add(j)
      ig.weights[i].add(g.getEdgeAttr(nd, nb).getWeight())
    for p in g.pred[nd].keys:
      predAdj[i].add(nodeIdx[p])
  result = (ig, predAdj, nodeList, nodeIdx)

# ============================================================================
# Parallel Betweenness Centrality
# ============================================================================

proc brandesBFS(ig: ptr IndexedGraph, s: int,
                bc: ptr UncheckedArray[float]) {.gcsafe.} =
  ## Single-source Brandes BFS. Accumulates into bc[].
  let n = ig.n
  var stack = newSeqOfCap[int](n)
  var pred = newSeq[seq[int]](n)
  var sigma = newSeq[float](n)
  sigma[s] = 1.0
  var dist = newSeq[int](n)
  for i in 0 ..< n: dist[i] = -1
  dist[s] = 0

  var queue = initDeque[int]()
  queue.addLast(s)

  while queue.len > 0:
    let v = queue.popFirst()
    stack.add(v)
    for w in ig.adj[v]:
      if dist[w] < 0:
        dist[w] = dist[v] + 1
        queue.addLast(w)
      if dist[w] == dist[v] + 1:
        sigma[w] += sigma[v]
        pred[w].add(v)

  var delta = newSeq[float](n)
  while stack.len > 0:
    let w = stack.pop()
    for v in pred[w]:
      delta[v] += (sigma[v] / sigma[w]) * (1.0 + delta[w])
    if w != s:
      bc[w] += delta[w]

when compileOption("threads"):
  proc brandesBatchWorker(igPtr: ptr IndexedGraph,
                          sources: ptr UncheckedArray[int],
                          numSources: int,
                          bcArr: ptr UncheckedArray[float]) {.gcsafe.} =
    for si in 0 ..< numSources:
      brandesBFS(igPtr, sources[si], bcArr)

proc parallelBetweennessCentrality*[N](g: Graph[N],
    normalized: bool = true): Table[N, float] =
  ## Compute betweenness centrality using Brandes' algorithm with
  ## multi-threaded source-parallel BFS.
  let (ig, nodeList, nodeIdx) = toIndexed(g)
  let n = ig.n
  if n <= 2:
    result = initTable[N, float]()
    for nd in nodeList:
      result[nd] = 0.0
    return

  when compileOption("threads"):
    let numWorkers = min(n, countProcessors())
    var perThread = newSeq[seq[float]](numWorkers)
    for t in 0 ..< numWorkers:
      perThread[t] = newSeq[float](n)

    var assignments = newSeq[seq[int]](numWorkers)
    for s in 0 ..< n:
      assignments[s mod numWorkers].add(s)

    var m = createMaster()
    m.awaitAll:
      for t in 0 ..< numWorkers:
        if assignments[t].len > 0:
          m.spawn brandesBatchWorker(
            addr ig,
            cast[ptr UncheckedArray[int]](addr assignments[t][0]),
            assignments[t].len,
            cast[ptr UncheckedArray[float]](addr perThread[t][0])
          )

    var bc = newSeq[float](n)
    for t in 0 ..< numWorkers:
      for i in 0 ..< n:
        bc[i] += perThread[t][i]
  else:
    var bc = newSeq[float](n)
    for s in 0 ..< n:
      brandesBFS(addr ig, s, cast[ptr UncheckedArray[float]](addr bc[0]))

  if normalized:
    let norm = float((n - 1) * (n - 2))
    if norm > 0.0:
      for i in 0 ..< n:
        bc[i] /= norm
  else:
    for i in 0 ..< n:
      bc[i] /= 2.0

  result = initTable[N, float]()
  for i, nd in nodeList:
    result[nd] = bc[i]

# ============================================================================
# Parallel Closeness Centrality
# ============================================================================

proc bfsCloseness(ig: ptr IndexedGraph, s: int): float {.gcsafe.} =
  ## Single-source BFS returning closeness centrality for source s.
  let n = ig.n
  var dist = newSeq[int](n)
  for i in 0 ..< n: dist[i] = -1
  dist[s] = 0
  var queue = initDeque[int]()
  queue.addLast(s)
  var totalDist = 0
  var reachable = 0

  while queue.len > 0:
    let v = queue.popFirst()
    for w in ig.adj[v]:
      if dist[w] < 0:
        dist[w] = dist[v] + 1
        totalDist += dist[w]
        reachable += 1
        queue.addLast(w)

  if reachable == 0:
    return 0.0
  return float(reachable) / float(totalDist)

when compileOption("threads"):
  proc closenessWorker(igPtr: ptr IndexedGraph, s: int,
                       res: ptr UncheckedArray[float]) {.gcsafe.} =
    res[s] = bfsCloseness(igPtr, s)

proc parallelClosenessCentrality*[N](g: Graph[N]): Table[N, float] =
  ## Compute closeness centrality for all nodes with multi-threaded BFS.
  let (ig, nodeList, nodeIdx) = toIndexed(g)
  let n = ig.n
  var cc = newSeq[float](n)

  when compileOption("threads"):
    var m = createMaster()
    m.awaitAll:
      for s in 0 ..< n:
        m.spawn closenessWorker(addr ig, s,
          cast[ptr UncheckedArray[float]](addr cc[0]))
  else:
    for s in 0 ..< n:
      cc[s] = bfsCloseness(addr ig, s)

  result = initTable[N, float]()
  for i, nd in nodeList:
    result[nd] = cc[i]

# ============================================================================
# Parallel Clustering Coefficient
# ============================================================================

proc nodeClusteringCoeff(ig: ptr IndexedGraph,
                         v: int): float {.gcsafe.} =
  ## Compute local clustering coefficient for node v.
  let neighbors = ig.adj[v]
  let deg = neighbors.len
  if deg < 2:
    return 0.0

  var nbrSet: HashSet[int]
  for nb in neighbors:
    nbrSet.incl(nb)

  var triangles = 0
  for i in 0 ..< deg:
    let u = neighbors[i]
    for w in ig.adj[u]:
      if w in nbrSet and w != v and w != u:
        triangles += 1
  triangles = triangles div 2
  return 2.0 * float(triangles) / (float(deg) * float(deg - 1))

when compileOption("threads"):
  proc clusteringWorker(igPtr: ptr IndexedGraph, v: int,
                        res: ptr UncheckedArray[float]) {.gcsafe.} =
    res[v] = nodeClusteringCoeff(igPtr, v)

proc parallelClustering*[N](g: Graph[N]): Table[N, float] =
  ## Compute local clustering coefficient for all nodes in parallel.
  let (ig, nodeList, nodeIdx) = toIndexed(g)
  let n = ig.n
  var cc = newSeq[float](n)

  when compileOption("threads"):
    var m = createMaster()
    m.awaitAll:
      for v in 0 ..< n:
        m.spawn clusteringWorker(addr ig, v,
          cast[ptr UncheckedArray[float]](addr cc[0]))
  else:
    for v in 0 ..< n:
      cc[v] = nodeClusteringCoeff(addr ig, v)

  result = initTable[N, float]()
  for i, nd in nodeList:
    result[nd] = cc[i]

# ============================================================================
# Parallel PageRank (undirected)
# ============================================================================

when compileOption("threads"):
  proc scatterChunkWorker(igPtr: ptr IndexedGraph,
                          rankPtr: ptr UncheckedArray[float],
                          degsPtr: ptr UncheckedArray[int],
                          localBuf: ptr UncheckedArray[float],
                          startIdx, endIdx, nn: int) {.gcsafe.} =
    for i in startIdx ..< endIdx:
      if degsPtr[i] > 0:
        let contrib = rankPtr[i] / float(degsPtr[i])
        for j in igPtr.adj[i]:
          localBuf[j] += contrib

proc parallelPageRank*[N](g: Graph[N], maxIter: int = 100,
                           alpha: float = 0.85,
                           tol: float = 1e-6): Table[N, float] =
  ## Compute PageRank using iterative power method with parallel scatter.
  let (ig, nodeList, nodeIdx) = toIndexed(g)
  let n = ig.n
  if n == 0:
    return initTable[N, float]()

  let initVal = 1.0 / float(n)
  var rank = newSeq[float](n)
  for i in 0 ..< n:
    rank[i] = initVal

  var degrees = newSeq[int](n)
  for i in 0 ..< n:
    degrees[i] = ig.adj[i].len

  when compileOption("threads"):
    let numWorkers = min(n, countProcessors())
    let chunkSize = (n + numWorkers - 1) div numWorkers

    for iter in 0 ..< maxIter:
      var newRank = newSeq[float](n)
      var danglingSum = 0.0
      for i in 0 ..< n:
        if degrees[i] == 0:
          danglingSum += rank[i]

      var perThread = newSeq[seq[float]](numWorkers)
      for t in 0 ..< numWorkers:
        perThread[t] = newSeq[float](n)

      var m2 = createMaster()
      m2.awaitAll:
        for t in 0 ..< numWorkers:
          let s = t * chunkSize
          let e = min(s + chunkSize, n)
          if s < e:
            m2.spawn scatterChunkWorker(addr ig,
              cast[ptr UncheckedArray[float]](addr rank[0]),
              cast[ptr UncheckedArray[int]](addr degrees[0]),
              cast[ptr UncheckedArray[float]](addr perThread[t][0]),
              s, e, n)

      for t in 0 ..< numWorkers:
        for j in 0 ..< n:
          newRank[j] += perThread[t][j]

      let base = (1.0 - alpha + alpha * danglingSum) / float(n)
      var maxDiff = 0.0
      for i in 0 ..< n:
        newRank[i] = base + alpha * newRank[i]
        maxDiff = max(maxDiff, abs(newRank[i] - rank[i]))

      rank = newRank
      if maxDiff < tol:
        break
  else:
    for iter in 0 ..< maxIter:
      var newRank = newSeq[float](n)
      var danglingSum = 0.0
      for i in 0 ..< n:
        if degrees[i] == 0:
          danglingSum += rank[i]
      for i in 0 ..< n:
        if degrees[i] > 0:
          let contrib = rank[i] / float(degrees[i])
          for j in ig.adj[i]:
            newRank[j] += contrib
      let base = (1.0 - alpha + alpha * danglingSum) / float(n)
      var maxDiff = 0.0
      for i in 0 ..< n:
        newRank[i] = base + alpha * newRank[i]
        maxDiff = max(maxDiff, abs(newRank[i] - rank[i]))
      rank = newRank
      if maxDiff < tol:
        break

  result = initTable[N, float]()
  for i, nd in nodeList:
    result[nd] = rank[i]

# ============================================================================
# Parallel PageRank (directed)
# ============================================================================

when compileOption("threads"):
  proc diPageRankChunkWorker(predAdjPtr: ptr UncheckedArray[seq[int]],
                             rankPtr: ptr UncheckedArray[float],
                             outDegPtr: ptr UncheckedArray[int],
                             newRankPtr: ptr UncheckedArray[float],
                             alphaF, baseF: float,
                             startIdx, endIdx: int) {.gcsafe.} =
    for i in startIdx ..< endIdx:
      var r = baseF
      for p in predAdjPtr[i]:
        if outDegPtr[p] > 0:
          r += alphaF * rankPtr[p] / float(outDegPtr[p])
      newRankPtr[i] = r

proc parallelPageRank*[N](g: DiGraph[N], maxIter: int = 100,
                           alpha: float = 0.85,
                           tol: float = 1e-6): Table[N, float] =
  ## Compute PageRank for a directed graph using parallel power iteration.
  let (ig, predAdj, nodeList, nodeIdx) = toIndexedDi(g)
  let n = ig.n
  if n == 0:
    return initTable[N, float]()

  let initVal = 1.0 / float(n)
  var rank = newSeq[float](n)
  for i in 0 ..< n:
    rank[i] = initVal

  var outDeg = newSeq[int](n)
  for i in 0 ..< n:
    outDeg[i] = ig.adj[i].len

  when compileOption("threads"):
    let numWorkers = min(n, countProcessors())
    let chunkSize = (n + numWorkers - 1) div numWorkers

    for iter in 0 ..< maxIter:
      var danglingSum = 0.0
      for i in 0 ..< n:
        if outDeg[i] == 0:
          danglingSum += rank[i]
      let base = (1.0 - alpha + alpha * danglingSum) / float(n)

      var newRank = newSeq[float](n)

      var m = createMaster()
      m.awaitAll:
        for t in 0 ..< numWorkers:
          let s = t * chunkSize
          let e = min(s + chunkSize, n)
          if s < e:
            m.spawn diPageRankChunkWorker(
              cast[ptr UncheckedArray[seq[int]]](addr predAdj[0]),
              cast[ptr UncheckedArray[float]](addr rank[0]),
              cast[ptr UncheckedArray[int]](addr outDeg[0]),
              cast[ptr UncheckedArray[float]](addr newRank[0]),
              alpha, base, s, e)

      var maxDiff = 0.0
      for i in 0 ..< n:
        maxDiff = max(maxDiff, abs(newRank[i] - rank[i]))
      rank = newRank
      if maxDiff < tol:
        break
  else:
    for iter in 0 ..< maxIter:
      var danglingSum = 0.0
      for i in 0 ..< n:
        if outDeg[i] == 0:
          danglingSum += rank[i]
      let base = (1.0 - alpha + alpha * danglingSum) / float(n)
      var newRank = newSeq[float](n)
      for i in 0 ..< n:
        var r = base
        for p in predAdj[i]:
          if outDeg[p] > 0:
            r += alpha * rank[p] / float(outDeg[p])
        newRank[i] = r
      var maxDiff = 0.0
      for i in 0 ..< n:
        maxDiff = max(maxDiff, abs(newRank[i] - rank[i]))
      rank = newRank
      if maxDiff < tol:
        break

  result = initTable[N, float]()
  for i, nd in nodeList:
    result[nd] = rank[i]

# ============================================================================
# Parallel Johnson's All-Pairs Shortest Paths
# ============================================================================

proc dijkstraSingle(ig: ptr IndexedGraph, s: int,
                    hVals: ptr UncheckedArray[float],
                    distOut: ptr UncheckedArray[float],
                    n: int) {.gcsafe.} =
  ## Single-source Dijkstra with reweighted edges for Johnson's algorithm.
  type Entry = tuple[dist: float, node: int]
  var dist = newSeq[float](n)
  for i in 0 ..< n: dist[i] = Inf
  dist[s] = 0.0
  var visited = newSeq[bool](n)
  var pq = initHeapQueue[Entry]()
  pq.push((0.0, s))

  while pq.len > 0:
    let (d, u) = pq.pop()
    if visited[u]: continue
    visited[u] = true
    for jIdx in 0 ..< ig.adj[u].len:
      let v = ig.adj[u][jIdx]
      if not visited[v]:
        let w = ig.weights[u][jIdx]
        let reweighted = w + hVals[u] - hVals[v]
        let nd = d + reweighted
        if nd < dist[v]:
          dist[v] = nd
          pq.push((nd, v))

  for v in 0 ..< n:
    distOut[v] = dist[v] - hVals[s] + hVals[v]

when compileOption("threads"):
  proc dijkstraWorker(igPtr: ptr IndexedGraph, s: int,
                      hPtr: ptr UncheckedArray[float],
                      outPtr: ptr UncheckedArray[float],
                      nn: int) {.gcsafe.} =
    dijkstraSingle(igPtr, s, hPtr, outPtr, nn)

proc parallelJohnsons*[N](g: DiGraph[N]): Table[N, Table[N, float]] =
  ## Johnson's algorithm with parallel Dijkstra from each source.
  let (ig, predAdj, nodeList, nodeIdx) = toIndexedDi(g)
  let n = ig.n
  if n == 0:
    return initTable[N, Table[N, float]]()

  # Step 1: Bellman-Ford for h values (sequential)
  var hVals = newSeq[float](n)
  for iter in 0 ..< n - 1:
    for u in 0 ..< n:
      for jIdx in 0 ..< ig.adj[u].len:
        let v = ig.adj[u][jIdx]
        let w = ig.weights[u][jIdx]
        if hVals[u] + w < hVals[v]:
          hVals[v] = hVals[u] + w

  # Step 2: Parallel Dijkstra from each source
  var distMatrix = newSeq[seq[float]](n)
  for i in 0 ..< n:
    distMatrix[i] = newSeq[float](n)

  when compileOption("threads"):
    var m = createMaster()
    m.awaitAll:
      for s in 0 ..< n:
        m.spawn dijkstraWorker(addr ig, s,
          cast[ptr UncheckedArray[float]](addr hVals[0]),
          cast[ptr UncheckedArray[float]](addr distMatrix[s][0]),
          n)
  else:
    for s in 0 ..< n:
      dijkstraSingle(addr ig, s,
        cast[ptr UncheckedArray[float]](addr hVals[0]),
        cast[ptr UncheckedArray[float]](addr distMatrix[s][0]),
        n)

  result = initTable[N, Table[N, float]]()
  for i, src in nodeList:
    result[src] = initTable[N, float]()
    for j, dst in nodeList:
      result[src][dst] = distMatrix[i][j]
