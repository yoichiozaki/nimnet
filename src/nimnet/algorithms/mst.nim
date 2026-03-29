## Minimum spanning tree algorithms

import std/[tables, algorithm]
import ../types
import ../graph

type
  WeightedEdge[N] = tuple[weight: float, u: N, v: N]

# =============================================================================
# Kruskal's algorithm
# =============================================================================

proc kruskalMST*[N](g: Graph[N]): Graph[N] =
  ## Compute minimum spanning tree using Kruskal's algorithm.
  ## Uses "weight" edge attribute (default 1.0).
  result = newGraph[N]()
  for n in g.nodes:
    result.addNode(n)

  # Collect and sort edges by weight
  var edges: seq[WeightedEdge[N]]
  for (u, v, attr) in g.edgesWithAttr:
    edges.add((weight: attr.getWeight(), u: u, v: v))
  edges.sort(proc(a, b: WeightedEdge[N]): int = cmp(a.weight, b.weight))

  # Union-Find
  var parent = initTable[N, N]()
  var rank = initTable[N, int]()
  for n in g.nodes:
    parent[n] = n
    rank[n] = 0

  proc find(x: N): N =
    var current = x
    while parent[current] != current:
      parent[current] = parent[parent[current]]  # path compression
      current = parent[current]
    current

  proc union(x, y: N): bool =
    let px = find(x)
    let py = find(y)
    if px == py:
      return false
    if rank[px] < rank[py]:
      parent[px] = py
    elif rank[px] > rank[py]:
      parent[py] = px
    else:
      parent[py] = px
      rank[px].inc
    true

  for edge in edges:
    if union(edge.u, edge.v):
      result.addEdge(edge.u, edge.v, newEdgeAttr(edge.weight))

proc kruskalMSTWeight*[N](g: Graph[N]): float =
  ## Return the total weight of the minimum spanning tree.
  let mst = kruskalMST(g)
  for (_, _, attr) in mst.edgesWithAttr:
    result += attr.getWeight()

# =============================================================================
# Prim's algorithm
# =============================================================================

proc primMST*[N](g: Graph[N], start: N): Graph[N] =
  ## Compute minimum spanning tree using Prim's algorithm.
  ## Starts from the given node.
  if not g.hasNode(start):
    raise newException(NodeNotFound, "Start node not found")

  result = newGraph[N]()
  var inMST = initHashSet[N]()
  inMST.incl(start)
  result.addNode(start)

  while inMST.len < g.numberOfNodes():
    var bestWeight = Inf
    var bestU: N
    var bestV: N
    var found = false

    for u in inMST:
      for v in g.neighbors(u):
        if v notin inMST:
          let w = g.weight(u, v)
          if w < bestWeight:
            bestWeight = w
            bestU = u
            bestV = v
            found = true

    if not found:
      break  # disconnected graph

    inMST.incl(bestV)
    result.addEdge(bestU, bestV, newEdgeAttr(bestWeight))

  return result

proc primMST*[N](g: Graph[N]): Graph[N] =
  ## Compute minimum spanning tree using Prim's algorithm.
  ## Starts from an arbitrary node.
  if g.numberOfNodes() == 0:
    return newGraph[N]()
  var startNode: N
  for n in g.nodes:
    startNode = n
    break
  primMST(g, startNode)
