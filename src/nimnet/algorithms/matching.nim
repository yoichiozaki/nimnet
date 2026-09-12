## Matching algorithms for graphs
##
## Exact maximum-cardinality matching (Edmonds' blossom algorithm),
## greedy weighted matching, minimum edge covers, and matching validation.

import std/[tables, sets, algorithm]
import ../graph
import ../types

proc maximalMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Return a maximal matching — a set of edges where no two share
  ## a node, and no edge can be added without violating this.
  ## Self-loops are ignored. This need not have maximum cardinality.
  var matched = initHashSet[N]()
  for u in g.nodes:
    if u in matched:
      continue
    for v in g.adj[u].keys:
      if v notin matched and v != u:
        result.add((u, v))
        matched.incl(u)
        matched.incl(v)
        break

proc blossomMatching(adjacency: seq[seq[int]]): seq[int] =
  let n = adjacency.len
  var mate = newSeq[int](n)
  var parent = newSeq[int](n)
  var base = newSeq[int](n)
  var queued = newSeq[bool](n)
  var blossom = newSeq[bool](n)
  var queue = newSeqOfCap[int](n)
  for i in 0 ..< n:
    mate[i] = -1

  proc commonBase(a, b: int): int =
    var onPath = newSeq[bool](n)
    var u = a
    while true:
      u = base[u]
      onPath[u] = true
      if mate[u] == -1:
        break
      u = parent[mate[u]]
    u = b
    while true:
      u = base[u]
      if onPath[u]:
        return u
      u = parent[mate[u]]

  proc markPath(start, blossomBase, firstChild: int) =
    var u = start
    var child = firstChild
    while base[u] != blossomBase:
      blossom[base[u]] = true
      blossom[base[mate[u]]] = true
      parent[u] = child
      child = mate[u]
      u = parent[mate[u]]

  proc findAugmentingPath(root: int): int =
    for i in 0 ..< n:
      parent[i] = -1
      base[i] = i
      queued[i] = false
    queue.setLen(0)
    queue.add(root)
    queued[root] = true
    var head = 0
    while head < queue.len:
      let u = queue[head]
      head.inc
      for v in adjacency[u]:
        if base[u] == base[v] or mate[u] == v:
          continue
        if v == root or (mate[v] != -1 and parent[mate[v]] != -1):
          let blossomBase = commonBase(u, v)
          for i in 0 ..< n:
            blossom[i] = false
          markPath(u, blossomBase, v)
          markPath(v, blossomBase, u)
          # Reparent both sides so augmentation also expands nested blossoms.
          for i in 0 ..< n:
            if blossom[base[i]]:
              base[i] = blossomBase
              if not queued[i]:
                queued[i] = true
                queue.add(i)
        elif parent[v] == -1:
          parent[v] = u
          if mate[v] == -1:
            return v
          let next = mate[v]
          queued[next] = true
          queue.add(next)
    return -1

  for root in 0 ..< n:
    if mate[root] != -1:
      continue
    var u = findAugmentingPath(root)
    while u != -1:
      let v = parent[u]
      let next = mate[v]
      mate[u] = v
      mate[v] = u
      u = next
  result = mate

proc maximumCardinalityMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Return an exact maximum-cardinality matching in an undirected graph.
  ## Uses Edmonds' blossom/augmenting-path algorithm, including odd cycles,
  ## in O(V^3) time and O(V + E) auxiliary space, without recursive search.
  ## Each matched edge occurs once; its orientation and result order are
  ## unspecified. Weights and self-loops are ignored. Empty graphs and
  ## isolates are supported. Node ordering or string conversion is not used.
  var nodes = newSeqOfCap[N](g.numberOfNodes())
  var indices = initTable[N, int]()
  for node in g.nodes:
    indices[node] = nodes.len
    nodes.add(node)
  var adjacency = newSeq[seq[int]](nodes.len)
  for i, node in nodes:
    for neighbor in g.adj[node].keys:
      let j = indices[neighbor]
      if i != j:
        adjacency[i].add(j)
  let mate = blossomMatching(adjacency)
  for i, j in mate:
    if i < j:
      result.add((nodes[i], nodes[j]))

proc isMatching*[N](g: Graph[N], matching: seq[(N, N)]): bool =
  ## Return true if the given edges form a valid matching
  ## (no self-loops, and no two edges share a node).
  var used = initHashSet[N]()
  for (u, v) in matching:
    if u == v or not g.hasEdge(u, v):
      return false
    if u in used or v in used:
      return false
    used.incl(u)
    used.incl(v)
  result = true

proc isPerfectMatching*[N](g: Graph[N], matching: seq[(N, N)]): bool =
  ## Return true if the matching is perfect — every node is matched.
  if not isMatching(g, matching):
    return false
  result = matching.len * 2 == g.numberOfNodes()

proc maxWeightMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Return a greedy maximal matching, taking descending-weight edges.
  ## For finite nonnegative weights, its weight is at least half the maximum
  ## possible matching weight. It is not an exact weighted or cardinality
  ## solver. Negative edges are still considered for compatibility, with no
  ## approximation guarantee. Self-loops are ignored.
  ## See also ``approxMaxWeightMatching`` for the explicitly approximate name.
  type WeightedEdge = tuple[u, v: N, w: float]
  var edges: seq[WeightedEdge]
  for u, v, attr in g.edgesWithAttr:
    if u != v:
      edges.add((u: u, v: v, w: attr.getWeight()))

  edges.sort(proc(a, b: WeightedEdge): int =
    if a.w > b.w: -1
    elif a.w < b.w: 1
    else: 0
  )

  var matched = initHashSet[N]()
  for e in edges:
    if e.u notin matched and e.v notin matched:
      result.add((e.u, e.v))
      matched.incl(e.u)
      matched.incl(e.v)

proc minWeightMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Return a greedy maximal matching, taking ascending-weight edges.
  ## This heuristic has no general weight-approximation guarantee and does
  ## not minimize weight among maximum-cardinality matchings (nor among all
  ## matchings). Negative edges are considered; self-loops are ignored.
  ## See also ``approxMinWeightMatching`` for the explicitly approximate name.
  type WeightedEdge = tuple[u, v: N, w: float]
  var edges: seq[WeightedEdge]
  for u, v, attr in g.edgesWithAttr:
    if u != v:
      edges.add((u: u, v: v, w: attr.getWeight()))

  edges.sort(proc(a, b: WeightedEdge): int =
    if a.w < b.w: -1
    elif a.w > b.w: 1
    else: 0
  )

  var matched = initHashSet[N]()
  for e in edges:
    if e.u notin matched and e.v notin matched:
      result.add((e.u, e.v))
      matched.incl(e.u)
      matched.incl(e.v)

proc approxMaxWeightMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Alias for ``maxWeightMatching``: descending-weight greedy maximal
  ## matching, a 1/2-approximation for finite nonnegative edge weights.
  ## Negative weights have no guarantee; self-loops are ignored.
  maxWeightMatching(g)

proc approxMinWeightMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Alias for ``minWeightMatching``: ascending-weight greedy maximal
  ## matching, with no general weight-approximation or optimality guarantee.
  ## Self-loops are ignored.
  minWeightMatching(g)

# =============================================================================
# Edge Cover (#109)
# =============================================================================

proc minEdgeCover*[N](g: Graph[N]): seq[(N, N)] =
  ## Return a minimum edge cover of the graph.
  ## Uses exact maximum-cardinality matching, then covers unmatched nodes.
  ## The cover has ``V - |maximum matching|`` edges and takes O(V^3) time.
  ## A self-loop may cover its node. Empty graphs have an empty cover.
  ## Raises ``NimNetUnfeasible`` if an isolated node has no incident edge.
  for node in g.nodes:
    if g.adj[node].len == 0:
      raise newException(NimNetUnfeasible,
        "An edge cover does not exist for a graph with isolated nodes")
  let matching = maximumCardinalityMatching(g)
  var matched = initHashSet[N]()
  for (u, v) in matching:
    result.add((u, v))
    matched.incl(u)
    matched.incl(v)
  for node in g.nodes:
    if node notin matched:
      for nbr in g.adj[node].keys:
        result.add((node, nbr))
        matched.incl(node)
        matched.incl(nbr)
        break

proc isEdgeCover*[N](g: Graph[N], cover: seq[(N, N)]): bool =
  ## Check if the given set of edges forms a valid edge cover.
  var covered = initHashSet[N]()
  for (u, v) in cover:
    if not g.hasEdge(u, v):
      return false
    covered.incl(u)
    covered.incl(v)
  for node in g.nodes:
    if node notin covered:
      return false
  result = true

# =============================================================================
# Additional Matching (#135)
# =============================================================================

proc isMaximalMatching*[N](g: Graph[N], matching: seq[(N, N)]): bool =
  ## Check if matching is maximal (no non-loop edge can be added).
  if not isMatching(g, matching):
    return false
  var matched = initHashSet[N]()
  for (u, v) in matching:
    matched.incl(u)
    matched.incl(v)
  for (u, v) in g.edges:
    if u != v and u notin matched and v notin matched:
      return false  # Can add this edge
  result = true
