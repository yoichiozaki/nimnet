## DAG algorithms: topological sort and cycle detection

import std/[tables, sets, deques, algorithm]
import ../types
import ../digraph

# =============================================================================
# Topological sort (Kahn's algorithm)
# =============================================================================

proc topologicalSort*[N](g: DiGraph[N]): seq[N] =
  ## Return nodes in topological order. Raises HasACycle if graph has a cycle.
  var inDeg = initTable[N, int]()
  for n in g.nodes:
    inDeg[n] = g.inDegree(n)

  var queue = initDeque[N]()
  for n, d in inDeg:
    if d == 0:
      queue.addLast(n)

  while queue.len > 0:
    let n = queue.popFirst()
    result.add(n)
    for succ in g.neighbors(n):
      inDeg[succ].dec
      if inDeg[succ] == 0:
        queue.addLast(succ)

  if result.len != g.numberOfNodes():
    raise newException(HasACycle, "Graph contains a cycle")

proc isDirectedAcyclicGraph*[N](g: DiGraph[N]): bool =
  ## Return true if the graph is a DAG (directed acyclic graph).
  try:
    discard topologicalSort(g)
    true
  except HasACycle:
    false

# =============================================================================
# Cycle detection
# =============================================================================

proc hasCycle*[N](g: DiGraph[N]): bool =
  ## Return true if the directed graph contains a cycle.
  not isDirectedAcyclicGraph(g)

proc findCycle*[N](g: DiGraph[N]): seq[N] =
  ## Find and return a cycle in the directed graph.
  ## Raises HasACycle with message if no cycle found (but this shouldn't happen
  ## since we only call this when we know there's a cycle).
  ## Returns the cycle as a sequence of nodes.
  const
    White = 0  # not visited
    Gray = 1   # in current path
    Black = 2  # fully processed
  var color = initTable[N, int]()
  var parent = initTable[N, N]()
  for n in g.nodes:
    color[n] = White

  proc dfsVisit(u: N): seq[N] =
    color[u] = Gray
    for v in g.neighbors(u):
      if color[v] == Gray:
        # Found cycle, reconstruct it
        var cycle = @[v, u]
        var current = u
        while current != v:
          current = parent[current]
          cycle.add(current)
        cycle.reverse()
        return cycle
      if color[v] == White:
        parent[v] = u
        let c = dfsVisit(v)
        if c.len > 0:
          return c
    color[u] = Black
    @[]

  for n in g.nodes:
    if color[n] == White:
      let cycle = dfsVisit(n)
      if cycle.len > 0:
        return cycle
  @[]

# =============================================================================
# DAG utilities
# =============================================================================

proc ancestors*[N](g: DiGraph[N], n: N): HashSet[N] =
  ## Return all ancestors of node n in a DAG.
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  result = initHashSet[N]()
  var queue = initDeque[N]()
  for p in g.predecessors(n):
    queue.addLast(p)
    result.incl(p)
  while queue.len > 0:
    let current = queue.popFirst()
    for p in g.predecessors(current):
      if p notin result:
        result.incl(p)
        queue.addLast(p)

proc descendants*[N](g: DiGraph[N], n: N): HashSet[N] =
  ## Return all descendants of node n in a DAG.
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  result = initHashSet[N]()
  var queue = initDeque[N]()
  for s in g.neighbors(n):
    queue.addLast(s)
    result.incl(s)
  while queue.len > 0:
    let current = queue.popFirst()
    for s in g.neighbors(current):
      if s notin result:
        result.incl(s)
        queue.addLast(s)

proc dagLongestPath*[N](g: DiGraph[N]): seq[N] =
  ## Find the longest path in a DAG.
  let order = topologicalSort(g)
  var dist = initTable[N, int]()
  var pred = initTable[N, N]()
  for n in order:
    dist[n] = 0

  for u in order:
    for v in g.neighbors(u):
      if dist[u] + 1 > dist[v]:
        dist[v] = dist[u] + 1
        pred[v] = u

  # Find node with max distance
  var maxDist = 0
  var endNode: N
  var found = false
  for n, d in dist:
    if d > maxDist or not found:
      maxDist = d
      endNode = n
      found = true

  if not found or maxDist == 0:
    # Single node or empty
    for n in order:
      return @[n]

  # Reconstruct path
  var path: seq[N]
  var current = endNode
  path.add(current)
  while current in pred:
    current = pred[current]
    path.add(current)
  algorithm.reverse(path)
  result = path

# =============================================================================
# Transitive closure and reduction
# =============================================================================

proc transitiveClosure*[N](g: DiGraph[N]): DiGraph[N] =
  ## Return the transitive closure of a directed graph.
  ## Adds edge (u, v) for every pair where v is reachable from u.
  result = g.copy()
  for u in g.nodes:
    # BFS from u to find all reachable nodes
    var visited = initHashSet[N]()
    var queue = initDeque[N]()
    for s in g.neighbors(u):
      if s notin visited:
        visited.incl(s)
        queue.addLast(s)
    while queue.len > 0:
      let v = queue.popFirst()
      if not result.hasEdge(u, v):
        result.addEdge(u, v)
      for w in g.neighbors(v):
        if w notin visited:
          visited.incl(w)
          queue.addLast(w)

proc transitiveReduction*[N](g: DiGraph[N]): DiGraph[N] =
  ## Return the transitive reduction of a DAG.
  ## Removes redundant edges while preserving reachability.
  ## Raises HasACycle if the graph has a cycle.
  if hasCycle(g):
    raise newException(HasACycle, "Transitive reduction is only defined for DAGs")
  result = g.copy()
  for u in g.nodes:
    for v in g.neighbors(u):
      # Check if v is reachable from u without the direct edge u->v
      # by checking if any other successor of u can reach v
      for w in g.neighbors(u):
        if w != v:
          # BFS from w; if v is reachable, remove edge u->v
          var visited = initHashSet[N]()
          var queue = initDeque[N]()
          visited.incl(w)
          queue.addLast(w)
          var found = false
          while queue.len > 0 and not found:
            let cur = queue.popFirst()
            if cur == v:
              found = true
              break
            for s in g.neighbors(cur):
              if s notin visited:
                visited.incl(s)
                queue.addLast(s)
          if found:
            if result.hasEdge(u, v):
              result.removeEdge(u, v)
            break
