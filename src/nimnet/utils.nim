## Utility functions for nimnet graphs
##
## Provides graph-level queries, freeze support, display, and helper functions.

import std/[tables, sets, strutils, algorithm, deques]
import ./types, ./graph, ./digraph

# --- Freeze support --------------------------------------------------------

proc freeze*[N](g: var Graph[N]) =
  ## Mark a graph as frozen. After freezing, mutation raises NimNetError.
  g.frozen = true

proc freeze*[N](g: var DiGraph[N]) =
  ## Mark a digraph as frozen. After freezing, mutation raises NimNetError.
  g.frozen = true

func isFrozen*[N](g: Graph[N]): bool =
  ## Check if graph is frozen.
  g.frozen

func isFrozen*[N](g: DiGraph[N]): bool =
  ## Check if digraph is frozen.
  g.frozen

# --- Property checks -------------------------------------------------------

func isWeighted*[N](g: Graph[N]): bool =
  ## Check if any edge has weight != 1.0.
  for (u, v, attr) in g.edgesWithAttr:
    if attr.weight != 1.0:
      return true
  return false

func isWeighted*[N](g: DiGraph[N]): bool =
  ## Check if any edge has weight != 1.0.
  for (u, v, attr) in g.edgesWithAttr:
    if attr.weight != 1.0:
      return true
  return false

func isNegativelyWeighted*[N](g: Graph[N]): bool =
  ## Check if any edge has negative weight.
  for (u, v, attr) in g.edgesWithAttr:
    if attr.weight < 0.0:
      return true
  return false

func isNegativelyWeighted*[N](g: DiGraph[N]): bool =
  ## Check if any edge has negative weight.
  for (u, v, attr) in g.edgesWithAttr:
    if attr.weight < 0.0:
      return true
  return false

func isMultigraph*[N](g: Graph[N]): bool =
  ## Graph is not a multigraph.
  false

func isMultigraph*[N](g: DiGraph[N]): bool =
  ## DiGraph is not a multigraph.
  false

# --- Path utilities --------------------------------------------------------

func isPath*[N](g: Graph[N], path: openArray[N]): bool =
  ## Check if the sequence of nodes forms a valid path in the graph.
  if path.len == 0: return true
  for i in 0 ..< path.len - 1:
    if not g.hasEdge(path[i], path[i + 1]):
      return false
  return true

func isPath*[N](g: DiGraph[N], path: openArray[N]): bool =
  ## Check if the sequence of nodes forms a valid path in the digraph.
  if path.len == 0: return true
  for i in 0 ..< path.len - 1:
    if not g.hasEdge(path[i], path[i + 1]):
      return false
  return true

func pathWeight*[N](g: Graph[N], path: openArray[N]): float =
  ## Compute total weight of a path.
  result = 0.0
  for i in 0 ..< path.len - 1:
    result += g.weight(path[i], path[i + 1])

func pathWeight*[N](g: DiGraph[N], path: openArray[N]): float =
  ## Compute total weight of a path.
  result = 0.0
  for i in 0 ..< path.len - 1:
    result += g.weight(path[i], path[i + 1])

# --- Node/Edge queries -----------------------------------------------------

iterator nonNodes*[N](g: Graph[N], nodes: openArray[N]): N =
  ## Yield nodes from the list that are NOT in the graph.
  for n in nodes:
    if not g.hasNode(n):
      yield n

iterator nonNodes*[N](g: DiGraph[N], nodes: openArray[N]): N =
  ## Yield nodes from the list that are NOT in the graph.
  for n in nodes:
    if not g.hasNode(n):
      yield n

iterator nonEdges*[N](g: Graph[N]): (N, N) =
  ## Yield pairs of nodes that are NOT connected by an edge.
  let ns = g.nodeSeq
  for i in 0 ..< ns.len:
    for j in i + 1 ..< ns.len:
      if not g.hasEdge(ns[i], ns[j]):
        yield (ns[i], ns[j])

iterator nonEdges*[N](g: DiGraph[N]): (N, N) =
  ## Yield pairs of nodes that are NOT connected by a directed edge.
  let ns = g.nodeSeq
  for i in 0 ..< ns.len:
    for j in 0 ..< ns.len:
      if i != j and not g.hasEdge(ns[i], ns[j]):
        yield (ns[i], ns[j])

# --- Display ---------------------------------------------------------------

proc display*[N](g: Graph[N]): string =
  ## Return a summary string representation of the graph.
  result = "Graph '" & g.name & "' (n=" & $g.numberOfNodes & ", m=" & $g.numberOfEdges & ")"

proc display*[N](g: DiGraph[N]): string =
  ## Return a summary string representation of the digraph.
  result = "DiGraph '" & g.name & "' (n=" & $g.numberOfNodes & ", m=" & $g.numberOfEdges & ")"

# --- Utility functions (from #153) ----------------------------------------

proc createEmptyCopy*[N](g: Graph[N]): Graph[N] =
  ## Create a copy of g with all nodes but no edges.
  result = newGraph[N](name = g.name)
  for n in g.nodes:
    result.addNode(n)

proc createEmptyCopy*[N](g: DiGraph[N]): DiGraph[N] =
  ## Create a copy of g with all nodes but no edges.
  result = newDiGraph[N](name = g.name)
  for n in g.nodes:
    result.addNode(n)

proc convertNodeLabelsToIntegers*[N](g: Graph[N]): Graph[int] =
  ## Relabel all nodes as integers 0..n-1.
  result = newGraph[int](capacity = g.numberOfNodes)
  var mapping: Table[N, int]
  var idx = 0
  for n in g.nodes:
    mapping[n] = idx
    result.addNode(idx)
    inc idx
  for (u, v) in g.edges:
    result.addEdge(mapping[u], mapping[v])

proc convertNodeLabelsToIntegers*[N](g: DiGraph[N]): DiGraph[int] =
  ## Relabel all nodes as integers 0..n-1.
  result = newDiGraph[int](capacity = g.numberOfNodes)
  var mapping: Table[N, int]
  var idx = 0
  for n in g.nodes:
    mapping[n] = idx
    result.addNode(idx)
    inc idx
  for (u, v) in g.edges:
    result.addEdge(mapping[u], mapping[v])

proc reverseCuthillMckeeOrdering*[N](g: Graph[N]): seq[N] =
  ## Compute Reverse Cuthill-McKee ordering for bandwidth reduction.
  var res: seq[N]
  if g.numberOfNodes == 0:
    return res
  # Find node with minimum degree as starting node
  let ns = g.nodeSeq
  var startNode = ns[0]
  var minDeg = g.degree(ns[0])
  for n in ns:
    let d = g.degree(n)
    if d < minDeg:
      minDeg = d
      startNode = n
  # BFS-based Cuthill-McKee
  var visited: HashSet[N]
  var queue: Deque[N]
  queue.addLast(startNode)
  visited.incl(startNode)
  while queue.len > 0:
    let node = queue.popFirst()
    res.add(node)
    var nbrs: seq[(int, N)]
    for nb in g.neighbors(node):
      if nb notin visited:
        nbrs.add((g.degree(nb), nb))
    nbrs.sort(proc(a, b: (int, N)): int = cmp(a[0], b[0]))
    for (_, nb) in nbrs:
      if nb notin visited:
        visited.incl(nb)
        queue.addLast(nb)
  # Handle disconnected components
  for n in ns:
    if n notin visited:
      visited.incl(n)
      queue.addLast(n)
      while queue.len > 0:
        let node = queue.popFirst()
        res.add(node)
        var nbrs: seq[(int, N)]
        for nb in g.neighbors(node):
          if nb notin visited:
            nbrs.add((g.degree(nb), nb))
        nbrs.sort(proc(a, b: (int, N)): int = cmp(a[0], b[0]))
        for (_, nb) in nbrs:
          if nb notin visited:
            visited.incl(nb)
            queue.addLast(nb)
  algorithm.reverse(res)
  result = res

iterator pairwiseIter*[T](s: openArray[T]): (T, T) =
  ## Yield consecutive pairs from a sequence.
  for i in 0 ..< s.len - 1:
    yield (s[i], s[i + 1])

proc pairwise*[T](s: openArray[T]): seq[(T, T)] =
  ## Return consecutive pairs from a sequence.
  for i in 0 ..< s.len - 1:
    result.add((s[i], s[i + 1]))

proc groups*[K, V](mapping: Table[K, V]): Table[V, seq[K]] =
  ## Group keys by their values.
  for k, v in mapping:
    if v notin result:
      result[v] = @[]
    result[v].add(k)

proc flatten*[T](nested: seq[seq[T]]): seq[T] =
  ## Flatten a sequence of sequences.
  for inner in nested:
    for item in inner:
      result.add(item)

var uniqueNodeCounter {.threadvar.}: int

proc generateUniqueNode*(): int =
  ## Generate a unique integer node ID.
  inc uniqueNodeCounter
  result = uniqueNodeCounter

proc generateUniqueNode*[N: SomeInteger](g: Graph[N]): N =
  ## Generate a unique node not in g.
  var candidate = N(g.numberOfNodes)
  while g.hasNode(candidate):
    inc candidate
  result = candidate

proc generateUniqueNode*[N: SomeInteger](g: DiGraph[N]): N =
  ## Generate a unique node not in g.
  var candidate = N(g.numberOfNodes)
  while g.hasNode(candidate):
    inc candidate
  result = candidate
