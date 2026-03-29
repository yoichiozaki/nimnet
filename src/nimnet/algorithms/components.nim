## Connected and strongly connected component algorithms

import std/[sets, deques, tables, sequtils]
import ../types
import ../graph
import ../digraph
import ./flow

# =============================================================================
# Connected components (undirected)
# =============================================================================

proc connectedComponents*[N](g: Graph[N]): seq[HashSet[N]] =
  ## Return connected components as a sequence of node sets.
  let nNodes = g.numberOfNodes()
  var visited = initHashSet[N](nNodes)
  for startNode in g.adj.keys:
    if startNode notin visited:
      var component = initHashSet[N](nNodes)
      var queue = initDeque[N]()
      queue.addLast(startNode)
      visited.incl(startNode)
      component.incl(startNode)
      while queue.len > 0:
        let current = queue.popFirst()
        for neighbor in g.adj[current].keys:
          if neighbor notin visited:
            visited.incl(neighbor)
            component.incl(neighbor)
            queue.addLast(neighbor)
      result.add(move component)

proc isConnected*[N](g: Graph[N]): bool =
  ## Return true if the graph is connected.
  let nNodes = g.numberOfNodes()
  if nNodes == 0:
    return true
  # Single BFS from first node — check if all nodes reached
  var startNode: N
  for n in g.adj.keys:
    startNode = n
    break
  var visited = initHashSet[N](nNodes)
  visited.incl(startNode)
  var queue = initDeque[N]()
  queue.addLast(startNode)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.adj[current].keys:
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  visited.len == nNodes

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
    for neighbor in g.adj[current].keys:
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
  var sccs: seq[HashSet[N]] = @[]

  proc strongConnect(v: N) =
    indices[v] = index
    lowlink[v] = index
    index.inc
    stack.add(v)
    onStack.incl(v)

    for w in g.adj[v].keys:
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
      sccs.add(component)

  for v in g.nodes:
    if v notin indices:
      strongConnect(v)
  result = sccs

proc isStronglyConnected*[N](g: DiGraph[N]): bool =
  ## Return true if the directed graph is strongly connected.
  if g.numberOfNodes() == 0:
    return true
  let components = stronglyConnectedComponents(g)
  components.len == 1

proc numberOfStronglyConnectedComponents*[N](g: DiGraph[N]): int =
  ## Return the number of strongly connected components.
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
  ## Return true if the directed graph is weakly connected.
  if g.numberOfNodes() == 0:
    return true
  weaklyConnectedComponents(g).len == 1

# =============================================================================
# Extended Components (#124)
# =============================================================================

proc attractingComponents*[N](g: DiGraph[N]): seq[HashSet[N]] =
  ## Find attracting components of a directed graph.
  ## An attracting component is a strongly connected component with
  ## no outgoing edges (terminal SCC).
  let sccs = stronglyConnectedComponents(g)
  for scc in sccs:
    var hasOutgoing = false
    for node in scc:
      for nbr in g.neighbors(node):
        if nbr notin scc:
          hasOutgoing = true
          break
      if hasOutgoing: break
    if not hasOutgoing:
      result.add(scc)

proc isAttractingComponent*[N](g: DiGraph[N], comp: HashSet[N]): bool =
  ## Check if a set of nodes forms an attracting component.
  # Must be strongly connected within
  for node in comp:
    var visited = initHashSet[N]()
    var queue = initDeque[N]()
    visited.incl(node)
    queue.addLast(node)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v in comp and v notin visited:
          visited.incl(v)
          queue.addLast(v)
    if visited != comp: return false
  # Must have no outgoing edges
  for node in comp:
    for nbr in g.neighbors(node):
      if nbr notin comp: return false
  result = true

proc numberOfAttractingComponents*[N](g: DiGraph[N]): int =
  ## Return the number of attracting components.
  attractingComponents(g).len

proc isSemiconnected*[N](g: DiGraph[N]): bool =
  ## Check if a directed graph is semiconnected.
  ## A graph is semiconnected if for every pair u,v either
  ## u can reach v or v can reach u.
  let cond = condensation(g)
  # The condensation must form a single chain (Hamiltonian path)
  if cond.numberOfNodes() == 0: return true
  # Topological order and check that consecutive nodes are connected
  var inDeg = initTable[int, int]()
  for n in cond.nodes:
    inDeg[n] = 0
  for (u, v) in cond.edges:
    inDeg[v] = inDeg.getOrDefault(v, 0) + 1
  var queue = initDeque[int]()
  for n, d in inDeg:
    if d == 0:
      queue.addLast(n)
  var order = newSeq[int]()
  while queue.len > 0:
    if queue.len > 1: return false  # Multiple choices = not semiconnected
    let n = queue.popFirst()
    order.add(n)
    for s in cond.neighbors(n):
      inDeg[s].dec
      if inDeg[s] == 0:
        queue.addLast(s)
  result = order.len == cond.numberOfNodes()

iterator biconnectedComponentEdges*[N](g: Graph[N]): seq[(N, N)] =
  ## Yield biconnected components as sequences of edges.
  ## Uses a Tarjan-like DFS algorithm.
  var disc = initTable[N, int]()
  var low = initTable[N, int]()
  var parent = initTable[N, N]()
  var timer = 0
  var edgeStack = newSeq[(N, N)]()
  for start in g.nodes:
    if start in disc: continue
    var stack = @[(start, true)]  # (node, first_visit)
    var iterStack: seq[(N, seq[N], int)]  # (node, neighbors, index)
    var nbrs: seq[N]
    for nbr in g.neighbors(start): nbrs.add(nbr)
    iterStack.add((start, nbrs, 0))
    disc[start] = timer
    low[start] = timer
    timer.inc
    while iterStack.len > 0:
      let idx = iterStack.len - 1
      var (u, neighbors, ni) = iterStack[idx]
      if ni < neighbors.len:
        let v = neighbors[ni]
        iterStack[idx][2] = ni + 1
        if v notin disc:
          parent[v] = u
          disc[v] = timer
          low[v] = timer
          timer.inc
          edgeStack.add((u, v))
          var vnbrs: seq[N]
          for nbr in g.neighbors(v): vnbrs.add(nbr)
          iterStack.add((v, vnbrs, 0))
        elif v != parent.getOrDefault(u, v) and disc[v] < disc[u]:
          edgeStack.add((u, v))
          if disc[v] < low[u]:
            low[u] = disc[v]
      else:
        iterStack.del(idx)
        if iterStack.len > 0:
          let pidx = iterStack.len - 1
          let p = iterStack[pidx][0]
          if low[u] < low[p]:
            low[p] = low[u]
          if low[u] >= disc[p]:
            var component = newSeq[(N, N)]()
            while edgeStack.len > 0:
              let e = edgeStack.pop()
              component.add(e)
              if (e[0] == p and e[1] == u) or (e[0] == u and e[1] == p):
                break
            if component.len > 0:
              yield component

proc edgeDisjointPaths*[N](g: Graph[N], s, t: N): int =
  ## Count the number of edge-disjoint paths between s and t.
  ## Uses max flow on a directed version.
  var dg = newDiGraph[N]()
  for node in g.nodes:
    dg.addNode(node)
  for (u, v) in g.edges:
    dg.addEdge(u, v, newEdgeAttr(1.0))
    dg.addEdge(v, u, newEdgeAttr(1.0))
  # Use Edmonds-Karp
  let (flow, _) = edmondsKarp(dg, s, t)
  result = int(flow)

proc nodeDisjointPaths*[N](g: Graph[N], s, t: N): int =
  ## Count the number of node-disjoint paths between s and t.
  ## Uses node-splitting technique with max flow.
  # Split each node (except s and t) into two: node_in and node_out
  # with capacity 1 edge between them
  var dg = newDiGraph[int]()
  var nodeToIn = initTable[N, int]()
  var nodeToOut = initTable[N, int]()
  var idx = 0
  for node in g.nodes:
    nodeToIn[node] = idx
    nodeToOut[node] = idx + 1
    idx += 2
  # Inner edges: in -> out with capacity 1 (except s and t: infinite)
  for node in g.nodes:
    let cap = if node == s or node == t: float(g.numberOfNodes()) else: 1.0
    dg.addEdge(nodeToIn[node], nodeToOut[node], newEdgeAttr(cap))
  # Graph edges: out[u] -> in[v] and out[v] -> in[u] with infinite capacity
  let inf = float(g.numberOfNodes())
  for (u, v) in g.edges:
    dg.addEdge(nodeToOut[u], nodeToIn[v], newEdgeAttr(inf))
    dg.addEdge(nodeToOut[v], nodeToIn[u], newEdgeAttr(inf))
  let (flow, _) = edmondsKarp(dg, nodeToOut[s], nodeToIn[t])
  result = int(flow)
