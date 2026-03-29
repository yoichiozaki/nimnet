## Centrality measures for nimnet

import std/[tables, sets, deques, algorithm]
import ../types
import ../graph
import ../digraph

# =============================================================================
# Degree centrality
# =============================================================================

proc degreeCentrality*[N](g: Graph[N]): Table[N, float] =
  ## Compute degree centrality for all nodes.
  ## Normalized by (n - 1) where n is the number of nodes.
  let n = g.numberOfNodes()
  result = initTable[N, float]()
  if n <= 1:
    for node in g.nodes:
      result[node] = 0.0
    return
  let norm = 1.0 / float(n - 1)
  for node in g.nodes:
    result[node] = float(g.degree(node)) * norm

proc inDegreeCentrality*[N](g: DiGraph[N]): Table[N, float] =
  ## Compute in-degree centrality for a directed graph.
  ## Normalized by (n - 1).
  let n = g.numberOfNodes()
  result = initTable[N, float]()
  if n <= 1:
    for node in g.nodes:
      result[node] = 0.0
    return
  let norm = 1.0 / float(n - 1)
  for node in g.nodes:
    result[node] = float(g.inDegree(node)) * norm

proc outDegreeCentrality*[N](g: DiGraph[N]): Table[N, float] =
  ## Compute out-degree centrality for a directed graph.
  ## Normalized by (n - 1).
  let n = g.numberOfNodes()
  result = initTable[N, float]()
  if n <= 1:
    for node in g.nodes:
      result[node] = 0.0
    return
  let norm = 1.0 / float(n - 1)
  for node in g.nodes:
    result[node] = float(g.outDegree(node)) * norm

# =============================================================================
# Closeness centrality
# =============================================================================

proc closenessCentrality*[N](g: Graph[N]): Table[N, float] =
  ## Compute closeness centrality for all nodes.
  ## C(u) = (n-1) / sum(d(u, v) for all reachable v)
  result = initTable[N, float]()
  for source in g.adj.keys:
    # BFS for shortest path lengths
    var dist = initTable[N, int]()
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let current = queue.popFirst()
      let cd = dist[current]
      for neighbor in g.adj[current].keys:
        if neighbor notin dist:
          dist[neighbor] = cd + 1
          queue.addLast(neighbor)
    let reachable = dist.len - 1  # excluding self
    if reachable == 0:
      result[source] = 0.0
    else:
      var totalDist = 0
      for node, d in dist:
        if node != source:
          totalDist += d
      result[source] = float(reachable) / float(totalDist)

# =============================================================================
# Betweenness centrality (Brandes' algorithm)
# =============================================================================

proc betweennessCentrality*[N](g: Graph[N], normalized: bool = true): Table[N, float] =
  ## Compute betweenness centrality for all nodes using Brandes' algorithm.
  result = initTable[N, float]()
  for n in g.adj.keys:
    result[n] = 0.0

  for s in g.adj.keys:
    # Single-source shortest paths
    var stack: seq[N]
    var pred = initTable[N, seq[N]]()
    for n in g.adj.keys:
      pred[n] = @[]
    var sigma = initTable[N, float]()
    for n in g.adj.keys:
      sigma[n] = 0.0
    sigma[s] = 1.0
    var dist = initTable[N, int]()
    dist[s] = 0

    var queue = initDeque[N]()
    queue.addLast(s)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      let dv = dist[v]
      for w in g.adj[v].keys:
        # Path discovery
        if w notin dist:
          dist[w] = dv + 1
          queue.addLast(w)
        # Path counting
        if dist[w] == dv + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)

    # Accumulation
    var delta = initTable[N, float]()
    for n in g.adj.keys:
      delta[n] = 0.0
    while stack.len > 0:
      let w = stack.pop()
      for v in pred[w]:
        delta[v] += (sigma[v] / sigma[w]) * (1.0 + delta[w])
      if w != s:
        result[w] += delta[w]

  # Undirected: each pair (s,t) counted twice
  if normalized:
    let n = g.numberOfNodes()
    if n > 2:
      let norm = 1.0 / (float(n - 1) * float(n - 2))
      for node in result.keys:
        result[node] *= norm
  else:
    for node in result.keys:
      result[node] /= 2.0

# =============================================================================
# PageRank
# =============================================================================

proc pageRank*[N](g: DiGraph[N], alpha: float = 0.85, maxIter: int = 100,
                   tol: float = 1.0e-6): Table[N, float] =
  ## Compute PageRank for a directed graph using power iteration.
  ## Uses array-indexed computation internally for cache-friendly performance.
  ## ``alpha``: damping factor (default 0.85).
  let n = g.numberOfNodes()
  if n == 0:
    return initTable[N, float]()

  # Build indexed structure for cache-friendly inner loop
  var nodeList = newSeqOfCap[N](n)
  var nodeIdx = initTable[N, int](n)
  var predIdx = newSeq[seq[int]](n)
  var outDeg = newSeq[int](n)
  var invOutDeg = newSeq[float](n)

  var idx = 0
  for node in g.adj.keys:
    nodeList.add(node)
    nodeIdx[node] = idx
    outDeg[idx] = g.adj[node].len
    idx.inc

  # Build predecessor adjacency by index
  for i in 0 ..< n:
    let node = nodeList[i]
    predIdx[i] = newSeqOfCap[int](g.pred[node].len)
    for p in g.pred[node].keys:
      predIdx[i].add(nodeIdx[p])

  # Precompute inverse out-degree
  for i in 0 ..< n:
    invOutDeg[i] = if outDeg[i] > 0: 1.0 / float(outDeg[i]) else: 0.0

  # Power iteration with flat arrays
  let initVal = 1.0 / float(n)
  var rank = newSeq[float](n)
  var newRank = newSeq[float](n)
  for i in 0 ..< n:
    rank[i] = initVal

  for iter in 0 ..< maxIter:
    var danglingSum = 0.0
    for i in 0 ..< n:
      if outDeg[i] == 0:
        danglingSum += rank[i]

    let base = (1.0 - alpha + alpha * danglingSum) / float(n)
    for i in 0 ..< n:
      var r = base
      for j in predIdx[i]:
        r += alpha * rank[j] * invOutDeg[j]
      newRank[i] = r

    var diff = 0.0
    for i in 0 ..< n:
      diff += abs(newRank[i] - rank[i])
    swap(rank, newRank)
    if diff < tol:
      break

  # Convert back to Table
  result = initTable[N, float](n)
  for i in 0 ..< n:
    result[nodeList[i]] = rank[i]

proc pageRank*[N](g: Graph[N], alpha: float = 0.85, maxIter: int = 100,
                   tol: float = 1.0e-6): Table[N, float] =
  ## Compute PageRank for undirected graph (treated as bidirectional).
  ## Uses array-indexed computation internally for cache-friendly performance.
  let n = g.numberOfNodes()
  if n == 0:
    return initTable[N, float]()

  # Build indexed structure for cache-friendly inner loop
  var nodeList = newSeqOfCap[N](n)
  var nodeIdx = initTable[N, int](n)
  var adjIdx = newSeq[seq[int]](n)
  var invDeg = newSeq[float](n)  # precomputed 1/degree

  var idx = 0
  for node, neighbors in g.adj:
    nodeList.add(node)
    nodeIdx[node] = idx
    var d = neighbors.len
    if node in neighbors: d.inc  # self-loop
    invDeg[idx] = if d > 0: 1.0 / float(d) else: 0.0
    idx.inc

  # Build adjacency by index
  for i in 0 ..< n:
    let node = nodeList[i]
    adjIdx[i] = newSeqOfCap[int](g.adj[node].len)
    for neighbor in g.adj[node].keys:
      adjIdx[i].add(nodeIdx[neighbor])

  # Power iteration with flat arrays — no hash lookups in inner loop
  let initVal = 1.0 / float(n)
  let base = (1.0 - alpha) / float(n)
  var rank = newSeq[float](n)
  var newRank = newSeq[float](n)
  for i in 0 ..< n:
    rank[i] = initVal

  for iter in 0 ..< maxIter:
    for i in 0 ..< n:
      var r = base
      for j in adjIdx[i]:
        r += alpha * rank[j] * invDeg[j]
      newRank[i] = r

    var diff = 0.0
    for i in 0 ..< n:
      diff += abs(newRank[i] - rank[i])
    swap(rank, newRank)
    if diff < tol:
      break

  # Convert back to Table
  result = initTable[N, float](n)
  for i in 0 ..< n:
    result[nodeList[i]] = rank[i]

# =============================================================================
# HITS (Hyperlink-Induced Topic Search)
# =============================================================================

proc hits*[N](g: DiGraph[N], maxIter: int = 100,
              tol: float = 1.0e-8): (Table[N, float], Table[N, float]) =
  ## Compute HITS hubs and authorities for a directed graph.
  ## Returns ``(hubs, authorities)``.
  let n = g.numberOfNodes()
  if n == 0:
    return (initTable[N, float](), initTable[N, float]())

  var nodeList = newSeqOfCap[N](n)
  for node in g.adj.keys:
    nodeList.add(node)

  var hubs = initTable[N, float]()
  var auths = initTable[N, float]()
  var newAuths = initTable[N, float]()
  var newHubs = initTable[N, float]()
  for node in nodeList:
    hubs[node] = 1.0
    auths[node] = 1.0
    newAuths[node] = 0.0
    newHubs[node] = 0.0

  for _ in 0 ..< maxIter:
    for node in nodeList:
      newAuths[node] = 0.0
      newHubs[node] = 0.0

    # Authority update: auth(v) = sum(hub(u) for u -> v)
    for node in nodeList:
      for pred in g.pred[node].keys:
        newAuths[node] += hubs[pred]

    # Hub update: hub(u) = sum(auth(v) for u -> v)
    for node in nodeList:
      for succ in g.adj[node].keys:
        newHubs[node] += newAuths[succ]

    # Normalize by L1 norm (sum = 1) to match NetworkX convention
    var authNorm = 0.0
    var hubNorm = 0.0
    for node in nodeList:
      authNorm += newAuths[node]
      hubNorm += newHubs[node]
    if authNorm > 0:
      for node in nodeList:
        newAuths[node] /= authNorm
    if hubNorm > 0:
      for node in nodeList:
        newHubs[node] /= hubNorm

    # Check convergence
    var diff = 0.0
    for node in nodeList:
      diff += abs(newAuths[node] - auths[node])
      diff += abs(newHubs[node] - hubs[node])
    swap(auths, newAuths)
    swap(hubs, newHubs)
    if diff < tol:
      break

  result = (hubs, auths)

# =============================================================================
# Eigenvector centrality
# =============================================================================

proc eigenvectorCentrality*[N](g: Graph[N], maxIter: int = 100,
                                tol: float = 1.0e-6): Table[N, float] =
  ## Compute eigenvector centrality for an undirected graph via power iteration.
  let n = g.numberOfNodes()
  if n == 0:
    return initTable[N, float]()

  var nodeList = newSeqOfCap[N](n)
  for node in g.adj.keys:
    nodeList.add(node)

  result = initTable[N, float]()
  var newVals = initTable[N, float]()
  for node in nodeList:
    result[node] = 1.0 / float(n)
    newVals[node] = 0.0

  for _ in 0 ..< maxIter:
    for node in nodeList:
      var s = 0.0
      for neighbor in g.adj[node].keys:
        s += result[neighbor]
      newVals[node] = s

    # Normalize by max value
    var maxVal = 0.0
    for node in nodeList:
      if abs(newVals[node]) > maxVal:
        maxVal = abs(newVals[node])
    if maxVal > 0:
      for node in nodeList:
        newVals[node] /= maxVal

    # Check convergence
    var diff = 0.0
    for node in nodeList:
      diff += abs(newVals[node] - result[node])
    swap(result, newVals)
    if diff < tol:
      break

# =============================================================================
# Katz centrality
# =============================================================================

proc katzCentrality*[N](g: Graph[N], alpha: float = 0.1,
                         beta: float = 1.0,
                         maxIter: int = 1000,
                         tol: float = 1.0e-6): Table[N, float] =
  ## Compute Katz centrality for an undirected graph.
  ## ``C_katz(i) = alpha * sum(A_ij * C_katz(j)) + beta``.
  let n = g.numberOfNodes()
  if n == 0:
    return initTable[N, float]()

  var nodeList = newSeqOfCap[N](n)
  for node in g.adj.keys:
    nodeList.add(node)

  result = initTable[N, float]()
  var newVals = initTable[N, float]()
  for node in nodeList:
    result[node] = 0.0
    newVals[node] = 0.0

  for _ in 0 ..< maxIter:
    for node in nodeList:
      var s = beta
      for neighbor in g.adj[node].keys:
        s += alpha * result[neighbor]
      newVals[node] = s

    var diff = 0.0
    for node in nodeList:
      diff += abs(newVals[node] - result[node])
    swap(result, newVals)
    if diff < tol:
      break

# =============================================================================
# Harmonic centrality
# =============================================================================

proc harmonicCentrality*[N](g: Graph[N]): Table[N, float] =
  ## Compute harmonic centrality for all nodes.
  ## H(u) = sum(1/d(u,v) for all reachable v != u) / (n-1)
  ## Handles disconnected graphs naturally (unreachable nodes contribute 0).
  let n = g.numberOfNodes()
  result = initTable[N, float]()
  if n <= 1:
    for node in g.nodes:
      result[node] = 0.0
    return
  let norm = 1.0 / float(n - 1)
  for source in g.nodes:
    var dist = initTable[N, int]()
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let current = queue.popFirst()
      let cd = dist[current]
      for neighbor in g.neighbors(current):
        if neighbor notin dist:
          dist[neighbor] = cd + 1
          queue.addLast(neighbor)
    var harmSum = 0.0
    for node, d in dist:
      if node != source and d > 0:
        harmSum += 1.0 / float(d)
    result[source] = harmSum * norm

proc harmonicCentrality*[N](g: DiGraph[N]): Table[N, float] =
  ## Compute harmonic centrality for all nodes in a directed graph.
  ## H(u) = sum(1/d(v,u) for all v that can reach u) / (n-1)
  let n = g.numberOfNodes()
  result = initTable[N, float]()
  if n <= 1:
    for node in g.nodes:
      result[node] = 0.0
    return
  # For each source, BFS gives distances to all reachable nodes.
  # For harmonic centrality of v, we need sum(1/d(u,v)) from all u.
  # So we accumulate contributions from each source's BFS.
  for node in g.nodes:
    result[node] = 0.0
  let norm = 1.0 / float(n - 1)
  for source in g.nodes:
    var dist = initTable[N, int]()
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let current = queue.popFirst()
      let cd = dist[current]
      for neighbor in g.neighbors(current):
        if neighbor notin dist:
          dist[neighbor] = cd + 1
          queue.addLast(neighbor)
    for target, d in dist:
      if target != source and d > 0:
        result[target] += 1.0 / float(d)
  for node in g.nodes:
    result[node] *= norm
