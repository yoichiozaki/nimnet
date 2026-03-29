## Shortest path algorithms for nimnet

import std/[tables, sets, deques, algorithm, heapqueue]
import ../types
import ../graph
import ../digraph

# Helper type for priority queue (avoids requiring `<` on N)
type
  DijkEntry[N] = object
    dist: float
    node: N

func `<`*[N](a, b: DijkEntry[N]): bool = a.dist < b.dist

type
  AstarEntry[N] = object
    fScore: float
    gScore: float
    node: N

func `<`*[N](a, b: AstarEntry[N]): bool = a.fScore < b.fScore

# =============================================================================
# Unweighted shortest paths (BFS-based)
# =============================================================================

proc shortestPath*[N](g: Graph[N], source, target: N): seq[N] =
  ## Find the shortest path between source and target (unweighted).
  ## Raises NimNetNoPath if no path exists.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return @[source]
  var pred = initTable[N, N]()
  var visited = initHashSet[N](g.numberOfNodes())
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  var found = false
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.adj[current].keys:
      if neighbor notin visited:
        visited.incl(neighbor)
        pred[neighbor] = current
        if neighbor == target:
          found = true
          break
        queue.addLast(neighbor)
    if found:
      break
  if not found:
    raise newException(NimNetNoPath, "No path between source and target")
  # Reconstruct path
  var path: seq[N]
  var current = target
  while current != source:
    path.add(current)
    current = pred[current]
  path.add(source)
  path.reverse()
  result = path

proc shortestPath*[N](g: DiGraph[N], source, target: N): seq[N] =
  ## Shortest path in directed graph.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return @[source]
  var pred = initTable[N, N]()
  var visited = initHashSet[N](g.numberOfNodes())
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  var found = false
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.adj[current].keys:
      if neighbor notin visited:
        visited.incl(neighbor)
        pred[neighbor] = current
        if neighbor == target:
          found = true
          break
        queue.addLast(neighbor)
    if found:
      break
  if not found:
    raise newException(NimNetNoPath, "No path between source and target")
  var path: seq[N]
  var current = target
  while current != source:
    path.add(current)
    current = pred[current]
  path.add(source)
  path.reverse()
  result = path

proc shortestPathLength*[N](g: Graph[N], source, target: N): int =
  ## Return length of shortest path (number of edges).
  let path = shortestPath(g, source, target)
  path.len - 1

proc shortestPathLength*[N](g: DiGraph[N], source, target: N): int =
  ## Return length of shortest path in a directed graph (number of edges).
  let path = shortestPath(g, source, target)
  path.len - 1

proc hasPath*[N](g: Graph[N], source, target: N): bool =
  ## Return true if a path exists between source and target.
  if not g.hasNode(source) or not g.hasNode(target):
    return false
  if source == target:
    return true
  var visited = initHashSet[N](g.numberOfNodes())
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.adj[current].keys:
      if neighbor == target:
        return true
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  false

proc hasPath*[N](g: DiGraph[N], source, target: N): bool =
  ## Return true if a directed path exists from source to target.
  if not g.hasNode(source) or not g.hasNode(target):
    return false
  if source == target:
    return true
  var visited = initHashSet[N](g.numberOfNodes())
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.adj[current].keys:
      if neighbor == target:
        return true
      if neighbor notin visited:
        visited.incl(neighbor)
        queue.addLast(neighbor)
  false

proc singleSourceShortestPathLength*[N](g: Graph[N], source: N): Table[N, int] =
  ## Return shortest path lengths from source to all reachable nodes.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  result = initTable[N, int]()
  result[source] = 0
  var queue = initDeque[N]()
  queue.addLast(source)
  while queue.len > 0:
    let current = queue.popFirst()
    let dist = result[current]
    for neighbor in g.adj[current].keys:
      if neighbor notin result:
        result[neighbor] = dist + 1
        queue.addLast(neighbor)

proc singleSourceShortestPathLength*[N](g: DiGraph[N], source: N): Table[N, int] =
  ## Return shortest path lengths from source in a directed graph.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  result = initTable[N, int]()
  result[source] = 0
  var queue = initDeque[N]()
  queue.addLast(source)
  while queue.len > 0:
    let current = queue.popFirst()
    let dist = result[current]
    for neighbor in g.adj[current].keys:
      if neighbor notin result:
        result[neighbor] = dist + 1
        queue.addLast(neighbor)

# =============================================================================
# Dijkstra's Algorithm (binary heap — O((V+E) log V))
# =============================================================================

proc dijkstraPath*[N](g: Graph[N], source, target: N): seq[N] =
  ## Find shortest weighted path using Dijkstra's algorithm.
  ## Uses "weight" edge attribute (default 1.0).
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return @[source]

  var dist = initTable[N, float]()
  var pred = initTable[N, N]()
  var visited = initHashSet[N](g.numberOfNodes())
  dist[source] = 0.0

  var pq: HeapQueue[DijkEntry[N]]
  pq.push(DijkEntry[N](dist: 0.0, node: source))

  while pq.len > 0:
    let entry = pq.pop()
    let u = entry.node
    if u in visited:
      continue
    if u == target:
      break
    visited.incl(u)
    let uDist = entry.dist
    for v, attr in g.adj[u]:
      if v notin visited:
        let newDist = uDist + attr.weight
        if newDist < dist.getOrDefault(v, Inf):
          dist[v] = newDist
          pred[v] = u
          pq.push(DijkEntry[N](dist: newDist, node: v))

  if target notin dist:
    raise newException(NimNetNoPath, "No path between source and target")

  var path: seq[N]
  var current = target
  while current != source:
    path.add(current)
    current = pred[current]
  path.add(source)
  path.reverse()
  result = path

proc dijkstraPath*[N](g: DiGraph[N], source, target: N): seq[N] =
  ## Find shortest weighted path in a directed graph using Dijkstra's algorithm.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return @[source]

  var dist = initTable[N, float]()
  var pred = initTable[N, N]()
  var visited = initHashSet[N](g.numberOfNodes())
  dist[source] = 0.0

  var pq: HeapQueue[DijkEntry[N]]
  pq.push(DijkEntry[N](dist: 0.0, node: source))

  while pq.len > 0:
    let entry = pq.pop()
    let u = entry.node
    if u in visited:
      continue
    if u == target:
      break
    visited.incl(u)
    let uDist = entry.dist
    for v, attr in g.adj[u]:
      if v notin visited:
        let newDist = uDist + attr.weight
        if newDist < dist.getOrDefault(v, Inf):
          dist[v] = newDist
          pred[v] = u
          pq.push(DijkEntry[N](dist: newDist, node: v))

  if target notin dist:
    raise newException(NimNetNoPath, "No path between source and target")

  var path: seq[N]
  var current = target
  while current != source:
    path.add(current)
    current = pred[current]
  path.add(source)
  path.reverse()
  result = path

proc dijkstraPathLength*[N](g: Graph[N], source, target: N): float =
  ## Return weighted shortest path length.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return 0.0

  var dist = initTable[N, float]()
  var visited = initHashSet[N](g.numberOfNodes())
  dist[source] = 0.0

  var pq: HeapQueue[DijkEntry[N]]
  pq.push(DijkEntry[N](dist: 0.0, node: source))

  while pq.len > 0:
    let entry = pq.pop()
    let u = entry.node
    if u in visited:
      continue
    if u == target:
      return entry.dist
    visited.incl(u)
    let uDist = entry.dist
    for v, attr in g.adj[u]:
      if v notin visited:
        let newDist = uDist + attr.getWeight()
        if v notin dist or newDist < dist[v]:
          dist[v] = newDist
          pq.push(DijkEntry[N](dist: newDist, node: v))

  if target notin dist:
    raise newException(NimNetNoPath, "No path between source and target")
  dist[target]

proc dijkstraPathLength*[N](g: DiGraph[N], source, target: N): float =
  ## Return weighted shortest path length in a directed graph.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return 0.0

  var dist = initTable[N, float]()
  var visited = initHashSet[N](g.numberOfNodes())
  dist[source] = 0.0

  var pq: HeapQueue[DijkEntry[N]]
  pq.push(DijkEntry[N](dist: 0.0, node: source))

  while pq.len > 0:
    let entry = pq.pop()
    let u = entry.node
    if u in visited:
      continue
    if u == target:
      return entry.dist
    visited.incl(u)
    let uDist = entry.dist
    for v, attr in g.adj[u]:
      if v notin visited:
        let newDist = uDist + attr.getWeight()
        if v notin dist or newDist < dist[v]:
          dist[v] = newDist
          pq.push(DijkEntry[N](dist: newDist, node: v))

  if target notin dist:
    raise newException(NimNetNoPath, "No path between source and target")
  dist[target]

proc singleSourceDijkstra*[N](g: Graph[N], source: N): (Table[N, float], Table[N, seq[N]]) =
  ## Return (distances, paths) from source to all reachable nodes.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")

  var dist = initTable[N, float]()
  var pred = initTable[N, N]()
  var visited = initHashSet[N](g.numberOfNodes())
  dist[source] = 0.0

  var pq: HeapQueue[DijkEntry[N]]
  pq.push(DijkEntry[N](dist: 0.0, node: source))

  while pq.len > 0:
    let entry = pq.pop()
    let u = entry.node
    if u in visited:
      continue
    visited.incl(u)
    let uDist = entry.dist
    for v, attr in g.adj[u]:
      if v notin visited:
        let newDist = uDist + attr.getWeight()
        if v notin dist or newDist < dist[v]:
          dist[v] = newDist
          pred[v] = u
          pq.push(DijkEntry[N](dist: newDist, node: v))

  # Reconstruct paths from predecessors
  var paths = initTable[N, seq[N]]()
  paths[source] = @[source]
  for node in dist.keys:
    if node == source:
      continue
    var path: seq[N]
    var current = node
    while current != source:
      path.add(current)
      current = pred[current]
    path.add(source)
    path.reverse()
    paths[node] = path

  result = (dist, paths)

# =============================================================================
# Bellman-Ford Algorithm
# =============================================================================

proc bellmanFordPath*[N](g: Graph[N], source, target: N): seq[N] =
  ## Find shortest weighted path using Bellman-Ford. Supports negative weights.
  ## Raises NimNetUnfeasible if negative cycle is detected.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return @[source]

  var dist = initTable[N, float]()
  var pred = initTable[N, N]()
  for n in g.nodes:
    dist[n] = Inf
  dist[source] = 0.0

  let nodeCount = g.numberOfNodes()
  # Relax edges |V| - 1 times
  for i in 0 ..< nodeCount - 1:
    for (u, v, attr) in g.edgesWithAttr:
      let w = attr.getWeight()
      # Undirected: relax both directions
      if dist[u] + w < dist[v]:
        dist[v] = dist[u] + w
        pred[v] = u
      if dist[v] + w < dist[u]:
        dist[u] = dist[v] + w
        pred[u] = v

  # Check for negative cycles
  for (u, v, attr) in g.edgesWithAttr:
    let w = attr.getWeight()
    if dist[u] + w < dist[v] or dist[v] + w < dist[u]:
      raise newException(NimNetUnfeasible, "Negative cycle detected")

  if dist[target] == Inf:
    raise newException(NimNetNoPath, "No path between source and target")

  var path: seq[N]
  var current = target
  while current != source:
    path.add(current)
    current = pred[current]
  path.add(source)
  path.reverse()
  result = path

proc bellmanFordPath*[N](g: DiGraph[N], source, target: N): seq[N] =
  ## Find shortest weighted path in a directed graph using Bellman-Ford.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return @[source]

  var dist = initTable[N, float]()
  var pred = initTable[N, N]()
  for n in g.nodes:
    dist[n] = Inf
  dist[source] = 0.0

  let nodeCount = g.numberOfNodes()
  for i in 0 ..< nodeCount - 1:
    for (u, v, attr) in g.edgesWithAttr:
      let w = attr.getWeight()
      if dist[u] + w < dist[v]:
        dist[v] = dist[u] + w
        pred[v] = u

  # Check for negative cycles
  for (u, v, attr) in g.edgesWithAttr:
    let w = attr.getWeight()
    if dist[u] + w < dist[v]:
      raise newException(NimNetUnfeasible, "Negative cycle detected")

  if dist[target] == Inf:
    raise newException(NimNetNoPath, "No path between source and target")

  var path: seq[N]
  var current = target
  while current != source:
    path.add(current)
    current = pred[current]
  path.add(source)
  path.reverse()
  result = path

# =============================================================================
# A* search
# =============================================================================

proc astarPath*[N](g: Graph[N], source, target: N,
                   heuristic: proc(n: N): float): seq[N] =
  ## A* shortest path from source to target using a heuristic function.
  ## The heuristic should estimate the distance from node n to the target.
  ## Uses edge weights if present (default weight = 1.0).
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(target):
    raise newException(NodeNotFound, "Target node not found")
  if source == target:
    return @[source]

  # Open set with (f_score, g_score, node) - use binary heap for O(log n) pop
  var openSet: HeapQueue[AstarEntry[N]]
  openSet.push(AstarEntry[N](fScore: heuristic(source), gScore: 0.0, node: source))
  var cameFrom = initTable[N, N]()
  var gScore = initTable[N, float]()
  gScore[source] = 0.0
  var closedSet = initHashSet[N](g.numberOfNodes())

  while openSet.len > 0:
    let entry = openSet.pop()
    let current = entry.node

    if current == target:
      # Reconstruct path
      var path: seq[N] = @[target]
      var node = target
      while node in cameFrom:
        node = cameFrom[node]
        path.add(node)
      path.reverse()
      return path

    if current in closedSet:
      continue
    closedSet.incl(current)

    for neighbor, edgeAttr in g.adj[current]:
      let tentativeG = gScore[current] + edgeAttr.getWeight()

      # If neighbor is closed and we don't have a better path, skip it.
      if neighbor in closedSet and tentativeG >= gScore.getOrDefault(neighbor, Inf):
        continue

      if neighbor notin gScore or tentativeG < gScore[neighbor]:
        cameFrom[neighbor] = current
        gScore[neighbor] = tentativeG
        let fScore = tentativeG + heuristic(neighbor)
        openSet.push(AstarEntry[N](fScore: fScore, gScore: tentativeG, node: neighbor))
        # Re-open neighbor if we found a better path.
        if neighbor in closedSet:
          closedSet.excl(neighbor)

  raise newException(NimNetNoPath, "No path between source and target")

proc astarPathLength*[N](g: Graph[N], source, target: N,
                          heuristic: proc(n: N): float): float =
  ## Return the length (total weight) of the A* shortest path.
  let path = astarPath(g, source, target, heuristic)
  result = 0.0
  for i in 0 ..< path.len - 1:
    result += g.adj[path[i]][path[i + 1]].getWeight()

# =============================================================================
# Bellman-Ford Enhancements
# =============================================================================

proc hasNegativeCycle*[N](g: Graph[N]): bool =
  ## Check whether the undirected graph contains a negative weight cycle.
  ## An undirected graph has a negative cycle if any edge has negative weight.
  for (u, v, attr) in g.edgesWithAttr:
    if attr.getWeight() < 0.0:
      return true
  return false

proc hasNegativeCycle*[N](g: DiGraph[N]): bool =
  ## Check whether the directed graph contains a negative weight cycle
  ## reachable from any node. Uses Bellman-Ford from each component.
  var visited = initHashSet[N]()

  for startNode in g.nodes:
    if startNode in visited:
      continue

    var dist = initTable[N, float]()
    for n in g.nodes:
      dist[n] = Inf
    dist[startNode] = 0.0
    visited.incl(startNode)

    let nodeCount = g.numberOfNodes()
    for i in 0 ..< nodeCount - 1:
      for (u, v, attr) in g.edgesWithAttr:
        let w = attr.getWeight()
        if dist[u] != Inf and dist[u] + w < dist[v]:
          dist[v] = dist[u] + w
          visited.incl(v)

    # Check for negative cycle
    for (u, v, attr) in g.edgesWithAttr:
      let w = attr.getWeight()
      if dist[u] != Inf and dist[u] + w < dist[v]:
        return true

  return false

proc bellmanFordDistances*[N](g: Graph[N], source: N): Table[N, float] =
  ## Compute shortest distances from ``source`` to all reachable nodes
  ## using Bellman-Ford. Supports negative weights.
  ##
  ## **Raises:** ``NimNetUnfeasible`` if negative cycle is detected.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")

  for n in g.nodes:
    result[n] = Inf
  result[source] = 0.0

  let nodeCount = g.numberOfNodes()
  for i in 0 ..< nodeCount - 1:
    for (u, v, attr) in g.edgesWithAttr:
      let w = attr.getWeight()
      if result[u] + w < result[v]:
        result[v] = result[u] + w
      if result[v] + w < result[u]:
        result[u] = result[v] + w

  for (u, v, attr) in g.edgesWithAttr:
    let w = attr.getWeight()
    if result[u] + w < result[v] or result[v] + w < result[u]:
      raise newException(NimNetUnfeasible, "Negative cycle detected")

proc bellmanFordDistances*[N](g: DiGraph[N], source: N): Table[N, float] =
  ## Compute shortest distances from ``source`` to all reachable nodes
  ## in a directed graph using Bellman-Ford.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")

  for n in g.nodes:
    result[n] = Inf
  result[source] = 0.0

  let nodeCount = g.numberOfNodes()
  for i in 0 ..< nodeCount - 1:
    for (u, v, attr) in g.edgesWithAttr:
      let w = attr.getWeight()
      if result[u] != Inf and result[u] + w < result[v]:
        result[v] = result[u] + w

  for (u, v, attr) in g.edgesWithAttr:
    let w = attr.getWeight()
    if result[u] != Inf and result[u] + w < result[v]:
      raise newException(NimNetUnfeasible, "Negative cycle detected")

# =============================================================================
# Yen's K-Shortest Simple Paths (#133)
# =============================================================================

proc shortestSimplePaths*[N](g: Graph[N], source, target: N, k: int = 10): seq[seq[N]] =
  ## Find the k shortest simple paths from source to target using Yen's algorithm.
  ## Returns up to k paths in order of length.
  if source == target:
    return @[@[source]]
  # Find first shortest path using Dijkstra
  var firstPath: seq[N]
  try:
    firstPath = dijkstraPath(g, source, target)
  except:
    return @[]
  if firstPath.len == 0:
    return @[]
  result = @[firstPath]
  var candidates: seq[(float, seq[N])] = @[]
  for ki in 1 ..< k:
    let lastPath = result[^1]
    for i in 0 ..< lastPath.len - 1:
      let spurNode = lastPath[i]
      let rootPath = lastPath[0 .. i]
      # Build modified graph excluding edges used by existing paths
      var excludeEdges = initHashSet[(N, N)]()
      for p in result:
        if p.len > i and p[0 .. i] == rootPath:
          excludeEdges.incl((p[i], p[i + 1]))
      var excludeNodes = initHashSet[N]()
      for j in 0 ..< i:
        excludeNodes.incl(rootPath[j])
      # Dijkstra on modified graph
      var dist = initTable[N, float]()
      var prev = initTable[N, N]()
      dist[spurNode] = 0.0
      var pq = initHeapQueue[DijkEntry[N]]()
      pq.push(DijkEntry[N](node: spurNode, dist: 0.0))
      while pq.len > 0:
        let entry = pq.pop()
        if entry.dist > dist.getOrDefault(entry.node, Inf): continue
        if entry.node == target: break
        for nbr in g.neighbors(entry.node):
          if nbr in excludeNodes: continue
          if (entry.node, nbr) in excludeEdges: continue
          let w = g[entry.node, nbr].getWeight()
          let nd = entry.dist + w
          if nd < dist.getOrDefault(nbr, Inf):
            dist[nbr] = nd
            prev[nbr] = entry.node
            pq.push(DijkEntry[N](node: nbr, dist: nd))
      if target in dist:
        var spurPath = @[target]
        var curr = target
        while curr != spurNode:
          curr = prev[curr]
          spurPath.add(curr)
        algorithm.reverse(spurPath)
        let totalPath = rootPath[0 ..< rootPath.len - 1] & spurPath
        let totalDist = block:
          var d = 0.0
          for idx in 0 ..< totalPath.len - 1:
            d += g[totalPath[idx], totalPath[idx + 1]].getWeight()
          d
        candidates.add((totalDist, totalPath))
    if candidates.len == 0: break
    candidates.sort(proc(a, b: (float, seq[N])): int =
      if a[0] < b[0]: -1
      elif a[0] > b[0]: 1
      else: 0)
    # Find best candidate not already in result
    var added = false
    var newCandidates: seq[(float, seq[N])]
    for c in candidates:
      if c[1] notin result:
        if not added:
          result.add(c[1])
          added = true
        else:
          newCandidates.add(c)
      else:
        newCandidates.add(c)
    candidates = newCandidates
    if not added: break

proc shortestSimplePaths*[N](g: DiGraph[N], source, target: N, k: int = 10): seq[seq[N]] =
  ## Find the k shortest simple paths in a directed graph.
  if source == target:
    return @[@[source]]
  var firstPath: seq[N]
  try:
    firstPath = dijkstraPath(g, source, target)
  except:
    return @[]
  if firstPath.len == 0: return @[]
  result = @[firstPath]
  var candidates: seq[(float, seq[N])] = @[]
  for ki in 1 ..< k:
    let lastPath = result[^1]
    for i in 0 ..< lastPath.len - 1:
      let spurNode = lastPath[i]
      let rootPath = lastPath[0 .. i]
      var excludeEdges = initHashSet[(N, N)]()
      for p in result:
        if p.len > i and p[0 .. i] == rootPath:
          excludeEdges.incl((p[i], p[i + 1]))
      var excludeNodes = initHashSet[N]()
      for j in 0 ..< i:
        excludeNodes.incl(rootPath[j])
      var dist = initTable[N, float]()
      var prev = initTable[N, N]()
      dist[spurNode] = 0.0
      var pq = initHeapQueue[DijkEntry[N]]()
      pq.push(DijkEntry[N](node: spurNode, dist: 0.0))
      while pq.len > 0:
        let entry = pq.pop()
        if entry.dist > dist.getOrDefault(entry.node, Inf): continue
        if entry.node == target: break
        for nbr in g.neighbors(entry.node):
          if nbr in excludeNodes: continue
          if (entry.node, nbr) in excludeEdges: continue
          let w = g[entry.node, nbr].getWeight()
          let nd = entry.dist + w
          if nd < dist.getOrDefault(nbr, Inf):
            dist[nbr] = nd
            prev[nbr] = entry.node
            pq.push(DijkEntry[N](node: nbr, dist: nd))
      if target in dist:
        var spurPath = @[target]
        var curr = target
        while curr != spurNode:
          curr = prev[curr]
          spurPath.add(curr)
        algorithm.reverse(spurPath)
        let totalPath = rootPath[0 ..< rootPath.len - 1] & spurPath
        let totalDist = block:
          var d = 0.0
          for idx in 0 ..< totalPath.len - 1:
            d += g[totalPath[idx], totalPath[idx + 1]].getWeight()
          d
        candidates.add((totalDist, totalPath))
    if candidates.len == 0: break
    candidates.sort(proc(a, b: (float, seq[N])): int =
      if a[0] < b[0]: -1
      elif a[0] > b[0]: 1
      else: 0)
    var added = false
    var newCandidates: seq[(float, seq[N])]
    for c in candidates:
      if c[1] notin result:
        if not added:
          result.add(c[1])
          added = true
        else:
          newCandidates.add(c)
      else:
        newCandidates.add(c)
    candidates = newCandidates
    if not added: break
