## Community detection algorithms

import std/[tables, sets, sequtils, deques, algorithm, random]
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

# =============================================================================
# Extended Community Detection (#123)
# =============================================================================

proc girvanNewmanStep[N](g: Graph[N]): (N, N) =
  ## Find the edge with highest betweenness and return it.
  var bestEdge: (N, N)
  var bestBC = -1.0
  for source in g.nodes:
    var stack = newSeq[N]()
    var pred = initTable[N, seq[N]]()
    var sigma = initTable[N, float]()
    var dist = initTable[N, int]()
    for node in g.nodes:
      pred[node] = newSeq[N]()
      sigma[node] = 0.0
      dist[node] = -1
    sigma[source] = 1.0
    dist[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for w in g.neighbors(v):
        if dist[w] < 0:
          queue.addLast(w)
          dist[w] = dist[v] + 1
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          pred[w].add(v)
    var delta = initTable[N, float]()
    for node in g.nodes:
      delta[node] = 0.0
    for i in countdown(stack.len - 1, 0):
      let w = stack[i]
      let coeff = (1.0 + delta[w]) / sigma[w]
      for v in pred[w]:
        let c = sigma[v] * coeff
        # Track edge betweenness
        let edgeBC = c
        if edgeBC > bestBC:
          bestBC = edgeBC
          bestEdge = (v, w)
        delta[v] += c
  bestEdge

proc girvanNewman*[N](g: Graph[N], k: int = 2): seq[HashSet[N]] =
  ## Detect communities using the Girvan-Newman algorithm.
  ## Iteratively removes edges with highest betweenness centrality.
  ## Returns partition into k communities.
  var h = newGraph[N]()
  for n in g.nodes:
    h.addNode(n)
  for (u, v) in g.edges:
    h.addEdge(u, v, g[u, v])
  while true:
    # Count connected components
    var visited = initHashSet[N]()
    var components = newSeq[HashSet[N]]()
    for node in h.nodes:
      if node notin visited:
        var comp = initHashSet[N]()
        var queue = initDeque[N]()
        queue.addLast(node)
        visited.incl(node)
        while queue.len > 0:
          let u = queue.popFirst()
          comp.incl(u)
          for v in h.neighbors(u):
            if v notin visited:
              visited.incl(v)
              queue.addLast(v)
        components.add(comp)
    if components.len >= k:
      return components
    if h.numberOfEdges() == 0:
      return components
    # Remove edge with highest betweenness
    let (u, v) = girvanNewmanStep(h)
    if h.hasEdge(u, v):
      h.removeEdge(u, v)

proc kernighanLinBisection*[N](g: Graph[N]): (HashSet[N], HashSet[N]) =
  ## Bisect the graph using the Kernighan-Lin algorithm.
  ## Returns two approximately equal-sized partitions.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    var s1 = nodes.toHashSet()
    return (s1, initHashSet[N]())
  # Initial partition: split in half
  var a = initHashSet[N]()
  var b = initHashSet[N]()
  for i in 0 ..< n:
    if i < n div 2:
      a.incl(nodes[i])
    else:
      b.incl(nodes[i])
  # KL iterations
  for _ in 0 ..< 10:
    var locked = initHashSet[N]()
    var improved = false
    for _ in 0 ..< min(a.len, b.len):
      var bestGain = -Inf
      var bestA, bestB: N
      for na in a:
        if na in locked: continue
        for nb in b:
          if nb in locked: continue
          # Compute gain of swapping na and nb
          var gain = 0.0
          for nbr in g.neighbors(na):
            if nbr in b: gain += g[na, nbr].getWeight()
            elif nbr in a and nbr != na: gain -= g[na, nbr].getWeight()
          for nbr in g.neighbors(nb):
            if nbr in a: gain += g[nb, nbr].getWeight()
            elif nbr in b and nbr != nb: gain -= g[nb, nbr].getWeight()
          if g.hasEdge(na, nb):
            gain -= 2.0 * g[na, nb].getWeight()
          if gain > bestGain:
            bestGain = gain
            bestA = na
            bestB = nb
      if bestGain <= 0.0: break
      a.excl(bestA); a.incl(bestB)
      b.excl(bestB); b.incl(bestA)
      locked.incl(bestA)
      locked.incl(bestB)
      improved = true
    if not improved: break
  result = (a, b)

proc fluidCommunities*[N](g: Graph[N], k: int, seed: int = 0): seq[HashSet[N]] =
  ## Detect communities using the Fluid Communities algorithm.
  ## k is the number of communities to find.
  let n = g.numberOfNodes()
  if n == 0 or k <= 0: return @[]
  var rng = if seed != 0: initRand(seed) else: initRand()
  # Initialize: pick k random seed nodes
  var nodes = g.nodeSeq()
  rng.shuffle(nodes)
  var label = initTable[N, int]()
  var density = newSeq[float](k)
  for i in 0 ..< min(k, n):
    label[nodes[i]] = i
    density[i] = 1.0
  # Propagate
  for _ in 0 ..< 100:
    var changed = false
    rng.shuffle(nodes)
    for node in nodes:
      if g.degree(node) == 0: continue
      var votes = newSeq[float](k)
      for nbr in g.neighbors(node):
        if nbr in label:
          let l = label[nbr]
          votes[l] += 1.0 / density[l]
      var bestLabel = label.getOrDefault(node, 0)
      var bestVote = -1.0
      for l in 0 ..< k:
        if votes[l] > bestVote:
          bestVote = votes[l]
          bestLabel = l
      if node notin label or label[node] != bestLabel:
        label[node] = bestLabel
        changed = true
    # Update density
    for i in 0 ..< k:
      density[i] = 0.0
    for _, l in label:
      density[l] += 1.0
    for i in 0 ..< k:
      if density[i] == 0.0: density[i] = 1.0
    if not changed: break
  var comNodes = newSeq[HashSet[N]](k)
  for i in 0 ..< k:
    comNodes[i] = initHashSet[N]()
  for node, l in label:
    comNodes[l].incl(node)
  for s in comNodes:
    if s.len > 0:
      result.add(s)

proc coverage*[N](g: Graph[N], communities: seq[HashSet[N]]): float =
  ## Compute the coverage of a partition.
  ## Fraction of edges within communities.
  let m = g.numberOfEdges()
  if m == 0: return 0.0
  var intraCom = 0
  for comm in communities:
    for (u, v) in g.edges:
      if u in comm and v in comm:
        intraCom.inc
  result = float(intraCom) / float(m)

proc performance*[N](g: Graph[N], communities: seq[HashSet[N]]): float =
  ## Compute the performance of a partition.
  ## Fraction of node pairs correctly classified (intra-community edges +
  ## inter-community non-edges) / total possible pairs.
  let n = g.numberOfNodes()
  if n <= 1: return 1.0
  var correct = 0
  let nodes = g.nodeSeq()
  for i in 0 ..< nodes.len:
    for j in i + 1 ..< nodes.len:
      let sameComm = block:
        var same = false
        for comm in communities:
          if nodes[i] in comm and nodes[j] in comm:
            same = true
            break
        same
      let hasEdge = g.hasEdge(nodes[i], nodes[j])
      if (sameComm and hasEdge) or (not sameComm and not hasEdge):
        correct.inc
  result = float(correct) / float(n * (n - 1) div 2)

proc isPartition*[N](g: Graph[N], communities: seq[HashSet[N]]): bool =
  ## Check if communities form a valid partition of the graph's nodes.
  var allNodes = initHashSet[N]()
  for comm in communities:
    for n in comm:
      if n in allNodes: return false  # Duplicate
      allNodes.incl(n)
  for n in g.nodes:
    if n notin allNodes: return false  # Missing
  result = true
