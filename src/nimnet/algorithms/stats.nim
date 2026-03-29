## Network statistics and summary
##
## Degree distribution, assortativity, and graph summary utilities.

import std/[tables, sets, deques, math, strformat]
import ../types
import ../graph

proc info*[N](g: Graph[N]): string =
  ## Return a human-readable summary of the graph.
  let name = if g.name.len > 0: g.name else: "Graph"
  result = fmt"{name}: {g.numberOfNodes()} nodes, {g.numberOfEdges()} edges"

proc degreeHistogram*[N](g: Graph[N]): Table[int, int] =
  ## Return degree histogram: degree -> count.
  result = initTable[int, int]()
  for n in g.nodes:
    let d = g.degree(n)
    result[d] = result.getOrDefault(d, 0) + 1

proc averageDegree*[N](g: Graph[N]): float =
  ## Return the average degree of all nodes.
  let n = g.numberOfNodes()
  if n == 0:
    return 0.0
  result = 2.0 * g.numberOfEdges().float / n.float

proc degreeAssortativity*[N](g: Graph[N]): float =
  ## Compute the degree assortativity coefficient.
  ## Measures the correlation between degrees of adjacent nodes.
  ## Range: [-1, 1]. Positive = assortative (high connects to high).
  let m = g.numberOfEdges()
  if m == 0:
    return 0.0

  var sumProd = 0.0       # sum of di * dj for each edge
  var sumDeg = 0.0        # sum of (di + dj) for each edge
  var sumDegSq = 0.0      # sum of (di^2 + dj^2) for each edge

  for (u, v) in g.edges:
    let du = g.degree(u).float
    let dv = g.degree(v).float
    sumProd += du * dv
    sumDeg += du + dv
    sumDegSq += du * du + dv * dv

  let mf = m.float
  let num = sumProd / mf - (sumDeg / (2.0 * mf)) * (sumDeg / (2.0 * mf))
  let den = sumDegSq / (2.0 * mf) - (sumDeg / (2.0 * mf)) * (sumDeg / (2.0 * mf))
  if abs(den) < 1.0e-15:
    return 0.0
  result = num / den

proc averageShortestPathLength*[N](g: Graph[N]): float =
  ## Return the average shortest path length.
  ## Only considers reachable pairs. Raises NimNetError if graph is disconnected.
  let n = g.numberOfNodes()
  if n <= 1:
    return 0.0

  var totalLen = 0.0
  var totalPairs = 0

  for source in g.nodes:
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
    for target, d in dist:
      if target != source:
        totalLen += d.float
        totalPairs += 1

  if totalPairs == 0:
    return 0.0
  # Each pair counted twice (source->target and target->source)
  result = totalLen / totalPairs.float

proc density*[N](g: Graph[N]): float =
  ## Return the density of the graph.
  ## density = 2m / (n * (n-1)) for undirected graphs.
  let n = g.numberOfNodes()
  if n <= 1:
    return 0.0
  result = 2.0 * g.numberOfEdges().float / (n.float * (n.float - 1.0))

proc reciprocity*[N](g: Graph[N]): float =
  ## For undirected graphs, reciprocity is always 1.0.
  result = 1.0
