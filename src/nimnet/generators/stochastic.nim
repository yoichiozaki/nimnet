## Stochastic graph generator

import std/[tables]
import ../types, ../graph

proc stochasticGraph*[N](g: Graph[N], weighted: bool = false): Graph[N] =
  ## Create a stochastic graph (row-normalize adjacency).
  ## Each row sums to 1.0. If weighted=true, normalize weighted adjacency.
  result = newGraph[N]()
  for n in g.nodes:
    result.addNode(n)
  for n in g.nodes:
    var totalWeight = 0.0
    for nb in g.neighbors(n):
      if weighted:
        totalWeight += g.weight(n, nb)
      else:
        totalWeight += 1.0
    if totalWeight > 0:
      for nb in g.neighbors(n):
        let w = if weighted: g.weight(n, nb) / totalWeight else: 1.0 / totalWeight
        if not result.hasEdge(n, nb):
          result.addWeightedEdge(n, nb, w)
