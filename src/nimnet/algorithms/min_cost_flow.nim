## Minimum cost flow algorithm
##
## Successive shortest path algorithm for minimum cost flow problems.

import std/[tables, sets, deques, heapqueue, strutils]
import ../types
import ../digraph

proc minimumCostFlow*[N](g: DiGraph[N], demand: Table[N, float]): (float, Table[N, Table[N, float]]) =
  ## Solve minimum cost flow problem.
  ## Each edge has capacity (weight attribute) and cost (cost attribute if present, else 1.0).
  ## `demand` maps nodes to their demand: positive = supply, negative = demand.
  ## Returns (total_cost, flow) where flow[u][v] is the flow on edge (u, v).

  # Build residual network
  var capacity = initTable[N, Table[N, float]]()
  var cost = initTable[N, Table[N, float]]()
  var flow = initTable[N, Table[N, float]]()

  let nodes = g.nodeSeq()
  for u in nodes:
    capacity[u] = initTable[N, float]()
    cost[u] = initTable[N, float]()
    flow[u] = initTable[N, float]()

  for (u, v) in g.edges:
    let attrs = g.getEdgeAttr(u, v)
    let cap = attrs.getWeight(default = Inf)
    let c = if "cost" in attrs: parseFloat(attrs["cost"]) else: 1.0
    capacity[u][v] = cap
    cost[u][v] = c
    flow[u][v] = 0.0
    # Reverse edge for residual
    if v notin capacity: capacity[v] = initTable[N, float]()
    if u notin cost[v]: cost[v][u] = -c
    if v notin flow: flow[v] = initTable[N, float]()
    if u notin flow[v]: flow[v][u] = 0.0
    if u notin capacity[v]: capacity[v][u] = 0.0

  # Find successive shortest paths from supply to demand nodes
  var totalCost = 0.0

  # Find supply and demand nodes
  var supplyNodes: seq[N] = @[]
  var demandNodes: seq[N] = @[]
  for n, d in demand:
    if d > 0: supplyNodes.add(n)
    elif d < 0: demandNodes.add(n)

  var remainingSupply = initTable[N, float]()
  var remainingDemand = initTable[N, float]()
  for n in supplyNodes:
    remainingSupply[n] = demand[n]
  for n in demandNodes:
    remainingDemand[n] = -demand[n]  # store as positive

  type SPEntry = tuple[dist: float, node: N]

  proc findShortestAugPath(source, sink: N): (float, seq[N]) =
    # Dijkstra on residual graph with Bellman-Ford potential
    var dist = initTable[N, float]()
    var pred = initTable[N, N]()

    # Use SPFA (Bellman-Ford variant)
    dist[source] = 0.0
    var inQueue = initHashSet[N]()
    var queue = initDeque[N]()
    queue.addLast(source)
    inQueue.incl(source)

    while queue.len > 0:
      let u = queue.popFirst()
      inQueue.excl(u)

      for v in nodes:
        let resCap = capacity.getOrDefault(u, initTable[N, float]()).getOrDefault(v, 0.0) -
                     flow.getOrDefault(u, initTable[N, float]()).getOrDefault(v, 0.0)
        if resCap > 1e-10:
          let c = cost.getOrDefault(u, initTable[N, float]()).getOrDefault(v, 0.0)
          let newDist = dist[u] + c
          if v notin dist or newDist < dist[v] - 1e-10:
            dist[v] = newDist
            pred[v] = u
            if v notin inQueue:
              queue.addLast(v)
              inQueue.incl(v)

    if sink notin dist:
      return (0.0, @[])

    # Reconstruct path
    var path: seq[N] = @[sink]
    var curr = sink
    while curr != source:
      curr = pred[curr]
      path.insert(curr, 0)

    # Find bottleneck capacity
    var bottleneck = Inf
    for i in 0 ..< path.len - 1:
      let u = path[i]
      let v = path[i + 1]
      let resCap = capacity.getOrDefault(u, initTable[N, float]()).getOrDefault(v, 0.0) -
                   flow.getOrDefault(u, initTable[N, float]()).getOrDefault(v, 0.0)
      if resCap < bottleneck:
        bottleneck = resCap

    return (bottleneck, path)

  # Send flow along shortest augmenting paths
  for s in supplyNodes:
    for t in demandNodes:
      while remainingSupply.getOrDefault(s, 0.0) > 1e-10 and remainingDemand.getOrDefault(t, 0.0) > 1e-10:
        let (bottleneck, path) = findShortestAugPath(s, t)
        if path.len == 0 or bottleneck < 1e-10:
          break
        let sendFlow = min(min(bottleneck, remainingSupply[s]), remainingDemand[t])
        # Augment flow
        for i in 0 ..< path.len - 1:
          let u = path[i]
          let v = path[i + 1]
          flow[u][v] = flow[u].getOrDefault(v, 0.0) + sendFlow
          flow[v][u] = flow[v].getOrDefault(u, 0.0) - sendFlow
          totalCost += sendFlow * cost[u].getOrDefault(v, 0.0)

        remainingSupply[s] = remainingSupply[s] - sendFlow
        remainingDemand[t] = remainingDemand[t] - sendFlow

  # Clean up: only return positive flow on original edges
  var resultFlow = initTable[N, Table[N, float]]()
  for (u, v) in g.edges:
    let f = flow[u].getOrDefault(v, 0.0)
    if f > 1e-10:
      if u notin resultFlow:
        resultFlow[u] = initTable[N, float]()
      resultFlow[u][v] = f

  result = (totalCost, resultFlow)
