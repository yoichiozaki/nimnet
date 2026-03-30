## Degree sequence generators.
##
## Generate graphs with a specified degree sequence.
##
## - ``configurationModel`` — random graph from given degree sequence
## - ``havelHakimiGraph`` — deterministic realization
## - ``expectedDegreeGraph`` — Chung-Lu model
## - ``degreeSequenceTree`` — tree with given degree sequence
## - ``isGraphical`` — Erdős–Gallai test for realizability
## - ``directedConfigurationModel`` — directed random graph from in/out degree sequences
## - ``directedHavelHakimiGraph`` — directed deterministic realization
## - ``randomDegreeSequenceGraph`` — random graph matching a degree sequence

import std/[algorithm, random]
import ../types, ../graph, ../digraph

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

proc directedConfigurationModel*(inDegSeq, outDegSeq: openArray[int], seed: int64 = 0): DiGraph[int] =
  ## Generate a directed random graph from in-degree and out-degree sequences.
  var rng = if seed != 0: initRand(seed) else: initRand()
  let n = inDegSeq.len
  result = newDiGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  var inStubs, outStubs: seq[int]
  for i in 0 ..< n:
    for _ in 0 ..< inDegSeq[i]:
      inStubs.add(i)
    for _ in 0 ..< outDegSeq[i]:
      outStubs.add(i)
  rng.shuffle(inStubs)
  rng.shuffle(outStubs)
  let m = min(inStubs.len, outStubs.len)
  for i in 0 ..< m:
    if outStubs[i] != inStubs[i]:
      result.addEdge(outStubs[i], inStubs[i])

proc directedHavelHakimiGraph*(inDegSeq, outDegSeq: openArray[int]): DiGraph[int] =
  ## Generate a directed graph using the Havel-Hakimi algorithm.
  let n = inDegSeq.len
  result = newDiGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  var outRemaining = newSeq[int](n)
  var inRemaining = newSeq[int](n)
  for i in 0 ..< n:
    outRemaining[i] = outDegSeq[i]
    inRemaining[i] = inDegSeq[i]
  for step in 0 ..< n:
    # Find node with max remaining out-degree
    var maxOut = 0
    var maxNode = -1
    for i in 0 ..< n:
      if outRemaining[i] > maxOut:
        maxOut = outRemaining[i]
        maxNode = i
    if maxNode < 0: break
    let u = maxNode
    let d = outRemaining[u]
    outRemaining[u] = 0
    # Sort others by in-degree remaining (descending)
    var candidates: seq[(int, int)]  # (inRemaining, node)
    for i in 0 ..< n:
      if i != u and inRemaining[i] > 0:
        candidates.add((inRemaining[i], i))
    candidates.sort(proc(a, b: (int, int)): int = cmp(b[0], a[0]))
    let k = min(d, candidates.len)
    for i in 0 ..< k:
      let v = candidates[i][1]
      result.addEdge(u, v)
      inRemaining[v] -= 1

proc randomDegreeSequenceGraph*(degSeq: openArray[int], seed: int64 = 0): Graph[int] =
  ## Generate a random simple graph with the given degree sequence.
  var rng = if seed != 0: initRand(seed) else: initRand()
  let n = degSeq.len
  for attempt in 0 ..< 100:
    var g = newGraph[int](capacity = n)
    for i in 0 ..< n:
      g.addNode(i)
    var stubs: seq[int]
    for i in 0 ..< n:
      for _ in 0 ..< degSeq[i]:
        stubs.add(i)
    rng.shuffle(stubs)
    var valid = true
    var idx = 0
    while idx + 1 < stubs.len:
      let u = stubs[idx]
      let v = stubs[idx + 1]
      if u != v and not g.hasEdge(u, v):
        g.addEdge(u, v)
      else:
        valid = false
      idx += 2
    if valid:
      return g
  # Fallback
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
