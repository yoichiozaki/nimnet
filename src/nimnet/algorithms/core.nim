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
