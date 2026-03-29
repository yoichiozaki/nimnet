## Connected and strongly connected component algorithms

import std/[sets, deques, tables, sequtils, algorithm]
import ../types
import ../graph
import ../digraph

# =============================================================================
# Connected components (undirected)
# =============================================================================

proc connectedComponents*[N](g: Graph[N]): seq[HashSet[N]] =
  ## Return connected components as a sequence of node sets.
  var visited = initHashSet[N]()
  for startNode in g.nodes:
    if startNode notin visited:
      var component = initHashSet[N]()
      var queue = initDeque[N]()
      queue.addLast(startNode)
      visited.incl(startNode)
      component.incl(startNode)
      while queue.len > 0:
        let current = queue.popFirst()
        for neighbor in g.neighbors(current):
          if neighbor notin visited:
            visited.incl(neighbor)
            component.incl(neighbor)
            queue.addLast(neighbor)
      result.add(component)

proc isConnected*[N](g: Graph[N]): bool =
  ## Return true if the graph is connected.
  if g.numberOfNodes() == 0:
    return true
  let components = connectedComponents(g)
  components.len == 1

proc numberOfConnectedComponents*[N](g: Graph[N]): int =
  ## Return the number of connected components.
  connectedComponents(g).len

proc nodeConnectedComponent*[N](g: Graph[N], n: N): HashSet[N] =
  ## Return the connected component containing node n.
  if not g.hasNode(n):
    raise newException(NodeNotFound, "Node not found")
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  queue.addLast(n)
  visited.incl(n)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  visited

# =============================================================================
# Strongly connected components (directed) - Tarjan's algorithm
# =============================================================================

proc stronglyConnectedComponents*[N](g: DiGraph[N]): seq[HashSet[N]] =
  ## Return strongly connected components using Tarjan's algorithm.
  var index = 0
  var indices = initTable[N, int]()
  var lowlink = initTable[N, int]()
  var onStack = initHashSet[N]()
  var stack: seq[N]

  proc strongConnect(v: N) =
    indices[v] = index
    lowlink[v] = index
    index.inc
    stack.add(v)
    onStack.incl(v)

    for w in g.neighbors(v):
      if w notin indices:
        strongConnect(w)
        lowlink[v] = min(lowlink[v], lowlink[w])
      elif w in onStack:
        lowlink[v] = min(lowlink[v], indices[w])

    # Root node of SCC
    if lowlink[v] == indices[v]:
      var component = initHashSet[N]()
      while true:
        let w = stack.pop()
        onStack.excl(w)
        component.incl(w)
        if w == v:
          break
      result.add(component)

  for v in g.nodes:
    if v notin indices:
      strongConnect(v)

proc isStronglyConnected*[N](g: DiGraph[N]): bool =
  ## Return true if the directed graph is strongly connected.
  if g.numberOfNodes() == 0:
    return true
  let components = stronglyConnectedComponents(g)
  components.len == 1

proc numberOfStronglyConnectedComponents*[N](g: DiGraph[N]): int =
  stronglyConnectedComponents(g).len

proc condensation*[N](g: DiGraph[N]): DiGraph[int] =
  ## Return the condensation of g — the DAG of strongly connected components.
  ## Each SCC becomes a single node (0, 1, 2, ...).
  let sccs = stronglyConnectedComponents(g)
  var nodeToScc = initTable[N, int]()
  for i, scc in sccs:
    for node in scc:
      nodeToScc[node] = i

  result = newDiGraph[int]()
  for i in 0 ..< sccs.len:
    result.addNode(i)

  for (u, v) in g.edges:
    let su = nodeToScc[u]
    let sv = nodeToScc[v]
    if su != sv and not result.hasEdge(su, sv):
      result.addEdge(su, sv)

# =============================================================================
# Weakly connected components (directed)
# =============================================================================

proc weaklyConnectedComponents*[N](g: DiGraph[N]): seq[HashSet[N]] =
  ## Return weakly connected components (ignoring edge direction).
  var visited = initHashSet[N]()
  # Build undirected adjacency
  var undirAdj = initTable[N, HashSet[N]]()
  for n in g.nodes:
    undirAdj[n] = initHashSet[N]()
  for (u, v) in g.edges:
    undirAdj[u].incl(v)
    undirAdj[v].incl(u)

  for startNode in g.nodes:
    if startNode notin visited:
      var component = initHashSet[N]()
      var queue = initDeque[N]()
      queue.addLast(startNode)
      visited.incl(startNode)
      component.incl(startNode)
      while queue.len > 0:
        let current = queue.popFirst()
        for neighbor in undirAdj[current]:
          if neighbor notin visited:
            visited.incl(neighbor)
            component.incl(neighbor)
            queue.addLast(neighbor)
      result.add(component)

proc isWeaklyConnected*[N](g: DiGraph[N]): bool =
  if g.numberOfNodes() == 0:
    return true
  weaklyConnectedComponents(g).len == 1
