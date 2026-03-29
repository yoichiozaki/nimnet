## Bridges, articulation points, and biconnected components
##
## A **bridge** is an edge whose removal disconnects the graph.
## An **articulation point** is a vertex whose removal increases the
## number of connected components.
## Uses Tarjan's DFS algorithm — O(V + E).

import std/[tables, sets]
import ../graph

# =============================================================================
# Bridges (cut edges)
# =============================================================================

proc bridges*[N](g: Graph[N]): seq[(N, N)] =
  ## Return all bridges (cut edges) in the graph.
  ## A bridge is an edge whose removal disconnects the graph.
  ## Uses Tarjan's algorithm — O(V + E).
  if g.numberOfNodes() == 0:
    return @[]

  var disc = initTable[N, int]()
  var low = initTable[N, int]()
  var timer = 0
  var res: seq[(N, N)]

  proc dfs(u, parent: N) =
    disc[u] = timer
    low[u] = timer
    timer.inc
    for v in g.neighbors(u):
      if v notin disc:
        dfs(v, u)
        if low[v] < low[u]:
          low[u] = low[v]
        if low[v] > disc[u]:
          res.add((u, v))
      elif v != parent:
        if disc[v] < low[u]:
          low[u] = disc[v]

  for n in g.nodes:
    if n notin disc:
      dfs(n, n)

  result = res

proc hasBridges*[N](g: Graph[N]): bool =
  ## Return true if the graph has any bridges.
  bridges(g).len > 0

# =============================================================================
# Articulation points (cut vertices)
# =============================================================================

proc articulationPoints*[N](g: Graph[N]): seq[N] =
  ## Return all articulation points (cut vertices) in the graph.
  ## An articulation point is a vertex whose removal disconnects the graph.
  ## Uses Tarjan's algorithm — O(V + E).
  if g.numberOfNodes() == 0:
    return @[]

  var disc = initTable[N, int]()
  var low = initTable[N, int]()
  var timer = 0
  var isAP = initHashSet[N]()

  proc dfs(u, parent: N) =
    disc[u] = timer
    low[u] = timer
    timer.inc
    var childCount = 0
    for v in g.neighbors(u):
      if v notin disc:
        childCount.inc
        dfs(v, u)
        if low[v] < low[u]:
          low[u] = low[v]
        # u is an AP if it's not root and low[v] >= disc[u]
        if parent != u and low[v] >= disc[u]:
          isAP.incl(u)
        # u is an AP if it's root and has 2+ children
        if parent == u and childCount > 1:
          isAP.incl(u)
      elif v != parent:
        if disc[v] < low[u]:
          low[u] = disc[v]

  for n in g.nodes:
    if n notin disc:
      dfs(n, n)

  for n in sets.items(isAP):
    result.add(n)

# =============================================================================
# Biconnected components
# =============================================================================

proc biconnectedComponents*[N](g: Graph[N]): seq[HashSet[N]] =
  ## Return the biconnected components of the graph.
  ## Each component is a maximal 2-connected subgraph (set of nodes).
  ## Uses a stack-based DFS — O(V + E).
  if g.numberOfNodes() == 0:
    return @[]

  var disc = initTable[N, int]()
  var low = initTable[N, int]()
  var timer = 0
  var edgeStack: seq[(N, N)]
  var res: seq[HashSet[N]]

  proc dfs(u, parent: N) =
    disc[u] = timer
    low[u] = timer
    timer.inc
    var childCount = 0
    for v in g.neighbors(u):
      if v notin disc:
        childCount.inc
        edgeStack.add((u, v))
        dfs(v, u)
        if low[v] < low[u]:
          low[u] = low[v]
        # Found a biconnected component
        if (parent == u and childCount > 1) or (parent != u and low[v] >= disc[u]):
          var component = initHashSet[N]()
          while edgeStack.len > 0:
            let (eu, ev) = edgeStack.pop()
            component.incl(eu)
            component.incl(ev)
            if eu == u and ev == v:
              break
          if component.len > 0:
            res.add(component)
      elif v != parent and disc[v] < disc[u]:
        edgeStack.add((u, v))
        if disc[v] < low[u]:
          low[u] = disc[v]

  for n in g.nodes:
    if n notin disc:
      dfs(n, n)
      # Remaining edges form a component
      if edgeStack.len > 0:
        var component = initHashSet[N]()
        while edgeStack.len > 0:
          let (eu, ev) = edgeStack.pop()
          component.incl(eu)
          component.incl(ev)
        if component.len > 0:
          res.add(component)

  result = res

proc isBiconnected*[N](g: Graph[N]): bool =
  ## Return true if the graph is biconnected (2-connected).
  ## A biconnected graph has no articulation points.
  if g.numberOfNodes() < 2:
    return false
  articulationPoints(g).len == 0
