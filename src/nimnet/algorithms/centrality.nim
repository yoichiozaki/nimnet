## Centrality measures for nimnet

import std/[tables, sets, deques, algorithm, math]
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

# =============================================================================
# Edge Betweenness Centrality (#121)
# =============================================================================

proc edgeBetweennessCentrality*[N](g: Graph[N], normalized: bool = true): Table[(N, N), float] =
  ## Compute edge betweenness centrality for all edges.
  ## Uses Brandes' algorithm adapted for edges.
  result = initTable[(N, N), float]()
  for (u, v) in g.edges:
    result[(u, v)] = 0.0
    result[(v, u)] = 0.0
  let n = g.numberOfNodes()
  for source in g.nodes:
    var stack = newSeq[N]()
    var pred = initTable[N, seq[N]]()
    for node in g.nodes:
      pred[node] = newSeq[N]()
    var sigma = initTable[N, float]()
    var dist = initTable[N, int]()
    for node in g.nodes:
      sigma[node] = 0.0
      dist[node] = -1
    sigma[source] = 1.0
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for w in g.neighbors(v):
        if dist[w] < 0:
          queue.addLast(w)
          dist[w] = dist[v] + 1
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)
    var delta = initTable[N, float]()
    for node in g.nodes:
      delta[node] = 0.0
    for i in countdown(stack.len - 1, 0):
      let w = stack[i]
      let coeff = (1.0 + delta[w]) / sigma[w]
      for v in pred[w]:
        let c = sigma[v] * coeff
        if (v, w) in result:
          result[(v, w)] += c
        elif (w, v) in result:
          result[(w, v)] += c
        delta[v] += c
  # Normalize: each edge counted from both endpoints
  if normalized and n > 1:
    let norm = 1.0 / float(n * (n - 1))
    for key in result.keys:
      result[key] *= norm
  else:
    for key in result.keys:
      result[key] *= 0.5

proc edgeBetweennessCentrality*[N](g: DiGraph[N], normalized: bool = true): Table[(N, N), float] =
  ## Compute edge betweenness centrality for a directed graph.
  result = initTable[(N, N), float]()
  for (u, v) in g.edges:
    result[(u, v)] = 0.0
  let n = g.numberOfNodes()
  for source in g.nodes:
    var stack = newSeq[N]()
    var pred = initTable[N, seq[N]]()
    for node in g.nodes:
      pred[node] = newSeq[N]()
    var sigma = initTable[N, float]()
    var dist = initTable[N, int]()
    for node in g.nodes:
      sigma[node] = 0.0
      dist[node] = -1
    sigma[source] = 1.0
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for w in g.neighbors(v):
        if dist[w] < 0:
          queue.addLast(w)
          dist[w] = dist[v] + 1
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)
    var delta = initTable[N, float]()
    for node in g.nodes:
      delta[node] = 0.0
    for i in countdown(stack.len - 1, 0):
      let w = stack[i]
      let coeff = (1.0 + delta[w]) / sigma[w]
      for v in pred[w]:
        let c = sigma[v] * coeff
        if (v, w) in result:
          result[(v, w)] += c
        delta[v] += c
  if normalized and n > 1:
    let norm = 1.0 / float(n * (n - 1))
    for key in result.keys:
      result[key] *= norm

# =============================================================================
# Load Centrality (#121)
# =============================================================================

proc loadCentrality*[N](g: Graph[N], normalized: bool = true): Table[N, float] =
  ## Compute load centrality (Newman's variant of betweenness).
  ## Counts the fraction of shortest paths through each node.
  result = initTable[N, float]()
  for node in g.nodes:
    result[node] = 0.0
  let n = g.numberOfNodes()
  for source in g.nodes:
    var stack = newSeq[N]()
    var pred = initTable[N, seq[N]]()
    var sigma = initTable[N, float]()
    var dist = initTable[N, int]()
    for node in g.nodes:
      pred[node] = newSeq[N]()
      sigma[node] = 0.0
      dist[node] = -1
    sigma[source] = 1.0
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for w in g.neighbors(v):
        if dist[w] < 0:
          queue.addLast(w)
          dist[w] = dist[v] + 1
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)
    var delta = initTable[N, float]()
    for node in g.nodes:
      delta[node] = 0.0
    for i in countdown(stack.len - 1, 0):
      let w = stack[i]
      let coeff = (1.0 + delta[w]) / sigma[w]
      for v in pred[w]:
        delta[v] += sigma[v] * coeff
    for node in g.nodes:
      if node != source:
        result[node] += delta[node]
  if normalized and n > 2:
    let norm = 1.0 / float((n - 1) * (n - 2))
    for node in g.nodes:
      result[node] *= norm

# =============================================================================
# Subgraph Centrality (#121)
# =============================================================================

proc subgraphCentrality*[N](g: Graph[N]): Table[N, float] =
  ## Compute subgraph centrality using walks of different lengths.
  ## SC(v) = sum_{k=0}^{infty} (A^k)_{vv} / k!
  ## Approximated using limited walk lengths.
  result = initTable[N, float]()
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0: return
  var nodeIdx = initTable[N, int]()
  for i, node in nodes:
    nodeIdx[node] = i
    result[node] = 1.0  # k=0 term
  # Build adjacency matrix and compute matrix powers
  var mat = newSeq[seq[float]](n)
  for i in 0 ..< n:
    mat[i] = newSeq[float](n)
  for (u, v) in g.edges:
    let ui = nodeIdx[u]
    let vi = nodeIdx[v]
    mat[ui][vi] = 1.0
    mat[vi][ui] = 1.0
  # Compute A^k / k! iteratively
  var power = newSeq[seq[float]](n)  # A^k
  for i in 0 ..< n:
    power[i] = newSeq[float](n)
    power[i][i] = 1.0  # A^0 = I
  var factorial = 1.0
  let maxK = min(n, 20)  # limit iterations
  for k in 1 .. maxK:
    factorial *= float(k)
    # power = power * mat
    var newPower = newSeq[seq[float]](n)
    for i in 0 ..< n:
      newPower[i] = newSeq[float](n)
      for j in 0 ..< n:
        for l in 0 ..< n:
          newPower[i][j] += power[i][l] * mat[l][j]
    power = newPower
    for i in 0 ..< n:
      result[nodes[i]] += power[i][i] / factorial

# =============================================================================
# Dispersion (#121)
# =============================================================================

proc dispersion*[N](g: Graph[N], u, v: N): float =
  ## Compute the dispersion between two nodes u and v.
  ## Dispersion measures how much u's neighbors are connected to each
  ## other only through u and v.
  var uNeighbors = initHashSet[N]()
  for n in g.neighbors(u):
    uNeighbors.incl(n)
  var vNeighbors = initHashSet[N]()
  for n in g.neighbors(v):
    vNeighbors.incl(n)
  # Common neighbors of both u and v (excluding u and v themselves)
  var common = initHashSet[N]()
  for n in uNeighbors:
    if n in vNeighbors and n != u and n != v:
      common.incl(n)
  if common.len == 0:
    return 0.0
  var disp = 0.0
  let commonSeq = common.toSeq()
  for i in 0 ..< commonSeq.len:
    for j in i + 1 ..< commonSeq.len:
      let s = commonSeq[i]
      let t = commonSeq[j]
      # Check if s and t are NOT connected through paths
      # that don't go through u or v
      if not g.hasEdge(s, t):
        var hasCommonNeighborOutside = false
        for ns in g.neighbors(s):
          if ns != u and ns != v and ns notin common and g.hasEdge(ns, t):
            hasCommonNeighborOutside = true
            break
        if not hasCommonNeighborOutside:
          disp += 1.0
  result = disp

# =============================================================================
# VoteRank (#121)
# =============================================================================

proc voteRank*[N](g: Graph[N], k: int = 0): seq[N] =
  ## Select influential nodes using the VoteRank algorithm.
  ## Returns up to k nodes (0 = all possible).
  let n = g.numberOfNodes()
  if n == 0: return @[]
  let maxK = if k <= 0: n else: min(k, n)
  var votingAbility = initTable[N, float]()
  for node in g.nodes:
    votingAbility[node] = 1.0
  let avgDeg = if n > 1: float(2 * g.numberOfEdges()) / float(n)
               else: 0.0
  let dampFactor = if avgDeg > 0.0: 1.0 / avgDeg else: 0.0
  for _ in 0 ..< maxK:
    # Count votes
    var scores = initTable[N, float]()
    for node in g.nodes:
      if votingAbility[node] <= 0.0: continue
      scores[node] = 0.0
    for node in g.nodes:
      if votingAbility[node] <= 0.0: continue
      for nbr in g.neighbors(node):
        if nbr in scores:
          scores[nbr] += votingAbility[node]
    if scores.len == 0: break
    # Find node with highest score
    var bestNode: N
    var bestScore = -1.0
    var found = false
    for node, score in scores:
      if score > bestScore:
        bestScore = score
        bestNode = node
        found = true
    if not found or bestScore <= 0.0: break
    result.add(bestNode)
    # Remove winner's voting ability and reduce neighbors' ability
    votingAbility[bestNode] = 0.0
    for nbr in g.neighbors(bestNode):
      votingAbility[nbr] = max(0.0, votingAbility[nbr] - dampFactor)

# =============================================================================
# Laplacian Centrality (#121)
# =============================================================================

proc laplacianCentrality*[N](g: Graph[N], normalized: bool = true): Table[N, float] =
  ## Compute Laplacian centrality for all nodes.
  ## Based on the drop in Laplacian energy when a node is removed.
  ## LC(v) = (deg(v))^2 + deg(v) + 2 * sum(deg(u) for u in neighbors(v))
  result = initTable[N, float]()
  let n = g.numberOfNodes()
  if n == 0: return
  var totalEnergy = 0.0
  for node in g.nodes:
    let d = float(g.degree(node))
    totalEnergy += d * d
  for node in g.nodes:
    let d = float(g.degree(node))
    var sumNeighDeg = 0.0
    for nbr in g.neighbors(node):
      sumNeighDeg += float(g.degree(nbr))
    let lc = d * d + d + 2.0 * sumNeighDeg
    if normalized and totalEnergy > 0.0:
      result[node] = lc / totalEnergy
    else:
      result[node] = lc

# =============================================================================
# Reaching Centrality (#121)
# =============================================================================

proc localReachingCentrality*[N](g: DiGraph[N], v: N): float =
  ## Compute local reaching centrality of node v in a directed graph.
  ## Fraction of other nodes reachable from v.
  let n = g.numberOfNodes()
  if n <= 1: return 0.0
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  visited.incl(v)
  queue.addLast(v)
  while queue.len > 0:
    let u = queue.popFirst()
    for w in g.neighbors(u):
      if w notin visited:
        visited.incl(w)
        queue.addLast(w)
  result = float(visited.len - 1) / float(n - 1)

proc globalReachingCentrality*[N](g: DiGraph[N]): float =
  ## Compute global reaching centrality.
  ## Maximum local reaching centrality minus average.
  let n = g.numberOfNodes()
  if n <= 1: return 0.0
  var maxLRC = 0.0
  var sumLRC = 0.0
  for node in g.nodes:
    let lrc = localReachingCentrality(g, node)
    sumLRC += lrc
    if lrc > maxLRC:
      maxLRC = lrc
  let avgLRC = sumLRC / float(n)
  var sumDiff = 0.0
  for node in g.nodes:
    let lrc = localReachingCentrality(g, node)
    sumDiff += (maxLRC - lrc)
  result = sumDiff / float(n - 1)

# =============================================================================
# Percolation Centrality (#121)
# =============================================================================

proc percolationCentrality*[N](g: Graph[N], states: Table[N, float] = initTable[N, float]()): Table[N, float] =
  ## Compute percolation centrality.
  ## Uses the fraction of "percolated" paths through each node.
  ## If states not provided, uses uniform state = 1/n.
  result = initTable[N, float]()
  let n = g.numberOfNodes()
  if n <= 2:
    for node in g.nodes:
      result[node] = 0.0
    return
  var nodeStates = states
  if nodeStates.len == 0:
    let s = 1.0 / float(n)
    for node in g.nodes:
      nodeStates[node] = s
  for node in g.nodes:
    result[node] = 0.0
  for source in g.nodes:
    var stack = newSeq[N]()
    var pred = initTable[N, seq[N]]()
    var sigma = initTable[N, float]()
    var dist = initTable[N, int]()
    for node in g.nodes:
      pred[node] = newSeq[N]()
      sigma[node] = 0.0
      dist[node] = -1
    sigma[source] = 1.0
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for w in g.neighbors(v):
        if dist[w] < 0:
          queue.addLast(w)
          dist[w] = dist[v] + 1
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)
    var delta = initTable[N, float]()
    for node in g.nodes:
      delta[node] = 0.0
    for i in countdown(stack.len - 1, 0):
      let w = stack[i]
      let coeff = (nodeStates[w] + delta[w]) / sigma[w]
      for v in pred[w]:
        delta[v] += sigma[v] * coeff
    for node in g.nodes:
      if node != source:
        result[node] += delta[node]
  # Normalize
  let norm = 1.0 / float(n - 2)
  for node in g.nodes:
    result[node] *= norm

# =============================================================================
# Second Order Centrality (#121)
# =============================================================================

proc secondOrderCentrality*[N](g: Graph[N]): Table[N, float] =
  ## Compute second-order centrality based on random walk standard deviation.
  ## SOC(v) = standard deviation of return times of a random walk.
  result = initTable[N, float]()
  let n = g.numberOfNodes()
  if n <= 1:
    for node in g.nodes:
      result[node] = 0.0
    return
  # Approximate using degree-based formula:
  # SOC(v) ≈ sqrt(n) * (2m / (deg(v) * n))
  let m = float(g.numberOfEdges())
  let nf = float(n)
  for node in g.nodes:
    let d = float(g.degree(node))
    if d > 0.0:
      result[node] = sqrt(nf) * (2.0 * m) / (d * nf)
    else:
      result[node] = Inf

# =============================================================================
# Trophic Levels (#121)
# =============================================================================

proc trophicLevels*[N](g: DiGraph[N]): Table[N, float] =
  ## Compute trophic levels of nodes in a directed graph (food web).
  ## Basal nodes (in-degree 0) have trophic level 1.
  ## Other nodes: TL(v) = 1 + avg(TL(u) for u in predecessors(v))
  ## Solved iteratively.
  result = initTable[N, float]()
  let n = g.numberOfNodes()
  if n == 0: return
  for node in g.nodes:
    if g.inDegree(node) == 0:
      result[node] = 1.0
    else:
      result[node] = 1.0
  # Iterate until convergence
  for _ in 0 ..< 100:
    var maxDiff = 0.0
    for node in g.nodes:
      if g.inDegree(node) == 0:
        continue
      var sumPred = 0.0
      var count = 0
      for p in g.predecessors(node):
        sumPred += result[p]
        count.inc
      let newLevel = 1.0 + sumPred / float(count)
      let diff = abs(newLevel - result[node])
      if diff > maxDiff:
        maxDiff = diff
      result[node] = newLevel
    if maxDiff < 1.0e-10:
      break
