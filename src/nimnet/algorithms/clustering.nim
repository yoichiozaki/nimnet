## Clustering coefficient and transitivity
##
## Uses sorted adjacency intersection for efficient triangle counting.

import std/[tables, sets, algorithm]
import ../types
import ../graph

# =============================================================================
# Fast triangle counting — sorted set intersection
# =============================================================================

proc trianglesMap*[N](g: Graph[N]): Table[N, int] =
  ## Count triangles for each node using sorted adjacency intersection.
  ## Each triangle {i,j,k} is counted exactly once (order i < j < k)
  ## then attributed to all three vertices.
  let n = g.numberOfNodes()
  if n == 0:
    return initTable[N, int]()

  # Build indexed adjacency with sorted neighbor lists
  var nodeList = newSeqOfCap[N](n)
  var nodeIdx = initTable[N, int](n)
  var idx = 0
  for node in g.adj.keys:
    nodeIdx[node] = idx
    nodeList.add(node)
    idx.inc

  var adjSorted = newSeq[seq[int]](n)
  for i in 0 ..< n:
    let node = nodeList[i]
    adjSorted[i] = newSeqOfCap[int](g.adj[node].len)
    for neighbor in g.adj[node].keys:
      adjSorted[i].add(nodeIdx[neighbor])
    adjSorted[i].sort()

  # For each edge (i,j) with i < j, count common neighbors k > j
  var triCount = newSeq[int](n)
  for i in 0 ..< n:
    let adjI = adjSorted[i]
    let lenI = adjI.len
    for jPos in 0 ..< lenI:
      let j = adjI[jPos]
      if j <= i: continue  # only process each edge once (i < j)
      let adjJ = adjSorted[j]
      let lenJ = adjJ.len
      # Sorted intersection counting only k > j
      var pi = jPos + 1  # start past j in adjI (all earlier are <= j)
      var pj = 0
      # Advance pj past j
      while pj < lenJ and adjJ[pj] <= j:
        pj.inc
      while pi < lenI and pj < lenJ:
        let wi = adjI[pi]
        let wj = adjJ[pj]
        if wi < wj:
          pi.inc
        elif wi > wj:
          pj.inc
        else:
          # Common neighbor k = wi = wj, and k > j > i
          triCount[i] += 1
          triCount[j] += 1
          triCount[wi] += 1
          pi.inc
          pj.inc

  result = initTable[N, int](n)
  for i in 0 ..< n:
    result[nodeList[i]] = triCount[i]

proc triangles*[N](g: Graph[N], n: N): int =
  ## Count the number of triangles that include node n.
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  let neighbors = g.adj[n]
  for u in neighbors.keys:
    let uAdj = g.adj[u]
    for v in neighbors.keys:
      if u != v and v in uAdj:
        result.inc
  result = result div 2

# =============================================================================
# Clustering coefficient
# =============================================================================

proc clusteringCoefficient*[N](g: Graph[N], n: N): float =
  ## Compute the local clustering coefficient for node n.
  ## C(n) = 2 * triangles(n) / (degree(n) * (degree(n) - 1))
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  let deg = g.adj[n].len
  if deg < 2:
    return 0.0
  let tri = triangles(g, n)
  result = 2.0 * float(tri) / (float(deg) * float(deg - 1))

proc clustering*[N](g: Graph[N]): Table[N, float] =
  ## Compute local clustering coefficient for all nodes.
  ## Uses single-pass triangle counting for efficiency.
  let tmap = trianglesMap(g)
  result = initTable[N, float]()
  for node in g.adj.keys:
    let deg = g.adj[node].len
    if deg < 2:
      result[node] = 0.0
    else:
      result[node] = 2.0 * float(tmap[node]) / (float(deg) * float(deg - 1))

proc averageClustering*[N](g: Graph[N]): float =
  ## Compute the average clustering coefficient of the graph.
  ## Uses single-pass triangle counting for efficiency.
  let n = g.numberOfNodes()
  if n == 0:
    return 0.0
  let tmap = trianglesMap(g)
  var total = 0.0
  for node in g.adj.keys:
    let deg = g.adj[node].len
    if deg >= 2:
      total += 2.0 * float(tmap[node]) / (float(deg) * float(deg - 1))
  result = total / float(n)

proc transitivity*[N](g: Graph[N]): float =
  ## Compute the graph transitivity (ratio of triangles to triads).
  ## T = 3 * number_of_triangles / number_of_triads
  let tmap = trianglesMap(g)
  var totalTriangles = 0
  var triads = 0
  for node in g.adj.keys:
    let dv = g.adj[node].len
    triads += dv * (dv - 1)
    totalTriangles += tmap[node]
  if triads == 0:
    return 0.0
  # totalTriangles = sum of per-node triangle counts = 3T
  # triads = sum of dv*(dv-1) = ordered 2-paths
  # Original formula: 6T / triads, so 2 * 3T / triads
  result = 2.0 * float(totalTriangles) / float(triads)

# =============================================================================
# Square clustering
# =============================================================================

proc squareClustering*[N](g: Graph[N], n: N): float =
  ## Compute the square clustering coefficient for node n.
  ## Ratio of squares (4-cycles) to potential squares through n.
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  let neighborsN = g.adj[n]
  let deg = neighborsN.len
  if deg < 2:
    return 0.0
  var squares = 0
  var potential = 0
  let nbrList = block:
    var s: seq[N]
    for k in neighborsN.keys: s.add(k)
    s
  for i in 0 ..< nbrList.len:
    let u = nbrList[i]
    for j in i + 1 ..< nbrList.len:
      let v = nbrList[j]
      potential.inc
      # Count common neighbors of u and v that are not n
      for w in g.neighbors(u):
        if w != n and w != v and g.hasEdge(w, v):
          squares.inc
  if potential == 0:
    return 0.0
  result = squares.float / potential.float

proc squareClustering*[N](g: Graph[N]): Table[N, float] =
  ## Compute square clustering coefficient for all nodes.
  result = initTable[N, float]()
  for n in g.nodes:
    result[n] = squareClustering(g, n)

# =============================================================================
# Generalized degree
# =============================================================================

proc generalizedDegree*[N](g: Graph[N], n: N): Table[int, int] =
  ## Compute the generalized degree for node n.
  ## Returns a table mapping k -> number of edges incident to n that
  ## belong to exactly k triangles.
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  result = initTable[int, int]()
  let neighborsN = g.adj[n]
  for u in neighborsN.keys:
    # Count triangles containing edge (n, u)
    var triCount = 0
    for w in g.neighbors(u):
      if w != n and w in neighborsN:
        triCount.inc
    result[triCount] = result.getOrDefault(triCount, 0) + 1

proc generalizedDegree*[N](g: Graph[N]): Table[N, Table[int, int]] =
  ## Compute generalized degree for all nodes.
  result = initTable[N, Table[int, int]]()
  for n in g.nodes:
    result[n] = generalizedDegree(g, n)

# =============================================================================
# All triangles (as node sets)
# =============================================================================

proc allTriangles*[N](g: Graph[N]): seq[(N, N, N)] =
  ## Return all triangles in the graph as (u, v, w) tuples.
  ## Each triangle is returned exactly once.
  let n = g.numberOfNodes()
  if n < 3:
    return @[]
  var nodeList = newSeqOfCap[N](n)
  var nodeIdx = initTable[N, int](n)
  var idx = 0
  for node in g.adj.keys:
    nodeIdx[node] = idx
    nodeList.add(node)
    idx.inc
  # For each edge (i,j) with idx(i) < idx(j), find common neighbor k with idx(k) > idx(j)
  for i in 0 ..< n:
    let u = nodeList[i]
    for v in g.neighbors(u):
      let j = nodeIdx[v]
      if j <= i: continue
      for w in g.neighbors(v):
        let k = nodeIdx[w]
        if k <= j: continue
        if g.hasEdge(w, u):
          result.add((u, v, w))
