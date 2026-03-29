## Community detection algorithms

import std/[tables, sets]
import ../types
import ../graph

# =============================================================================
# Modularity
# =============================================================================

proc modularity*[N](g: Graph[N], communities: seq[HashSet[N]]): float =
  ## Compute the modularity of a partition.
  ## Q = (1/2m) * sum_ij [ A_ij - k_i * k_j / (2m) ] * delta(c_i, c_j)
  let m = g.numberOfEdges()
  if m == 0:
    return 0.0
  let m2 = 2.0 * float(m)

  # Build community membership map
  var membership = initTable[N, int]()
  for i, comm in communities:
    for n in comm:
      membership[n] = i

  var q = 0.0
  for comm in communities:
    var lc = 0  # edges within community
    var dc = 0  # sum of degrees in community
    for u in comm:
      dc += g.degree(u)
      for v in g.neighbors(u):
        if v in comm:
          lc.inc
    lc = lc div 2  # each internal edge counted twice
    q += float(lc) / float(m) - (float(dc) / m2) * (float(dc) / m2)
  result = q

# =============================================================================
# Greedy modularity optimization
# =============================================================================

proc greedyModularityCommunities*[N](g: Graph[N]): seq[HashSet[N]] =
  ## Detect communities using greedy modularity optimization (CNM algorithm).
  ## Returns a partition of nodes into communities.
  if g.numberOfNodes() == 0:
    return @[]

  # Start with each node in its own community
  var communities: seq[HashSet[N]]
  var nodeToComm = initTable[N, int]()
  var idx = 0
  for n in g.nodes:
    var s = initHashSet[N]()
    s.incl(n)
    communities.add(s)
    nodeToComm[n] = idx
    idx.inc

  let m = g.numberOfEdges()
  if m == 0:
    return communities

  var bestQ = modularity(g, communities)

  # Iteratively merge communities that increase modularity the most
  var improved = true
  while improved and communities.len > 1:
    improved = false
    var bestDeltaQ = 0.0
    var bestI = -1
    var bestJ = -1

    # Find the merge that maximizes modularity gain
    for (u, v) in g.edges:
      let ci = nodeToComm[u]
      let cv = nodeToComm[v]
      if ci != cv:
        # Try merging ci and cv
        var merged = communities
        let lo = min(ci, cv)
        let hi = max(ci, cv)
        merged[lo] = merged[lo] + merged[hi]
        merged.delete(hi)
        let newQ = modularity(g, merged)
        let deltaQ = newQ - bestQ
        if deltaQ > bestDeltaQ:
          bestDeltaQ = deltaQ
          bestI = lo
          bestJ = hi

    if bestI >= 0 and bestDeltaQ > 0:
      # Merge
      communities[bestI] = communities[bestI] + communities[bestJ]
      communities.delete(bestJ)
      # Rebuild nodeToComm
      nodeToComm.clear()
      for i, comm in communities:
        for n in comm:
          nodeToComm[n] = i
      bestQ += bestDeltaQ
      improved = true

  result = communities

# =============================================================================
# Label propagation
# =============================================================================

proc labelPropagationCommunities*[N](g: Graph[N], maxIter: int = 100): seq[HashSet[N]] =
  ## Detect communities using label propagation algorithm.
  if g.numberOfNodes() == 0:
    return @[]

  # Initialize: each node gets its own label
  var labels = initTable[N, int]()
  var idx = 0
  for n in g.nodes:
    labels[n] = idx
    idx.inc

  var nodes = g.nodeSeq()

  for _ in 0 ..< maxIter:
    var changed = false
    for node in nodes:
      # Count labels of neighbors
      var labelCounts = initTable[int, int]()
      for neighbor in g.neighbors(node):
        let l = labels[neighbor]
        if l notin labelCounts:
          labelCounts[l] = 0
        labelCounts[l].inc

      if labelCounts.len > 0:
        # Find most common label
        var maxCount = 0
        var maxLabel = labels[node]
        for l, c in labelCounts:
          if c > maxCount:
            maxCount = c
            maxLabel = l
        if maxLabel != labels[node]:
          labels[node] = maxLabel
          changed = true

    if not changed:
      break

  # Group nodes by label
  var commMap = initTable[int, HashSet[N]]()
  for n, l in labels:
    if l notin commMap:
      commMap[l] = initHashSet[N]()
    commMap[l].incl(n)

  for comm in commMap.values:
    result.add(comm)
