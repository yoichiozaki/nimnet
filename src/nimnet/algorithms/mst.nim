## Minimum spanning tree algorithms

import std/[tables, sets, algorithm, heapqueue]
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
  ## Uses array-based Union-Find for fast find/union operations.
  result = newGraph[N]()
  let n = g.numberOfNodes()
  if n == 0: return

  # Build node index mapping for array-based Union-Find
  var nodeList = newSeqOfCap[N](n)
  var nodeIdx = initTable[N, int](n)
  var idx = 0
  for node in g.adj.keys:
    nodeList.add(node)
    nodeIdx[node] = idx
    result.addNode(node)
    idx.inc

  # Collect and sort edges — use seq[bool] for dedup (faster than HashSet)
  var edges = newSeqOfCap[(float, int, int)](g.numberOfEdges())
  var seen = newSeq[bool](n)
  for u, neighbors in g.adj:
    let ui = nodeIdx[u]
    for v, attr in neighbors:
      let vi = nodeIdx[v]
      if not seen[vi] or ui == vi:
        edges.add((attr.weight, ui, vi))
    seen[ui] = true
  edges.sort()

  # Array-based Union-Find with path compression and union by rank
  var parent = newSeq[int](n)
  var ufRank = newSeq[int](n)
  for i in 0 ..< n:
    parent[i] = i

  proc find(x: int): int =
    var current = x
    while parent[current] != current:
      parent[current] = parent[parent[current]]  # path halving
      current = parent[current]
    current

  for (w, ui, vi) in edges:
    let pu = find(ui)
    let pv = find(vi)
    if pu != pv:
      if ufRank[pu] < ufRank[pv]:
        parent[pu] = pv
      elif ufRank[pu] > ufRank[pv]:
        parent[pv] = pu
      else:
        parent[pv] = pu
        ufRank[pu].inc
      result.addEdge(nodeList[ui], nodeList[vi], newEdgeAttr(w))

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

# =============================================================================
# Maximum spanning tree (negate weights and use Kruskal)
# =============================================================================

proc maximumSpanningTree*[N](g: Graph[N]): Graph[N] =
  ## Compute maximum spanning tree by negating weights and using Kruskal.
  var negG = newGraph[N]()
  for n in g.nodes:
    negG.addNode(n)
  for (u, v) in g.edges:
    let attr = g[u, v]
    negG.addWeightedEdge(u, v, -attr.weight)
  let negMst = kruskalMST(negG)
  result = newGraph[N]()
  for n in negMst.nodes:
    result.addNode(n)
  for (u, v) in negMst.edges:
    let origAttr = g[u, v]
    result.addEdge(u, v, origAttr)

# =============================================================================
# Borůvka's MST algorithm
# =============================================================================

proc boruvkaMST*[N](g: Graph[N]): Graph[N] =
  ## Compute minimum spanning tree using Borůvka's algorithm.
  ## O(E log V) time.
  result = newGraph[N]()
  let n = g.numberOfNodes()
  if n == 0: return

  var nodeList = newSeqOfCap[N](n)
  var nodeIdx = initTable[N, int](n)
  var idx = 0
  for node in g.nodes:
    nodeList.add(node)
    nodeIdx[node] = idx
    result.addNode(node)
    idx.inc

  # Union-Find
  var parent = newSeq[int](n)
  var ufRank = newSeq[int](n)
  for i in 0 ..< n:
    parent[i] = i

  proc find(x: int): int =
    var current = x
    while parent[current] != current:
      parent[current] = parent[parent[current]]
      current = parent[current]
    current

  proc union(a, b: int) =
    let pa = find(a)
    let pb = find(b)
    if pa == pb: return
    if ufRank[pa] < ufRank[pb]:
      parent[pa] = pb
    elif ufRank[pa] > ufRank[pb]:
      parent[pb] = pa
    else:
      parent[pb] = pa
      ufRank[pa].inc

  var numComponents = n
  while numComponents > 1:
    # Find cheapest edge for each component
    var cheapest = newSeq[int](n)  # index into edges list
    var cheapWeight = newSeq[float](n)
    var cheapU = newSeq[int](n)
    var cheapV = newSeq[int](n)
    for i in 0 ..< n:
      cheapWeight[i] = Inf

    for (u, v) in g.edges:
      let ui = nodeIdx[u]
      let vi = nodeIdx[v]
      let pu = find(ui)
      let pv = find(vi)
      if pu == pv: continue
      let w = g[u, v].weight
      if w < cheapWeight[pu]:
        cheapWeight[pu] = w
        cheapU[pu] = ui
        cheapV[pu] = vi
      if w < cheapWeight[pv]:
        cheapWeight[pv] = w
        cheapU[pv] = ui
        cheapV[pv] = vi

    var merged = false
    for i in 0 ..< n:
      if cheapWeight[i] < Inf and find(i) == i:
        let ui = cheapU[i]
        let vi = cheapV[i]
        if find(ui) != find(vi):
          union(ui, vi)
          result.addEdge(nodeList[ui], nodeList[vi],
                        newEdgeAttr(cheapWeight[i]))
          numComponents.dec
          merged = true
    if not merged:
      break  # Graph is disconnected

proc maximumSpanningTreeWeight*[N](g: Graph[N]): float =
  ## Return the total weight of the maximum spanning tree.
  let mst = maximumSpanningTree(g)
  result = 0.0
  for (u, v) in mst.edges:
    result += mst[u, v].weight
