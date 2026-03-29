## Degree sequence generators.
##
## Generate graphs with a specified degree sequence.
##
## - ``configurationModel`` — random graph from given degree sequence
## - ``havelHakimiGraph`` — deterministic realization
## - ``expectedDegreeGraph`` — Chung-Lu model
## - ``degreeSequenceTree`` — tree with given degree sequence
## - ``isGraphical`` — Erdős–Gallai test for realizability

import std/[algorithm, random]
import ../types, ../graph

func isGraphical*(degSequence: openArray[int]): bool =
  ## Test whether the integer sequence is graphical (can be realized as a
  ## simple undirected graph) using the Erdős–Gallai theorem.
  if degSequence.len == 0:
    return true

  var ds = @degSequence
  ds.sort(order = SortOrder.Descending)

  let n = ds.len
  var total = 0
  for d in ds:
    if d < 0:
      return false
    total += d
  if total mod 2 != 0:
    return false

  # Erdős–Gallai: for each k = 1..n,
  # sum(ds[0..k-1]) <= k*(k-1) + sum_{j=k}^{n-1} min(ds[j], k)
  var leftSum = 0
  for k in 1 .. n:
    leftSum += ds[k - 1]
    var rightSum = k * (k - 1)
    for j in k ..< n:
      rightSum += min(ds[j], k)
    if leftSum > rightSum:
      return false

  return true

proc havelHakimiGraph*(degSequence: openArray[int]): Graph[int] =
  ## Create a simple graph using the Havel-Hakimi algorithm.
  ## The degree sequence must be graphical.
  ##
  ## **Raises:** ``NimNetError`` if the sequence is not graphical.
  if not isGraphical(degSequence):
    raise newException(NimNetError, "Degree sequence is not graphical")

  var g = newGraph[int]()
  let n = degSequence.len
  if n == 0:
    return g

  for i in 0 ..< n:
    g.addNode(i)

  # (degree, nodeIndex) pairs, sorted descending by degree
  var stubs: seq[(int, int)]
  for i, d in degSequence:
    stubs.add((d, i))

  while true:
    stubs.sort(proc(a, b: (int, int)): int =
      cmp(b[0], a[0])  # descending by degree
    )

    # Remove nodes with degree 0
    while stubs.len > 0 and stubs[^1][0] == 0:
      stubs.setLen(stubs.len - 1)

    if stubs.len == 0:
      break

    let (d, node) = stubs[0]
    stubs.delete(0)

    if d > stubs.len:
      raise newException(NimNetError, "Havel-Hakimi algorithm failed")

    for i in 0 ..< d:
      g.addEdge(node, stubs[i][1])
      stubs[i] = (stubs[i][0] - 1, stubs[i][1])

  result = g

proc configurationModel*(degSequence: openArray[int],
                          seed: int64 = 0): Graph[int] =
  ## Create a random pseudograph using the configuration model.
  ## May produce parallel edges and self-loops. For simple graphs,
  ## reject and retry.
  ##
  ## **Raises:** ``NimNetError`` if sum of degrees is odd.
  var total = 0
  for d in degSequence:
    total += d
  if total mod 2 != 0:
    raise newException(NimNetError, "Sum of degrees must be even")

  var rng = if seed != 0: initRand(seed) else: initRand()
  var g = newGraph[int]()
  let n = degSequence.len

  for i in 0 ..< n:
    g.addNode(i)

  # Create stub list: each node i appears degSequence[i] times
  var stubs: seq[int]
  for i in 0 ..< n:
    for j in 0 ..< degSequence[i]:
      stubs.add(i)

  rng.shuffle(stubs)

  # Pair up consecutive stubs
  var i = 0
  while i + 1 < stubs.len:
    let u = stubs[i]
    let v = stubs[i + 1]
    if u != v:  # skip self-loops
      if not g.hasEdge(u, v):  # skip parallel edges
        g.addEdge(u, v)
    i += 2

  result = g

proc expectedDegreeGraph*(weights: openArray[float],
                           seed: int64 = 0): Graph[int] =
  ## Create a graph using the Chung-Lu model.
  ## Edge (i,j) exists with probability w_i * w_j / sum(w).
  ##
  ## **Raises:** ``NimNetError`` if any weight is negative.
  for w in weights:
    if w < 0.0:
      raise newException(NimNetError, "Weights must be non-negative")

  var rng = if seed != 0: initRand(seed) else: initRand()
  var g = newGraph[int]()
  let n = weights.len

  if n == 0:
    return g

  for i in 0 ..< n:
    g.addNode(i)

  var totalWeight = 0.0
  for w in weights:
    totalWeight += w

  if totalWeight == 0.0:
    return g

  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      let p = weights[i] * weights[j] / totalWeight
      if rng.rand(1.0) < p:
        g.addEdge(i, j)

  result = g

proc degreeSequenceTree*(degSequence: openArray[int]): Graph[int] =
  ## Create a tree from a degree sequence using a greedy approach.
  ## The degree sequence must sum to 2*(n-1) for a valid tree.
  ##
  ## **Raises:** ``NimNetError`` if the sequence doesn't represent a tree.
  let n = degSequence.len
  if n == 0:
    return newGraph[int]()

  var total = 0
  for d in degSequence:
    if d < 1 and n > 1:
      raise newException(NimNetError, "All degrees must be >= 1 for a tree")
    total += d
  if n > 1 and total != 2 * (n - 1):
    raise newException(NimNetError, "Degree sum must equal 2*(n-1) for a tree")

  var g = newGraph[int]()
  if n == 1:
    g.addNode(0)
    return g

  for i in 0 ..< n:
    g.addNode(i)

  # Use Prüfer-sequence-like approach: repeatedly connect leaf nodes
  var remaining = newSeq[int](n)
  for i in 0 ..< n:
    remaining[i] = degSequence[i]

  var available: seq[int]
  for i in 0 ..< n:
    available.add(i)

  while available.len > 1:
    # Find a leaf (remaining degree = 1)
    var leafIdx = -1
    for idx in 0 ..< available.len:
      if remaining[available[idx]] == 1:
        leafIdx = idx
        break

    if leafIdx < 0:
      break

    let leaf = available[leafIdx]
    available.delete(leafIdx)

    # Connect to the first available node with remaining capacity
    for idx in 0 ..< available.len:
      let neighbor = available[idx]
      if remaining[neighbor] > 0:
        g.addEdge(leaf, neighbor)
        remaining[leaf] -= 1
        remaining[neighbor] -= 1
        break

  result = g
