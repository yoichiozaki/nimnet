## Deterministic workloads for the library-improvement backlog.
## Compile with -d:release --opt:speed; BENCH_RUNS defaults to three.

import std/[sets, strformat, tables]
import nimnet
import bench_common

let runs = benchmarkRuns(default = 3)

template measure(body: untyped): float =
  medianTime(runs):
    body

proc report(name: string, n, m: int, elapsed: float) =
  echo &"nimnet,{name},n{n},{n},{m},{elapsed:.9f}"

proc communityGraph(n: int): Graph[int] =
  result = newGraph[int]()
  for u in 0 ..< n:
    result.addNode(u)
    for v in (u div 4) * 4 ..< u:
      result.addEdge(u, v)
  for group in 0 ..< n div 4:
    result.addEdge(group * 4, ((group + 1) * 4) mod n)

proc matchingGraph(n: int): Graph[int] =
  result = newGraph[int]()
  for u in 0 ..< n:
    for v in 0 .. u:
      result.addEdge(u, n + v)

proc sparseWeightedGraph(n: int): Graph[int] =
  result = newGraph[int]()
  for u in 0 ..< n:
    result.addWeightedEdge(u, (u + 1) mod n, 1.0)
    result.addWeightedEdge(u, (u + 7) mod n, 2.5)

echo "library,benchmark,size,nodes,edges,time_seconds"

for n in [32, 64, 128]:
  let g = communityGraph(n)
  let elapsed = measure:
    let communities = greedyModularityCommunities(g)
    doAssert communities.len > 0
  report("greedy_modularity", n, g.numberOfEdges(), elapsed)

for n in [128, 256, 512]:
  let g = matchingGraph(n)
  let elapsed = measure:
    let matching = maximumMatching(g)
    doAssert matching.len == n
  report("bipartite_matching", g.numberOfNodes(), g.numberOfEdges(), elapsed)

for n in [64, 128, 256]:
  let g = sparseWeightedGraph(n)
  let floydTime = measure:
    let distances = floydWarshall(g)
    doAssert distances.len == n and distances[0].len == n
    doAssert distances[0][n - 1] == 1.0
  report("floyd_warshall_sparse", n, g.numberOfEdges(), floydTime)
  when compiles(johnsons(g, includeUnreachable = true)):
    let johnsonTime = measure:
      let distances = johnsons(g, includeUnreachable = true)
      doAssert distances.len == n and distances[0].len == n
      doAssert distances[0][n - 1] == 1.0
    report("johnsons_sparse", n, g.numberOfEdges(), johnsonTime)

for n in [1_000, 5_000, 10_000]:
  let p = 4.0 / n.float
  var denseEdges = 0
  let denseTime = measure:
    let g = erdosRenyiGraph(n, p, seed = 42)
    doAssert g.numberOfNodes() == n
    denseEdges = g.numberOfEdges()
  report("gnp_dense", n, denseEdges, denseTime)
  when declared(fastGnpRandomGraph):
    var sparseEdges = 0
    let sparseTime = measure:
      let g = fastGnpRandomGraph(n, p, seed = 42)
      doAssert g.numberOfNodes() == n
      sparseEdges = g.numberOfEdges()
    report("gnp_sparse", n, sparseEdges, sparseTime)
