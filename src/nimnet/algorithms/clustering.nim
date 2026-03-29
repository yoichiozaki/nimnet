## Clustering coefficient and transitivity

import std/[tables, sets, math]
import ../types
import ../graph

# =============================================================================
# Clustering coefficient
# =============================================================================

proc clusteringCoefficient*[N](g: Graph[N], n: N): float =
  ## Compute the local clustering coefficient for node n.
  ## C(n) = 2 * triangles(n) / (degree(n) * (degree(n) - 1))
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  let deg = g.degree(n)
  if deg < 2:
    return 0.0
  var triangles = 0
  let neighbors = block:
    var s = initHashSet[N]()
    for nb in g.neighbors(n):
      s.incl(nb)
    s
  for u in neighbors:
    for v in neighbors:
      if u != v and g.hasEdge(u, v):
        triangles.inc
  # Each triangle counted twice (u,v) and (v,u)
  triangles = triangles div 2
  result = 2.0 * float(triangles) / (float(deg) * float(deg - 1))

proc clustering*[N](g: Graph[N]): Table[N, float] =
  ## Compute local clustering coefficient for all nodes.
  result = initTable[N, float]()
  for n in g.nodes:
    result[n] = clusteringCoefficient(g, n)

proc averageClustering*[N](g: Graph[N]): float =
  ## Compute the average clustering coefficient of the graph.
  let n = g.numberOfNodes()
  if n == 0:
    return 0.0
  var total = 0.0
  for node in g.nodes:
    total += clusteringCoefficient(g, node)
  result = total / float(n)

proc transitivity*[N](g: Graph[N]): float =
  ## Compute the graph transitivity (ratio of triangles to triads).
  ## T = 3 * number_of_triangles / number_of_triads
  var triangles = 0
  var triads = 0
  for v in g.nodes:
    let neighbors = block:
      var s = initHashSet[N]()
      for nb in g.neighbors(v):
        s.incl(nb)
      s
    let dv = neighbors.len
    triads += dv * (dv - 1)
    for u in neighbors:
      for w in neighbors:
        if u != w and g.hasEdge(u, w):
          triangles.inc
  # Each triangle counted 6 times (3 vertices * 2 orderings)
  if triads == 0:
    return 0.0
  result = float(triangles) / float(triads)

proc triangles*[N](g: Graph[N], n: N): int =
  ## Count the number of triangles that include node n.
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  let neighbors = block:
    var s = initHashSet[N]()
    for nb in g.neighbors(n):
      s.incl(nb)
    s
  for u in neighbors:
    for v in neighbors:
      if u != v and g.hasEdge(u, v):
        result.inc
  result = result div 2

proc trianglesMap*[N](g: Graph[N]): Table[N, int] =
  ## Count triangles for each node.
  result = initTable[N, int]()
  for n in g.nodes:
    result[n] = triangles(g, n)
