## Bipartite graph algorithms
##
## Bipartiteness check, 2-coloring, maximum matching (Hopcroft-Karp).

import std/[sets, tables, deques]
import ../types
import ../graph

proc isBipartite*[N](g: Graph[N]): bool =
  ## Check if the graph is bipartite using 2-coloring BFS.
  var color = initTable[N, int]()
  for startNode in g.nodes:
    if startNode in color:
      continue
    color[startNode] = 0
    var queue = initDeque[N]()
    queue.addLast(startNode)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin color:
          color[v] = 1 - color[u]
          queue.addLast(v)
        elif color[v] == color[u]:
          return false
  return true

proc bipartiteSets*[N](g: Graph[N]): (HashSet[N], HashSet[N]) =
  ## Return the two partitions of a bipartite graph.
  ## Raises NimNetError if the graph is not bipartite.
  var color = initTable[N, int]()
  var setA = initHashSet[N]()
  var setB = initHashSet[N]()
  for startNode in g.nodes:
    if startNode in color:
      continue
    color[startNode] = 0
    setA.incl(startNode)
    var queue = initDeque[N]()
    queue.addLast(startNode)
    while queue.len > 0:
      let u = queue.popFirst()
      for v in g.neighbors(u):
        if v notin color:
          color[v] = 1 - color[u]
          if color[v] == 0:
            setA.incl(v)
          else:
            setB.incl(v)
          queue.addLast(v)
        elif color[v] == color[u]:
          raise newException(NimNetError, "Graph is not bipartite")
  result = (setA, setB)

type IndexedBipartite[N] = object
  nodes: seq[N]
  adjacency: seq[seq[int]]
  top: seq[int]

proc indexBipartite[N](g: Graph[N], topNodes: HashSet[N],
    inferPartition: bool): IndexedBipartite[N] =
  var indices = initTable[N, int]()
  for node in g.nodes:
    indices[node] = result.nodes.len
    result.nodes.add(node)
  let n = result.nodes.len
  result.adjacency = newSeq[seq[int]](n)
  for i, node in result.nodes:
    for neighbor in g.adj[node].keys:
      result.adjacency[i].add(indices[neighbor])

  var color = newSeq[int](n)
  if inferPartition:
    for i in 0 ..< n:
      color[i] = -1
    var queue = newSeqOfCap[int](n)
    for start in 0 ..< n:
      if color[start] != -1:
        continue
      color[start] = 0
      queue.setLen(0)
      queue.add(start)
      var head = 0
      while head < queue.len:
        let u = queue[head]
        head.inc
        for v in result.adjacency[u]:
          if color[v] == -1:
            color[v] = 1 - color[u]
            queue.add(v)
          elif color[v] == color[u]:
            raise newException(NimNetError, "Graph is not bipartite")
  else:
    for i in 0 ..< n:
      color[i] = 1
    for node in topNodes:
      let i = indices.getOrDefault(node, -1)
      if i == -1:
        raise newException(NodeNotFound, "topNodes contains a node not in the graph")
      color[i] = 0
    for u, neighbors in result.adjacency:
      for v in neighbors:
        if color[u] == color[v]:
          raise newException(NimNetError,
            "topNodes and its complement must form a bipartition")
  for i in 0 ..< n:
    if color[i] == 0:
      result.top.add(i)

proc hopcroftKarp(adjacency: seq[seq[int]], top: seq[int]): seq[int] =
  let n = adjacency.len
  var mate = newSeq[int](n)
  var distance = newSeq[int](n)
  var cursor = newSeq[int](n)
  var queue = newSeqOfCap[int](top.len)
  var path = newSeqOfCap[int](top.len)
  for i in 0 ..< n:
    mate[i] = -1

  while true:
    queue.setLen(0)
    for u in top:
      cursor[u] = 0
      if mate[u] == -1:
        distance[u] = 0
        queue.add(u)
      else:
        distance[u] = -1
    var shortest = -1
    var head = 0
    while head < queue.len:
      let u = queue[head]
      head.inc
      if shortest != -1 and distance[u] >= shortest:
        continue
      for v in adjacency[u]:
        let next = mate[v]
        if next == -1:
          shortest = distance[u] + 1
        elif distance[next] == -1:
          distance[next] = distance[u] + 1
          queue.add(next)
    if shortest == -1:
      break

    for root in top:
      if mate[root] != -1 or distance[root] == -1:
        continue
      path.setLen(0)
      path.add(root)
      var augmented = false
      while path.len > 0 and not augmented:
        let u = path[^1]
        var descended = false
        while cursor[u] < adjacency[u].len:
          let v = adjacency[u][cursor[u]]
          cursor[u].inc
          let next = mate[v]
          if next == -1:
            if distance[u] + 1 != shortest:
              continue
            # The old mate of each child is its incoming right-hand vertex.
            # Unwind the explicit stack to update both directions together.
            var right = v
            for i in countdown(path.high, 0):
              let left = path[i]
              let oldRight = mate[left]
              mate[left] = right
              mate[right] = left
              right = oldRight
              distance[left] = -1
            augmented = true
            break
          elif distance[next] == distance[u] + 1:
            path.add(next)
            descended = true
            break
        if not descended and not augmented:
          distance[u] = -1
          discard path.pop()
  result = mate

proc matchingPairs[N](indexed: IndexedBipartite[N], mate: seq[int]): seq[(N, N)] =
  for u in indexed.top:
    if mate[u] != -1:
      result.add((indexed.nodes[u], indexed.nodes[mate[u]]))

proc vertexCover[N](indexed: IndexedBipartite[N], mate: seq[int]): HashSet[N] =
  result = initHashSet[N]()
  var reached = newSeq[bool](indexed.nodes.len)
  var queue = newSeqOfCap[int](indexed.top.len)
  for u in indexed.top:
    if mate[u] == -1:
      reached[u] = true
      queue.add(u)
  var head = 0
  while head < queue.len:
    let u = queue[head]
    head.inc
    for v in indexed.adjacency[u]:
      if mate[u] == v or reached[v]:
        continue
      reached[v] = true
      result.incl(indexed.nodes[v])
      let next = mate[v]
      if next != -1 and not reached[next]:
        reached[next] = true
        queue.add(next)
  # König's theorem: (top \ reached) union (bottom intersect reached).
  for u in indexed.top:
    if not reached[u]:
      result.incl(indexed.nodes[u])

proc maximumMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Return an exact maximum-cardinality bipartite matching using layered
  ## Hopcroft-Karp, with indexed data and iterative, stack-safe augmentation.
  ## Time is O((V + E) sqrt(V)); auxiliary space is O(V + E).
  ## Each matched edge occurs once, oriented from an inferred first partition.
  ## Disconnected components and isolates are supported; weights are ignored.
  ## Raises ``NimNetError`` for odd cycles or self-loops.
  let indexed = indexBipartite(g, initHashSet[N](), true)
  matchingPairs(indexed, hopcroftKarp(indexed.adjacency, indexed.top))

proc maximumMatching*[N](g: Graph[N], topNodes: HashSet[N]): seq[(N, N)] =
  ## Return an exact maximum-cardinality matching using the supplied partition.
  ## Each pair is (node in topNodes, node outside topNodes), occurring once.
  ## topNodes and its complement must cover the two sides of every edge;
  ## disconnected components may be oriented independently and isolates may
  ## be on either side. The partition is validated once, without inference.
  ## Raises ``NodeNotFound`` for unknown topNodes and ``NimNetError`` for
  ## intra-part edges (including self-loops). No node ordering is required.
  ## Uses stack-safe Hopcroft-Karp in O((V + E) sqrt(V)) time, O(V + E) space.
  let indexed = indexBipartite(g, topNodes, false)
  matchingPairs(indexed, hopcroftKarp(indexed.adjacency, indexed.top))

proc minimumVertexCover*[N](g: Graph[N]): HashSet[N] =
  ## Return an exact minimum vertex cover of a bipartite graph.
  ## By König's theorem its size equals the maximum matching cardinality.
  ## Infers and validates the partition once, reusing indexed Hopcroft-Karp
  ## data. Disconnected graphs and isolates are supported. Raises
  ## ``NimNetError`` for odd cycles or self-loops.
  ## Time is O((V + E) sqrt(V)); auxiliary space is O(V + E).
  let indexed = indexBipartite(g, initHashSet[N](), true)
  vertexCover(indexed, hopcroftKarp(indexed.adjacency, indexed.top))

proc minimumVertexCover*[N](g: Graph[N], topNodes: HashSet[N]): HashSet[N] =
  ## Return an exact minimum vertex cover using the supplied bipartition.
  ## Partition rules and exceptions are the same as for
  ## ``maximumMatching(g, topNodes)``. Validation occurs once, with no hidden
  ## inference. Isolates are never needed in the cover.
  ## Time is O((V + E) sqrt(V)); auxiliary space is O(V + E).
  let indexed = indexBipartite(g, topNodes, false)
  vertexCover(indexed, hopcroftKarp(indexed.adjacency, indexed.top))

# =============================================================================
# Extended Bipartite (#132)
# =============================================================================

proc bipartiteProjection*[N](g: Graph[N], nodes: HashSet[N]): Graph[N] =
  ## Project a bipartite graph onto one set of nodes.
  ## Two nodes in the projection are connected if they share a neighbor
  ## in the other partition.
  result = newGraph[N]()
  for n in nodes:
    result.addNode(n)
  let nodeSeq = nodes.toSeq()
  for i in 0 ..< nodeSeq.len:
    for j in i + 1 ..< nodeSeq.len:
      # Check if they share a neighbor
      for nbr in g.neighbors(nodeSeq[i]):
        if nbr notin nodes and g.hasEdge(nbr, nodeSeq[j]):
          if not result.hasEdge(nodeSeq[i], nodeSeq[j]):
            result.addEdge(nodeSeq[i], nodeSeq[j])
          break

proc bipartiteWeightedProjection*[N](g: Graph[N], nodes: HashSet[N]): Graph[N] =
  ## Project with weights equal to number of shared neighbors.
  result = newGraph[N]()
  for n in nodes:
    result.addNode(n)
  let nodeSeq = nodes.toSeq()
  for i in 0 ..< nodeSeq.len:
    for j in i + 1 ..< nodeSeq.len:
      var shared = 0
      for nbr in g.neighbors(nodeSeq[i]):
        if nbr notin nodes and g.hasEdge(nbr, nodeSeq[j]):
          shared.inc
      if shared > 0:
        result.addWeightedEdge(nodeSeq[i], nodeSeq[j], float(shared))

proc bipartiteClustering*[N](g: Graph[N]): Table[N, float] =
  ## Compute the bipartite clustering coefficient for each node.
  ## CC(v) = number of 4-cycles through v / (deg(v) * (deg(v)-1) / 2)
  result = initTable[N, float]()
  for v in g.nodes:
    let d = g.degree(v)
    if d < 2:
      result[v] = 0.0
      continue
    var fourCycles = 0
    let nbrs = block:
      var s: seq[N]
      for n in g.neighbors(v): s.add(n)
      s
    for i in 0 ..< nbrs.len:
      for j in i + 1 ..< nbrs.len:
        # Count common neighbors of nbrs[i] and nbrs[j] (excluding v)
        for n2 in g.neighbors(nbrs[i]):
          if n2 != v and g.hasEdge(n2, nbrs[j]):
            fourCycles.inc
    let pairs = d * (d - 1) div 2
    result[v] = if pairs > 0: float(fourCycles) / float(pairs) else: 0.0

proc bipartiteRedundancy*[N](g: Graph[N]): Table[N, float] =
  ## Compute the redundancy coefficient for each node.
  ## RC(v) = fraction of neighbor pairs that share more than one neighbor.
  result = initTable[N, float]()
  for v in g.nodes:
    let nbrs = block:
      var s: seq[N]
      for n in g.neighbors(v): s.add(n)
      s
    if nbrs.len < 2:
      result[v] = 0.0
      continue
    var redundant = 0
    for i in 0 ..< nbrs.len:
      for j in i + 1 ..< nbrs.len:
        var sharedCount = 0
        for n2 in g.neighbors(nbrs[i]):
          if n2 != v and g.hasEdge(n2, nbrs[j]):
            sharedCount.inc
        if sharedCount > 0:
          redundant.inc
    let pairs = nbrs.len * (nbrs.len - 1) div 2
    result[v] = if pairs > 0: float(redundant) / float(pairs) else: 0.0
