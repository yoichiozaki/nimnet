## NimNet Micro-Benchmark Suite
##
## Measures fine-grained graph operation performance across small (100),
## medium (1,000), and large (10,000) node graphs.
## Outputs results in CSV format for comparison with bench_micro_networkx.py.

import std/[times, strformat, random, tables, algorithm, sequtils]
import nimnet

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

const benchRuns = 5  # Number of timed runs per benchmark

template bench(body: untyped): float =
  ## Run body multiple times and return the median elapsed time.
  # Warmup run (not timed)
  body
  var times: seq[float]
  for _ in 0 ..< benchRuns:
    let t0 = cpuTime()
    body
    let elapsed = cpuTime() - t0
    times.add(elapsed)
  times.sort()
  times[times.len div 2]  # median

proc buildGraph(n: int, seed: int = 42): Graph[int] =
  ## Build an Erdős-Rényi-like graph: n nodes, ~n*5 edges.
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  var rng = initRand(seed)
  let m = n * 5
  var added = 0
  while added < m:
    let u = rng.rand(n - 1)
    let v = rng.rand(n - 1)
    if u != v and not result.hasEdge(u, v):
      result.addWeightedEdge(u, v, rng.rand(1.0 .. 10.0))
      added += 1

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
  var rng = initRand(42)
  var pairs: seq[(int, int)]
  pairs.setLen(n * 5)
  for i in 0 ..< n * 5:
    pairs[i] = (rng.rand(n - 1), rng.rand(n - 1))
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

proc benchAddEdgeBulk(n: int): float =
  var rng = initRand(42)
  var edgePairs: seq[(int, int)]
  while edgePairs.len < n * 5:
    let u = rng.rand(n - 1)
    let v = rng.rand(n - 1)
    if u != v:
      edgePairs.add((u, v))
  bench:
    var g = newGraph[int](capacity = n)
    for i in 0 ..< n:
      g.addNode(i)
    for (u, v) in edgePairs:
      g.addEdge(u, v)
    doAssert g.numberOfNodes() == n

proc benchGetEdgeAttr(g: Graph[int]): float =
  let edges = g.edges.toSeq()
  bench:
    var total = 0.0
    for (u, v) in edges:
      total += g.getEdgeAttr(u, v).getWeight()
    doAssert total > 0.0

# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

proc runMicroBenchmarks() =
  echo "library,benchmark,size,nodes,edges,time_seconds"

  let sizes = [
    ("small",  100,    500),
    ("medium", 1_000,  5_000),
    ("large",  10_000, 50_000),
  ]

  for (sizeName, n, _) in sizes:
    let g = buildGraph(n)
    let m = g.numberOfEdges()

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

    let t7 = benchAddEdgeBulk(n)
    echo &"nimnet,add_edge_bulk,{sizeName},{n},{m},{t7:.6f}"

    let t8 = benchGetEdgeAttr(g)
    echo &"nimnet,get_edge_attr,{sizeName},{n},{m},{t8:.6f}"

when isMainModule:
  runMicroBenchmarks()
