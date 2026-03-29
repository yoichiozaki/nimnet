## Tree generators

import std/[random, tables, sets, deques]
import ../types
import ../graph

proc balancedTree*(r, h: int): Graph[int] =
  ## Generate a balanced tree with branching factor r and height h.
  ## Root is node 0.
  result = newGraph[int]()
  result.addNode(0)
  var nodeId = 1
  var parents = @[0]
  for level in 1 .. h:
    var nextParents: seq[int]
    for parent in parents:
      for _ in 0 ..< r:
        result.addEdge(parent, nodeId)
        nextParents.add(nodeId)
        nodeId.inc
    parents = nextParents

proc randomTree*(n: int, seed: int64 = 0): Graph[int] =
  ## Generate a random labeled tree on n nodes using Prüfer sequence.
  if n <= 0:
    return newGraph[int]()
  if n == 1:
    result = newGraph[int]()
    result.addNode(0)
    return
  if n == 2:
    result = newGraph[int]()
    result.addEdge(0, 1)
    return

  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)

  # Generate random Prüfer sequence
  var prufer: seq[int]
  for _ in 0 ..< n - 2:
    prufer.add(rng.rand(n - 1))

  # Decode Prüfer sequence to tree
  var degree = newSeq[int](n)
  for i in 0 ..< n:
    degree[i] = 1
  for p in prufer:
    degree[p].inc

  for p in prufer:
    for i in 0 ..< n:
      if degree[i] == 1:
        result.addEdge(i, p)
        degree[i].dec
        degree[p].dec
        break

  # Connect the last two nodes with degree 1
  var remaining: seq[int]
  for i in 0 ..< n:
    if degree[i] == 1:
      remaining.add(i)
  if remaining.len == 2:
    result.addEdge(remaining[0], remaining[1])

proc binomialTree*(order: int): Graph[int] =
  ## Generate a binomial tree of given order (2^order nodes).
  let n = 1 shl order  # 2^order
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)
  # Recursive structure: B_k = two copies of B_{k-1}
  var size = 1
  for k in 0 ..< order:
    for i in 0 ..< size:
      result.addEdge(i, i + size)
    size *= 2

proc starTree*(n: int): Graph[int] =
  ## Generate a star tree (same as star graph): one center, n leaves.
  result = newGraph[int]()
  result.addNode(0)
  for i in 1 .. n:
    result.addEdge(0, i)

proc caterpillarTree*(backbone: int, legs: int, seed: int64 = 0): Graph[int] =
  ## Generate a caterpillar tree: a path backbone with random legs.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  # Create backbone path
  for i in 0 ..< backbone:
    result.addNode(i)
  for i in 0 ..< backbone - 1:
    result.addEdge(i, i + 1)
  # Add legs
  var nextId = backbone
  for i in 0 ..< backbone:
    let numLegs = rng.rand(legs)
    for _ in 0 ..< numLegs:
      result.addEdge(i, nextId)
      nextId.inc
