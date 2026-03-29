## Dominating set algorithms

import std/[sets, tables]
import ../types
import ../graph

func isDominatingSet*[N](g: Graph[N], nodes: HashSet[N]): bool =
  ## Check if the given node set is a dominating set.
  ## Every node is either in the set or adjacent to a node in the set.
  for n in g.nodes:
    if n in nodes:
      continue
    var dominated = false
    for u in g.neighbors(n):
      if u in nodes:
        dominated = true
        break
    if not dominated:
      return false
  return true

proc minimumDominatingSet*[N](g: Graph[N]): HashSet[N] =
  ## Greedy approximation for minimum dominating set.
  ## Iteratively picks the node that dominates the most uncovered nodes.
  result = initHashSet[N]()
  var uncovered = initHashSet[N]()
  for n in g.nodes:
    uncovered.incl(n)

  while uncovered.len > 0:
    # Pick node that covers the most uncovered nodes
    var bestNode: N
    var bestCount = -1
    for n in g.nodes:
      var count = 0
      if n in uncovered:
        count = 1
      for u in g.neighbors(n):
        if u in uncovered:
          count += 1
      if count > bestCount:
        bestCount = count
        bestNode = n

    result.incl(bestNode)
    uncovered.excl(bestNode)
    for u in g.neighbors(bestNode):
      uncovered.excl(u)

proc dominationNumber*[N](g: Graph[N]): int =
  ## Return the domination number (size of a minimum dominating set).
  ## Uses greedy approximation.
  result = minimumDominatingSet(g).len
