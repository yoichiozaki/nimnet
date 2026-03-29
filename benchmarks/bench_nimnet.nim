## NimNet Benchmark Suite
##
## Measures nimnet performance on common graph operations across
## small (100), medium (10,000), and large (1,000,000) graphs.
## Outputs results in CSV format for comparison.

import std/[times, strformat, strutils, random, tables, sets, os]

# Use relative path for nimble or direct compilation
when defined(benchDirect):
  import nimnet
else:
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
  ## Build a random graph with n nodes and m edges (fast, no duplicate check).
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
  ## Build a random weighted graph.
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
# Benchmark functions
# ---------------------------------------------------------------------------

proc benchGraphCreation(n: int, m: int): float =
  ## Benchmark: create graph with n nodes, m edges.
  bench("graph_creation"):
    let g = buildErdosRenyi(n, m)
    doAssert g.numberOfNodes() == n

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
    let pr = pageRank(g)
    doAssert pr.len > 0

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
    let communities = louvainCommunities(g)
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

type BenchSize = tuple[name: string, nodes: int, edges: int]

proc runBenchmarks() =
  let sizes: seq[BenchSize] = @[
    ("small", 100, 500),
    ("medium", 1_000, 5_000),
    ("large", 10_000, 50_000),
  ]

  echo "library,benchmark,size,nodes,edges,time_seconds"

  for (sizeName, n, m) in sizes:
    # Graph creation
    let tCreate = benchGraphCreation(n, m)
    echo &"nimnet,graph_creation,{sizeName},{n},{m},{tCreate:.6f}"

    # Build graphs for other benchmarks
    let g = buildErdosRenyi(n, m)
    let gw = buildWeightedErdosRenyi(n, m)

    # BFS
    let tBFS = benchBFS(g)
    echo &"nimnet,bfs,{sizeName},{n},{m},{tBFS:.6f}"

    # DFS
    let tDFS = benchDFS(g)
    echo &"nimnet,dfs,{sizeName},{n},{m},{tDFS:.6f}"

    # Dijkstra (shortest path to a node roughly n/2)
    let target = n div 2
    try:
      let tDijkstra = benchDijkstra(gw, target)
      echo &"nimnet,dijkstra,{sizeName},{n},{m},{tDijkstra:.6f}"
    except:
      echo &"nimnet,dijkstra,{sizeName},{n},{m},NA"

    # PageRank
    let tPR = benchPageRank(g)
    echo &"nimnet,pagerank,{sizeName},{n},{m},{tPR:.6f}"

    # Connected components
    let tCC = benchConnectedComponents(g)
    echo &"nimnet,connected_components,{sizeName},{n},{m},{tCC:.6f}"

    # MST (Kruskal)
    let tMST = benchMSTKruskal(gw)
    echo &"nimnet,mst_kruskal,{sizeName},{n},{m},{tMST:.6f}"

    # Louvain community detection (skip for large — can be slow)
    if n <= 1_000:
      let tLouv = benchCommunityLouvain(g)
      echo &"nimnet,louvain,{sizeName},{n},{m},{tLouv:.6f}"
    else:
      echo &"nimnet,louvain,{sizeName},{n},{m},NA"

    # Clustering coefficient (skip for large)
    if n <= 1_000:
      let tClust = benchClustering(g)
      echo &"nimnet,clustering,{sizeName},{n},{m},{tClust:.6f}"
    else:
      echo &"nimnet,clustering,{sizeName},{n},{m},NA"

    # Triangle counting (skip for large)
    if n <= 1_000:
      let tTri = benchTriangleCount(g)
      echo &"nimnet,triangles,{sizeName},{n},{m},{tTri:.6f}"
    else:
      echo &"nimnet,triangles,{sizeName},{n},{m},NA"

when isMainModule:
  runBenchmarks()
