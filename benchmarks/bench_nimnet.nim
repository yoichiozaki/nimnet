## NimNet Benchmark Suite
##
## Measures nimnet performance on common graph operations across
## small (100), medium (1,000), and large (10,000) graphs.
## Outputs results in CSV format for comparison.

import std/[strformat, tables, sets]
import nimnet
import bench_common
import bench_graphs

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

let benchRuns = benchmarkRuns()

template bench(name: string, body: untyped): float =
  medianTime(benchRuns):
    body

# ---------------------------------------------------------------------------
# Benchmark functions
# ---------------------------------------------------------------------------

proc benchGraphCreation(fixture: Fixture): float =
  ## Benchmark graph construction, excluding random generation and file I/O.
  bench("graph_creation"):
    let g = buildFixture(fixture)
    doAssert g.numberOfNodes() == fixture.size.nodes
    doAssert g.numberOfEdges() == fixture.size.edges

proc benchBFS(g: Graph[int]): float =
  ## Benchmark: BFS traversal from node 0.
  bench("bfs"):
    var count = 0
    for edge in bfsEdges(g, 0):
      count += 1
    doAssert count > 0

proc benchDFS(g: Graph[int]): float =
  ## Benchmark: DFS traversal from node 0.
  bench("dfs"):
    let nodes = dfsPreorderNodes(g, 0)
    doAssert nodes.len > 0

proc benchDijkstra(g: Graph[int], target: int): float =
  ## Benchmark: Dijkstra shortest path from 0 to target.
  bench("dijkstra"):
    let path = dijkstraPath(g, 0, target)
    doAssert path.len > 0

proc benchPageRank(g: Graph[int]): float =
  ## Benchmark: PageRank computation.
  bench("pagerank"):
    let pr = pageRank(g, alpha = 0.85, maxIter = 100, tol = 1e-6)
    doAssert pr.len == g.numberOfNodes()
    var total = 0.0
    for value in pr.values:
      doAssert value >= 0.0
      total += value
    doAssert abs(total - 1.0) < 1e-8

proc benchConnectedComponents(g: Graph[int]): float =
  ## Benchmark: find connected components.
  bench("connected_components"):
    let comps = connectedComponents(g)
    doAssert comps.len > 0

proc benchMSTKruskal(g: Graph[int]): float =
  ## Benchmark: Kruskal MST.
  bench("mst_kruskal"):
    let tree = kruskalMST(g)
    doAssert tree.len > 0

proc benchCommunityLouvain(g: Graph[int]): float =
  ## Benchmark: Louvain community detection.
  bench("louvain"):
    let communities = louvainCommunities(g, resolution = 1.0, seed = 42)
    doAssert communities.len > 0

proc benchClustering(g: Graph[int]): float =
  ## Benchmark: average clustering coefficient.
  bench("clustering"):
    let cc = averageClustering(g)
    discard cc

proc benchTriangleCount(g: Graph[int]): float =
  ## Benchmark: triangle counting.
  bench("triangles"):
    let t = trianglesMap(g)
    doAssert t.len > 0

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

proc runBenchmarks() =
  let fixtures = loadFixtures()
  echo "library,benchmark,size,nodes,edges,time_seconds"

  for fixture in fixtures:
    let (sizeName, n, m) = fixture.size
    # Graph creation
    let tCreate = benchGraphCreation(fixture)
    echo &"nimnet,graph_creation,{sizeName},{n},{m},{tCreate:.6f}"

    # Build graphs for other benchmarks
    let g = buildFixture(fixture)
    let gw = buildFixture(fixture, weighted = true)
    doAssert gw.numberOfNodes() == n and gw.numberOfEdges() == m
    for (u, v, weightMillis) in fixture.edges:
      doAssert gw.weight(u, v) == weightMillis.float / 1000.0

    # BFS
    let tBFS = benchBFS(g)
    echo &"nimnet,bfs,{sizeName},{n},{m},{tBFS:.6f}"

    # DFS
    let tDFS = benchDFS(g)
    echo &"nimnet,dfs,{sizeName},{n},{m},{tDFS:.6f}"

    # Dijkstra (shortest path to a node roughly n/2)
    let target = n div 2
    let tDijkstra = benchDijkstra(gw, target)
    echo &"nimnet,dijkstra,{sizeName},{n},{m},{tDijkstra:.6f}"

    # PageRank
    let tPR = benchPageRank(g)
    echo &"nimnet,pagerank,{sizeName},{n},{m},{tPR:.6f}"

    # Connected components
    let tCC = benchConnectedComponents(g)
    echo &"nimnet,connected_components,{sizeName},{n},{m},{tCC:.6f}"

    # MST (Kruskal)
    let tMST = benchMSTKruskal(gw)
    echo &"nimnet,mst_kruskal,{sizeName},{n},{m},{tMST:.6f}"

    # Louvain community detection
    let tLouv = benchCommunityLouvain(g)
    echo &"nimnet,louvain,{sizeName},{n},{m},{tLouv:.6f}"

    # Clustering coefficient
    let tClust = benchClustering(g)
    echo &"nimnet,clustering,{sizeName},{n},{m},{tClust:.6f}"

    # Triangle counting
    let tTri = benchTriangleCount(g)
    echo &"nimnet,triangles,{sizeName},{n},{m},{tTri:.6f}"

when isMainModule:
  runBenchmarks()
