## Graph operators: union, complement, compose, etc.

import std/[tables, sets, deques]
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
  ## Return the union of two directed graphs.
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
  ## Return disjoint union of directed graphs — g2's nodes are relabeled.
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
  ## Return the complement of a directed graph.
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
  ## Return a directed graph with nodes and edges common to both.
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
  ## Return a new directed graph with nodes relabeled according to mapping.
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

# =============================================================================
# Additional Operators (#111)
# =============================================================================

proc symmetricDifference*[N](g1, g2: Graph[N]): Graph[N] =
  ## Return a graph with edges in exactly one of g1 or g2.
  result = newGraph[N]()
  for n in g1.nodes:
    result.addNode(n)
  for n in g2.nodes:
    result.addNode(n)
  for (u, v) in g1.edges:
    if not g2.hasEdge(u, v):
      result.addEdge(u, v)
  for (u, v) in g2.edges:
    if not g1.hasEdge(u, v):
      result.addEdge(u, v)

proc fullJoin*[N](g1, g2: Graph[N]): Graph[N] =
  ## Return the full join (complete join) of g1 and g2.
  ## Contains all edges from both graphs, plus edges between all nodes
  ## of g1 and all nodes of g2.
  result = newGraph[N]()
  for n in g1.nodes:
    result.addNode(n)
  for n in g2.nodes:
    result.addNode(n)
  for (u, v) in g1.edges:
    result.addEdge(u, v)
  for (u, v) in g2.edges:
    result.addEdge(u, v)
  for n1 in g1.nodes:
    for n2 in g2.nodes:
      if not result.hasEdge(n1, n2):
        result.addEdge(n1, n2)

proc power*[N](g: Graph[N], k: int): Graph[N] =
  ## Return the k-th power of graph g.
  ## G^k has an edge between u and v if the shortest path distance <= k.
  result = newGraph[N]()
  for n in g.nodes:
    result.addNode(n)
  for source in g.nodes:
    # BFS from source
    var dist = initTable[N, int]()
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let u = queue.popFirst()
      if dist[u] >= k: continue
      for v in g.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          queue.addLast(v)
    for target, d in dist:
      if target != source and d <= k:
        if not result.hasEdge(source, target):
          result.addEdge(source, target)

proc coronaProduct*[N](g1, g2: Graph[N]): Graph[string] =
  ## Compute the corona product G1 ∘ G2.
  ## For each node u in G1, attach a copy of G2 and connect u to all nodes in that copy.
  result = newGraph[string]()
  # Add G1 nodes
  for n in g1.nodes:
    result.addNode("1:" & $n)
  for (u, v) in g1.edges:
    result.addEdge("1:" & $u, "1:" & $v)
  # For each node in G1, create a copy of G2
  var idx = 0
  for u in g1.nodes:
    let prefix = "2_" & $idx & ":"
    for n in g2.nodes:
      result.addNode(prefix & $n)
    for (a, b) in g2.edges:
      result.addEdge(prefix & $a, prefix & $b)
    # Connect u to all nodes in its copy
    for n in g2.nodes:
      result.addEdge("1:" & $u, prefix & $n)
    idx.inc

proc rootedProduct*[N](g1, g2: Graph[N], root: N): Graph[string] =
  ## Compute the rooted product of G1 and G2 with specified root in G2.
  result = newGraph[string]()
  # For each node u in G1, make a copy of G2
  var idx = 0
  for u in g1.nodes:
    let prefix = $idx & ":"
    for n in g2.nodes:
      result.addNode(prefix & $n)
    for (a, b) in g2.edges:
      result.addEdge(prefix & $a, prefix & $b)
    idx.inc
  # Add G1 edges: connect root nodes of respective copies
  idx = 0
  var rootMap = initTable[string, string]()
  var i = 0
  for u in g1.nodes:
    rootMap["1:" & $u] = $i & ":" & $root
    i.inc
  i = 0
  for u in g1.nodes:
    for v in g1.neighbors(u):
      let uRoot = $i & ":" & $root
      var j = 0
      for w in g1.nodes:
        if w == v:
          let vRoot = $j & ":" & $root
          if not result.hasEdge(uRoot, vRoot):
            result.addEdge(uRoot, vRoot)
          break
        j.inc
    i.inc

proc modularProduct*[N](g1, g2: Graph[N]): Graph[string] =
  ## Compute the modular product of G1 and G2.
  ## Nodes are (u1, u2) for u1 in G1, u2 in G2.
  ## Edge between (u1,u2) and (v1,v2) if:
  ##   - u1 adj v1 in G1 AND u2 adj v2 in G2, or
  ##   - u1 NOT adj v1 in G1 AND u2 NOT adj v2 in G2
  result = newGraph[string]()
  var nodes1: seq[N]
  var nodes2: seq[N]
  for n in g1.nodes: nodes1.add(n)
  for n in g2.nodes: nodes2.add(n)
  for u1 in nodes1:
    for u2 in nodes2:
      result.addNode($u1 & "," & $u2)
  for i1 in 0 ..< nodes1.len:
    for i2 in 0 ..< nodes2.len:
      for j1 in (i1 + 1) ..< nodes1.len:
        for j2 in 0 ..< nodes2.len:
          if i1 == j1 and i2 == j2: continue
          let u1 = nodes1[i1]
          let u2 = nodes2[i2]
          let v1 = nodes1[j1]
          let v2 = nodes2[j2]
          if u2 == v2: continue
          let adj1 = g1.hasEdge(u1, v1)
          let adj2 = g2.hasEdge(u2, v2)
          if (adj1 and adj2) or (not adj1 and not adj2):
            let a = $u1 & "," & $u2
            let b = $v1 & "," & $v2
            if not result.hasEdge(a, b):
              result.addEdge(a, b)
