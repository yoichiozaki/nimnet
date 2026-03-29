## Maximum flow algorithms

import std/[tables, sets, deques]
import ../types
import ../digraph

# =============================================================================
# Edmonds-Karp (BFS-based Ford-Fulkerson)
# =============================================================================

proc edmondsKarp*[N](g: DiGraph[N], source, sink: N): (float, Table[N, Table[N, float]]) =
  ## Compute maximum flow using Edmonds-Karp algorithm.
  ## Returns (max_flow_value, flow_dict).
  ## Uses "weight" edge attribute as capacity (default 1.0).
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(sink):
    raise newException(NodeNotFound, "Sink node not found")

  # Build residual capacity graph
  var residual = initTable[N, Table[N, float]]()
  for n in g.nodes:
    residual[n] = initTable[N, float]()
  for (u, v, attr) in g.edgesWithAttr:
    let cap = attr.getWeight()
    residual[u][v] = cap
    if v notin residual or u notin residual[v]:
      residual[v][u] = 0.0

  # Initialize flow
  var flow = initTable[N, Table[N, float]]()
  for n in g.nodes:
    flow[n] = initTable[N, float]()

  var totalFlow = 0.0

  while true:
    # BFS to find augmenting path
    var pred = initTable[N, N]()
    var visited = initHashSet[N]()
    visited.incl(source)
    var queue = initDeque[N]()
    queue.addLast(source)
    var found = false

    while queue.len > 0 and not found:
      let u = queue.popFirst()
      for v, cap in residual[u]:
        if v notin visited and cap > 0:
          visited.incl(v)
          pred[v] = u
          if v == sink:
            found = true
            break
          queue.addLast(v)

    if not found:
      break

    # Find bottleneck
    var bottleneck = Inf
    var v = sink
    while v != source:
      let u = pred[v]
      bottleneck = min(bottleneck, residual[u][v])
      v = u

    # Update residual and flow
    v = sink
    while v != source:
      let u = pred[v]
      residual[u][v] -= bottleneck
      if u notin residual[v]:
        residual[v][u] = 0.0
      residual[v][u] += bottleneck
      if v notin flow[u]:
        flow[u][v] = 0.0
      flow[u][v] += bottleneck
      v = u

    totalFlow += bottleneck

  result = (totalFlow, flow)

proc maximumFlowValue*[N](g: DiGraph[N], source, sink: N): float =
  ## Return the maximum flow value from source to sink.
  let (value, _) = edmondsKarp(g, source, sink)
  value

proc minimumCut*[N](g: DiGraph[N], source, sink: N): (float, HashSet[N], HashSet[N]) =
  ## Return minimum cut value and the two partitions.
  ## Uses max-flow min-cut theorem.
  if not g.hasNode(source):
    raise newException(NodeNotFound, "Source node not found")
  if not g.hasNode(sink):
    raise newException(NodeNotFound, "Sink node not found")

  # Build residual after max flow
  var residual = initTable[N, Table[N, float]]()
  for n in g.nodes:
    residual[n] = initTable[N, float]()
  for (u, v, attr) in g.edgesWithAttr:
    let cap = attr.getWeight()
    residual[u][v] = cap
    if v notin residual or u notin residual[v]:
      residual[v][u] = 0.0

  var totalFlow = 0.0
  while true:
    var pred = initTable[N, N]()
    var visited = initHashSet[N]()
    visited.incl(source)
    var queue = initDeque[N]()
    queue.addLast(source)
    var found = false
    while queue.len > 0 and not found:
      let u = queue.popFirst()
      for v, cap in residual[u]:
        if v notin visited and cap > 0:
          visited.incl(v)
          pred[v] = u
          if v == sink:
            found = true
            break
          queue.addLast(v)
    if not found:
      break
    var bottleneck = Inf
    var v = sink
    while v != source:
      let u = pred[v]
      bottleneck = min(bottleneck, residual[u][v])
      v = u
    v = sink
    while v != source:
      let u = pred[v]
      residual[u][v] -= bottleneck
      if u notin residual[v]:
        residual[v][u] = 0.0
      residual[v][u] += bottleneck
      v = u
    totalFlow += bottleneck

  # BFS on residual to find source-side of cut
  var sourceSet = initHashSet[N]()
  sourceSet.incl(source)
  var queue = initDeque[N]()
  queue.addLast(source)
  while queue.len > 0:
    let u = queue.popFirst()
    for v, cap in residual[u]:
      if v notin sourceSet and cap > 0:
        sourceSet.incl(v)
        queue.addLast(v)

  var sinkSet = initHashSet[N]()
  for n in g.nodes:
    if n notin sourceSet:
      sinkSet.incl(n)

  result = (totalFlow, sourceSet, sinkSet)
