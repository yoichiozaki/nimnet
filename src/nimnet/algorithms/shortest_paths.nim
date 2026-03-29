## Shortest path algorithms for nimnet

import std/[tables, sets, deques, sequtils, hashes, algorithm, heapqueue]
import ../types
import ../graph
import ../digraph

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
  var visited = initHashSet[N]()
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  var found = false
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
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
  var visited = initHashSet[N]()
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  var found = false
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
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
  var visited = initHashSet[N]()
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
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
  var visited = initHashSet[N]()
  visited.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  while queue.len > 0:
    let current = queue.popFirst()
    for neighbor in g.neighbors(current):
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
    for neighbor in g.neighbors(current):
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
    for neighbor in g.neighbors(current):
      if neighbor notin result:
        result[neighbor] = dist + 1
        queue.addLast(neighbor)

# =============================================================================
# Dijkstra's Algorithm
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

  type Entry = tuple[dist: float, node: N]
  var pq = initHeapQueue[Entry]()
  var dist = initTable[N, float]()
  var pred = initTable[N, N]()
  var visited = initHashSet[N]()

  dist[source] = 0.0
  pq.push((0.0, source))

  while pq.len > 0:
    let (d, u) = pq.pop()
    if u in visited:
      continue
    if u == target:
      break
    visited.incl(u)
    for neighbor in g.neighbors(u):
      if neighbor notin visited:
        let w = g.weight(u, neighbor)
        let newDist = d + w
        if neighbor notin dist or newDist < dist[neighbor]:
          dist[neighbor] = newDist
          pred[neighbor] = u
          pq.push((newDist, neighbor))

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

  type Entry = tuple[dist: float, node: N]
  var pq = initHeapQueue[Entry]()
  var dist = initTable[N, float]()
  var pred = initTable[N, N]()
  var visited = initHashSet[N]()

  dist[source] = 0.0
  pq.push((0.0, source))

  while pq.len > 0:
    let (d, u) = pq.pop()
    if u in visited:
      continue
    if u == target:
      break
    visited.incl(u)
    for neighbor in g.neighbors(u):
      if neighbor notin visited:
        let w = g.weight(u, neighbor)
        let newDist = d + w
        if neighbor notin dist or newDist < dist[neighbor]:
          dist[neighbor] = newDist
          pred[neighbor] = u
          pq.push((newDist, neighbor))

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

  type Entry = tuple[dist: float, node: N]
  var pq = initHeapQueue[Entry]()
  var dist = initTable[N, float]()
  var visited = initHashSet[N]()

  dist[source] = 0.0
  pq.push((0.0, source))

  while pq.len > 0:
    let (d, u) = pq.pop()
    if u in visited:
      continue
    if u == target:
      return dist[u]
    visited.incl(u)
    for neighbor in g.neighbors(u):
      if neighbor notin visited:
        let w = g.weight(u, neighbor)
        let newDist = d + w
        if neighbor notin dist or newDist < dist[neighbor]:
          dist[neighbor] = newDist
          pq.push((newDist, neighbor))

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

  type Entry = tuple[dist: float, node: N]
  var pq = initHeapQueue[Entry]()
  var dist = initTable[N, float]()
  var visited = initHashSet[N]()

  dist[source] = 0.0
  pq.push((0.0, source))

  while pq.len > 0:
    let (d, u) = pq.pop()
    if u in visited:
      continue
    if u == target:
      return dist[u]
    visited.incl(u)
    for neighbor in g.neighbors(u):
      if neighbor notin visited:
        let w = g.weight(u, neighbor)
        let newDist = d + w
        if neighbor notin dist or newDist < dist[neighbor]:
          dist[neighbor] = newDist
          pq.push((newDist, neighbor))

  if target notin dist:
    raise newException(NimNetNoPath, "No path between source and target")
  dist[target]

proc singleSourceDijkstra*[N](g: Graph[N], source: N): (Table[N, float], Table[N, seq[N]]) =
  ## Return (distances, paths) from source to all reachable nodes.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")

  type Entry = tuple[dist: float, node: N]
  var pq = initHeapQueue[Entry]()
  var dist = initTable[N, float]()
  var paths = initTable[N, seq[N]]()
  var visited = initHashSet[N]()

  dist[source] = 0.0
  paths[source] = @[source]
  pq.push((0.0, source))

  while pq.len > 0:
    let (d, u) = pq.pop()
    if u in visited:
      continue
    visited.incl(u)
    for neighbor in g.neighbors(u):
      if neighbor notin visited:
        let w = g.weight(u, neighbor)
        let newDist = d + w
        if neighbor notin dist or newDist < dist[neighbor]:
          dist[neighbor] = newDist
          paths[neighbor] = paths[u] & @[neighbor]
          pq.push((newDist, neighbor))

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

  type Entry = tuple[fScore: float, gScore: float, node: N]
  var openSet = initHeapQueue[Entry]()
  openSet.push((heuristic(source), 0.0, source))
  var cameFrom = initTable[N, N]()
  var gScore = initTable[N, float]()
  gScore[source] = 0.0
  var closedSet = initHashSet[N]()

  while openSet.len > 0:
    let (_, _, current) = openSet.pop()
    if current == target:
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
    for neighbor in g.neighbors(current):
      let edgeWeight = g[current, neighbor].getWeight()
      let tentativeG = gScore[current] + edgeWeight
      if neighbor in closedSet and tentativeG >= gScore.getOrDefault(neighbor, Inf):
        continue
      if neighbor notin gScore or tentativeG < gScore[neighbor]:
        cameFrom[neighbor] = current
        gScore[neighbor] = tentativeG
        let fScore = tentativeG + heuristic(neighbor)
        openSet.push((fScore, tentativeG, neighbor))
        if neighbor in closedSet:
          closedSet.excl(neighbor)

  raise newException(NimNetNoPath, "No path between source and target")

proc astarPathLength*[N](g: Graph[N], source, target: N,
                          heuristic: proc(n: N): float): float =
  ## Return the length (total weight) of the A* shortest path.
  let path = astarPath(g, source, target, heuristic)
  result = 0.0
  for i in 0 ..< path.len - 1:
    result += g[path[i], path[i + 1]].getWeight()
