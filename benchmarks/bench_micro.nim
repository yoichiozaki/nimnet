## NimNet Micro-Benchmark Suite
##
## Measures fine-grained graph operation performance across small (100),
## medium (1,000), and large (10,000) node graphs.
## Outputs results in CSV format for comparison with bench_micro_networkx.py.

import std/[strformat, tables]
import nimnet
import bench_common, bench_graphs

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

let benchRuns = benchmarkRuns()

template bench(body: untyped): float =
  medianTime(benchRuns):
    body

# ---------------------------------------------------------------------------
# Benchmark functions
# ---------------------------------------------------------------------------

proc benchNeighborIteration(g: Graph[int]): float =
  bench:
    var total = 0
    for node in g.nodes:
      for _ in g.neighbors(node):
        total += 1
    doAssert total > 0

proc benchWeightAccess(g: Graph[int]): float =
  bench:
    var total = 0.0
    for (u, v, attr) in g.edgesWithAttr:
      total += attr.getWeight()
    doAssert total > 0.0

proc benchHasEdge(g: Graph[int], n: int): float =
  let pairs = queryPairs(n)
  bench:
    var count = 0
    for (u, v) in pairs:
      if g.hasEdge(u, v):
        count += 1
    doAssert count >= 0

proc benchNodeIteration(g: Graph[int]): float =
  bench:
    var total = 0
    for _ in g.nodes:
      total += 1
    doAssert total > 0

proc benchEdgeIteration(g: Graph[int]): float =
  bench:
    var total = 0
    for _ in g.edges:
      total += 1
    doAssert total > 0

proc benchDegreeAccess(g: Graph[int]): float =
  bench:
    var total = 0
    for node in g.nodes:
      total += g.degree(node)
    doAssert total > 0

proc benchAddEdgeBulk(fixture: Fixture): float =
  bench:
    let g = buildFixture(fixture)
    doAssert g.numberOfNodes() == fixture.size.nodes
    doAssert g.numberOfEdges() == fixture.size.edges

proc benchGetEdgeAttr(g: Graph[int], fixture: Fixture): float =
  var edges: seq[(int, int)]
  for (u, v, _) in fixture.edges:
    edges.add((u, v))
  bench:
    var total = 0.0
    for (u, v) in edges:
      total += g.getEdgeAttr(u, v).getWeight()
    doAssert total > 0.0

# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

proc runMicroBenchmarks() =
  let fixtures = loadFixtures()
  echo "library,benchmark,size,nodes,edges,time_seconds"

  for fixture in fixtures:
    let (sizeName, n, m) = fixture.size
    let g = buildFixture(fixture, weighted = true)
    doAssert g.numberOfNodes() == n and g.numberOfEdges() == m

    let t1 = benchNeighborIteration(g)
    echo &"nimnet,neighbor_iteration,{sizeName},{n},{m},{t1:.6f}"

    let t2 = benchWeightAccess(g)
    echo &"nimnet,weight_access,{sizeName},{n},{m},{t2:.6f}"

    let t3 = benchHasEdge(g, n)
    echo &"nimnet,has_edge,{sizeName},{n},{m},{t3:.6f}"

    let t4 = benchNodeIteration(g)
    echo &"nimnet,node_iteration,{sizeName},{n},{m},{t4:.6f}"

    let t5 = benchEdgeIteration(g)
    echo &"nimnet,edge_iteration,{sizeName},{n},{m},{t5:.6f}"

    let t6 = benchDegreeAccess(g)
    echo &"nimnet,degree_access,{sizeName},{n},{m},{t6:.6f}"

    let t7 = benchAddEdgeBulk(fixture)
    echo &"nimnet,add_edge_bulk,{sizeName},{n},{m},{t7:.6f}"

    let t8 = benchGetEdgeAttr(g, fixture)
    echo &"nimnet,get_edge_attr,{sizeName},{n},{m},{t8:.6f}"

when isMainModule:
  runMicroBenchmarks()
