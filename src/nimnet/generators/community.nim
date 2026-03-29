## Community graph generators.
##
## Generate graphs with built-in community structure for testing
## community detection algorithms.
##
## - ``cavemanGraph(l, k)`` — l disconnected cliques of size k
## - ``connectedCavemanGraph(l, k)`` — l cliques in a ring
## - ``plantedPartitionGraph(l, k, pIn, pOut)`` — stochastic block model
## - ``windmillGraph(n, k)`` — n copies of K_k sharing a universal node
## - ``relaxedCavemanGraph(l, k, p)`` — caveman with random rewiring
## - ``ringOfCliques(numCliques, cliqueSize)`` — cliques arranged in a ring

import std/[random, math]
import ../types
import ../graph

proc cavemanGraph*(l, k: int): Graph[int] =
  ## Generate a caveman graph: ``l`` cliques of size ``k``, unconnected.
  ## Total nodes: l*k. No edges between cliques.
  result = newGraph[int]()
  for c in 0 ..< l:
    let base = c * k
    for i in 0 ..< k:
      for j in (i + 1) ..< k:
        result.addEdge(base + i, base + j)

proc connectedCavemanGraph*(l, k: int): Graph[int] =
  ## Generate a connected caveman graph.
  ## Start with ``l`` cliques of size ``k``, then remove one edge
  ## from each clique and use it to connect adjacent cliques in a ring.
  result = cavemanGraph(l, k)
  if l < 2 or k < 2:
    return

  # For each clique c, remove edge (c*k, c*k+1) and add
  # edge from c*k to ((c+1) mod l)*k
  for c in 0 ..< l:
    let base = c * k
    if result.hasEdge(base, base + 1):
      result.removeEdge(base, base + 1)
    let nextBase = ((c + 1) mod l) * k
    result.addEdge(base, nextBase)

proc plantedPartitionGraph*(l, k: int, pIn, pOut: float,
    seed = 0): Graph[int] =
  ## Generate a planted partition graph (stochastic block model).
  ## ``l`` groups of ``k`` nodes each. Intra-group edge probability ``pIn``,
  ## inter-group edge probability ``pOut``.
  if seed != 0:
    randomize(seed)
  else:
    randomize()

  result = newGraph[int]()
  let n = l * k
  for i in 0 ..< n:
    result.addNode(i)

  for i in 0 ..< n:
    for j in (i + 1) ..< n:
      let gi = i div k
      let gj = j div k
      let p = if gi == gj: pIn else: pOut
      if rand(1.0) < p:
        result.addEdge(i, j)

proc windmillGraph*(n, k: int): Graph[int] =
  ## Generate a windmill graph: ``n`` copies of the complete graph K_k,
  ## all sharing a single universal node (node 0).
  ## Total nodes: n*(k-1) + 1.
  result = newGraph[int]()
  result.addNode(0)  # universal node
  var nodeId = 1
  for c in 0 ..< n:
    var clique: seq[int]
    clique.add(0)  # universal node is in every clique
    for i in 0 ..< k - 1:
      clique.add(nodeId)
      result.addNode(nodeId)
      nodeId += 1
    # Add edges within clique
    for i in 0 ..< clique.len:
      for j in (i + 1) ..< clique.len:
        if not result.hasEdge(clique[i], clique[j]):
          result.addEdge(clique[i], clique[j])

proc relaxedCavemanGraph*(l, k: int, p: float,
    seed = 0): Graph[int] =
  ## Generate a relaxed caveman graph.
  ## Start with ``l`` cliques of size ``k``, then rewire each edge
  ## with probability ``p`` to a random node.
  if seed != 0:
    randomize(seed)
  else:
    randomize()

  result = cavemanGraph(l, k)
  let n = l * k

  var edgesToRewire: seq[(int, int)]
  for (u, v) in result.edges:
    if rand(1.0) < p:
      edgesToRewire.add((u, v))

  for (u, v) in edgesToRewire:
    result.removeEdge(u, v)
    # Pick a random node not u
    var target = rand(n - 1)
    while target == u or result.hasEdge(u, target):
      target = rand(n - 1)
    result.addEdge(u, target)

proc ringOfCliques*(numCliques, cliqueSize: int): Graph[int] =
  ## Generate a ring of cliques graph.
  ## ``numCliques`` complete graphs of ``cliqueSize`` nodes each,
  ## connected in a ring by edges between adjacent cliques.
  result = newGraph[int]()
  let total = numCliques * cliqueSize

  # Create cliques
  for c in 0 ..< numCliques:
    let base = c * cliqueSize
    for i in 0 ..< cliqueSize:
      for j in (i + 1) ..< cliqueSize:
        result.addEdge(base + i, base + j)

  # Connect adjacent cliques: last node of clique c to first node of clique c+1
  for c in 0 ..< numCliques:
    let thisLast = c * cliqueSize + cliqueSize - 1
    let nextFirst = ((c + 1) mod numCliques) * cliqueSize
    result.addEdge(thisLast, nextFirst)
