## Louvain community detection algorithm
##
## Full two-phase Louvain: Phase 1 (local moves) + Phase 2 (graph contraction),
## repeated until no further improvement. Uses flat-array inner loops for speed.

import std/[tables, sets, random, algorithm, sequtils]
import ../graph

# Internal flat-graph representation for contracted graphs
type
  FlatGraph = object
    n: int
    adjOff: seq[int]      # CSR offsets
    adjNbr: seq[int]      # neighbor indices
    adjWgt: seq[float]    # edge weights
    selfLoop: seq[float]  # self-loop weight per node
    degree: seq[float]    # weighted degree per node

proc buildFlatGraph(n: int, adjIdx: seq[seq[(int, float)]]): FlatGraph =
  result.n = n
  result.adjOff = newSeq[int](n + 1)
  result.selfLoop = newSeq[float](n)
  result.degree = newSeq[float](n)
  var totalEdges = 0
  for i in 0 ..< n:
    for (j, w) in adjIdx[i]:
      if j == i:
        result.selfLoop[i] += w
      else:
        totalEdges.inc
      result.degree[i] += w
    result.adjOff[i] = totalEdges - adjIdx[i].len + (if result.selfLoop[i] > 0: 1 else: 0)
  # Rebuild offsets properly
  result.adjNbr = newSeqOfCap[int](totalEdges)
  result.adjWgt = newSeqOfCap[float](totalEdges)
  var off = 0
  for i in 0 ..< n:
    result.adjOff[i] = off
    for (j, w) in adjIdx[i]:
      if j != i:
        result.adjNbr.add(j)
        result.adjWgt.add(w)
        off.inc
  result.adjOff[n] = off

proc phase1(fg: FlatGraph, resolution: float, rng: var Rand): (seq[int], bool) =
  ## Phase 1: local moves. Returns (community assignment, improved).
  let n = fg.n
  let m2 = block:
    var s = 0.0
    for i in 0 ..< n:
      s += fg.degree[i]
    s
  if m2 == 0.0:
    var com = newSeq[int](n)
    for i in 0 ..< n: com[i] = i
    return (com, false)

  let invM2 = 1.0 / m2
  let resInvM2sq = resolution * invM2 * invM2

  var com = newSeq[int](n)
  var sigTot = newSeq[float](n)
  for i in 0 ..< n:
    com[i] = i
    sigTot[i] = fg.degree[i]

  var ncWeight = newSeq[float](n)
  var activeComs = newSeqOfCap[int](64)
  var order = toSeq(0 ..< n)
  var improved = false
  var maxPasses = 100

  var moved = true
  while moved and maxPasses > 0:
    moved = false
    maxPasses.dec
    rng.shuffle(order)

    for idx in order:
      let currentCom = com[idx]
      let ki = fg.degree[idx]

      # Accumulate weights to neighboring communities
      activeComs.setLen(0)
      for k in fg.adjOff[idx] ..< fg.adjOff[idx + 1]:
        let nc = com[fg.adjNbr[k]]
        if ncWeight[nc] == 0.0:
          activeComs.add(nc)
        ncWeight[nc] += fg.adjWgt[k]

      # Ensure current community is in activeComs
      if ncWeight[currentCom] == 0.0:
        activeComs.add(currentCom)
        # It will stay at 0 weight — that's fine

      # Evaluate removal from current community
      let sigIn = ncWeight[currentCom]
      let sigC = sigTot[currentCom] - ki
      let removeGain = -(sigIn * invM2 * resolution - sigC * ki * resInvM2sq)

      var bestCom = currentCom
      var bestGain = 0.0

      for nc in activeComs:
        if nc == currentCom:
          continue
        let wSum = ncWeight[nc]
        let sigN = sigTot[nc]
        let addGain = wSum * invM2 * resolution - sigN * ki * resInvM2sq
        let totalGain = removeGain + addGain
        if totalGain > bestGain:
          bestGain = totalGain
          bestCom = nc

      # Clean up
      for c in activeComs:
        ncWeight[c] = 0.0

      if bestCom != currentCom:
        sigTot[currentCom] -= ki
        sigTot[bestCom] += ki
        com[idx] = bestCom
        moved = true
        improved = true

  result = (com, improved)

proc contractGraph(fg: FlatGraph, com: seq[int]): (FlatGraph, seq[seq[int]]) =
  ## Phase 2: contract graph by merging communities into super-nodes.
  ## Returns (contracted flat graph, mapping from super-node to list of original nodes).
  let n = fg.n

  # Renumber communities to 0..numComms-1
  var comMap = initTable[int, int]()
  var numComms = 0
  for i in 0 ..< n:
    if com[i] notin comMap:
      comMap[com[i]] = numComms
      numComms.inc
  var renumbered = newSeq[int](n)
  for i in 0 ..< n:
    renumbered[i] = comMap[com[i]]

  # Build mapping: super-node → original nodes
  var members = newSeq[seq[int]](numComms)
  for i in 0 ..< numComms:
    members[i] = @[]
  for i in 0 ..< n:
    members[renumbered[i]].add(i)

  # Build contracted adjacency
  # For each pair of super-nodes, sum the edge weights between their members
  var newAdj = newSeq[seq[(int, float)]](numComms)
  for i in 0 ..< numComms:
    newAdj[i] = @[]

  # Use a scratch array to accumulate weights
  var scratch = newSeq[float](numComms)
  var activeList = newSeqOfCap[int](numComms)

  for ci in 0 ..< numComms:
    activeList.setLen(0)
    # Accumulate self-loops from members
    var selfW = 0.0
    for node in members[ci]:
      selfW += fg.selfLoop[node]
      for k in fg.adjOff[node] ..< fg.adjOff[node + 1]:
        let cj = renumbered[fg.adjNbr[k]]
        if scratch[cj] == 0.0:
          activeList.add(cj)
        scratch[cj] += fg.adjWgt[k]

    for cj in activeList:
      let w = scratch[cj]
      scratch[cj] = 0.0
      if cj == ci:
        selfW += w  # edges within community become self-loops
      else:
        newAdj[ci].add((cj, w))

    if selfW > 0.0:
      # Store self-loop info to preserve in FlatGraph
      newAdj[ci].add((ci, selfW))

  # Build FlatGraph from newAdj (separating self-loops)
  var fg2: FlatGraph
  fg2.n = numComms
  fg2.adjOff = newSeq[int](numComms + 1)
  fg2.selfLoop = newSeq[float](numComms)
  fg2.degree = newSeq[float](numComms)
  var off = 0
  var nbrBuf = newSeqOfCap[int](numComms * 4)
  var wgtBuf = newSeqOfCap[float](numComms * 4)
  for ci in 0 ..< numComms:
    fg2.adjOff[ci] = off
    for (cj, w) in newAdj[ci]:
      fg2.degree[ci] += w
      if cj == ci:
        fg2.selfLoop[ci] += w
      else:
        nbrBuf.add(cj)
        wgtBuf.add(w)
        off.inc
  fg2.adjOff[numComms] = off
  fg2.adjNbr = nbrBuf
  fg2.adjWgt = wgtBuf

  result = (fg2, members)

proc louvainCommunities*[N](g: Graph[N], resolution: float = 1.0, seed: int64 = 0): seq[HashSet[N]] =
  ## Detect communities using the full Louvain algorithm (Phase 1 + Phase 2).
  ## Returns a list of communities (sets of nodes).
  ## `resolution` controls the size of communities (higher = smaller communities).
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0:
    return @[]

  var rng = if seed != 0: initRand(seed) else: initRand()
  let m2 = float(2 * g.numberOfEdges())
  if m2 == 0.0:
    for node in nodes:
      result.add([node].toHashSet)
    return

  # Build initial indexed adjacency
  var nodeIdx = initTable[N, int](n)
  for i in 0 ..< n:
    nodeIdx[nodes[i]] = i

  var adjIdx = newSeq[seq[(int, float)]](n)
  for i in 0 ..< n:
    let node = nodes[i]
    adjIdx[i] = newSeqOfCap[(int, float)](g.adj[node].len)
    for neighbor, attr in g.adj[node]:
      adjIdx[i].add((nodeIdx[neighbor], attr.weight))

  # Build initial FlatGraph
  var fg = buildFlatGraph(n, adjIdx)

  # nodeMap[i] = list of original node indices that super-node i represents
  var nodeMap = newSeq[seq[int]](n)
  for i in 0 ..< n:
    nodeMap[i] = @[i]

  # Multi-level Louvain loop
  var maxLevels = 20
  while maxLevels > 0:
    maxLevels.dec
    let (com, improved) = phase1(fg, resolution, rng)
    if not improved:
      break

    # Phase 2: contract
    let (fg2, members) = contractGraph(fg, com)

    # Update nodeMap: each new super-node maps to the union of its members' original nodes
    var newNodeMap = newSeq[seq[int]](fg2.n)
    for ci in 0 ..< fg2.n:
      newNodeMap[ci] = @[]
      for oldIdx in members[ci]:
        newNodeMap[ci].add(nodeMap[oldIdx])

    nodeMap = newNodeMap
    fg = fg2

    # If contracted graph has same size, no further improvement possible
    if fg.n == fg2.n and fg2.n == members.len:
      # Check if any community actually merged
      var allSingleton = true
      for ci in 0 ..< fg2.n:
        if members[ci].len > 1:
          allSingleton = false
          break
      if allSingleton:
        break

  # Convert nodeMap to result
  for ci in 0 ..< nodeMap.len:
    var s = initHashSet[N]()
    for origIdx in nodeMap[ci]:
      s.incl(nodes[origIdx])
    result.add(s)
