## Graph coloring algorithms
##
## Greedy coloring with multiple strategies.

import std/[tables, sets, algorithm]
import ../types
import ../graph

func isProperColoring*[N](g: Graph[N], coloring: Table[N, int]): bool =
  ## Check if the coloring is proper (no adjacent nodes share a color).
  for (u, v) in g.edges:
    if u in coloring and v in coloring:
      if coloring[u] == coloring[v]:
        return false
  return true

proc greedyColor*[N](g: Graph[N], strategy: string = "largest_first"): Table[N, int] =
  ## Greedy graph coloring.
  ## Strategies: "largest_first", "smallest_last", "sequential"
  result = initTable[N, int]()
  if g.numberOfNodes() == 0:
    return

  # Determine node ordering based on strategy
  var nodeOrder: seq[N] = @[]
  case strategy
  of "largest_first":
    # Sort by degree descending
    var nodes: seq[(int, N)] = @[]
    for n in g.nodes:
      nodes.add((g.degree(n), n))
    nodes.sort(proc(a, b: (int, N)): int =
      if a[0] > b[0]: -1
      elif a[0] < b[0]: 1
      else: 0
    )
    for (_, n) in nodes:
      nodeOrder.add(n)
  of "smallest_last":
    # Iteratively remove node with smallest degree
    var remaining = initHashSet[N]()
    for n in g.nodes:
      remaining.incl(n)
    var deg = initTable[N, int]()
    for n in g.nodes:
      deg[n] = g.degree(n)
    var order: seq[N] = @[]
    while remaining.len > 0:
      var minDeg = int.high
      var pick: N
      for n in remaining:
        if deg[n] < minDeg:
          minDeg = deg[n]
          pick = n
      order.add(pick)
      remaining.excl(pick)
      for u in g.neighbors(pick):
        if u in remaining:
          deg[u] = deg[u] - 1
    # Reverse to get smallest-last ordering
    for i in countdown(order.len - 1, 0):
      nodeOrder.add(order[i])
  else:  # "sequential" or default
    for n in g.nodes:
      nodeOrder.add(n)

  # Greedy assignment
  for n in nodeOrder:
    var usedColors = initHashSet[int]()
    for u in g.neighbors(n):
      if u in result:
        usedColors.incl(result[u])
    # Find smallest available color
    var color = 0
    while color in usedColors:
      color += 1
    result[n] = color

proc chromaticNumber*[N](g: Graph[N]): int =
  ## Estimate the chromatic number using greedy coloring.
  ## Returns an upper bound (exact for small graphs with good ordering).
  let coloring = greedyColor(g, "smallest_last")
  result = 0
  for n, c in coloring:
    if c + 1 > result:
      result = c + 1
