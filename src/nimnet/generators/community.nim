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

proc gaussianRandomPartitionGraph*(n, s: int, v: float, pIn, pOut: float, seed: int64 = 0): Graph[int] =
  ## Generate a Gaussian random partition graph.
  ## n nodes divided into communities of sizes drawn from Gaussian(s, v).
  ## pIn: intra-community edge probability, pOut: inter-community edge probability.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  # Assign communities with Gaussian sizes
  var communities: seq[seq[int]]
  var assigned = 0
  while assigned < n:
    var size = int(float(s) + v * rng.gauss())
    size = max(1, min(size, n - assigned))
    var comm: seq[int]
    for i in assigned ..< assigned + size:
      comm.add(i)
    communities.add(comm)
    assigned += size
  # Add edges
  for ci in 0 ..< communities.len:
    for i in 0 ..< communities[ci].len:
      for j in i + 1 ..< communities[ci].len:
        if rng.rand(1.0) < pIn:
          result.addEdge(communities[ci][i], communities[ci][j])
    for cj in ci + 1 ..< communities.len:
      for u in communities[ci]:
        for v2 in communities[cj]:
          if rng.rand(1.0) < pOut:
            result.addEdge(u, v2)

proc randomPartitionGraph*(sizes: openArray[int], pIn, pOut: float, seed: int64 = 0): Graph[int] =
  ## Generate a random partition graph.
  ## ``sizes`` specifies the size of each partition.
  var rng = if seed != 0: initRand(seed) else: initRand()
  var communities: seq[seq[int]]
  var nodeId = 0
  result = newGraph[int]()
  for size in sizes:
    var comm: seq[int]
    for _ in 0 ..< size:
      result.addNode(nodeId)
      comm.add(nodeId)
      inc nodeId
    communities.add(comm)
  for ci in 0 ..< communities.len:
    for i in 0 ..< communities[ci].len:
      for j in i + 1 ..< communities[ci].len:
        if rng.rand(1.0) < pIn:
          result.addEdge(communities[ci][i], communities[ci][j])
    for cj in ci + 1 ..< communities.len:
      for u in communities[ci]:
        for v2 in communities[cj]:
          if rng.rand(1.0) < pOut:
            result.addEdge(u, v2)

proc lfrBenchmarkGraph*(n: int, tau1, tau2, mu: float, seed: int64 = 0): Graph[int] =
  ## Generate a simplified LFR benchmark graph.
  ## n: number of nodes, tau1: power law exponent for degree distribution,
  ## tau2: power law exponent for community size, mu: mixing parameter.
  var rng = if seed != 0: initRand(seed) else: initRand()
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  # Simple community assignment
  let avgComm = max(3, n div 5)
  var communities: seq[seq[int]]
  var assigned = 0
  while assigned < n:
    let size = max(2, min(int(float(avgComm) * pow(rng.rand(1.0), 1.0 / tau2)), n - assigned))
    var comm: seq[int]
    for i in assigned ..< assigned + size:
      comm.add(i)
    communities.add(comm)
    assigned += size
  # Intra-community edges (1-mu fraction)
  for comm in communities:
    for i in 0 ..< comm.len:
      for j in i + 1 ..< comm.len:
        if rng.rand(1.0) < (1.0 - mu) * 2.0 / float(max(1, comm.len - 1)):
          result.addEdge(comm[i], comm[j])
  # Inter-community edges (mu fraction)
  for _ in 0 ..< int(mu * float(n)):
    let u = rng.rand(n - 1)
    let v = rng.rand(n - 1)
    if u != v and not result.hasEdge(u, v):
      result.addEdge(u, v)
