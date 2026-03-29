## Graph polynomials and non-randomness for nimnet

import std/[tables, sets, math, algorithm]
import ../types
import ../graph

# =============================================================================
# Chromatic Polynomial (#116)
# =============================================================================

proc chromaticPolynomial*[N](g: Graph[N], k: int): int =
  ## Evaluate the chromatic polynomial P(G, k) using deletion-contraction.
  ## Returns the number of proper k-colorings of g.
  ## Warning: exponential time, only practical for small graphs.
  let nEdges = g.numberOfEdges()
  let n = g.numberOfNodes()
  if n == 0: return 1
  if nEdges == 0:
    # Empty graph: k^n
    result = 1
    for _ in 0 ..< n:
      result *= k
    return
  # Pick an edge to delete/contract
  var eu, ev: N
  for (u, v) in g.edges:
    eu = u; ev = v
    break
  # Deletion: remove edge (eu, ev)
  var gDel = newGraph[N]()
  for node in g.nodes:
    gDel.addNode(node)
  for (u, v) in g.edges:
    if not (u == eu and v == ev) and not (u == ev and v == eu):
      gDel.addEdge(u, v)
  # Contraction: merge ev into eu
  var gCon = newGraph[N]()
  for node in g.nodes:
    if node != ev:
      gCon.addNode(node)
  for (u, v) in g.edges:
    var a = u
    var b = v
    if a == ev: a = eu
    if b == ev: b = eu
    if a != b and not gCon.hasEdge(a, b):
      gCon.addEdge(a, b)
  result = chromaticPolynomial(gDel, k) - chromaticPolynomial(gCon, k)

# =============================================================================
# Tutte Polynomial (#116)
# =============================================================================

proc tuttePolynomial*[N](g: Graph[N], x, y: float): float =
  ## Evaluate the Tutte polynomial T(G, x, y) using deletion-contraction.
  ## Warning: exponential time, only practical for small graphs.
  let n = g.numberOfNodes()
  let m = g.numberOfEdges()
  if n == 0: return 1.0
  if m == 0:
    # No edges: T = 1
    return 1.0
  # Check for loops (self-loops) or bridges
  # Pick an edge
  var eu, ev: N
  for (u, v) in g.edges:
    eu = u; ev = v
    break
  # Check if (eu, ev) is a bridge
  var gDel = newGraph[N]()
  for node in g.nodes:
    gDel.addNode(node)
  for (u, v) in g.edges:
    if not (u == eu and v == ev) and not (u == ev and v == eu):
      gDel.addEdge(u, v)
  # Check connectivity: is (eu, ev) a bridge?
  var visited = initHashSet[N]()
  var queue: seq[N] = @[eu]
  visited.incl(eu)
  var qi = 0
  while qi < queue.len:
    let curr = queue[qi]
    qi.inc
    for nbr in gDel.neighbors(curr):
      if nbr notin visited:
        visited.incl(nbr)
        queue.add(nbr)
  let isBridge = ev notin visited
  if isBridge:
    return x * tuttePolynomial(gDel, x, y)
  # Contraction
  var gCon = newGraph[N]()
  for node in g.nodes:
    if node != ev:
      gCon.addNode(node)
  for (u, v) in g.edges:
    var a = u
    var b = v
    if a == ev: a = eu
    if b == ev: b = eu
    if a != b and not gCon.hasEdge(a, b):
      gCon.addEdge(a, b)
  result = tuttePolynomial(gDel, x, y) + tuttePolynomial(gCon, x, y)

# =============================================================================
# Non-Randomness (#116)
# =============================================================================

proc nonRandomness*[N](g: Graph[N], k: int = 0): (float, float) =
  ## Compute the non-randomness of a graph.
  ## Returns (nr, scale) where nr is the non-randomness measure.
  ## Based on the ratio of triangles to expected triangles in random graph.
  let n = g.numberOfNodes()
  let m = g.numberOfEdges()
  if n <= 2 or m == 0:
    return (0.0, 0.0)
  # Count triangles
  var triCount = 0
  let nodes = g.nodeSeq()
  for i in 0 ..< nodes.len:
    for j in i + 1 ..< nodes.len:
      if g.hasEdge(nodes[i], nodes[j]):
        for k2 in j + 1 ..< nodes.len:
          if g.hasEdge(nodes[i], nodes[k2]) and g.hasEdge(nodes[j], nodes[k2]):
            triCount.inc
  let p = 2.0 * float(m) / float(n * (n - 1))
  let expectedTri = float(n * (n - 1) * (n - 2)) / 6.0 * p * p * p
  let nr = if expectedTri > 0.0: float(triCount) / expectedTri else: 0.0
  let scale = if n > 0: nr / float(n) else: 0.0
  result = (nr, scale)
