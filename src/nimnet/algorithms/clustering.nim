## Clustering coefficient and transitivity

import std/[tables, sets]
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
  let neighbors = g.adj[n]
  let deg = neighbors.len
  if deg < 2:
    return 0.0
  var triangles = 0
  for u in neighbors.keys:
    let uAdj = g.adj[u]
    for v in neighbors.keys:
      if u != v and v in uAdj:
        triangles.inc
  # Each triangle counted twice (u,v) and (v,u)
  triangles = triangles div 2
  result = 2.0 * float(triangles) / (float(deg) * float(deg - 1))

proc clustering*[N](g: Graph[N]): Table[N, float] =
  ## Compute local clustering coefficient for all nodes.
  result = initTable[N, float]()
  for n in g.adj.keys:
    result[n] = clusteringCoefficient(g, n)

proc averageClustering*[N](g: Graph[N]): float =
  ## Compute the average clustering coefficient of the graph.
  let n = g.numberOfNodes()
  if n == 0:
    return 0.0
  var total = 0.0
  for node in g.adj.keys:
    total += clusteringCoefficient(g, node)
  result = total / float(n)

proc transitivity*[N](g: Graph[N]): float =
  ## Compute the graph transitivity (ratio of triangles to triads).
  ## T = 3 * number_of_triangles / number_of_triads
  var triangles = 0
  var triads = 0
  for v in g.adj.keys:
    let neighbors = g.adj[v]
    let dv = neighbors.len
    triads += dv * (dv - 1)
    for u in neighbors.keys:
      let uAdj = g.adj[u]
      for w in neighbors.keys:
        if u != w and w in uAdj:
          triangles.inc
  # Each triangle counted 6 times (3 vertices * 2 orderings)
  if triads == 0:
    return 0.0
  result = float(triangles) / float(triads)

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

proc trianglesMap*[N](g: Graph[N]): Table[N, int] =
  ## Count triangles for each node.
  result = initTable[N, int]()
  for n in g.adj.keys:
    result[n] = triangles(g, n)
