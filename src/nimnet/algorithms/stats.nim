## Network statistics and summary
##
## Degree distribution, assortativity, and graph summary utilities.

import std/[tables, sets, deques, strformat, math]
import ../types
import ../graph
import ../digraph

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
  ## Return the average shortest path length over all reachable node pairs.
  ## Unreachable pairs are ignored; this does not raise on disconnected graphs.
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

proc reciprocity*[N](g: DiGraph[N]): float =
  ## Compute the overall reciprocity of a directed graph.
  ## reciprocity = (number of reciprocal edges) / (total number of edges)
  ## where a reciprocal edge is one where both (u,v) and (v,u) exist.
  let m = g.numberOfEdges()
  if m == 0:
    return 0.0
  var reciprocal = 0
  for (u, v) in g.edges:
    if g.hasEdge(v, u):
      reciprocal.inc
  result = reciprocal.float / m.float

proc overallReciprocity*[N](g: DiGraph[N]): float =
  ## Alias for reciprocity on directed graphs.
  reciprocity(g)

# =============================================================================
# Extended assortativity (#120)
# =============================================================================

proc averageNeighborDegree*[N](g: Graph[N]): Table[N, float] =
  ## Return the average degree of neighbors for each node.
  result = initTable[N, float]()
  for n in g.nodes:
    let deg = g.degree(n)
    if deg == 0:
      result[n] = 0.0
    else:
      var total = 0.0
      for nbr in g.neighbors(n):
        total += g.degree(nbr).float
      result[n] = total / deg.float

proc averageNeighborDegree*[N](g: DiGraph[N]): Table[N, float] =
  ## Return the average out-degree of successors for each node in a digraph.
  result = initTable[N, float]()
  for n in g.nodes:
    let deg = g.outDegree(n)
    if deg == 0:
      result[n] = 0.0
    else:
      var total = 0.0
      for nbr in g.neighbors(n):
        total += g.outDegree(nbr).float
      result[n] = total / deg.float

proc averageDegreeConnectivity*[N](g: Graph[N]): Table[int, float] =
  ## Return average nearest-neighbor degree for nodes of each degree k.
  ## Maps degree k -> mean neighbor degree of nodes with degree k.
  let and_map = averageNeighborDegree(g)
  var byDeg = initTable[int, seq[float]]()
  for n in g.nodes:
    let d = g.degree(n)
    if d notin byDeg:
      byDeg[d] = @[]
    byDeg[d].add(and_map[n])
  result = initTable[int, float]()
  for d, vals in byDeg:
    var s = 0.0
    for v in vals: s += v
    result[d] = s / vals.len.float

proc degreeMixingMatrix*[N](g: Graph[N], maxDeg: int = -1): seq[seq[float]] =
  ## Return the degree mixing matrix.
  ## Entry (i, j) = fraction of edges connecting degree-i to degree-j nodes.
  let m = g.numberOfEdges()
  if m == 0:
    return @[]
  var md = maxDeg
  if md < 0:
    md = 0
    for n in g.nodes:
      if g.degree(n) > md:
        md = g.degree(n)
  result = newSeq[seq[float]](md + 1)
  for i in 0 .. md:
    result[i] = newSeq[float](md + 1)
  for (u, v) in g.edges:
    let du = g.degree(u)
    let dv = g.degree(v)
    result[du][dv] += 1.0
    if u != v:
      result[dv][du] += 1.0
  let total = m.float
  for i in 0 .. md:
    for j in 0 .. md:
      result[i][j] /= total

proc degreePearsonCorrelation*[N](g: Graph[N]): float =
  ## Compute r, the Pearson correlation coefficient of degree between
  ## endpoints of edges. Same as degreeAssortativity but using the
  ## Pearson correlation formula explicitly.
  degreeAssortativity(g)
