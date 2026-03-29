## Connectivity and resilience analysis
##
## Node connectivity, edge connectivity, minimum cuts,
## and resilience measures for graphs.

import std/[tables, sets, deques]
import ../types
import ../graph
import ../digraph
import ./components
import ./flow

proc nodeConnectivity*[N](g: Graph[N]): int =
  ## Return the node connectivity of the graph.
  ## The minimum number of nodes that must be removed to disconnect the graph.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    return 0
  if not isConnected(g):
    return 0

  result = n  # upper bound

  # Transform to directed flow network
  # For each pair (s,t), find min node cut using max-flow
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let s = nodes[i]
      let t = nodes[j]

      # Build auxiliary digraph: split each node v into v_in, v_out
      # with capacity 1 edge between them (except s and t)
      # Use node-splitting: map node v to (2*index, 2*index+1)
      var nodeIdx = initTable[N, int]()
      for k, v in nodes:
        nodeIdx[v] = k

      var dg = newDiGraph[int]()
      for k, v in nodes:
        let vin = 2 * k
        let vout = 2 * k + 1
        if v == s or v == t:
          dg.addWeightedEdge(vin, vout, float(n))
        else:
          dg.addWeightedEdge(vin, vout, 1.0)

      for (u, v) in g.edges:
        let ui = nodeIdx[u]
        let vi = nodeIdx[v]
        dg.addWeightedEdge(2 * ui + 1, 2 * vi, float(n))
        dg.addWeightedEdge(2 * vi + 1, 2 * ui, float(n))

      let si = nodeIdx[s]
      let ti = nodeIdx[t]
      let flowVal = maximumFlowValue(dg, 2 * si + 1, 2 * ti)
      let conn = int(flowVal)
      if conn < result:
        result = conn

proc edgeConnectivity*[N](g: Graph[N]): int =
  ## Return the edge connectivity of the graph.
  ## The minimum number of edges that must be removed to disconnect the graph.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    return 0
  if not isConnected(g):
    return 0

  # Build directed version and find min cut
  var dg = newDiGraph[N]()
  for (u, v) in g.edges:
    dg.addWeightedEdge(u, v, 1.0)
    dg.addWeightedEdge(v, u, 1.0)

  result = g.numberOfEdges()  # upper bound
  let source = nodes[0]
  for i in 1 ..< n:
    let flowVal = maximumFlowValue(dg, source, nodes[i])
    let conn = int(flowVal)
    if conn < result:
      result = conn

proc minimumNodeCut*[N](g: Graph[N]): HashSet[N] =
  ## Return a minimum node cut set.
  ## Removing these nodes disconnects the graph.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    return initHashSet[N]()
  if not isConnected(g):
    return initHashSet[N]()

  var bestCut = initHashSet[N]()
  var bestSize = n

  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let s = nodes[i]
      let t = nodes[j]

      var nodeIdx = initTable[N, int]()
      for k, v in nodes:
        nodeIdx[v] = k

      var dg = newDiGraph[int]()
      for k, v in nodes:
        let vin = 2 * k
        let vout = 2 * k + 1
        if v == s or v == t:
          dg.addWeightedEdge(vin, vout, float(n))
        else:
          dg.addWeightedEdge(vin, vout, 1.0)

      for (u, v) in g.edges:
        let ui = nodeIdx[u]
        let vi = nodeIdx[v]
        dg.addWeightedEdge(2 * ui + 1, 2 * vi, float(n))
        dg.addWeightedEdge(2 * vi + 1, 2 * ui, float(n))

      let si = nodeIdx[s]
      let ti = nodeIdx[t]
      let (flowVal, sSet, _) = minimumCut(dg, 2 * si + 1, 2 * ti)
      let cutSize = int(flowVal)

      if cutSize < bestSize:
        bestSize = cutSize
        bestCut = initHashSet[N]()
        for k, v in nodes:
          if v != s and v != t:
            let vin = 2 * k
            let vout = 2 * k + 1
            if vin in sSet and vout notin sSet:
              bestCut.incl(v)

  result = bestCut

proc minimumEdgeCut*[N](g: Graph[N]): seq[(N, N)] =
  ## Return a minimum edge cut (set of edges whose removal disconnects the graph).
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    return @[]
  if not isConnected(g):
    return @[]

  var dg = newDiGraph[N]()
  for (u, v) in g.edges:
    dg.addWeightedEdge(u, v, 1.0)
    dg.addWeightedEdge(v, u, 1.0)

  var bestFlow = float(g.numberOfEdges())
  var bestSource = nodes[0]
  var bestTarget = nodes[1]

  let source = nodes[0]
  for i in 1 ..< n:
    let flowVal = maximumFlowValue(dg, source, nodes[i])
    if flowVal < bestFlow:
      bestFlow = flowVal
      bestSource = source
      bestTarget = nodes[i]

  let (_, sSet, tSet) = minimumCut(dg, bestSource, bestTarget)
  for (u, v) in g.edges:
    if (u in sSet and v in tSet) or (v in sSet and u in tSet):
      result.add((u, v))

proc averageNodeConnectivity*[N](g: Graph[N]): float =
  ## Return the average pairwise node connectivity.
  let nodes = g.nodeSeq()
  let n = nodes.len
  if n <= 1:
    return 0.0

  var total = 0.0
  var count = 0

  var dg = newDiGraph[N]()
  for (u, v) in g.edges:
    dg.addWeightedEdge(u, v, 1.0)
    dg.addWeightedEdge(v, u, 1.0)

  for i in 0 ..< n:
    for j in i + 1 ..< n:
      let flowVal = maximumFlowValue(dg, nodes[i], nodes[j])
      total += flowVal
      count += 1

  result = if count > 0: total / count.float else: 0.0
