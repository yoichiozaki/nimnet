## Rich-club coefficient
##
## Measures the degree to which well-connected nodes also
## connect to each other.

import std/[tables, algorithm]
import ../graph

proc richClubCoefficient*[N](g: Graph[N]): Table[int, float] =
  ## Return the rich-club coefficient for each degree k.
  ## φ(k) = 2 * E_k / (N_k * (N_k - 1))
  ## where N_k is the number of nodes with degree > k
  ## and E_k is the number of edges among those nodes.
  var degrees: seq[(N, int)]
  for n in g.nodes:
    degrees.add((n, g.degree(n)))
  # Find max degree
  var maxDeg = 0
  for (_, d) in degrees:
    if d > maxDeg:
      maxDeg = d
  for k in 0 ..< maxDeg:
    # Nodes with degree > k
    var richNodes = initTable[N, bool]()
    for (n, d) in degrees:
      if d > k:
        richNodes[n] = true
    let nk = richNodes.len
    if nk < 2:
      continue
    # Count edges among rich nodes
    var ek = 0
    for u in g.nodes:
      if u notin richNodes:
        continue
      for v in g.neighbors(u):
        if v in richNodes:
          ek += 1
    ek = ek div 2  # each edge counted twice in undirected graph
    result[k] = float(2 * ek) / float(nk * (nk - 1))
