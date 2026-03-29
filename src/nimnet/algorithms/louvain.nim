## Louvain community detection algorithm
##
## Detects communities by optimizing modularity in a greedy fashion,
## using two phases: local moves and community aggregation.

import std/[tables, sets, random, algorithm]
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
    # No edges: each node is its own community
    for node in nodes:
      result.add([node].toHashSet)
    return

  # Initialize: each node in its own community
  var community = initTable[N, int]()  # node -> community id
  var comId = 0
  for node in nodes:
    community[node] = comId
    comId.inc

  # Precompute degree weighted sum (ki)
  var ki = initTable[N, float]()
  for node in nodes:
    var degSum = 0.0
    for neighbor in g.neighbors(node):
      degSum += g.getEdgeAttr(node, neighbor).getWeight()
    ki[node] = degSum

  # Initialize sigmaTot once — maintained incrementally during Phase 1
  var sigmaTot = initTable[int, float]()
  for node in nodes:
    let c = community[node]
    sigmaTot[c] = sigmaTot.getOrDefault(c, 0.0) + ki[node]

  # Phase 1: Local moves
  var improved = true
  while improved:
    improved = false
    var order = nodes
    rng.shuffle(order)

    for node in order:
      let currentCom = community[node]

      # Calculate sum of weights to each neighboring community
      var neighborComs = initTable[int, float]()
      for neighbor in g.neighbors(node):
        let ncom = community[neighbor]
        let w = g.getEdgeAttr(node, neighbor).getWeight()
        neighborComs[ncom] = neighborComs.getOrDefault(ncom, 0.0) + w

      # Try removing node from current community
      let kiNode = ki[node]
      let sigIn = neighborComs.getOrDefault(currentCom, 0.0)
      let sigTot = sigmaTot.getOrDefault(currentCom, 0.0) - kiNode

      let removeGain = -resolution * (sigIn / m2 - sigTot * kiNode / (m2 * m2))

      # Try adding to each neighboring community
      var bestCom = currentCom
      var bestGain = 0.0

      for ncom, wSum in neighborComs:
        if ncom == currentCom:
          continue
        let sigTotN = sigmaTot.getOrDefault(ncom, 0.0)
        let addGain = resolution * (wSum / m2 - sigTotN * kiNode / (m2 * m2))
        let totalGain = removeGain + addGain
        if totalGain > bestGain:
          bestGain = totalGain
          bestCom = ncom

      if bestCom != currentCom:
        # Incrementally update sigmaTot — O(1) instead of recomputing O(V)
        sigmaTot[currentCom] = sigmaTot.getOrDefault(currentCom, 0.0) - kiNode
        sigmaTot[bestCom] = sigmaTot.getOrDefault(bestCom, 0.0) + kiNode
        community[node] = bestCom
        improved = true

  # Collect communities
  var comNodes = initTable[int, HashSet[N]]()
  for node in nodes:
    let c = community[node]
    if c notin comNodes:
      comNodes[c] = initHashSet[N]()
    comNodes[c].incl(node)

  for _, s in comNodes:
    result.add(s)
