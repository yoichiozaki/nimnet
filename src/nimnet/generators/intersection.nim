## Intersection graph generators

import std/[random, sets]
import ../graph

proc uniformRandomIntersectionGraph*(n, m: int, p: float, seed: int64 = 0): Graph[int] =
  ## Generate a uniform random intersection graph.
  ## n actors, m objects; each actor chooses each object with prob p.
  ## Two actors are connected if they share at least one object.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  var memberships = newSeq[HashSet[int]](n)
  for i in 0 ..< n:
    memberships[i] = initHashSet[int]()
    for j in 0 ..< m:
      if rng.rand(1.0) < p:
        memberships[i].incl(j)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if (memberships[i] * memberships[j]).len > 0:
        result.addEdge(i, j)

proc kRandomIntersectionGraph*(n, m, k: int, seed: int64 = 0): Graph[int] =
  ## Generate a k-random intersection graph.
  ## Each actor chooses exactly k objects uniformly at random.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  var memberships = newSeq[HashSet[int]](n)
  for i in 0 ..< n:
    memberships[i] = initHashSet[int]()
    var selected: HashSet[int]
    while selected.len < min(k, m):
      selected.incl(rng.rand(m - 1))
    memberships[i] = selected
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if (memberships[i] * memberships[j]).len > 0:
        result.addEdge(i, j)

proc generalRandomIntersectionGraph*(n, m: int, probs: openArray[float], seed: int64 = 0): Graph[int] =
  ## Generate a general random intersection graph.
  ## Each object j has probability probs[j] of being chosen by each actor.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  var memberships = newSeq[HashSet[int]](n)
  for i in 0 ..< n:
    memberships[i] = initHashSet[int]()
    for j in 0 ..< min(m, probs.len):
      if rng.rand(1.0) < probs[j]:
        memberships[i].incl(j)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if (memberships[i] * memberships[j]).len > 0:
        result.addEdge(i, j)
