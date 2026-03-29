## Matching algorithms for graphs
##
## Maximum matching (Edmonds' blossom simplified as greedy),
## maximal matching, and matching validation.

import std/[tables, sets, algorithm]
import ../graph
import ../types

proc maximalMatching*[N](g: Graph[N]): seq[(N, N)] =
  ## Return a maximal matching — a set of edges where no two share
  ## a node, and no edge can be added without violating this.
  var matched = initHashSet[N]()
  for u in g.nodes:
    if u in matched:
      continue
    for v in g.neighbors(u):
      if v notin matched and v != u:
        result.add((u, v))
        matched.incl(u)
        matched.incl(v)
        break

proc isMatching*[N](g: Graph[N], matching: seq[(N, N)]): bool =
  ## Return true if the given edges form a valid matching
  ## (no two edges share a node).
  var used = initHashSet[N]()
  for (u, v) in matching:
    if not g.hasEdge(u, v):
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
  ## Return an approximate maximum weight matching using a greedy approach.
  ## Edges are sorted by weight (descending) and greedily added.
  type WeightedEdge = tuple[u, v: N, w: float]
  var edges: seq[WeightedEdge]
  var seen = initHashSet[string]()  # avoid duplicate edges
  for u in g.nodes:
    for v in g.neighbors(u):
      let key = if $u < $v: $u & "-" & $v else: $v & "-" & $u
      if key notin seen:
        seen.incl(key)
        var w = 1.0
        try:
          let attr = g.getEdgeAttr(u, v)
          w = attr.getWeight(1.0)
        except:
          discard
        edges.add((u: u, v: v, w: w))

  # Sort descending by weight
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
  ## Return an approximate minimum weight matching using a greedy approach.
  ## Edges are sorted by weight (ascending) and greedily added.
  type WeightedEdge = tuple[u, v: N, w: float]
  var edges: seq[WeightedEdge]
  var seen = initHashSet[string]()
  for u in g.nodes:
    for v in g.neighbors(u):
      let key = if $u < $v: $u & "-" & $v else: $v & "-" & $u
      if key notin seen:
        seen.incl(key)
        var w = 1.0
        try:
          let attr = g.getEdgeAttr(u, v)
          w = attr.getWeight(1.0)
        except:
          discard
        edges.add((u: u, v: v, w: w))

  # Sort ascending by weight
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

# =============================================================================
# Edge Cover (#109)
# =============================================================================

proc minEdgeCover*[N](g: Graph[N]): seq[(N, N)] =
  ## Return a minimum edge cover of the graph.
  ## Uses maximum matching + adds edges for unmatched nodes.
  ## Requires that every node has at least one edge.
  let matching = maximalMatching(g)
  var matched = initHashSet[N]()
  for (u, v) in matching:
    result.add((u, v))
    matched.incl(u)
    matched.incl(v)
  # Cover unmatched nodes with any incident edge
  for node in g.nodes:
    if node notin matched:
      for nbr in g.neighbors(node):
        result.add((node, nbr))
        matched.incl(node)
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
  ## Check if matching is maximal (no edge can be added).
  if not isMatching(g, matching):
    return false
  var matched = initHashSet[N]()
  for (u, v) in matching:
    matched.incl(u)
    matched.incl(v)
  for (u, v) in g.edges:
    if u notin matched and v notin matched:
      return false  # Can add this edge
  result = true
