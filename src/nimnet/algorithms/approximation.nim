## Approximation algorithms for NP-hard graph problems

import std/[tables, sets, deques, random, algorithm, heapqueue]
import ../types
import ../graph

# =============================================================================
# Approximate Node Connectivity (#134)
# =============================================================================

proc approxNodeConnectivity*[N](g: Graph[N]): int =
  ## Approximate the node connectivity using a sampling approach.
  ## Based on White and Newman's algorithm.
  let n = g.numberOfNodes()
  if n <= 1: return 0
  result = n - 1
  let nodes = g.nodeSeq()
  for i in 0 ..< min(nodes.len, 10):
    for j in i + 1 ..< min(nodes.len, 10):
      # Find node-disjoint paths between nodes[i] and nodes[j]
      var pathCount = 0
      var excludeNodes = initHashSet[N]()
      for _ in 0 ..< n:
        # BFS ignoring excluded nodes
        var visited = initTable[N, N]()  # node -> parent
        var queue = initDeque[N]()
        let s = nodes[i]
        let t = nodes[j]
        queue.addLast(s)
        var found = false
        while queue.len > 0:
          let u = queue.popFirst()
          if u == t:
            found = true
            break
          for v in g.neighbors(u):
            if v notin visited and v notin excludeNodes:
              visited[v] = u
              queue.addLast(v)
        if not found: break
        pathCount.inc
        # Exclude internal nodes of found path
        var curr = t
        while curr in visited and visited[curr] != s:
          curr = visited[curr]
          if curr != s and curr != t:
            excludeNodes.incl(curr)
      if pathCount < result:
        result = pathCount

# =============================================================================
# Steiner Tree (#134)
# =============================================================================

proc steinerTree*[N](g: Graph[N], terminalNodes: HashSet[N]): Graph[N] =
  ## Approximate Steiner tree connecting terminal nodes.
  ## Uses the minimum spanning tree of shortest paths heuristic.
  result = newGraph[N]()
  if terminalNodes.len <= 1:
    for n in terminalNodes:
      result.addNode(n)
    return
  let terminals = terminalNodes.toSeq()
  # Build complete graph on terminals with shortest path distances
  type WEdge = tuple[w: float, i, j: int, path: seq[N]]
  var edges: seq[WEdge]
  for i in 0 ..< terminals.len:
    for j in i + 1 ..< terminals.len:
      # BFS for shortest path
      var dist = initTable[N, int]()
      var prev = initTable[N, N]()
      dist[terminals[i]] = 0
      var queue = initDeque[N]()
      queue.addLast(terminals[i])
      while queue.len > 0:
        let u = queue.popFirst()
        if u == terminals[j]: break
        for v in g.neighbors(u):
          if v notin dist:
            dist[v] = dist[u] + 1
            prev[v] = u
            queue.addLast(v)
      if terminals[j] in dist:
        var path = @[terminals[j]]
        var curr = terminals[j]
        while curr != terminals[i]:
          curr = prev[curr]
          path.add(curr)
        edges.add((float(dist[terminals[j]]), i, j, path))
  # Kruskal on complete terminal graph
  edges.sort(proc(a, b: WEdge): int =
    if a.w < b.w: -1
    elif a.w > b.w: 1
    else: 0)
  var parent = newSeq[int](terminals.len)
  for i in 0 ..< terminals.len:
    parent[i] = i
  proc find(x: int): int =
    var c = x
    while parent[c] != c:
      parent[c] = parent[parent[c]]
      c = parent[c]
    c
  for e in edges:
    if find(e.i) != find(e.j):
      parent[find(e.i)] = find(e.j)
      for node in e.path:
        result.addNode(node)
      for k in 0 ..< e.path.len - 1:
        if not result.hasEdge(e.path[k], e.path[k + 1]):
          result.addEdge(e.path[k], e.path[k + 1])

# =============================================================================
# Ramsey R(2,2) (#134)
# =============================================================================

proc ramseyR2*[N](g: Graph[N]): (HashSet[N], HashSet[N]) =
  ## Find a clique and independent set of the graph.
  ## Returns (clique, independent_set).
  var clique = initHashSet[N]()
  var indep = initHashSet[N]()
  var remaining = initHashSet[N]()
  for n in g.nodes:
    remaining.incl(n)
  while remaining.len > 0:
    var v: N
    for n in remaining:
      v = n; break
    remaining.excl(v)
    # Check if v connects to all current clique nodes
    var connectsToAll = true
    for c in clique:
      if not g.hasEdge(v, c):
        connectsToAll = false
        break
    if connectsToAll:
      clique.incl(v)
    else:
      indep.incl(v)
  result = (clique, indep)

# =============================================================================
# Max Cut Approximation (#134)
# =============================================================================

proc maxCut*[N](g: Graph[N]): (HashSet[N], HashSet[N]) =
  ## Approximate max cut using a greedy algorithm.
  ## Returns two sets that maximize the number of edges between them.
  var s1 = initHashSet[N]()
  var s2 = initHashSet[N]()
  for node in g.nodes:
    # Count edges to each side
    var toS1 = 0
    var toS2 = 0
    for nbr in g.neighbors(node):
      if nbr in s1: toS1.inc
      elif nbr in s2: toS2.inc
    if toS1 >= toS2:
      s2.incl(node)
    else:
      s1.incl(node)
  result = (s1, s2)

# =============================================================================
# Approximate Max Clique (#134)
# =============================================================================

proc approxMaxClique*[N](g: Graph[N]): HashSet[N] =
  ## Find an approximate maximum clique using a greedy approach.
  result = initHashSet[N]()
  # Sort nodes by degree (descending)
  var degNodes: seq[(int, N)]
  for n in g.nodes:
    degNodes.add((g.degree(n), n))
  degNodes.sort(proc(a, b: (int, N)): int =
    if a[0] > b[0]: -1
    elif a[0] < b[0]: 1
    else: 0)
  for (_, node) in degNodes:
    var fits = true
    for c in result:
      if not g.hasEdge(node, c):
        fits = false
        break
    if fits:
      result.incl(node)

# =============================================================================
# Approximate Average Clustering (#134)
# =============================================================================

proc approxAverageClusteringCoefficient*[N](g: Graph[N], trials: int = 1000, seed: int = 0): float =
  ## Approximate average clustering coefficient by sampling nodes.
  let n = g.numberOfNodes()
  if n == 0: return 0.0
  var rng = if seed != 0: initRand(seed) else: initRand()
  let nodes = g.nodeSeq()
  var totalCC = 0.0
  let sampleSize = min(trials, n)
  for _ in 0 ..< sampleSize:
    let node = nodes[rng.rand(n - 1)]
    let nbrs = g.neighborSeq(node)
    if nbrs.len < 2:
      continue
    var triangles = 0
    for i in 0 ..< nbrs.len:
      for j in i + 1 ..< nbrs.len:
        if g.hasEdge(nbrs[i], nbrs[j]):
          triangles.inc
    let pairs = nbrs.len * (nbrs.len - 1) div 2
    totalCC += float(triangles) / float(pairs)
  result = totalCC / float(sampleSize)

# =============================================================================
# Approximate Diameter (#134)
# =============================================================================

proc approxDiameter*[N](g: Graph[N]): int =
  ## Approximate the diameter using double-sweep BFS.
  if g.numberOfNodes() == 0: return 0
  # Start from a random node, BFS to find farthest, then BFS from there
  var startNode: N
  for n in g.nodes:
    startNode = n; break
  proc bfsFarthest(start: N): (N, int) =
    var dist = initTable[N, int]()
    dist[start] = 0
    var queue = initDeque[N]()
    queue.addLast(start)
    var farthest = start
    var maxDist = 0
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          queue.addLast(v)
          if dist[v] > maxDist:
            maxDist = dist[v]
            farthest = v
    (farthest, maxDist)
  let (far1, _) = bfsFarthest(startNode)
  let (_, diam) = bfsFarthest(far1)
  result = diam
