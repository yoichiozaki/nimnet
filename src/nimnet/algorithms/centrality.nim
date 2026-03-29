## Centrality measures for nimnet

import std/[tables, deques, math]
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
  for source in g.nodes:
    # BFS for shortest path lengths
    var dist = initTable[N, int]()
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let current = queue.popFirst()
      for neighbor in g.neighbors(current):
        if neighbor notin dist:
          dist[neighbor] = dist[current] + 1
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
  for n in g.nodes:
    result[n] = 0.0

  for s in g.nodes:
    # Single-source shortest paths
    var stack: seq[N]
    var pred = initTable[N, seq[N]]()
    for n in g.nodes:
      pred[n] = @[]
    var sigma = initTable[N, float]()
    for n in g.nodes:
      sigma[n] = 0.0
    sigma[s] = 1.0
    var dist = initTable[N, int]()
    dist[s] = 0

    var queue = initDeque[N]()
    queue.addLast(s)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for w in g.neighbors(v):
        # Path discovery
        if w notin dist:
          dist[w] = dist[v] + 1
          queue.addLast(w)
        # Path counting
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)

    # Accumulation
    var delta = initTable[N, float]()
    for n in g.nodes:
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
  ## Compute PageRank using power iteration.
  ## alpha: damping factor (default 0.85)
  let n = g.numberOfNodes()
  if n == 0:
    return initTable[N, float]()

  # Initialize
  let initVal = 1.0 / float(n)
  result = initTable[N, float]()
  for node in g.nodes:
    result[node] = initVal

  for _ in 0 ..< maxIter:
    var newRank = initTable[N, float]()
    # Sum of dangling nodes (nodes with no out-edges)
    var danglingSum = 0.0
    for node in g.nodes:
      if g.outDegree(node) == 0:
        danglingSum += result[node]

    for node in g.nodes:
      var rank = (1.0 - alpha + alpha * danglingSum) / float(n)
      for pred in g.predecessors(node):
        rank += alpha * result[pred] / float(g.outDegree(pred))
      newRank[node] = rank

    # Check convergence
    var diff = 0.0
    for node in g.nodes:
      diff += abs(newRank[node] - result[node])
    result = newRank
    if diff < tol:
      break

proc pageRank*[N](g: Graph[N], alpha: float = 0.85, maxIter: int = 100,
                   tol: float = 1.0e-6): Table[N, float] =
  ## Compute PageRank for undirected graph (treated as bidirectional).
  let n = g.numberOfNodes()
  if n == 0:
    return initTable[N, float]()

  let initVal = 1.0 / float(n)
  result = initTable[N, float]()
  for node in g.nodes:
    result[node] = initVal

  for _ in 0 ..< maxIter:
    var newRank = initTable[N, float]()
    for node in g.nodes:
      var rank = (1.0 - alpha) / float(n)
      for neighbor in g.neighbors(node):
        rank += alpha * result[neighbor] / float(g.degree(neighbor))
      newRank[node] = rank

    var diff = 0.0
    for node in g.nodes:
      diff += abs(newRank[node] - result[node])
    result = newRank
    if diff < tol:
      break
