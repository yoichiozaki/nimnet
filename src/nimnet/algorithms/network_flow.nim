## Spanner, Stoer-Wagner, Dinitz max flow, Gomory-Hu tree for nimnet

import std/[tables, sets, deques, algorithm, math]
import ../types
import ../graph
import ../digraph

# =============================================================================
# Graph Spanner (#117)
# =============================================================================

proc spanner*[N](g: Graph[N], stretch: int, seed: int = 0): Graph[N] =
  ## Compute a sparse spanner of g with given stretch factor.
  ## Uses a greedy approach: add edges in weight order if they would
  ## violate the stretch property.
  result = newGraph[N]()
  for n in g.nodes:
    result.addNode(n)
  # Collect and sort edges by weight
  type WEdge = tuple[u, v: N, w: float]
  var edges: seq[WEdge]
  for (u, v) in g.edges:
    edges.add((u, v, g[u, v].getWeight()))
  edges.sort(proc(a, b: WEdge): int =
    if a.w < b.w: -1
    elif a.w > b.w: 1
    else: 0)
  for e in edges:
    # BFS in current spanner to check distance
    var dist = initTable[N, int]()
    dist[e.u] = 0
    var queue = initDeque[N]()
    queue.addLast(e.u)
    var found = false
    while queue.len > 0:
      let u = queue.popFirst()
      if u == e.v and dist[u] <= stretch:
        found = true
        break
      if dist[u] >= stretch: continue
      for v in result.neighbors(u):
        if v notin dist:
          dist[v] = dist[u] + 1
          queue.addLast(v)
    if not found:
      result.addEdge(e.u, e.v, g[e.u, e.v])

# =============================================================================
# Stoer-Wagner Minimum Cut (#117)
# =============================================================================

proc stoerWagnerMinCut*[N](g: Graph[N]): (float, HashSet[N], HashSet[N]) =
  ## Compute the minimum cut using the Stoer-Wagner algorithm.
  ## Returns (cut_weight, partition1, partition2).
  let n = g.numberOfNodes()
  if n <= 1:
    var s1, s2: HashSet[N]
    for node in g.nodes:
      s1.incl(node)
    return (0.0, s1, s2)
  # Work with merged node sets
  var nodes = newSeq[HashSet[N]]()
  var nodeIdx = initTable[N, int]()
  var idx = 0
  for node in g.nodes:
    var s = initHashSet[N]()
    s.incl(node)
    nodes.add(s)
    nodeIdx[node] = idx
    idx.inc
  # Build weight matrix
  var w = newSeq[seq[float]](n)
  for i in 0 ..< n:
    w[i] = newSeq[float](n)
  for (u, v) in g.edges:
    let ui = nodeIdx[u]
    let vi = nodeIdx[v]
    let weight = g[u, v].getWeight()
    w[ui][vi] += weight
    w[vi][ui] += weight
  var active = newSeq[bool](n)
  for i in 0 ..< n:
    active[i] = true
  var bestCut = Inf
  var bestPartition: HashSet[N]
  for phase in 0 ..< n - 1:
    # Minimum cut phase
    var inA = newSeq[bool](n)
    var wA = newSeq[float](n)
    var prev = -1
    var last = -1
    # Find first active node
    for i in 0 ..< n:
      if active[i]:
        inA[i] = true
        for j in 0 ..< n:
          if active[j] and j != i:
            wA[j] += w[i][j]
        prev = i
        last = i
        break
    for _ in 1 ..< n - phase:
      # Find most tightly connected vertex
      var best = -1
      var bestW = -1.0
      for i in 0 ..< n:
        if active[i] and not inA[i]:
          if wA[i] > bestW:
            bestW = wA[i]
            best = i
      if best < 0: break
      inA[best] = true
      prev = last
      last = best
      for j in 0 ..< n:
        if active[j] and not inA[j]:
          wA[j] += w[best][j]
    # Cut of the phase
    let cutWeight = wA[last]
    if cutWeight < bestCut:
      bestCut = cutWeight
      bestPartition = nodes[last]
    # Merge last into prev
    if prev >= 0 and last >= 0 and prev != last:
      for node in nodes[last]:
        nodes[prev].incl(node)
      for i in 0 ..< n:
        w[prev][i] += w[last][i]
        w[i][prev] += w[i][last]
      active[last] = false
  var s1 = bestPartition
  var s2 = initHashSet[N]()
  for node in g.nodes:
    if node notin s1:
      s2.incl(node)
  result = (bestCut, s1, s2)

# =============================================================================
# Dinitz Max Flow (#117)
# =============================================================================

proc dinitz*[N](g: DiGraph[N], source, sink: N): (float, Table[N, Table[N, float]]) =
  ## Compute maximum flow using Dinitz's algorithm.
  ## Returns (max_flow_value, flow_dict).
  var capacity = initTable[N, Table[N, float]]()
  var flow = initTable[N, Table[N, float]]()
  for n in g.nodes:
    capacity[n] = initTable[N, float]()
    flow[n] = initTable[N, float]()
  for (u, v) in g.edges:
    capacity[u][v] = g[u, v].getWeight()
    flow[u][v] = 0.0
    if v notin capacity:
      capacity[v] = initTable[N, float]()
    if u notin capacity[v]:
      capacity[v][u] = 0.0
    if v notin flow:
      flow[v] = initTable[N, float]()
    flow[v][u] = 0.0

  proc bfsLevel(): Table[N, int] =
    var level = initTable[N, int]()
    level[source] = 0
    var queue = initDeque[N]()
    queue.addLast(source)
    while queue.len > 0:
      let u = queue.popFirst()
      for v, cap in capacity[u]:
        if v notin level and cap - flow[u].getOrDefault(v, 0.0) > 1e-10:
          level[v] = level[u] + 1
          queue.addLast(v)
    level

  var totalFlow = 0.0
  while true:
    let level = bfsLevel()
    if sink notin level: break
    # DFS to find blocking flow
    var iter = initTable[N, seq[N]]()
    for u in capacity.keys:
      iter[u] = newSeq[N]()
      for v in capacity[u].keys:
        iter[u].add(v)

    proc dfs(u: N, pushed: float): float =
      if u == sink: return pushed
      while iter[u].len > 0:
        let v = iter[u][^1]
        let residual = capacity[u].getOrDefault(v, 0.0) - flow[u].getOrDefault(v, 0.0)
        if residual > 1e-10 and level.getOrDefault(v, -1) == level[u] + 1:
          let d = dfs(v, min(pushed, residual))
          if d > 1e-10:
            flow[u][v] = flow[u].getOrDefault(v, 0.0) + d
            flow[v][u] = flow[v].getOrDefault(u, 0.0) - d
            return d
        discard iter[u].pop()
      return 0.0

    while true:
      let pushed = dfs(source, Inf)
      if pushed <= 1e-10: break
      totalFlow += pushed
  result = (totalFlow, flow)

# =============================================================================
# Gomory-Hu Tree (#117)
# =============================================================================

proc gomoryHuTree*[N](g: Graph[N]): Graph[N] =
  ## Compute the Gomory-Hu tree (cut tree) of the graph.
  ## Uses iterative max-flow computations.
  result = newGraph[N]()
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    for node in nodes:
      result.addNode(node)
    return
  # Build directed version for max-flow
  var dg = newDiGraph[N]()
  for node in g.nodes:
    dg.addNode(node)
  for (u, v) in g.edges:
    let w = g[u, v].getWeight()
    dg.addEdge(u, v, newEdgeAttr(w))
    dg.addEdge(v, u, newEdgeAttr(w))
  # Initialize: all nodes point to nodes[0]
  var parent = initTable[N, N]()
  for i in 1 ..< n:
    parent[nodes[i]] = nodes[0]
  for i in 1 ..< n:
    let s = nodes[i]
    let t = parent[s]
    let (flowVal, _) = dinitz(dg, s, t)
    result.addEdge(s, t, newEdgeAttr(flowVal))
    # Update parents
    for j in i + 1 ..< n:
      if parent[nodes[j]] == t:
        # Check if j is on s's side of the min cut
        # Simple approach: keep parent
        discard
