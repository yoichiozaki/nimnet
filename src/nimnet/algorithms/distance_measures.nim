## Distance measures for graphs
##
## Eccentricity, diameter, radius, center, and periphery.

import std/[tables, sets, deques]
import ../graph

proc eccentricity*[N](g: Graph[N], n: N): int =
  ## Return the eccentricity of node n — the maximum shortest-path
  ## distance from n to any other reachable node.
  ## Returns 0 for isolated nodes in a single-component context.
  var dist = initTable[N, int]()
  dist[n] = 0
  var queue = initDeque[N]()
  queue.addLast(n)
  while queue.len > 0:
    let u = queue.popFirst()
    for v in g.neighbors(u):
      if v notin dist:
        dist[v] = dist[u] + 1
        queue.addLast(v)
  result = 0
  for d in dist.values:
    if d > result:
      result = d

proc eccentricityMap*[N](g: Graph[N]): Table[N, int] =
  ## Return a table mapping each node to its eccentricity.
  for n in g.nodes:
    result[n] = eccentricity(g, n)

proc diameter*[N](g: Graph[N]): int =
  ## Return the diameter — the maximum eccentricity in the graph.
  let ecc = eccentricityMap(g)
  result = 0
  for e in ecc.values:
    if e > result:
      result = e

proc radius*[N](g: Graph[N]): int =
  ## Return the radius — the minimum eccentricity in the graph.
  let ecc = eccentricityMap(g)
  result = high(int)
  for e in ecc.values:
    if e < result:
      result = e
  if result == high(int):
    result = 0

proc center*[N](g: Graph[N]): seq[N] =
  ## Return the center — nodes with eccentricity equal to the radius.
  let ecc = eccentricityMap(g)
  let r = radius(g)
  for n in g.nodes:
    if ecc[n] == r:
      result.add(n)

proc periphery*[N](g: Graph[N]): seq[N] =
  ## Return the periphery — nodes with eccentricity equal to the diameter.
  let ecc = eccentricityMap(g)
  let d = diameter(g)
  for n in g.nodes:
    if ecc[n] == d:
      result.add(n)

proc barycenter*[N](g: Graph[N]): seq[N] =
  ## Return the barycenter — nodes minimizing the sum of distances
  ## to all other nodes.
  var sumDist = initTable[N, int]()
  for n in g.nodes:
    var dist = initTable[N, int]()
    dist[n] = 0
    var queue = initDeque[N]()
    queue.addLast(n)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          queue.addLast(v)
    var s = 0
    for d in dist.values:
      s += d
    sumDist[n] = s

  var minSum = high(int)
  for s in sumDist.values:
    if s < minSum:
      minSum = s
  for n in g.nodes:
    if sumDist[n] == minSum:
      result.add(n)
