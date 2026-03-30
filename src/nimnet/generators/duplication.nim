## Duplication-based graph generators

import std/[random, sets]
import ../graph

proc duplicationDivergenceGraph*(n: int, p: float, seed: int64 = 0): Graph[int] =
  ## Generate a graph using the duplication-divergence model.
  ## Start with 2 connected nodes. Each new node duplicates a random existing node's
  ## connections, then each edge is retained with probability p.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  result.addEdge(0, 1)
  for newNode in 2 ..< n:
    let ns = result.nodeSeq
    let target = ns[rng.rand(ns.len - 1)]
    result.addNode(newNode)
    for nb in result.neighbors(target):
      if rng.rand(1.0) < p:
        result.addEdge(newNode, nb)
    # Ensure at least one edge
    if result.degree(newNode) == 0:
      result.addEdge(newNode, target)

proc partialDuplicationGraph*(n: int, p, q: float, seed: int64 = 0): Graph[int] =
  ## Generate a graph using the partial duplication model.
  ## New node copies target's edges with prob p, then connects to target with prob q.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int]()
  result.addEdge(0, 1)
  for newNode in 2 ..< n:
    let ns = result.nodeSeq
    let target = ns[rng.rand(ns.len - 1)]
    result.addNode(newNode)
    for nb in result.neighbors(target):
      if rng.rand(1.0) < p:
        result.addEdge(newNode, nb)
    if rng.rand(1.0) < q:
      result.addEdge(newNode, target)
    if result.degree(newNode) == 0:
      result.addEdge(newNode, target)
