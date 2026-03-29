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
