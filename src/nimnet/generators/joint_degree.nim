## Joint degree graph generators

import std/[tables, random, algorithm, sets]
import ../graph

proc isValidJointDegree*(jointDegree: Table[(int, int), int]): bool =
  ## Check if a joint degree dictionary is valid (realizable).
  ## jointDegree maps (degree_i, degree_j) -> count of edges.
  var degreeCount: Table[int, int]
  for (key, count) in jointDegree.pairs:
    let (di, dj) = key
    if di > dj:
      return false  # should be normalized: di <= dj
    if count < 0:
      return false
    if di notin degreeCount: degreeCount[di] = 0
    degreeCount[di] += count
    if di != dj:
      if dj notin degreeCount: degreeCount[dj] = 0
      degreeCount[dj] += count
    else:
      degreeCount[di] += count
  # Check that total stubs at each degree are even multiples
  for deg, total in degreeCount:
    if total mod deg != 0:
      return false
  return true

proc jointDegreeGraph*(jointDegree: Table[(int, int), int], seed: int64 = 0): Graph[int] =
  ## Generate a graph with the given joint degree distribution.
  ## jointDegree maps (degree_i, degree_j) -> number of edges between
  ## nodes of degree degree_i and nodes of degree degree_j.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  # Compute required degree sequence
  var degreeCounts: Table[int, int]
  for (key, count) in jointDegree.pairs:
    let (di, dj) = key
    if di notin degreeCounts: degreeCounts[di] = 0
    degreeCounts[di] += count
    if di != dj:
      if dj notin degreeCounts: degreeCounts[dj] = 0
      degreeCounts[dj] += count
  # Assign nodes to degrees
  var nodeId = 0
  var degreeNodes: Table[int, seq[int]]
  for deg, totalStubs in degreeCounts:
    let nNodes = totalStubs div deg
    degreeNodes[deg] = @[]
    for _ in 0 ..< nNodes:
      result.addNode(nodeId)
      degreeNodes[deg].add(nodeId)
      inc nodeId
  # Connect based on joint degree
  for (key, count) in jointDegree.pairs:
    let (di, dj) = key
    var added = 0
    for _ in 0 ..< count * 10:
      if added >= count: break
      if degreeNodes[di].len > 0 and degreeNodes[dj].len > 0:
        let u = degreeNodes[di][rng.rand(degreeNodes[di].len - 1)]
        let v = degreeNodes[dj][rng.rand(degreeNodes[dj].len - 1)]
        if u != v and not result.hasEdge(u, v):
          result.addEdge(u, v)
          inc added
