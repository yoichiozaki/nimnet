## NimNet Micro-Benchmark Suite
##
## Measures fundamental graph data structure operations independently,
## enabling identification of bottlenecks in adjacency-map internals,
## iterator overhead, and edge attribute access.
##
## Outputs results in CSV format matching the main benchmark suite.

import std/[times, strformat, random]
import nimnet

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

template bench(name: string, body: untyped): float =
  ## Run body and return elapsed time in seconds.
  let t0 = cpuTime()
  body
  let elapsed = cpuTime() - t0
  elapsed

proc buildErdosRenyi(n: int, m: int): Graph[int] =
  ## Build a random graph with n nodes and m edges.
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)
  var rng = initRand(42)
  var added = 0
  while added < m:
    let u = rng.rand(n - 1)
    let v = rng.rand(n - 1)
    if u != v and not result.hasEdge(u, v):
      result.addEdge(u, v)
      added += 1

proc buildWeightedErdosRenyi(n: int, m: int): Graph[int] =
  ## Build a random weighted graph with n nodes and m edges.
  result = newGraph[int]()
  for i in 0 ..< n:
    result.addNode(i)
  var rng = initRand(42)
  var added = 0
  while added < m:
    let u = rng.rand(n - 1)
    let v = rng.rand(n - 1)
    if u != v and not result.hasEdge(u, v):
      let w = rng.rand(1.0 .. 10.0)
      result.addWeightedEdge(u, v, w)
      added += 1

# ---------------------------------------------------------------------------
# Micro-benchmark functions
# ---------------------------------------------------------------------------

proc benchNeighborIteration(g: Graph[int]): float =
  ## How fast can we iterate g.neighbors(v) for all v?
  bench("neighbor_iteration"):
    var count = 0
    for node in g.nodes:
      for neighbor in g.neighbors(node):
        count.inc
    doAssert count > 0

proc benchWeightAccess(gw: Graph[int]): float =
  ## How fast can we access gw.weight(u, v) for all edges?
  bench("weight_access"):
    var total = 0.0
    for (u, v) in gw.edges:
      total += gw.weight(u, v)
    doAssert total > 0.0

proc benchHasEdge(g: Graph[int], n: int): float =
  ## How fast is g.hasEdge(u, v) for random (u,v) pairs?
  var rng = initRand(42)
  var pairs: seq[(int, int)]
  for _ in 0 ..< 100_000:
    pairs.add((rng.rand(n - 1), rng.rand(n - 1)))
  bench("has_edge"):
    var count = 0
    for (u, v) in pairs:
      if g.hasEdge(u, v):
        count.inc
    discard count

proc benchNodeIteration(g: Graph[int]): float =
  ## How fast can we iterate for n in g.nodes?
  bench("node_iteration"):
    var count = 0
    for node in g.nodes:
      count.inc
    doAssert count > 0

proc benchEdgeIteration(g: Graph[int]): float =
  ## How fast can we iterate for (u,v) in g.edges?
  bench("edge_iteration"):
    var count = 0
    for (u, v) in g.edges:
      count.inc
    doAssert count > 0

proc benchDegreeAccess(g: Graph[int]): float =
  ## How fast is g.degree(v) for all v?
  bench("degree_access"):
    var total = 0
    for node in g.nodes:
      total += g.degree(node)
    doAssert total > 0

proc benchAddEdgeBulk(n, m: int): float =
  ## How fast can we build a graph by adding edges?
  var rng = initRand(42)
  var edgePairs: seq[(int, int)]
  for _ in 0 ..< m:
    edgePairs.add((rng.rand(n - 1), rng.rand(n - 1)))
  bench("add_edge_bulk"):
    var g = newGraph[int]()
    for (u, v) in edgePairs:
      g.addEdge(u, v)
    doAssert g.numberOfNodes() > 0

proc benchGetEdgeAttr(gw: Graph[int]): float =
  ## How fast can we access the EdgeAttr for all edges?
  bench("get_edge_attr"):
    var count = 0
    for (u, v, attr) in gw.edgesWithAttr:
      if attr.getWeight() > 0.0:
        count.inc
    doAssert count > 0

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

proc main() =
  echo "library,benchmark,size,nodes,edges,time_seconds"

  let sizes = [(10_000, 50_000, "large"), (1_000, 5_000, "medium"), (100, 500, "small")]

  for (n, m, sizeName) in sizes:
    let g = buildErdosRenyi(n, m)
    let gw = buildWeightedErdosRenyi(n, m)

    let tNeighbor = benchNeighborIteration(g)
    echo &"nimnet_micro,neighbor_iteration,{sizeName},{n},{m},{tNeighbor:.6f}"

    let tWeight = benchWeightAccess(gw)
    echo &"nimnet_micro,weight_access,{sizeName},{n},{m},{tWeight:.6f}"

    let tHasEdge = benchHasEdge(g, n)
    echo &"nimnet_micro,has_edge,{sizeName},{n},{m},{tHasEdge:.6f}"

    let tNodes = benchNodeIteration(g)
    echo &"nimnet_micro,node_iteration,{sizeName},{n},{m},{tNodes:.6f}"

    let tEdges = benchEdgeIteration(g)
    echo &"nimnet_micro,edge_iteration,{sizeName},{n},{m},{tEdges:.6f}"

    let tDegree = benchDegreeAccess(g)
    echo &"nimnet_micro,degree_access,{sizeName},{n},{m},{tDegree:.6f}"

    let tAddEdge = benchAddEdgeBulk(n, m)
    echo &"nimnet_micro,add_edge_bulk,{sizeName},{n},{m},{tAddEdge:.6f}"

    let tGetAttr = benchGetEdgeAttr(gw)
    echo &"nimnet_micro,get_edge_attr,{sizeName},{n},{m},{tGetAttr:.6f}"

main()
