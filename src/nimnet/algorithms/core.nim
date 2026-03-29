## k-core decomposition
##
## Identifies dense subgraph regions through iterative degree pruning.

import std/[tables, sets, deques]
import ../types
import ../graph

proc coreNumber*[N](g: Graph[N]): Table[N, int] =
  ## Compute the core number of each node.
  ## The core number is the largest k such that the node belongs to the k-core.
  ## O(V + E) implementation.
  result = initTable[N, int]()
  if g.numberOfNodes() == 0:
    return

  # Initialize degrees
  var degrees = initTable[N, int]()
  var maxDeg = 0
  for n in g.nodes:
    let d = g.degree(n)
    degrees[n] = d
    if d > maxDeg:
      maxDeg = d

  # Bucket sort by degree
  var buckets = newSeq[seq[N]](maxDeg + 1)
  for i in 0 .. maxDeg:
    buckets[i] = @[]
  for n in g.nodes:
    buckets[degrees[n]].add(n)

  var processed = initHashSet[N]()

  # Process nodes in order of degree (ascending)
  for k in 0 .. maxDeg:
    while buckets[k].len > 0:
      let v = buckets[k].pop()
      if v in processed:
        continue
      processed.incl(v)
      result[v] = k
      for u in g.neighbors(v):
        if u notin processed:
          let oldDeg = degrees[u]
          if oldDeg > k:
            degrees[u] = oldDeg - 1
            buckets[oldDeg - 1].add(u)

proc kCore*[N](g: Graph[N], k: int): Graph[N] =
  ## Return the k-core subgraph: the maximal subgraph where every node
  ## has degree >= k within the subgraph.
  let cores = coreNumber(g)
  result = newGraph[N]()
  for n in g.nodes:
    if cores.getOrDefault(n, 0) >= k:
      result.addNode(n)
  for (u, v) in g.edges:
    if cores.getOrDefault(u, 0) >= k and cores.getOrDefault(v, 0) >= k:
      result.addEdge(u, v)

proc kShell*[N](g: Graph[N], k: int): Graph[N] =
  ## Return the k-shell: nodes with core number exactly k.
  let cores = coreNumber(g)
  result = newGraph[N]()
  for n in g.nodes:
    if cores.getOrDefault(n, 0) == k:
      result.addNode(n)
  for (u, v) in g.edges:
    if cores.getOrDefault(u, 0) == k and cores.getOrDefault(v, 0) == k:
      result.addEdge(u, v)

proc kCrust*[N](g: Graph[N], k: int): Graph[N] =
  ## Return the k-crust: nodes with core number <= k.
  let cores = coreNumber(g)
  result = newGraph[N]()
  for n in g.nodes:
    if cores.getOrDefault(n, 0) <= k:
      result.addNode(n)
  for (u, v) in g.edges:
    if cores.getOrDefault(u, 0) <= k and cores.getOrDefault(v, 0) <= k:
      result.addEdge(u, v)

proc kCorona*[N](g: Graph[N], k: int): Graph[N] =
  ## Return the k-corona: nodes in the k-core that have exactly k
  ## neighbors in the k-core.
  let cores = coreNumber(g)
  result = newGraph[N]()
  for n in g.nodes:
    if cores.getOrDefault(n, 0) >= k:
      var coreNeighbors = 0
      for u in g.neighbors(n):
        if cores.getOrDefault(u, 0) >= k:
          coreNeighbors += 1
      if coreNeighbors == k:
        result.addNode(n)
  for (u, v) in g.edges:
    if u in result and v in result:
      result.addEdge(u, v)

# =============================================================================
# k-Truss (#109)
# =============================================================================

proc kTruss*[N](g: Graph[N], k: int): Graph[N] =
  ## Return the k-truss of g: the maximal subgraph where every edge
  ## participates in at least (k-2) triangles.
  result = newGraph[N]()
  if k < 2:
    # Return entire graph for k < 2
    for n in g.nodes:
      result.addNode(n)
    for (u, v) in g.edges:
      result.addEdge(u, v)
    return
  # Build mutable edge set
  var adj = initTable[N, HashSet[N]]()
  for n in g.nodes:
    adj[n] = initHashSet[N]()
  for (u, v) in g.edges:
    adj[u].incl(v)
    adj[v].incl(u)
  # Iteratively remove edges with less than k-2 triangle support
  var changed = true
  while changed:
    changed = false
    var toRemove = newSeq[(N, N)]()
    for u in adj.keys:
      for v in adj[u]:
        if u < v:
          # Count triangles for edge (u, v)
          var triangles = 0
          for w in adj[u]:
            if w != v and w in adj[v]:
              triangles.inc
          if triangles < k - 2:
            toRemove.add((u, v))
    for (u, v) in toRemove:
      if v in adj.getOrDefault(u, initHashSet[N]()):
        adj[u].excl(v)
        adj[v].excl(u)
        changed = true
  for u in adj.keys:
    if adj[u].len > 0:
      result.addNode(u)
  for u in adj.keys:
    for v in adj[u]:
      if u < v:
        result.addEdge(u, v)

# =============================================================================
# Onion Decomposition (#109)
# =============================================================================

proc onionLayers*[N](g: Graph[N]): Table[N, int] =
  ## Compute the onion decomposition of the graph.
  ## Each node is assigned a layer number. Layer 1 is the outermost.
  result = initTable[N, int]()
  let n = g.numberOfNodes()
  if n == 0: return
  var deg = initTable[N, int]()
  var remaining = initHashSet[N]()
  for node in g.nodes:
    deg[node] = g.degree(node)
    remaining.incl(node)
  var layer = 0
  while remaining.len > 0:
    layer.inc
    # Find nodes with minimum degree in remaining subgraph
    var minDeg = int.high
    for node in remaining:
      if deg[node] < minDeg:
        minDeg = deg[node]
    var toRemove = newSeq[N]()
    for node in remaining:
      if deg[node] == minDeg:
        toRemove.add(node)
        result[node] = layer
    for node in toRemove:
      remaining.excl(node)
      for nbr in g.neighbors(node):
        if nbr in remaining:
          deg[nbr].dec
