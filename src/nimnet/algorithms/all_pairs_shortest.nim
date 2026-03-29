## All-pairs shortest paths: Floyd-Warshall and Johnson's algorithm
##
## Floyd-Warshall computes shortest paths between all pairs in O(V^3).
## Johnson's algorithm uses Bellman-Ford + Dijkstra for sparse graphs.

import std/[tables, sets, heapqueue]
import ../graph
import ../digraph

proc floydWarshall*[N](g: Graph[N]): Table[N, Table[N, float]] =
  ## Compute shortest path lengths between all pairs of nodes.
  ## Returns a table of tables: dist[u][v] = shortest distance from u to v.
  ## Uses edge weights if available (default weight = 1.0).
  let nodes = g.nodeSeq()
  let n = nodes.len
  result = initTable[N, Table[N, float]]()

  # Initialize distances
  for u in nodes:
    result[u] = initTable[N, float]()
    for v in nodes:
      if u == v:
        result[u][v] = 0.0
      else:
        result[u][v] = Inf

  # Set edge weights
  for (u, v) in g.edges:
    let w = g.getEdgeAttr(u, v).getWeight()
    if w < result[u][v]:
      result[u][v] = w
      result[v][u] = w

  # Floyd-Warshall relaxation
  for k in nodes:
    for i in nodes:
      for j in nodes:
        let through_k = result[i][k] + result[k][j]
        if through_k < result[i][j]:
          result[i][j] = through_k

proc floydWarshall*[N](g: DiGraph[N]): Table[N, Table[N, float]] =
  ## Compute shortest path lengths between all pairs in a directed graph.
  let nodes = g.nodeSeq()
  result = initTable[N, Table[N, float]]()

  for u in nodes:
    result[u] = initTable[N, float]()
    for v in nodes:
      if u == v:
        result[u][v] = 0.0
      else:
        result[u][v] = Inf

  for (u, v) in g.edges:
    let w = g.getEdgeAttr(u, v).getWeight()
    if w < result[u][v]:
      result[u][v] = w

  for k in nodes:
    for i in nodes:
      for j in nodes:
        let through_k = result[i][k] + result[k][j]
        if through_k < result[i][j]:
          result[i][j] = through_k

proc floydWarshallPaths*[N](g: Graph[N]): (Table[N, Table[N, float]], Table[N, Table[N, N]]) =
  ## Compute shortest path lengths and predecessors between all pairs.
  ## Returns (dist, pred) where pred[i][j] is the predecessor of j on the shortest path from i.
  let nodes = g.nodeSeq()
  var dist = initTable[N, Table[N, float]]()
  var pred = initTable[N, Table[N, N]]()

  for u in nodes:
    dist[u] = initTable[N, float]()
    pred[u] = initTable[N, N]()
    for v in nodes:
      if u == v:
        dist[u][v] = 0.0
      else:
        dist[u][v] = Inf

  for (u, v) in g.edges:
    let w = g.getEdgeAttr(u, v).getWeight()
    if w < dist[u][v]:
      dist[u][v] = w
      dist[v][u] = w
      pred[u][v] = u
      pred[v][u] = v

  for k in nodes:
    for i in nodes:
      for j in nodes:
        let through_k = dist[i][k] + dist[k][j]
        if through_k < dist[i][j]:
          dist[i][j] = through_k
          pred[i][j] = pred[k][j]

  result = (dist, pred)

proc johnsons*[N](g: DiGraph[N]): Table[N, Table[N, float]] =
  ## Johnson's algorithm for all-pairs shortest paths in sparse digraphs.
  ## Handles negative edge weights (but not negative cycles).
  ## O(VE + V^2 log V) using Bellman-Ford + reweighting + Dijkstra.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0:
    return initTable[N, Table[N, float]]()

  # Step 1: Add virtual source connected to all nodes with weight 0
  # Compute h[v] using Bellman-Ford from virtual source
  var h = initTable[N, float]()
  for v in nodes:
    h[v] = 0.0

  # Bellman-Ford relaxation (V-1 iterations)
  for i in 0 ..< n - 1:
    for (u, v) in g.edges:
      let w = g.getEdgeAttr(u, v).getWeight()
      if h[u] + w < h[v]:
        h[v] = h[u] + w

  # Step 2: Reweight edges: w'(u,v) = w(u,v) + h(u) - h(v) >= 0
  # Step 3: Run Dijkstra from each node with reweighted edges
  result = initTable[N, Table[N, float]]()

  type DijkEntry = tuple[dist: float, node: N]

  for source in nodes:
    var dist = initTable[N, float]()
    var visited = initHashSet[N]()
    var pq = initHeapQueue[DijkEntry]()

    dist[source] = 0.0
    pq.push((0.0, source))

    while pq.len > 0:
      let (d, u) = pq.pop()
      if u in visited:
        continue
      visited.incl(u)

      for v in g.neighbors(u):
        if v notin visited:
          let w = g.getEdgeAttr(u, v).getWeight()
          let reweighted = w + h[u] - h[v]
          let newDist = d + reweighted
          if v notin dist or newDist < dist[v]:
            dist[v] = newDist
            pq.push((newDist, v))

    # Convert back: real_dist[u][v] = reweighted_dist - h[u] + h[v]
    result[source] = initTable[N, float]()
    for v, d in dist:
      result[source][v] = d - h[source] + h[v]
