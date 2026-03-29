## Graph minors: edge/node contraction and quotient graphs.
##
## A **graph minor** is obtained by contracting edges or nodes.
## - ``contractedEdge(g, u, v)`` — contract an edge, merging endpoints
## - ``contractedNodes(g, u, v)`` — merge two nodes
## - ``quotientGraph(g, partition)`` — collapse each partition block into a node

import std/[tables, sets]
import ../types
import ../graph
import ../digraph

# =============================================================================
# Node contraction for undirected graphs
# =============================================================================

proc contractedNodes*[N](g: Graph[N], u, v: N, selfLoops = false): Graph[N] =
  ## Return a new graph with nodes u and v merged into u.
  ## All edges incident to v are redirected to u.
  ## Self-loops are excluded unless ``selfLoops`` is true.
  if not g.hasNode(u):
    raise newException(NodeNotFound, "Node u not found")
  if not g.hasNode(v):
    raise newException(NodeNotFound, "Node v not found")

  result = newGraph[N]()

  # Add all nodes except v
  for n in g.nodes:
    if n != v:
      result.addNode(n)
      let attr = g.getNodeAttr(n)
      if attr.len > 0:
        result.setNodeAttr(n, attr)

  # Add all edges, remapping v to u
  for (a, b) in g.edges:
    var na = a
    var nb = b
    if na == v: na = u
    if nb == v: nb = u
    if na == nb:
      if selfLoops:
        if not result.hasEdge(na, nb):
          result.addEdge(na, nb, g.getEdgeAttr(a, b))
      continue
    if not result.hasEdge(na, nb):
      result.addEdge(na, nb, g.getEdgeAttr(a, b))

proc contractedEdge*[N](g: Graph[N], u, v: N, selfLoops = false): Graph[N] =
  ## Return a new graph with the edge (u, v) contracted.
  ## Equivalent to ``contractedNodes(g, u, v)``, but raises
  ## ``EdgeNotFound`` if the edge doesn't exist.
  if not g.hasEdge(u, v):
    raise newException(EdgeNotFound, "Edge not found")
  contractedNodes(g, u, v, selfLoops)

proc quotientGraph*[N](g: Graph[N], partition: seq[HashSet[N]]): Graph[int] =
  ## Return the quotient graph where each partition block is collapsed
  ## into a single node (labeled by block index 0..k-1).
  ## An edge exists between blocks i and j if any node in block i
  ## is adjacent to any node in block j in the original graph.
  var nodeToBlock = initTable[N, int]()
  for i, blk in partition:
    for n in blk:
      nodeToBlock[n] = i

  result = newGraph[int]()
  for i in 0 ..< partition.len:
    result.addNode(i)

  for (u, v) in g.edges:
    if u in nodeToBlock and v in nodeToBlock:
      let bi = nodeToBlock[u]
      let bj = nodeToBlock[v]
      if bi != bj and not result.hasEdge(bi, bj):
        result.addEdge(bi, bj)

# =============================================================================
# Node contraction for directed graphs
# =============================================================================

proc contractedNodes*[N](dg: DiGraph[N], u, v: N, selfLoops = false): DiGraph[N] =
  ## Return a new digraph with nodes u and v merged into u.
  if not dg.hasNode(u):
    raise newException(NodeNotFound, "Node u not found")
  if not dg.hasNode(v):
    raise newException(NodeNotFound, "Node v not found")

  result = newDiGraph[N]()

  for n in dg.nodes:
    if n != v:
      result.addNode(n)
      let attr = dg.getNodeAttr(n)
      if attr.len > 0:
        result.setNodeAttr(n, attr)

  for (a, b) in dg.edges:
    var na = a
    var nb = b
    if na == v: na = u
    if nb == v: nb = u
    if na == nb:
      if selfLoops:
        if not result.hasEdge(na, nb):
          result.addEdge(na, nb, dg.getEdgeAttr(a, b))
      continue
    if not result.hasEdge(na, nb):
      result.addEdge(na, nb, dg.getEdgeAttr(a, b))

proc contractedEdge*[N](dg: DiGraph[N], u, v: N, selfLoops = false): DiGraph[N] =
  ## Return a new digraph with the edge (u, v) contracted.
  if not dg.hasEdge(u, v):
    raise newException(EdgeNotFound, "Edge not found")
  contractedNodes(dg, u, v, selfLoops)

proc quotientGraph*[N](dg: DiGraph[N], partition: seq[HashSet[N]]): DiGraph[int] =
  ## Return the quotient digraph where each partition block is collapsed
  ## into a single node (labeled by block index).
  var nodeToBlock = initTable[N, int]()
  for i, blk in partition:
    for n in blk:
      nodeToBlock[n] = i

  result = newDiGraph[int]()
  for i in 0 ..< partition.len:
    result.addNode(i)

  for (u, v) in dg.edges:
    if u in nodeToBlock and v in nodeToBlock:
      let bi = nodeToBlock[u]
      let bj = nodeToBlock[v]
      if bi != bj and not result.hasEdge(bi, bj):
        result.addEdge(bi, bj)
