## Graph property predicates
##
## Provides functions to test structural properties of graphs:
## isTree, isForest, isRegular, isComplete, etc.

import std/[sets, deques, tables, algorithm]
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

# =============================================================================
# Tree properties (#127)
# =============================================================================

func isArborescence*[N](g: DiGraph[N]): bool =
  ## Return true if the digraph is an arborescence (rooted directed tree).
  ## An arborescence is a directed tree where every node (except the root)
  ## has exactly one predecessor, and the root has zero predecessors.
  if g.numberOfNodes() == 0:
    return false
  if g.numberOfEdges() != g.numberOfNodes() - 1:
    return false
  var rootCount = 0
  for n in g.nodes:
    if g.inDegree(n) == 0:
      rootCount.inc
    elif g.inDegree(n) != 1:
      return false
  if rootCount != 1:
    return false
  # Check connectivity (all reachable from root)
  var root: N
  for n in g.nodes:
    if g.inDegree(n) == 0:
      root = n
      break
  var visited = initHashSet[N]()
  var queue = initDeque[N]()
  visited.incl(root)
  queue.addLast(root)
  while queue.len > 0:
    let u = queue.popFirst()
    for v in g.neighbors(u):
      if v notin visited:
        visited.incl(v)
        queue.addLast(v)
  result = visited.len == g.numberOfNodes()

func isBranching*[N](g: DiGraph[N]): bool =
  ## Return true if the digraph is a branching (forest of arborescences).
  ## Every node has in-degree 0 or 1, and there are no cycles.
  if g.numberOfNodes() == 0:
    return true
  for n in g.nodes:
    if g.inDegree(n) > 1:
      return false
  # Check no cycles (it's a DAG)
  var inDeg = initTable[N, int]()
  for n in g.nodes:
    inDeg[n] = g.inDegree(n)
  var queue = initDeque[N]()
  for n, d in inDeg:
    if d == 0:
      queue.addLast(n)
  var count = 0
  while queue.len > 0:
    let n = queue.popFirst()
    count.inc
    for s in g.neighbors(n):
      inDeg[s].dec
      if inDeg[s] == 0:
        queue.addLast(s)
  result = count == g.numberOfNodes()

proc treeCentroid*[N](g: Graph[N]): seq[N] =
  ## Return the centroid of a tree (1 or 2 nodes).
  ## The centroid minimizes the maximum distance to any other node.
  ## Uses leaf-peeling algorithm.
  let n = g.numberOfNodes()
  if n == 0:
    return @[]
  if n <= 2:
    return g.nodeSeq()
  var deg = initTable[N, int]()
  for node in g.nodes:
    deg[node] = g.degree(node)
  var leaves = initDeque[N]()
  for node, d in deg:
    if d <= 1:
      leaves.addLast(node)
  var remaining = n
  while remaining > 2:
    var newLeaves = initDeque[N]()
    let batchSize = leaves.len
    for _ in 0 ..< batchSize:
      let leaf = leaves.popFirst()
      remaining.dec
      for nbr in g.neighbors(leaf):
        deg[nbr].dec
        if deg[nbr] == 1:
          newLeaves.addLast(nbr)
    leaves = newLeaves
  while leaves.len > 0:
    result.add(leaves.popFirst())

# =============================================================================
# Extended Graph Properties (#131)
# =============================================================================

func isKRegular*[N](g: Graph[N], k: int): bool =
  ## Check if every node has degree exactly k.
  for node in g.nodes:
    if g.degree(node) != k:
      return false
  result = true

proc isStronglyRegular*[N](g: Graph[N]): bool =
  ## Check if the graph is strongly regular.
  ## A graph is strongly regular with parameters (n, k, λ, μ) if it is
  ## k-regular and every pair of adjacent vertices has λ common neighbors
  ## and every pair of non-adjacent vertices has μ common neighbors.
  let n = g.numberOfNodes()
  if n == 0: return true
  # Check regularity
  var k = -1
  for node in g.nodes:
    if k < 0:
      k = g.degree(node)
    elif g.degree(node) != k:
      return false
  if k < 0: return true
  # Check λ and μ
  var lambda = -1
  var mu = -1
  let nodes = g.nodeSeq()
  for i in 0 ..< nodes.len:
    for j in i + 1 ..< nodes.len:
      var commonNeighbors = 0
      for nbr in g.neighbors(nodes[i]):
        if g.hasEdge(nbr, nodes[j]):
          commonNeighbors.inc
      if g.hasEdge(nodes[i], nodes[j]):
        if lambda < 0:
          lambda = commonNeighbors
        elif commonNeighbors != lambda:
          return false
      else:
        if mu < 0:
          mu = commonNeighbors
        elif commonNeighbors != mu:
          return false
  result = true

proc isDistanceRegular*[N](g: Graph[N]): bool =
  ## Check if the graph is distance-regular.
  ## A graph is distance-regular if for any vertices u, v at distance i,
  ## the number of neighbors of v at distance i-1, i, i+1 from u
  ## depends only on i and not on the specific choice of u and v.
  let n = g.numberOfNodes()
  if n == 0: return true
  # Compute all pairs shortest paths
  var dist = initTable[(N, N), int]()
  for source in g.nodes:
    var d = initTable[N, int]()
    d[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin d:
          d[v] = d[u] + 1
          queue.addLast(v)
    for target, td in d:
      dist[(source, target)] = td
  # Find max distance
  var maxDist = 0
  for _, d in dist:
    if d > maxDist: maxDist = d
  # For each distance i, check that intersection numbers are consistent
  for i in 0 .. maxDist:
    var ci = -1  # neighbors at distance i-1
    var ai = -1  # neighbors at distance i
    var bi = -1  # neighbors at distance i+1
    for u in g.nodes:
      for v in g.nodes:
        if dist.getOrDefault((u, v), -1) != i: continue
        var cCount, aCount, bCount: int
        for w in g.neighbors(v):
          let duw = dist.getOrDefault((u, w), -1)
          if duw == i - 1: cCount.inc
          elif duw == i: aCount.inc
          elif duw == i + 1: bCount.inc
        if ci < 0: ci = cCount
        elif ci != cCount: return false
        if ai < 0: ai = aCount
        elif ai != aCount: return false
        if bi < 0: bi = bCount
        elif bi != bCount: return false
  result = true

proc isThresholdGraph*[N](g: Graph[N]): bool =
  ## Check if the graph is a threshold graph.
  ## A threshold graph can be constructed by repeated addition of
  ## isolated nodes or nodes connected to all existing nodes.
  let n = g.numberOfNodes()
  if n <= 2: return true
  # Degree sequence characterization: sort degrees descending,
  # check the "creation sequence" property
  var degrees = newSeq[int]()
  for node in g.nodes:
    degrees.add(g.degree(node))
  degrees.sort(order = Descending)
  # Build by checking: if deg = n-1, it's a dominating node
  # Otherwise it's an isolated addition
  var remaining = n
  var degCopy = degrees
  for i in 0 ..< n:
    if degCopy[0] == remaining - 1:
      # Dominating node: reduce all others by 1
      degCopy.delete(0)
      for j in 0 ..< degCopy.len:
        degCopy[j].dec
    elif degCopy[^1] == 0:
      # Isolated node
      degCopy.setLen(degCopy.len - 1)
    else:
      return false
    remaining.dec
    if remaining <= 0: break
    degCopy.sort(order = SortOrder.Descending)
  result = true

proc moralGraph*[N](g: DiGraph[N]): Graph[N] =
  ## Compute the moral graph of a DAG (marry parents + drop orientation).
  result = newGraph[N]()
  for n in g.nodes:
    result.addNode(n)
  for (u, v) in g.edges:
    if not result.hasEdge(u, v):
      result.addEdge(u, v)
  # Marry parents: for each node, add edges between all pairs of parents
  for node in g.nodes:
    var parents = newSeq[N]()
    for p in g.predecessors(node):
      parents.add(p)
    for i in 0 ..< parents.len:
      for j in i + 1 ..< parents.len:
        if not result.hasEdge(parents[i], parents[j]):
          result.addEdge(parents[i], parents[j])

proc flowHierarchy*[N](g: DiGraph[N]): float =
  ## Compute the flow hierarchy of a directed graph.
  ## The fraction of edges not in a cycle.
  let m = g.numberOfEdges()
  if m == 0: return 1.0
  # Find edges in cycles using SCC
  var inCycle = 0
  let sccs = block:
    # Inline SCC (Tarjan's)
    var index = 0
    var stack = newSeq[N]()
    var onStack = initHashSet[N]()
    var indices = initTable[N, int]()
    var lowlink = initTable[N, int]()
    var components = newSeq[HashSet[N]]()
    proc strongconnect(v: N) =
      indices[v] = index
      lowlink[v] = index
      index.inc
      stack.add(v)
      onStack.incl(v)
      for w in g.neighbors(v):
        if w notin indices:
          strongconnect(w)
          lowlink[v] = min(lowlink[v], lowlink[w])
        elif w in onStack:
          lowlink[v] = min(lowlink[v], indices[w])
      if lowlink[v] == indices[v]:
        var comp = initHashSet[N]()
        while true:
          let w = stack.pop()
          onStack.excl(w)
          comp.incl(w)
          if w == v: break
        components.add(comp)
    for n in g.nodes:
      if n notin indices:
        strongconnect(n)
    components
  for (u, v) in g.edges:
    for scc in sccs:
      if u in scc and v in scc and scc.len > 1:
        inCycle.inc
        break
  result = 1.0 - float(inCycle) / float(m)
