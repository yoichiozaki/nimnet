## Wiener index and related distance-sum graph indices.

import std/[tables, deques]
import ../graph

proc wienerIndex*[N](g: Graph[N]): int =
  ## Return the Wiener index — the sum of shortest-path distances
  ## over all unordered pairs of nodes. Returns 0 for graphs with
  ## fewer than 2 nodes.
  let n = g.numberOfNodes()
  if n <= 1:
    return 0
  result = 0
  var visited = initTable[N, bool]()
  for u in g.nodes:
    visited[u] = true
    var dist = initTable[N, int]()
    dist[u] = 0
    var queue = initDeque[N]()
    queue.addLast(u)
    while queue.len > 0:
      let curr = queue.popFirst()
      for v in g.neighbors(curr):
        if v notin dist:
          dist[v] = dist[curr] + 1
          queue.addLast(v)
    for v in g.nodes:
      if v notin visited and v in dist:
        result += dist[v]

# =============================================================================
# Hyper-Wiener Index (#135)
# =============================================================================

proc hyperWienerIndex*[N](g: Graph[N]): float =
  ## Compute the hyper-Wiener index: WW = (1/2) * sum(d + d^2) for all pairs.
  result = 0.0
  for source in g.nodes:
    var dist = initTable[N, int]()
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          queue.addLast(v)
    for target, d in dist:
      if target != source:
        result += float(d) + float(d * d)
  result /= 4.0  # Each pair counted twice, and the formula has 1/2
