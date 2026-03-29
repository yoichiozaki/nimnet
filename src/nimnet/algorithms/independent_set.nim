## Independent set and vertex cover algorithms

import std/[sets, tables]
import ../types
import ../graph

func isIndependentSet*[N](g: Graph[N], nodes: HashSet[N]): bool =
  ## Check if the given node set is independent (no edges between them).
  for u in nodes:
    for v in nodes:
      if u != v and g.hasEdge(u, v):
        return false
  return true

proc maximumIndependentSet*[N](g: Graph[N]): HashSet[N] =
  ## Greedy approximation for maximum independent set.
  ## Iteratively picks the node with minimum degree and removes it and neighbors.
  result = initHashSet[N]()
  var remaining = initHashSet[N]()
  for n in g.nodes:
    remaining.incl(n)

  # Build local degree map within remaining
  var deg = initTable[N, int]()
  for n in remaining:
    var d = 0
    for u in g.neighbors(n):
      if u in remaining:
        d += 1
    deg[n] = d

  while remaining.len > 0:
    # Pick node with minimum degree among remaining
    var minDeg = int.high
    var pick: N
    for n in remaining:
      if deg[n] < minDeg:
        minDeg = deg[n]
        pick = n

    result.incl(pick)
    # Remove pick and all its neighbors from remaining
    var toRemove = initHashSet[N]()
    toRemove.incl(pick)
    for u in g.neighbors(pick):
      if u in remaining:
        toRemove.incl(u)
    for n in toRemove:
      remaining.excl(n)
      # Update degrees of neighbors of removed nodes
      for u in g.neighbors(n):
        if u in remaining:
          deg[u] = deg[u] - 1

proc minimumVertexCover*[N](g: Graph[N]): HashSet[N] =
  ## 2-approximation minimum vertex cover.
  ## Greedy: pick edges and add both endpoints until all edges covered.
  result = initHashSet[N]()
  for (u, v) in g.edges:
    if u notin result and v notin result:
      result.incl(u)
      result.incl(v)
