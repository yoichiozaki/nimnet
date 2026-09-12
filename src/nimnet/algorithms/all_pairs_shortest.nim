## All-pairs shortest paths: Floyd-Warshall and Johnson's algorithm
##
## Floyd-Warshall computes shortest paths between all pairs in O(V^3).
## Johnson's algorithm uses Bellman-Ford + Dijkstra for sparse graphs.

import std/[tables, heapqueue, math]
import ../types
import ../graph
import ../digraph

proc floydWarshall*[N](g: Graph[N]): Table[N, Table[N, float]] =
  ## Compute shortest path lengths between all pairs of nodes.
  ## Returns a table of tables: ``dist[u][v]`` = shortest distance from u to v.
  ## Uses edge weights if available (default weight = 1.0).
  let nodes = g.nodeSeq()
  let n = nodes.len
  result = initTable[N, Table[N, float]]()

  # Initialize distances
  for u in nodes:
    result[u] = initTable[N, float]()
    for v in nodes:
      if u == v:
        result[u][v] = 0.0
      else:
        result[u][v] = Inf

  # Set edge weights
  for (u, v) in g.edges:
    let w = g.getEdgeAttr(u, v).getWeight()
    if w < result[u][v]:
      result[u][v] = w
      result[v][u] = w

  # Floyd-Warshall relaxation
  for k in nodes:
    for i in nodes:
      for j in nodes:
        let through_k = result[i][k] + result[k][j]
        if through_k < result[i][j]:
          result[i][j] = through_k

proc floydWarshall*[N](g: DiGraph[N]): Table[N, Table[N, float]] =
  ## Compute shortest path lengths between all pairs in a directed graph.
  let nodes = g.nodeSeq()
  result = initTable[N, Table[N, float]]()

  for u in nodes:
    result[u] = initTable[N, float]()
    for v in nodes:
      if u == v:
        result[u][v] = 0.0
      else:
        result[u][v] = Inf

  for (u, v) in g.edges:
    let w = g.getEdgeAttr(u, v).getWeight()
    if w < result[u][v]:
      result[u][v] = w

  for k in nodes:
    for i in nodes:
      for j in nodes:
        let through_k = result[i][k] + result[k][j]
        if through_k < result[i][j]:
          result[i][j] = through_k

proc floydWarshallPaths*[N](g: Graph[N]): (Table[N, Table[N, float]], Table[N, Table[N, N]]) =
  ## Compute shortest path lengths and predecessors between all pairs.
  ## Returns ``(dist, pred)`` where ``pred[i][j]`` is the predecessor of j on the shortest path from i.
  let nodes = g.nodeSeq()
  var dist = initTable[N, Table[N, float]]()
  var pred = initTable[N, Table[N, N]]()

  for u in nodes:
    dist[u] = initTable[N, float]()
    pred[u] = initTable[N, N]()
    for v in nodes:
      if u == v:
        dist[u][v] = 0.0
      else:
        dist[u][v] = Inf

  for (u, v) in g.edges:
    let w = g.getEdgeAttr(u, v).getWeight()
    if w < dist[u][v]:
      dist[u][v] = w
      dist[v][u] = w
      pred[u][v] = u
      pred[v][u] = v

  for k in nodes:
    for i in nodes:
      for j in nodes:
        let through_k = dist[i][k] + dist[k][j]
        if through_k < dist[i][j]:
          dist[i][j] = through_k
          pred[i][j] = pred[k][j]

  result = (dist, pred)

type
  PathsAdjacency = object
    offsets: seq[int]
    neighbors: seq[int]
    weights: seq[float]

  IndexedDistance = tuple[distance: float, node: int]

func checkedPathValue(value: float): float {.inline.} =
  if classify(value) in {fcNan, fcInf, fcNegInf}:
    raise newException(NimNetAlgorithmError,
      "Johnson's shortest-path arithmetic is not finite")
  value

proc reweightForJohnsons(adjacency: var PathsAdjacency): seq[float] =
  let n = adjacency.offsets.len - 1
  result = newSeq[float](n)
  # Zero initial potentials represent a virtual source reaching every component.
  for iteration in 0 ..< n:
    var changed = false
    for u in 0 ..< n:
      for edge in adjacency.offsets[u] ..< adjacency.offsets[u + 1]:
        let v = adjacency.neighbors[edge]
        let candidate = checkedPathValue(result[u] + adjacency.weights[edge])
        if candidate < result[v]:
          if iteration == n - 1:
            raise newException(NimNetUnfeasible, "Negative cycle detected")
          result[v] = candidate
          changed = true
    if not changed:
      break

  for u in 0 ..< n:
    for edge in adjacency.offsets[u] ..< adjacency.offsets[u + 1]:
      let v = adjacency.neighbors[edge]
      # Use the same addition order as Bellman-Ford so its final inequalities
      # guarantee nonnegative reweighted edges without clamping negative values.
      adjacency.weights[edge] = checkedPathValue(
        checkedPathValue(result[u] + adjacency.weights[edge]) - result[v])

proc indexedDijkstra(adjacency: PathsAdjacency, source: int,
    distances: var seq[float], queue: var HeapQueue[IndexedDistance],
    reached: var seq[int]) =
  for node in reached:
    distances[node] = Inf
  reached.setLen(0)
  distances[source] = 0.0
  reached.add(source)
  queue.push((0.0, source))
  while queue.len > 0:
    let (distance, u) = queue.pop()
    if distance != distances[u]:
      continue
    for edge in adjacency.offsets[u] ..< adjacency.offsets[u + 1]:
      let v = adjacency.neighbors[edge]
      let candidate = checkedPathValue(distance + adjacency.weights[edge])
      if candidate < distances[v]:
        if distances[v] == Inf:
          reached.add(v)
        distances[v] = candidate
        queue.push((candidate, v))

proc indexedJohnsons[N](adj: Table[N, Table[N, EdgeAttr]],
    directed: static[bool], includeUnreachable: bool): Table[N, Table[N, float]] =
  let n = adj.len
  result = initTable[N, Table[N, float]](n)
  if n == 0:
    return

  var nodes = newSeqOfCap[N](n)
  var nodeIndex = initTable[N, int](n)
  var arcCount = 0
  for node in tables.keys(adj):
    nodeIndex[node] = nodes.len
    nodes.add(node)
    arcCount += adj[node].len

  var adjacency = PathsAdjacency(
    offsets: newSeq[int](n + 1),
    neighbors: newSeqOfCap[int](arcCount),
    weights: newSeqOfCap[float](arcCount))
  var hasNegative = false
  for i, node in nodes:
    adjacency.offsets[i] = adjacency.neighbors.len
    for neighbor, attr in tables.pairs(adj[node]):
      let weight = attr.getWeight()
      if classify(weight) in {fcNan, fcInf, fcNegInf}:
        raise newException(ValueError, "Johnson's algorithm requires finite edge weights")
      if weight < 0.0:
        when directed:
          hasNegative = true
        else:
          raise newException(NimNetUnfeasible,
            "An undirected negative edge forms a negative cycle")
      adjacency.neighbors.add(nodeIndex[neighbor])
      adjacency.weights.add(weight)
  adjacency.offsets[n] = adjacency.neighbors.len

  var potential = newSeq[float](n)
  when directed:
    if hasNegative:
      potential = reweightForJohnsons(adjacency)

  var distances = newSeq[float](n)
  for i in 0 ..< n:
    distances[i] = Inf
  var reached = newSeqOfCap[int](n)
  var queue = initHeapQueue[IndexedDistance]()
  for source in 0 ..< n:
    indexedDijkstra(adjacency, source, distances, queue, reached)
    let targetCount = if includeUnreachable: n else: reached.len
    var row = initTable[N, float](targetCount)
    for i in 0 ..< targetCount:
      let target = if includeUnreachable: i else: reached[i]
      if distances[target] == Inf:
        row[nodes[target]] = Inf
      else:
        row[nodes[target]] = checkedPathValue(
          distances[target] + (potential[target] - potential[source]))
    result[nodes[source]] = row

proc johnsons*[N](g: Graph[N],
    includeUnreachable: bool = false): Table[N, Table[N, float]] =
  ## All-pairs weighted distances for sparse undirected graphs.
  ## Runs binary-heap Dijkstra from each source over one reusable indexed
  ## adjacency. Uses edge weights (default 1.0), including zero weights.
  ## By default, each source's row contains only reachable destinations,
  ## including its self-distance of 0.0 even for an isolated node.
  ## ``includeUnreachable = true`` requests every destination, using Inf for
  ## unreachable pairs. The empty graph returns an empty table.
  ##
  ## Raises ``NimNetUnfeasible`` for any negative edge, including a self-loop,
  ## because traversing an undirected negative edge yields a negative cycle.
  ## Requires finite weights (otherwise ``ValueError``); unrepresentable
  ## distance arithmetic raises ``NimNetAlgorithmError``.
  ## Nodes need only hashing and equality, not ordering.
  ##
  ## Worst-case time: O(V(V + E) log(V + 1)). Working space: O(V + E).
  ## Sparse output uses O(V + R) space, where R is the number of reachable
  ## ordered pairs; complete output uses O(V^2). Only reached indices are reset
  ## between searches. The graph and its attributes are not modified.
  indexedJohnsons(g.adj, false, includeUnreachable)

proc johnsons*[N](g: DiGraph[N],
    includeUnreachable: bool = false): Table[N, Table[N, float]] =
  ## Johnson's all-pairs weighted distances for sparse directed graphs.
  ## Supports negative edges; raises ``NimNetUnfeasible`` for a negative cycle
  ## anywhere in the graph, even in a disconnected component. Nonnegative
  ## inputs skip Bellman-Ford. Reuses one indexed adjacency for every source.
  ##
  ## Preserves reachable-only rows by default, including each source's
  ## self-distance of 0.0. ``includeUnreachable = true`` explicitly requests
  ## every destination with Inf for unreachable pairs. Empty graphs return
  ## an empty table; isolated nodes retain a row containing their self-distance.
  ## Requires finite weights (otherwise ``ValueError``); unrepresentable
  ## distance arithmetic raises ``NimNetAlgorithmError``.
  ## Nodes need only hashing and equality, not ordering.
  ##
  ## Worst-case time: O(VE + V(V + E) log(V + 1)) with binary heaps.
  ## Working space is O(V + E); only reached indices are reset between searches.
  ## Output uses O(V + R) space for R reachable ordered pairs by default,
  ## or O(V^2) with complete output. Does not modify the graph.
  indexedJohnsons(g.adj, true, includeUnreachable)
