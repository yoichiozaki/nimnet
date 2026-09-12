## Community detection algorithms

import std/[tables, sets, sequtils, deques, algorithm, random, heapqueue]
import ../types
import ../graph

# =============================================================================
# Modularity
# =============================================================================

proc modularity*[N](g: Graph[N], communities: seq[HashSet[N]]): float =
  ## Compute unweighted modularity for a partition of the graph's nodes.
  ## ``Q = sum_C [ L_C / m - (D_C / (2m))^2 ]``, where ``m`` is the edge count,
  ## ``L_C`` counts internal edges once (including self-loops), and ``D_C`` is the
  ## sum of degrees (self-loops contribute twice). All edge attributes,
  ## including weights, are ignored. Returns 0.0 when there are no edges.
  let m = g.numberOfEdges()
  if m == 0:
    return 0.0
  let m2 = 2.0 * float(m)

  for comm in communities:
    var internalEndpoints = 0
    var dc = 0
    for u in sets.items(comm):
      dc += g.degree(u)
      for v in g.neighbors(u):
        if sets.contains(comm, v):
          internalEndpoints += (if u == v: 2 else: 1)
    let fraction = float(dc) / m2
    result += float(internalEndpoints) / m2 - fraction * fraction

# =============================================================================
# Greedy modularity optimization
# =============================================================================

type ModularityMerge = tuple[
  priority: float, left, right, leftVersion, rightVersion: int]

proc queueModularityMerge(queue: var HeapQueue[ModularityMerge],
    left, right, count: int, degrees, versions: seq[int], m2: float) =
  let lo = min(left, right)
  let hi = max(left, right)
  # Compare the numerator of delta-Q, avoiding subtraction of whole Q values.
  let observed = m2 * float(count)
  let expected = float(degrees[lo]) * float(degrees[hi])
  let gain = observed - expected
  const Roundoff = 8.0 * 2.220446049250313e-16
  if gain > Roundoff * max(observed, expected):
    queue.push((-gain, lo, hi, versions[lo], versions[hi]))

proc modularityMergeHeap(links: seq[Table[int, int]], degrees,
    versions: seq[int], m2: float): HeapQueue[ModularityMerge] =
  for i in 0 ..< links.len:
    for j, count in tables.pairs(links[i]):
      if i < j:
        queueModularityMerge(result, i, j, count, degrees, versions, m2)

proc greedyModularityCommunities*[N](g: Graph[N]): seq[HashSet[N]] =
  ## Greedily maximize the same unweighted objective as ``modularity``.
  ## Weights are ignored; self-loops count once as edges and twice in degrees.
  ## Starting from singleton communities, merge the adjacent pair with greatest
  ## positive delta-Q, stopping when no gain exceeds floating-point roundoff.
  ## Ties use indices in ``g.nodeSeq()`` order, never comparisons of node values.
  ## Returns a valid partition, including singleton isolates; the empty graph
  ## returns an empty sequence. This is a heuristic, not a global optimum.
  ##
  ## Maintains inter-community edge counts and degree sums in a lazy heap.
  ## Only neighbors of a merged community are updated, without cloning
  ## partitions or reevaluating modularity per candidate. Worst-case time is
  ## O(V + VE log(V + 1)); auxiliary space is O(V + E).
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n == 0:
    return @[]

  let m = g.numberOfEdges()
  if m == 0:
    for node in nodes:
      var singleton = initHashSet[N]()
      sets.incl(singleton, node)
      result.add(singleton)
    return

  var nodeIndex = initTable[N, int](n)
  var degrees = newSeq[int](n)
  var parent = newSeq[int](n)
  var versions = newSeq[int](n)
  var links = newSeq[Table[int, int]](n)
  for i, node in nodes:
    nodeIndex[node] = i
    degrees[i] = g.degree(node)
    parent[i] = i
    links[i] = initTable[int, int]()

  var livePairs = 0
  for i, node in nodes:
    for neighbor in g.neighbors(node):
      let j = nodeIndex[neighbor]
      if i != j:
        links[i][j] = 1
        if i < j:
          livePairs.inc

  let m2 = 2.0 * float(m)
  var queue = modularityMergeHeap(links, degrees, versions, m2)
  while queue.len > 0:
    let candidate = queue.pop()
    let a = candidate.left
    let b = candidate.right
    if parent[a] != a or parent[b] != b or
        versions[a] != candidate.leftVersion or
        versions[b] != candidate.rightVersion:
      continue

    parent[b] = a
    degrees[a] += degrees[b]
    versions[a].inc
    links[a].del(b)
    links[b].del(a)
    livePairs.dec
    for neighbor, count in tables.pairs(links[b]):
      links[neighbor].del(b)
      if links[a].hasKey(neighbor):
        livePairs.dec
      let combined = links[a].getOrDefault(neighbor) + count
      links[a][neighbor] = combined
      links[neighbor][a] = combined
    links[b] = default(Table[int, int])

    for neighbor, count in tables.pairs(links[a]):
      queueModularityMerge(queue, a, neighbor, count, degrees, versions, m2)

    # Bound stale heap storage even for highly unbalanced merge sequences.
    if queue.len > 4 * livePairs:
      queue = modularityMergeHeap(links, degrees, versions, m2)

  var members = newSeq[HashSet[N]](n)
  for i in 0 ..< n:
    if parent[i] == i:
      members[i] = initHashSet[N]()
  for i, node in nodes:
    var root = i
    while parent[root] != root:
      root = parent[root]
    var current = i
    while parent[current] != root:
      let next = parent[current]
      parent[current] = root
      current = next
    sets.incl(members[root], node)
  for i in 0 ..< n:
    if parent[i] == i:
      result.add(members[i])

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
