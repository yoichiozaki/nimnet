## TSP (Travelling Salesman Problem) heuristic solvers
##
## Nearest neighbor, greedy, 2-opt local search.
## All operate on complete weighted graphs.

import std/[tables, sets, algorithm, heapqueue]
import ../graph

proc tspNearestNeighbor*[N](g: Graph[N], start: N): (seq[N], float) =
  ## Solve TSP using nearest neighbor heuristic.
  ## Returns (tour, total_weight).
  ## Graph should be complete with edge weights.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    return (nodes, 0.0)

  var visited = initHashSet[N]()
  var tour: seq[N] = @[start]
  visited.incl(start)
  var totalWeight = 0.0
  var current = start

  while visited.len < n:
    var bestNext: N
    var bestWeight = Inf
    var found = false
    for neighbor in g.neighbors(current):
      if neighbor notin visited:
        let w = g.getEdgeAttr(current, neighbor).getWeight()
        if w < bestWeight:
          bestWeight = w
          bestNext = neighbor
          found = true
    if not found:
      break
    tour.add(bestNext)
    visited.incl(bestNext)
    totalWeight += bestWeight
    current = bestNext

  # Return to start
  if g.hasEdge(current, start):
    totalWeight += g.getEdgeAttr(current, start).getWeight()
    tour.add(start)

  result = (tour, totalWeight)

proc tspGreedy*[N](g: Graph[N]): (seq[N], float) =
  ## Solve TSP using greedy heuristic.
  ## Builds tour by adding shortest edges that don't create premature cycles.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    return (nodes, 0.0)

  type WeightedEdgeEntry = tuple[weight: float, u, v: N]
  var edges: seq[WeightedEdgeEntry] = @[]
  for (u, v) in g.edges:
    let w = g.getEdgeAttr(u, v).getWeight()
    edges.add((w, u, v))
  edges.sort(proc(a, b: WeightedEdgeEntry): int = cmp(a.weight, b.weight))

  var degree = initTable[N, int]()
  var adj = initTable[N, seq[N]]()
  for node in nodes:
    degree[node] = 0
    adj[node] = @[]
  var totalWeight = 0.0
  var edgeCount = 0

  proc wouldCreatePrematureCycle(u, v: N): bool =
    if edgeCount < n - 1:
      # Check if u and v are already connected
      var visited = initHashSet[N]()
      var stack = @[u]
      visited.incl(u)
      while stack.len > 0:
        let current = stack.pop()
        if current == v:
          return true
        for neighbor in adj[current]:
          if neighbor notin visited:
            visited.incl(neighbor)
            stack.add(neighbor)
      return false
    return false

  for (w, u, v) in edges:
    if degree[u] >= 2 or degree[v] >= 2:
      continue
    if edgeCount < n - 1 and wouldCreatePrematureCycle(u, v):
      continue
    adj[u].add(v)
    adj[v].add(u)
    degree[u].inc
    degree[v].inc
    totalWeight += w
    edgeCount.inc
    if edgeCount == n:
      break

  # Build tour from adjacency list
  var tour: seq[N] = @[]
  var visited = initHashSet[N]()
  # Find start node (preferably degree-1 endpoint, else any)
  var start = nodes[0]
  for node in nodes:
    if degree[node] == 1:
      start = node
      break

  var current = start
  tour.add(current)
  visited.incl(current)
  while true:
    var moved = false
    for neighbor in adj[current]:
      if neighbor notin visited:
        tour.add(neighbor)
        visited.incl(neighbor)
        current = neighbor
        moved = true
        break
    if not moved:
      break

  tour.add(start)
  result = (tour, totalWeight)

proc tsp2Opt*[N](g: Graph[N], initialTour: seq[N]): (seq[N], float) =
  ## Improve a TSP tour using 2-opt local search.
  ## Repeatedly reverses segments that reduce total distance.
  var tour = initialTour
  let n = tour.len - 1  # exclude duplicate start node at end

  proc tourWeight(): float =
    var total = 0.0
    for i in 0 ..< tour.len - 1:
      if g.hasEdge(tour[i], tour[i+1]):
        total += g.getEdgeAttr(tour[i], tour[i+1]).getWeight()
      else:
        total += Inf
    result = total

  var improved = true
  while improved:
    improved = false
    for i in 1 ..< n - 1:
      for j in i + 1 ..< n:
        # Check if reversing segment [i..j] improves
        let a = tour[i-1]
        let b = tour[i]
        let c = tour[j]
        let d = tour[j+1]

        if not g.hasEdge(a, b) or not g.hasEdge(c, d):
          continue
        if not g.hasEdge(a, c) or not g.hasEdge(b, d):
          continue

        let oldDist = g.getEdgeAttr(a, b).getWeight() + g.getEdgeAttr(c, d).getWeight()
        let newDist = g.getEdgeAttr(a, c).getWeight() + g.getEdgeAttr(b, d).getWeight()

        if newDist < oldDist - 1e-10:
          # Reverse the segment
          var left = i
          var right = j
          while left < right:
            swap(tour[left], tour[right])
            left.inc
            right.dec
          improved = true

  result = (tour, tourWeight())
