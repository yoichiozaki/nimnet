## Eulerian and Hamiltonian path algorithms
##
## Hierholzer's algorithm for Eulerian circuits/paths.
## Backtracking for Hamiltonian detection (small graphs).

import std/[sets, tables, deques]
import ../types
import ../graph
import ../digraph

# =============================================================================
# Eulerian (undirected)
# =============================================================================

func isEulerian*[N](g: Graph[N]): bool =
  ## Check if the undirected graph has an Eulerian circuit.
  ## Requires: connected and all vertices have even degree.
  if g.numberOfNodes() == 0:
    return true
  if g.numberOfEdges() == 0:
    return true
  # Check connectivity (only among nodes with edges)
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  var startNode: N
  var found = false
  for n in g.nodes:
    if g.degree(n) > 0:
      startNode = n
      found = true
      break
  if not found:
    return true
  queue.addLast(startNode)
  visited.incl(startNode)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  # Check all nodes with edges are visited
  for n in g.nodes:
    if g.degree(n) > 0 and n notin visited:
      return false
  # Check all degrees are even
  for n in g.nodes:
    if g.degree(n) mod 2 != 0:
      return false
  return true

func isSemiEulerian*[N](g: Graph[N]): bool =
  ## Check if the graph has an Eulerian path (but not circuit).
  ## Requires: connected and exactly 2 vertices have odd degree.
  if g.numberOfNodes() == 0:
    return false
  if g.numberOfEdges() == 0:
    return false
  # Check connectivity
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  var startNode: N
  for n in g.nodes:
    if g.degree(n) > 0:
      startNode = n
      break
  queue.addLast(startNode)
  visited.incl(startNode)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  for n in g.nodes:
    if g.degree(n) > 0 and n notin visited:
      return false
  var oddCount = 0
  for n in g.nodes:
    if g.degree(n) mod 2 != 0:
      oddCount += 1
  return oddCount == 2

proc eulerianCircuit*[N](g: Graph[N]): seq[N] =
  ## Find an Eulerian circuit using Hierholzer's algorithm.
  ## Raises NimNetError if graph is not Eulerian.
  if not isEulerian(g):
    raise newException(NimNetError, "Graph has no Eulerian circuit")
  if g.numberOfEdges() == 0:
    if g.numberOfNodes() > 0:
      for n in g.nodes:
        return @[n]
    return @[]

  # Build mutable edge set
  var edgeCount = initTable[(N, N), int]()
  for (u, v) in g.edges:
    let key1 = (u, v)
    let key2 = (v, u)
    edgeCount[key1] = edgeCount.getOrDefault(key1, 0) + 1
    edgeCount[key2] = edgeCount.getOrDefault(key2, 0) + 1

  var stack: seq[N] = @[]
  var startNode: N
  for n in g.nodes:
    if g.degree(n) > 0:
      startNode = n
      break
  stack.add(startNode)
  result = @[]

  while stack.len > 0:
    let v = stack[^1]
    var foundEdge = false
    for u in g.neighbors(v):
      let key = (v, u)
      if edgeCount.getOrDefault(key, 0) > 0:
        edgeCount[key] = edgeCount[key] - 1
        edgeCount[(u, v)] = edgeCount[(u, v)] - 1
        stack.add(u)
        foundEdge = true
        break
    if not foundEdge:
      result.add(stack.pop())

proc eulerianPath*[N](g: Graph[N]): seq[N] =
  ## Find an Eulerian path using Hierholzer's algorithm.
  ## Raises NimNetError if graph has no Eulerian path.
  if not isSemiEulerian(g) and not isEulerian(g):
    raise newException(NimNetError, "Graph has no Eulerian path")
  if isEulerian(g):
    return eulerianCircuit(g)

  # Find start node (odd degree)
  var startNode: N
  for n in g.nodes:
    if g.degree(n) mod 2 != 0:
      startNode = n
      break

  var edgeCount = initTable[(N, N), int]()
  for (u, v) in g.edges:
    edgeCount[(u, v)] = edgeCount.getOrDefault((u, v), 0) + 1
    edgeCount[(v, u)] = edgeCount.getOrDefault((v, u), 0) + 1

  var stack: seq[N] = @[startNode]
  result = @[]

  while stack.len > 0:
    let v = stack[^1]
    var foundEdge = false
    for u in g.neighbors(v):
      let key = (v, u)
      if edgeCount.getOrDefault(key, 0) > 0:
        edgeCount[key] = edgeCount[key] - 1
        edgeCount[(u, v)] = edgeCount[(u, v)] - 1
        stack.add(u)
        foundEdge = true
        break
    if not foundEdge:
      result.add(stack.pop())

# =============================================================================
# Eulerian (directed)
# =============================================================================

func isEulerianDirected*[N](g: DiGraph[N]): bool =
  ## Check if the directed graph has an Eulerian circuit.
  ## Requires: strongly connected and in-degree == out-degree for all.
  if g.numberOfNodes() == 0:
    return true
  for n in g.nodes:
    if g.inDegree(n) != g.outDegree(n):
      return false
  # Check strong connectivity of nodes with edges
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  var startNode: N
  var found = false
  for n in g.nodes:
    if g.outDegree(n) > 0:
      startNode = n
      found = true
      break
  if not found:
    return true
  queue.addLast(startNode)
  visited.incl(startNode)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.successors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  for n in g.nodes:
    if (g.inDegree(n) > 0 or g.outDegree(n) > 0) and n notin visited:
      return false
  return true

# =============================================================================
# Hamiltonian (backtracking, small graphs only)
# =============================================================================

proc isHamiltonian*[N](g: Graph[N]): bool =
  ## Check if the graph has a Hamiltonian cycle (visits all nodes exactly once).
  ## WARNING: NP-complete. Only practical for small graphs (< ~20 nodes).
  let n = g.numberOfNodes()
  if n < 3:
    return false
  let nodes = g.nodeSeq()

  var path: seq[N] = @[nodes[0]]
  var visited = initHashSet[N]()
  visited.incl(nodes[0])

  proc backtrack(): bool =
    if path.len == n:
      # Check if last node connects back to first
      return g.hasEdge(path[^1], path[0])
    let current = path[^1]
    for neighbor in g.neighbors(current):
      if neighbor notin visited:
        path.add(neighbor)
        visited.incl(neighbor)
        if backtrack():
          return true
        visited.excl(neighbor)
        discard path.pop()
    return false

  result = backtrack()
