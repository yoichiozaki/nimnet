## Graph efficiency measures
##
## Local and global efficiency based on shortest path lengths.

import std/[tables, deques]
import ../graph

proc globalEfficiency*[N](g: Graph[N]): float =
  ## Return the global efficiency of the graph.
  ## Global efficiency is the average inverse shortest path length
  ## over all pairs of distinct nodes.
  let n = g.numberOfNodes()
  if n <= 1:
    return 0.0
  var sumInv = 0.0
  for u in g.nodes:
    # BFS from u
    var dist = initTable[N, int]()
    dist[u] = 0
    var queue = initDeque[N]()
    queue.addLast(u)
    while queue.len > 0:
      let curr = queue.popFirst()
      for v in g.neighbors(curr):
        if v notin dist:
          dist[v] = dist[curr] + 1
          queue.addLast(v)
    for v in g.nodes:
      if v != u and v in dist and dist[v] > 0:
        sumInv += 1.0 / float(dist[v])
  result = sumInv / float(n * (n - 1))

proc localEfficiency*[N](g: Graph[N], node: N): float =
  ## Return the local efficiency of a node.
  ## This is the global efficiency of the subgraph induced by the
  ## neighbors of the node.
  var nbrs: seq[N]
  for v in g.neighbors(node):
    nbrs.add(v)
  let k = nbrs.len
  if k <= 1:
    return 0.0
  # Build neighbor set for fast lookup
  var nbrSet = initTable[N, bool]()
  for n in nbrs:
    nbrSet[n] = true
  # Compute efficiency over the subgraph induced by neighbors
  var sumInv = 0.0
  for i in 0 ..< k:
    let u = nbrs[i]
    # BFS within the neighbor subgraph
    var dist = initTable[N, int]()
    dist[u] = 0
    var queue = initDeque[N]()
    queue.addLast(u)
    while queue.len > 0:
      let curr = queue.popFirst()
      for v in g.neighbors(curr):
        if v in nbrSet and v notin dist:
          dist[v] = dist[curr] + 1
          queue.addLast(v)
    for j in 0 ..< k:
      let v = nbrs[j]
      if v != u and v in dist and dist[v] > 0:
        sumInv += 1.0 / float(dist[v])
  result = sumInv / float(k * (k - 1))

proc averageLocalEfficiency*[N](g: Graph[N]): float =
  ## Return the average local efficiency over all nodes.
  let n = g.numberOfNodes()
  if n == 0:
    return 0.0
  var total = 0.0
  for node in g.nodes:
    total += localEfficiency(g, node)
  result = total / float(n)
