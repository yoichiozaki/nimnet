## Minimum spanning tree algorithms

import std/[tables, sets, algorithm, sequtils, heapqueue]
import ../types
import ../graph

type
  WeightedEdge[N] = tuple[weight: float, u: N, v: N]
  PrimEntry[N] = object
    weight: float
    u: N
    v: N

func `<`*[N](a, b: PrimEntry[N]): bool = a.weight < b.weight

# =============================================================================
# Kruskal's algorithm
# =============================================================================

proc kruskalMST*[N](g: Graph[N]): Graph[N] =
  ## Compute minimum spanning tree using Kruskal's algorithm.
  ## Uses "weight" edge attribute (default 1.0).
  result = newGraph[N]()
  for n in g.adj.keys:
    result.addNode(n)

  # Collect and sort edges by weight (direct adj access avoids edgesWithAttr overhead)
  var edges = newSeqOfCap[WeightedEdge[N]](g.numberOfEdges())
  var seen = initHashSet[N](g.numberOfNodes() * 2)
  for u, neighbors in g.adj:
    for v, attr in neighbors:
      if v notin seen or u == v:
        edges.add((weight: attr.getWeight(), u: u, v: v))
    seen.incl(u)
  edges.sort(proc(a, b: WeightedEdge[N]): int = cmp(a.weight, b.weight))

  # Union-Find
  var parent = initTable[N, N]()
  var rank = initTable[N, int]()
  for n in g.adj.keys:
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
  var inMST = initHashSet[N](g.numberOfNodes())
  inMST.incl(start)
  result.addNode(start)

  var pq: HeapQueue[PrimEntry[N]]
  for v, attr in g.adj[start]:
    pq.push(PrimEntry[N](weight: attr.getWeight(), u: start, v: v))

  while pq.len > 0 and inMST.len < g.numberOfNodes():
    let entry = pq.pop()
    if entry.v in inMST:
      continue
    inMST.incl(entry.v)
    result.addEdge(entry.u, entry.v, newEdgeAttr(entry.weight))
    for w, attr in g.adj[entry.v]:
      if w notin inMST:
        pq.push(PrimEntry[N](weight: attr.getWeight(), u: entry.v, v: w))

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
