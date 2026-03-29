## Graph operators: union, complement, compose, etc.

import std/[tables]
import types
import graph
import digraph

# =============================================================================
# Union
# =============================================================================

proc union*[N](g1, g2: Graph[N]): Graph[N] =
  ## Return the union of g1 and g2 (nodes and edges combined).
  ## If both graphs have the same edge, attributes from g2 take precedence.
  result = g1.copy()
  for n in g2.nodes:
    result.addNode(n)
  for (u, v, attr) in g2.edgesWithAttr:
    result.addEdge(u, v, attr)

proc union*[N](g1, g2: DiGraph[N]): DiGraph[N] =
  result = g1.copy()
  for n in g2.nodes:
    result.addNode(n)
  for (u, v, attr) in g2.edgesWithAttr:
    result.addEdge(u, v, attr)

proc disjointUnion*(g1, g2: Graph[int]): Graph[int] =
  ## Return disjoint union — g2's nodes are relabeled to avoid conflict.
  result = g1.copy()
  let offset = g1.numberOfNodes()
  for n in g2.nodes:
    result.addNode(n + offset)
  for (u, v, attr) in g2.edgesWithAttr:
    result.addEdge(u + offset, v + offset, attr)

proc disjointUnion*(g1, g2: DiGraph[int]): DiGraph[int] =
  result = g1.copy()
  let offset = g1.numberOfNodes()
  for n in g2.nodes:
    result.addNode(n + offset)
  for (u, v, attr) in g2.edgesWithAttr:
    result.addEdge(u + offset, v + offset, attr)

# =============================================================================
# Compose
# =============================================================================

proc compose*[N](g1, g2: Graph[N]): Graph[N] =
  ## Compose two graphs: union of nodes, union of edges.
  ## Same as union for simple graphs.
  union(g1, g2)

# =============================================================================
# Complement
# =============================================================================

proc complement*[N](g: Graph[N]): Graph[N] =
  ## Return the complement graph — has edges where g doesn't, and vice versa.
  result = newGraph[N]()
  let nodes = g.nodeSeq()
  for n in nodes:
    result.addNode(n)
  for i in 0 ..< nodes.len:
    for j in i + 1 ..< nodes.len:
      if not g.hasEdge(nodes[i], nodes[j]):
        result.addEdge(nodes[i], nodes[j])

proc complement*[N](g: DiGraph[N]): DiGraph[N] =
  result = newDiGraph[N]()
  let nodes = g.nodeSeq()
  for n in nodes:
    result.addNode(n)
  for i in 0 ..< nodes.len:
    for j in 0 ..< nodes.len:
      if i != j and not g.hasEdge(nodes[i], nodes[j]):
        result.addEdge(nodes[i], nodes[j])

# =============================================================================
# Intersection
# =============================================================================

proc intersection*[N](g1, g2: Graph[N]): Graph[N] =
  ## Return a graph with nodes in both g1 and g2, and edges in both.
  result = newGraph[N]()
  for n in g1.nodes:
    if g2.hasNode(n):
      result.addNode(n)
  for (u, v) in g1.edges:
    if g2.hasEdge(u, v):
      result.addEdge(u, v)

proc intersection*[N](g1, g2: DiGraph[N]): DiGraph[N] =
  result = newDiGraph[N]()
  for n in g1.nodes:
    if g2.hasNode(n):
      result.addNode(n)
  for (u, v) in g1.edges:
    if g2.hasEdge(u, v):
      result.addEdge(u, v)

# =============================================================================
# Difference
# =============================================================================

proc difference*[N](g1, g2: Graph[N]): Graph[N] =
  ## Return edges in g1 but not in g2 (on shared nodes).
  result = newGraph[N]()
  for n in g1.nodes:
    result.addNode(n)
  for (u, v) in g1.edges:
    if not g2.hasEdge(u, v):
      result.addEdge(u, v)

# =============================================================================
# Relabel
# =============================================================================

proc relabelNodes*[N, M](g: Graph[N], mapping: Table[N, M]): Graph[M] =
  ## Return a new graph with nodes relabeled according to mapping.
  result = newGraph[M]()
  for n in g.nodes:
    let newLabel = if n in mapping: mapping[n] else: raise newException(NimNetError, "Missing mapping for node")
    result.addNode(newLabel)
  for (u, v, attr) in g.edgesWithAttr:
    result.addEdge(mapping[u], mapping[v], attr)

proc relabelNodes*[N, M](g: DiGraph[N], mapping: Table[N, M]): DiGraph[M] =
  result = newDiGraph[M]()
  for n in g.nodes:
    let newLabel = if n in mapping: mapping[n] else: raise newException(NimNetError, "Missing mapping for node")
    result.addNode(newLabel)
  for (u, v, attr) in g.edgesWithAttr:
    result.addEdge(mapping[u], mapping[v], attr)

# =============================================================================
# Convert between graph types
# =============================================================================

proc toDirected*[N](g: Graph[N]): DiGraph[N] =
  ## Convert undirected graph to directed (each edge becomes two directed edges).
  result = newDiGraph[N]()
  for n in g.nodes:
    result.addNode(n)
  for (u, v, attr) in g.edgesWithAttr:
    result.addEdge(u, v, attr)
    if u != v:
      result.addEdge(v, u, attr)

proc toUndirected*[N](g: DiGraph[N]): Graph[N] =
  ## Convert directed graph to undirected (merge reciprocal edges).
  result = newGraph[N]()
  for n in g.nodes:
    result.addNode(n)
  for (u, v, attr) in g.edgesWithAttr:
    if not result.hasEdge(u, v):
      result.addEdge(u, v, attr)
