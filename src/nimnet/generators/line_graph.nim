## Line graph generator
##
## The line graph L(G) of a graph G has a node for each edge in G,
## with two nodes in L(G) adjacent iff the corresponding edges in G
## share an endpoint.

import std/[tables, sets]
import ../graph

proc lineGraph*[N](g: Graph[N]): Graph[string] =
  ## Return the line graph of g.
  ## Each edge (u,v) in g becomes a node "u-v" in the line graph.
  ## Two such nodes are adjacent iff their edges share an endpoint.
  result = newGraph[string]()
  # Collect edges as canonical (sorted) string pairs
  type EdgeId = string
  var edgeNodes: seq[(N, N, EdgeId)]
  var seen = initHashSet[string]()
  for u in g.nodes:
    for v in g.neighbors(u):
      let key = if $u < $v: $u & "-" & $v else: $v & "-" & $u
      if key notin seen:
        seen.incl(key)
        edgeNodes.add((u, v, key))
        result.addNode(key)
  # Two edge-nodes are adjacent if they share an endpoint
  for i in 0 ..< edgeNodes.len:
    let (u1, v1, id1) = edgeNodes[i]
    for j in i + 1 ..< edgeNodes.len:
      let (u2, v2, id2) = edgeNodes[j]
      if u1 == u2 or u1 == v2 or v1 == u2 or v1 == v2:
        result.addEdge(id1, id2)

proc inverseLineGraph*[N](lg: Graph[N]): Graph[int] =
  ## Compute the inverse line graph (root graph) of lg.
  ## Uses a simplified clique-cover approach.
  ## Note: not all graphs have an inverse line graph.
  result = newGraph[int]()
  var nodeId = 0
  var edgeToNode: Table[N, seq[int]]
  for n in lg.nodes:
    # Each node in the line graph represents an edge in the original
    # Assign two endpoint nodes
    let u = nodeId
    inc nodeId
    let v = nodeId
    inc nodeId
    edgeToNode[n] = @[u, v]
    result.addNode(u)
    result.addNode(v)
    result.addEdge(u, v)
  # Merge nodes for adjacent edges in lg (they share an endpoint)
  # Simple heuristic: for each edge in lg, merge one endpoint pair
  for e1 in lg.nodes:
    for e2 in lg.neighbors(e1):
      if $e1 < $e2:
        # Merge one endpoint of e1 with one of e2
        let nodes1 = edgeToNode[e1]
        let nodes2 = edgeToNode[e2]
        # Connect them through shared endpoint
        if not result.hasEdge(nodes1[0], nodes2[0]):
          result.addEdge(nodes1[0], nodes2[0])
