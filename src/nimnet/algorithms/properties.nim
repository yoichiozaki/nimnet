## Graph property predicates
##
## Provides functions to test structural properties of graphs:
## isTree, isForest, isRegular, isComplete, etc.

import std/[sets, deques, tables]
import ../types
import ../graph
import ../digraph

func isConnected*[N](g: Graph[N]): bool =
  ## Return true if the undirected graph is connected.
  if g.numberOfNodes() == 0:
    return true  # empty graph is vacuously connected
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  var first = true
  for n in g.nodes:
    if first:
      queue.addLast(n)
      visited.incl(n)
      first = false
      break
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  result = visited.len == g.numberOfNodes()

func isTree*[N](g: Graph[N]): bool =
  ## Return true if the undirected graph is a tree.
  ## A tree is a connected graph with exactly n-1 edges.
  if g.numberOfNodes() == 0:
    return true
  result = g.isConnected() and g.numberOfEdges() == g.numberOfNodes() - 1

func isForest*[N](g: Graph[N]): bool =
  ## Return true if the undirected graph is a forest (acyclic).
  ## A forest has no cycles; equivalently each connected component is a tree.
  if g.numberOfNodes() == 0:
    return true
  # BFS cycle detection: a back-edge to any node other than the BFS parent
  # means a cycle exists.
  var visited = initHashSet[N]()
  var parent = initTable[N, N]()
  for startNode in g.nodes:
    if startNode notin visited:
      var queue = initDeque[N]()
      queue.addLast(startNode)
      visited.incl(startNode)
      parent[startNode] = startNode
      while queue.len > 0:
        let current = queue.popFirst()
        for neighbor in g.neighbors(current):
          if neighbor notin visited:
            visited.incl(neighbor)
            parent[neighbor] = current
            queue.addLast(neighbor)
          elif parent[current] != neighbor:
            # Back-edge to a non-parent: cycle found
            return false
  return true

func isRegular*[N](g: Graph[N]): bool =
  ## Return true if every node has the same degree.
  if g.numberOfNodes() <= 1:
    return true
  var deg = -1
  for n in g.nodes:
    let d = g.degree(n)
    if deg < 0:
      deg = d
    elif d != deg:
      return false
  return true

func isComplete*[N](g: Graph[N]): bool =
  ## Return true if the graph is complete (every pair connected).
  let n = g.numberOfNodes()
  if n <= 1:
    return true
  result = g.numberOfEdges() == n * (n - 1) div 2

func isWeaklyConnected*[N](g: DiGraph[N]): bool =
  ## Return true if the directed graph is weakly connected.
  if g.numberOfNodes() == 0:
    return true
  # Build undirected view via BFS ignoring direction
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  var first = true
  for n in g.nodes:
    if first:
      queue.addLast(n)
      visited.incl(n)
      first = false
      break
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.successors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
    for neighbor in g.predecessors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  result = visited.len == g.numberOfNodes()

func isStronglyConnected*[N](g: DiGraph[N]): bool =
  ## Return true if the directed graph is strongly connected.
  if g.numberOfNodes() == 0:
    return true
  # BFS forward from arbitrary start
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  var startNode: N
  for n in g.nodes:
    startNode = n
    break
  queue.addLast(startNode)
  visited.incl(startNode)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.successors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  if visited.len != g.numberOfNodes():
    return false
  # BFS backward from same start
  visited.clear()
  queue.addLast(startNode)
  visited.incl(startNode)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.predecessors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  result = visited.len == g.numberOfNodes()

func isDAG*[N](g: DiGraph[N]): bool =
  ## Return true if the directed graph is a DAG (no cycles).
  # Kahn's algorithm: count nodes with zero in-degree
  var inDeg = initTable[N, int]()
  for n in g.nodes:
    inDeg[n] = 0
  for n in g.nodes:
    for succ in g.successors(n):
      inDeg[succ] = inDeg[succ] + 1
  var queue = initDeque[N]()
  for n, d in inDeg:
    if d == 0:
      queue.addLast(n)
  var count = 0
  while queue.len > 0:
    let current = queue.popFirst()
    count += 1
    for succ in g.successors(current):
      inDeg[succ] = inDeg[succ] - 1
      if inDeg[succ] == 0:
        queue.addLast(succ)
  result = count == g.numberOfNodes()

func girth*[N](g: Graph[N]): int =
  ## Return the length of the shortest cycle in the graph.
  ## Returns -1 if the graph is acyclic.
  if g.numberOfNodes() == 0 or g.numberOfEdges() == 0:
    return -1
  result = int.high
  for startNode in g.nodes:
    # BFS from startNode, tracking distances
    var dist = initTable[N, int]()
    var parent = initTable[N, N]()
    var queue = initDeque[N]()
    dist[startNode] = 0
    queue.addLast(startNode)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          parent[v] = u
          queue.addLast(v)
        elif parent.getOrDefault(u) != v:
          # Found a cycle
          let cycleLen = dist[u] + dist[v] + 1
          if cycleLen < result:
            result = cycleLen
  if result == int.high:
    result = -1
