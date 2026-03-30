## Internet AS graph generator

import std/[random]
import ../graph

proc randomInternetAsGraph*(n: int, seed: int64 = 0): Graph[int] =
  ## Generate a random Internet AS-like graph.
  ## Uses a simplified model with core, peer, and customer tiers.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  let nCore = max(1, n div 10)
  let nPeer = max(1, n div 3)
  # Core: fully connected
  for i in 0 ..< nCore:
    for j in i + 1 ..< nCore:
      result.addEdge(i, j)
  # Peer: connect to some core nodes
  for i in nCore ..< nCore + nPeer:
    let nConns = max(1, rng.rand(nCore))
    for _ in 0 ..< nConns:
      let target = rng.rand(nCore - 1)
      if not result.hasEdge(i, target):
        result.addEdge(i, target)
  # Customers: connect to peer or core
  for i in nCore + nPeer ..< n:
    let target = rng.rand(nCore + nPeer - 1)
    result.addEdge(i, target)
