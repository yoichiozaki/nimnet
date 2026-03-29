## Louvain community detection algorithm
##
## Detects communities by optimizing modularity in a greedy fashion,
## using local moves with indexed-array inner loop for maximum performance.

import std/[tables, sets, random, algorithm, sequtils]
import ../graph

proc louvainCommunities*[N](g: Graph[N], resolution: float = 1.0, seed: int64 = 0): seq[HashSet[N]] =
  ## Detect communities using the Louvain algorithm.
  ## Returns a list of communities (sets of nodes).
  ## `resolution` controls the size of communities (higher = smaller communities).
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0:
    return @[]

  var rng = if seed != 0: initRand(seed) else: initRand()
  let m2 = float(2 * g.numberOfEdges())  # 2m
  if m2 == 0.0:
    for node in nodes:
      result.add([node].toHashSet)
    return

  # Build indexed adjacency for cache-friendly inner loop
  var nodeIdx = initTable[N, int](n)
  for i in 0 ..< n:
    nodeIdx[nodes[i]] = i

  var adjIdx = newSeq[seq[(int, float)]](n)
  for i in 0 ..< n:
    let node = nodes[i]
    adjIdx[i] = newSeqOfCap[(int, float)](g.adj[node].len)
    for neighbor, attr in g.adj[node]:
      adjIdx[i].add((nodeIdx[neighbor], attr.weight))

  # Flat arrays for community state — no hash tables in inner loop
  var com = newSeq[int](n)       # node index → community id
  var kiArr = newSeq[float](n)   # weighted degree per node
  var sigTot = newSeq[float](n)  # sigmaTot per community (indexed by community id)

  for i in 0 ..< n:
    com[i] = i
    var degSum = 0.0
    for (_, w) in adjIdx[i]:
      degSum += w
    kiArr[i] = degSum
    sigTot[i] = degSum

  # Pre-allocated neighbor-community weight accumulator (avoids per-node Table allocation)
  var ncWeight = newSeq[float](n)  # community → accumulated weight
  var activeComs = newSeqOfCap[int](64)

  # Phase 1: Local moves with flat-array inner loop
  var improved = true
  var order = toSeq(0 ..< n)
  var maxPasses = 100
  let invM2 = 1.0 / m2
  let invM2sq = invM2 * invM2

  while improved and maxPasses > 0:
    improved = false
    maxPasses.dec
    rng.shuffle(order)

    for idx in order:
      let currentCom = com[idx]
      let ki = kiArr[idx]

      # Accumulate weights to neighboring communities (O(degree), no allocation)
      activeComs.setLen(0)
      for (j, w) in adjIdx[idx]:
        let nc = com[j]
        if ncWeight[nc] == 0.0:
          activeComs.add(nc)
        ncWeight[nc] += w

      # Evaluate removal from current community
      let sigIn = ncWeight[currentCom]
      let sigC = sigTot[currentCom] - ki
      let removeGain = -resolution * (sigIn * invM2 - sigC * ki * invM2sq)

      # Find best neighboring community
      var bestCom = currentCom
      var bestGain = 0.0

      for nc in activeComs:
        if nc == currentCom:
          continue
        let wSum = ncWeight[nc]
        let sigN = sigTot[nc]
        let addGain = resolution * (wSum * invM2 - sigN * ki * invM2sq)
        let totalGain = removeGain + addGain
        if totalGain > bestGain:
          bestGain = totalGain
          bestCom = nc

      # Clean up accumulator (O(degree) reset — no Table.clear overhead)
      for c in activeComs:
        ncWeight[c] = 0.0

      if bestCom != currentCom:
        sigTot[currentCom] -= ki
        sigTot[bestCom] += ki
        com[idx] = bestCom
        improved = true

  # Collect communities
  var comNodes = initTable[int, HashSet[N]]()
  for i in 0 ..< n:
    let c = com[i]
    if c notin comNodes:
      comNodes[c] = initHashSet[N]()
    comNodes[c].incl(nodes[i])

  for _, s in comNodes:
    result.add(s)
