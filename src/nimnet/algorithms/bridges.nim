## Bridges, articulation points, and biconnected components
##
## A **bridge** is an edge whose removal disconnects the graph.
## An **articulation point** is a vertex whose removal increases the
## number of connected components.
## Uses Tarjan's DFS algorithm — O(V + E).

import std/[tables, sets, deques]
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

# =============================================================================
# Local bridges
# =============================================================================

proc localBridges*[N](g: Graph[N]): seq[(N, N, int)] =
  ## Return local bridges in the graph.
  ## A local bridge is an edge (u, v) where removing it would increase
  ## the distance between u and v. Returns (u, v, span) tuples where
  ## span is the length of the shortest path between u and v if the edge
  ## were removed (infinity represented as -1 means a true bridge).
  var seen = initHashSet[(N, N)]()
  for (u, v) in g.edges:
    if (u, v) in seen or (v, u) in seen:
      continue
    seen.incl((u, v))
    # Check if u and v have any common neighbor
    var hasCommon = false
    for w in g.neighbors(u):
      if w != v and g.hasEdge(w, v):
        hasCommon = true
        break
    if not hasCommon:
      # It's a local bridge — find shortest alternate path via BFS
      # excluding the direct edge
      var dist = initTable[N, int]()
      dist[u] = 0
      var queue = initDeque[N]()
      queue.addLast(u)
      var found = false
      while queue.len > 0:
        let cur = queue.popFirst()
        for w in g.neighbors(cur):
          if w notin dist:
            if cur == u and w == v:
              continue  # skip direct edge
            dist[w] = dist[cur] + 1
            if w == v:
              result.add((u, v, dist[w]))
              found = true
              break
            queue.addLast(w)
        if found:
          break
      if not found:
        result.add((u, v, -1))  # true bridge, infinite span

# =============================================================================
# Chain decomposition
# =============================================================================

proc chainDecomposition*[N](g: Graph[N]): seq[seq[(N, N)]] =
  ## Return the chain decomposition of the graph.
  ## Decomposes the graph into chains (paths and cycles) based on a DFS tree.
  ## Each chain starts with a back edge and follows tree edges back toward
  ## the root. Used for bridge-finding verification.
  if g.numberOfNodes() == 0:
    return @[]

  var disc = initTable[N, int]()
  var parent = initTable[N, N]()
  var timer = 0
  var visited = initHashSet[(N, N)]()

  # Build DFS tree
  proc dfs(u: N) =
    disc[u] = timer
    timer.inc
    for v in g.neighbors(u):
      if v notin disc:
        parent[v] = u
        dfs(v)

  for n in g.nodes:
    if n notin disc:
      parent[n] = n  # root
      dfs(n)

  # For each back edge, follow parent pointers to create a chain
  for (u, v) in g.edges:
    # Skip tree edges
    if parent.getOrDefault(v, v) == u or parent.getOrDefault(u, u) == v:
      continue
    # This is a back edge — orient so desc is the deeper node
    var desc, anc: N
    if disc.getOrDefault(u, 0) > disc.getOrDefault(v, 0):
      desc = u; anc = v
    else:
      desc = v; anc = u
    # Build chain: back edge + tree edges from desc toward anc
    var chain: seq[(N, N)] = @[(desc, anc)]
    var cur = desc
    while cur in parent and parent[cur] != cur and cur != anc:
      let p = parent[cur]
      if (cur, p) notin visited and (p, cur) notin visited:
        chain.add((cur, p))
        visited.incl((cur, p))
      else:
        break
      cur = p
    if chain.len > 0:
      result.add(chain)
