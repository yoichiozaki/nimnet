## Chordal graph algorithms for nimnet

import std/[tables, sets, deques, algorithm, sequtils]
import ../types
import ../graph

# =============================================================================
# Perfect Elimination Ordering (Lex-BFS)
# =============================================================================

proc perfectEliminationOrder*[N](g: Graph[N]): seq[N] =
  ## Compute a perfect elimination ordering using Lex-BFS.
  ## Returns empty seq if graph is not chordal.
  let n = g.numberOfNodes()
  if n == 0: return @[]
  # Use integer labels; higher = processed later = higher priority
  var label = initTable[N, int]()
  for node in g.nodes:
    label[node] = 0
  var order = newSeq[N]()
  var used = initHashSet[N]()
  for i in countdown(n - 1, 0):
    # Pick unnumbered vertex with largest label
    var best: N
    var bestLabel = -1
    var found = false
    for node in g.nodes:
      if node notin used:
        if not found or label[node] > bestLabel:
          best = node
          bestLabel = label[node]
          found = true
    if not found: break
    order.add(best)
    used.incl(best)
    for nbr in g.neighbors(best):
      if nbr notin used:
        label[nbr] += n - i  # Increase priority
  algorithm.reverse(order)
  result = order

# =============================================================================
# Is Chordal
# =============================================================================

proc isChordal*[N](g: Graph[N]): bool =
  ## Check if a graph is chordal using perfect elimination ordering.
  ## A graph is chordal if it has a perfect elimination ordering.
  let n = g.numberOfNodes()
  if n <= 3: return true
  let order = perfectEliminationOrder(g)
  if order.len != n: return false
  # Verify: for each node in reverse order, its later neighbors form a clique
  var pos = initTable[N, int]()
  for i, node in order:
    pos[node] = i
  for i in 0 ..< n:
    let v = order[i]
    var laterNeighbors = newSeq[N]()
    for nbr in g.neighbors(v):
      if pos[nbr] > i:
        laterNeighbors.add(nbr)
    # Check these form a clique
    for j in 0 ..< laterNeighbors.len:
      for k in j + 1 ..< laterNeighbors.len:
        if not g.hasEdge(laterNeighbors[j], laterNeighbors[k]):
          return false
  result = true

# =============================================================================
# Chordal Graph Cliques
# =============================================================================

proc chordalGraphCliques*[N](g: Graph[N]): seq[HashSet[N]] =
  ## Return the maximal cliques of a chordal graph.
  ## Uses the perfect elimination ordering.
  let order = perfectEliminationOrder(g)
  let n = order.len
  if n == 0: return @[]
  var pos = initTable[N, int]()
  for i, node in order:
    pos[node] = i
  var cliques = newSeq[HashSet[N]]()
  for i in 0 ..< n:
    let v = order[i]
    var clique = initHashSet[N]()
    clique.incl(v)
    for nbr in g.neighbors(v):
      if pos[nbr] > i:
        clique.incl(nbr)
    # Check if this is maximal (not subset of any existing)
    var isMaximal = true
    for existing in cliques:
      if clique <= existing:
        isMaximal = false
        break
    if isMaximal:
      cliques.add(clique)
  result = cliques

# =============================================================================
# Complete to Chordal (Minimum Fill-In)
# =============================================================================

proc completeToChordal*[N](g: Graph[N]): (Graph[N], seq[(N, N)]) =
  ## Return a chordal completion of the graph and the added fill edges.
  ## Uses a greedy approach (not guaranteed minimum).
  var h = newGraph[N]()
  for n in g.nodes:
    h.addNode(n)
  for (u, v) in g.edges:
    h.addEdge(u, v)
  var fillEdges = newSeq[(N, N)]()
  let order = perfectEliminationOrder(h)
  var pos = initTable[N, int]()
  for i, node in order:
    pos[node] = i
  for i in 0 ..< order.len:
    let v = order[i]
    var laterNeighbors = newSeq[N]()
    for nbr in h.neighbors(v):
      if pos[nbr] > i:
        laterNeighbors.add(nbr)
    for j in 0 ..< laterNeighbors.len:
      for k in j + 1 ..< laterNeighbors.len:
        if not h.hasEdge(laterNeighbors[j], laterNeighbors[k]):
          h.addEdge(laterNeighbors[j], laterNeighbors[k])
          fillEdges.add((laterNeighbors[j], laterNeighbors[k]))
  result = (h, fillEdges)
