## Graph isomorphism using VF2 algorithm
##
## Tests whether two graphs are isomorphic (structurally identical).

import std/[tables, sets, algorithm]
import ../graph

proc isIsomorphic*[N, M](g1: Graph[N], g2: Graph[M]): bool =
  ## Test whether two graphs are isomorphic using VF2 algorithm.
  ## Returns true if g1 and g2 are structurally identical.
  if g1.numberOfNodes() != g2.numberOfNodes():
    return false
  if g1.numberOfEdges() != g2.numberOfEdges():
    return false

  let nodes1 = g1.nodeSeq()
  let nodes2 = g2.nodeSeq()
  let n = nodes1.len

  if n == 0:
    return true

  # Check degree sequence
  var degs1: seq[int] = @[]
  var degs2: seq[int] = @[]
  for node in nodes1:
    degs1.add(g1.degree(node))
  for node in nodes2:
    degs2.add(g2.degree(node))
  degs1.sort()
  degs2.sort()
  if degs1 != degs2:
    return false

  # VF2 state
  var mapping: Table[N, M] = initTable[N, M]()  # g1 node -> g2 node
  var reverseMapping: Table[M, N] = initTable[M, N]()  # g2 node -> g1 node

  proc isFeasible(n1: N, n2: M): bool =
    # Check degree compatibility
    if g1.degree(n1) != g2.degree(n2):
      return false

    # Check consistency: all mapped neighbors of n1 must map to neighbors of n2
    for neighbor1 in g1.neighbors(n1):
      if neighbor1 in mapping:
        let mapped = mapping[neighbor1]
        if not g2.hasEdge(n2, mapped):
          return false

    for neighbor2 in g2.neighbors(n2):
      if neighbor2 in reverseMapping:
        let mapped = reverseMapping[neighbor2]
        if not g1.hasEdge(n1, mapped):
          return false

    # Look-ahead: count unmapped neighbors
    var unmapped1 = 0
    var mapped1 = 0
    for neighbor in g1.neighbors(n1):
      if neighbor in mapping:
        mapped1.inc
      else:
        unmapped1.inc

    var unmapped2 = 0
    var mapped2 = 0
    for neighbor in g2.neighbors(n2):
      if neighbor in reverseMapping:
        mapped2.inc
      else:
        unmapped2.inc

    if mapped1 != mapped2:
      return false
    # Lookahead rule: terminal set sizes must be compatible
    return true

  proc vf2Match(): bool =
    if mapping.len == n:
      return true

    # Get next unmapped node from g1
    var node1: N
    var found = false
    for v in nodes1:
      if v notin mapping:
        node1 = v
        found = true
        break

    if not found:
      return true

    # Try to map it to each unmapped node in g2
    for node2 in nodes2:
      if node2 notin reverseMapping:
        if isFeasible(node1, node2):
          mapping[node1] = node2
          reverseMapping[node2] = node1
          if vf2Match():
            return true
          mapping.del(node1)
          reverseMapping.del(node2)

    return false

  result = vf2Match()

proc graphIsomorphismMapping*[N, M](g1: Graph[N], g2: Graph[M]): Table[N, M] =
  ## Find an isomorphism mapping from g1 to g2.
  ## Returns empty table if graphs are not isomorphic.
  if g1.numberOfNodes() != g2.numberOfNodes():
    return initTable[N, M]()
  if g1.numberOfEdges() != g2.numberOfEdges():
    return initTable[N, M]()

  let nodes1 = g1.nodeSeq()
  let nodes2 = g2.nodeSeq()
  let n = nodes1.len

  if n == 0:
    return initTable[N, M]()

  var mapping = initTable[N, M]()
  var reverseMapping = initTable[M, N]()

  proc isFeasible(n1: N, n2: M): bool =
    if g1.degree(n1) != g2.degree(n2):
      return false
    for neighbor1 in g1.neighbors(n1):
      if neighbor1 in mapping:
        if not g2.hasEdge(n2, mapping[neighbor1]):
          return false
    for neighbor2 in g2.neighbors(n2):
      if neighbor2 in reverseMapping:
        if not g1.hasEdge(n1, reverseMapping[neighbor2]):
          return false
    return true

  proc vf2Match(): bool =
    if mapping.len == n:
      return true
    var node1: N
    for v in nodes1:
      if v notin mapping:
        node1 = v
        break
    for node2 in nodes2:
      if node2 notin reverseMapping:
        if isFeasible(node1, node2):
          mapping[node1] = node2
          reverseMapping[node2] = node1
          if vf2Match():
            return true
          mapping.del(node1)
          reverseMapping.del(node2)
    return false

  if vf2Match():
    result = mapping
  else:
    result = initTable[N, M]()

proc couldBeIsomorphic*[N, M](g1: Graph[N], g2: Graph[M]): bool =
  ## Quick check: could these graphs be isomorphic?
  ## Checks node count, edge count, and degree sequence.
  ## Faster than full isomorphism test but may give false positives.
  if g1.numberOfNodes() != g2.numberOfNodes():
    return false
  if g1.numberOfEdges() != g2.numberOfEdges():
    return false
  var degs1: seq[int] = @[]
  var degs2: seq[int] = @[]
  for node in g1.nodes:
    degs1.add(g1.degree(node))
  for node in g2.nodes:
    degs2.add(g2.degree(node))
  degs1.sort()
  degs2.sort()
  return degs1 == degs2
