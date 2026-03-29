## Tests for algorithm modules:
## traversal, shortest_paths, components, centrality, clustering,
## community, mst, dag, flow, properties, link_prediction, core,
## stats, clique, independent_set, dominating, coloring, bipartite, euler

import std/[unittest, tables, sets, math, strutils, json]
import nimnet

suite "Traversal - BFS":
  test "bfsEdges on simple graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4), (3,5)])
    var edges: seq[(int, int)] = @[]
    for (u, v) in bfsEdges(g, 1):
      edges.add((u, v))
    check edges.len == 4

  test "bfsTree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3), (2,4)])
    let tree = bfsTree(g, 1)
    check tree.numberOfNodes() == 4
    check tree.numberOfEdges() == 3  # tree has n-1 edges

  test "bfsLayers":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4), (3,4)])
    let layers = bfsLayers(g, 1)
    check layers[0] == @[1]
    check layers[1].len == 2  # nodes 2, 3
    check layers[2].len == 1  # node 4

  test "bfsPredecessors":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4)])
    let pred = bfsPredecessors(g, 1)
    check pred[2] == 1
    check pred[3] == 1
    check pred[4] == 2

suite "Traversal - DFS":
  test "dfsEdges on simple graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4)])
    var edges: seq[(int, int)] = @[]
    for (u, v) in dfsEdges(g, 1):
      edges.add((u, v))
    check edges.len == 3

  test "dfsTree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4)])
    let tree = dfsTree(g, 1)
    check tree.numberOfNodes() == 4
    check tree.numberOfEdges() == 3

  test "dfsPreorderNodes":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (2,4)])
    let pre = dfsPreorderNodes(g, 1)
    check pre[0] == 1
    check pre.len == 4

  test "dfsPostorderNodes":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let post = dfsPostorderNodes(g, 1)
    check post.len == 3
    check post[^1] == 1  # root is last in postorder

suite "Shortest Paths":
  test "unweighted shortest path":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    check shortestPath(g, 1, 3) == @[1, 3]

  test "shortest path length":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    check shortestPathLength(g, 1, 4) == 3

  test "hasPath":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (3,4)])
    check hasPath(g, 1, 2) == true
    check hasPath(g, 1, 3) == false

  test "dijkstra path":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(1, 3, 10.0)
    check dijkstraPath(g, 1, 3) == @[1, 2, 3]
    check abs(dijkstraPathLength(g, 1, 3) - 3.0) < 1e-10

  test "bellman-ford path":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(1, 3, 10.0)
    check bellmanFordPath(g, 1, 3) == @[1, 2, 3]

  test "no path raises":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    expect NimNetNoPath:
      discard shortestPath(g, 1, 2)

  test "A* search":
    var g = newGraph[int]()
    # Grid-like graph: 0-1-2-3 with shortcut 0-3 weight 10
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 1.0)
    g.addWeightedEdge(0, 3, 10.0)
    let heuristic = proc(n: int): float = abs(3 - n).float
    let path = astarPath(g, 0, 3, heuristic)
    check path == @[0, 1, 2, 3]

  test "A* path length":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 1.0)
    let heuristic = proc(n: int): float = abs(3 - n).float
    check abs(astarPathLength(g, 0, 3, heuristic) - 3.0) < 1e-10

suite "Components":
  test "connected components":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (4,5)])
    let comps = connectedComponents(g)
    check comps.len == 2

  test "isConnected":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    check components.isConnected(g) == true
    g.addNode(4)
    check components.isConnected(g) == false

  test "strongly connected components":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1), (4,5)])
    let sccs = stronglyConnectedComponents(dg)
    check sccs.len == 3  # {1,2,3}, {4}, {5}

  test "weakly connected":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check components.isWeaklyConnected(dg) == true

  test "condensation":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,1), (2,3)])
    let cond = condensation(dg)
    check cond.numberOfNodes() == 2  # SCC {1,2} and {3}

suite "Centrality":
  test "degree centrality":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (1,4)])
    let dc = degreeCentrality(g)
    check abs(dc[1] - 1.0) < 1e-10  # 3 / (4-1) = 1.0
    check abs(dc[2] - 1.0/3.0) < 1e-10

  test "closeness centrality":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    let cc = closenessCentrality(g)
    # Node 2: dist to 1=1, 3=1, 4=2; closeness = 3/4
    check abs(cc[2] - 3.0/4.0) < 1e-10

  test "pageRank sums to 1":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1)])
    let pr = pageRank(dg)
    var total = 0.0
    for n, r in pr:
      total += r
    check abs(total - 1.0) < 1e-4

  test "eigenvector centrality":
    let g = completeGraph[int](5)
    let ec = eigenvectorCentrality(g)
    # All nodes should have equal centrality in complete graph
    var vals: seq[float] = @[]
    for n, v in ec:
      vals.add(v)
    for v in vals:
      check abs(v - vals[0]) < 1e-4

  test "katz centrality":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let kc = katzCentrality(g, alpha = 0.1, beta = 1.0)
    # Node 2 (center) should have highest Katz centrality
    check kc[2] > kc[1]
    check kc[2] > kc[3]

  test "HITS on directed graph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (1,3), (2,3)])
    let (hubs, auths) = hits(dg)
    # Node 1 is a hub (points to others)
    check hubs[1] > 0
    # Node 3 should have high authority (pointed to by many)
    check auths[3] > auths[1]

suite "Clustering":
  test "clustering coefficient - triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    check abs(clusteringCoefficient(g, 1) - 1.0) < 1e-10

  test "clustering coefficient - star":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (1,4)])
    check abs(clusteringCoefficient(g, 1) - 0.0) < 1e-10

  test "average clustering":
    let g = completeGraph[int](4)
    check abs(averageClustering(g) - 1.0) < 1e-10

  test "transitivity":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    check abs(transitivity(g) - 1.0) < 1e-10

  test "triangles":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    check triangles(g, 1) == 1

suite "Community Detection":
  test "modularity of known partition":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (4,5), (5,6), (4,6), (3,4)])
    let comms = @[[1, 2, 3].toHashSet, [4, 5, 6].toHashSet]
    let q = modularity(g, comms)
    check q > 0.0  # positive modularity for good partition

  test "greedy modularity finds communities":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (4,5), (5,6), (4,6), (3,4)])
    let comms = greedyModularityCommunities(g)
    check comms.len >= 1

suite "MST":
  test "kruskal MST weight - triangle":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(1, 3, 3.0)
    check abs(kruskalMSTWeight(g) - 3.0) < 1e-10  # 1 + 2

  test "kruskal MST edges":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(1, 3, 3.0)
    let mstG = kruskalMST(g)
    check mstG.numberOfEdges() == 2
    check mstG.numberOfNodes() == 3

  test "prim MST":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(1, 3, 3.0)
    let mstG = primMST(g, 1)
    check mstG.numberOfEdges() == 2

suite "DAG":
  test "topological sort":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (1,3), (2,4), (3,4)])
    let order = topologicalSort(dg)
    check order[0] == 1  # must be first
    check order[^1] == 4  # must be last

  test "isDAG":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check isDirectedAcyclicGraph(dg) == true
    dg.addEdge(3, 1)
    check isDirectedAcyclicGraph(dg) == false

  test "hasCycle":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1)])
    check hasCycle(dg) == true

  test "ancestors and descendants":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (2,4)])
    check 1 in ancestors(dg, 3)
    check 2 in ancestors(dg, 3)
    check 3 in descendants(dg, 1)
    check 4 in descendants(dg, 1)

  test "DAG longest path":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (1,3)])
    let lp = dagLongestPath(dg)
    check lp.len == 3  # 1 -> 2 -> 3

suite "Flow":
  test "max flow - simple":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(1, 2, 3.0)
    dg.addWeightedEdge(2, 3, 2.0)
    dg.addWeightedEdge(1, 3, 1.0)
    let flowVal = maximumFlowValue(dg, 1, 3)
    check abs(flowVal - 3.0) < 1e-10  # 2 through 1->2->3 + 1 through 1->3

  test "minimum cut":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(1, 2, 3.0)
    dg.addWeightedEdge(2, 3, 2.0)
    dg.addWeightedEdge(1, 3, 1.0)
    let (cutVal, sSet, tSet) = minimumCut(dg, 1, 3)
    check abs(cutVal - 3.0) < 1e-10
    check 1 in sSet
    check 3 in tSet

suite "Properties":
  test "isTree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    check isTree(g) == true
    g.addEdge(1, 4)
    check isTree(g) == false  # now has cycle

  test "isForest":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (3,4)])
    check isForest(g) == true

  test "isRegular":
    let g = cycleGraph[int](5)
    check isRegular(g) == true
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(1,2), (1,3)])
    check isRegular(g2) == false

  test "isComplete":
    let g = completeGraph[int](5)
    check isComplete(g) == true
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(1,2), (2,3)])
    check isComplete(g2) == false

  test "isDAG":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check properties.isDAG(dg) == true
    dg.addEdge(3, 1)
    check properties.isDAG(dg) == false

  test "girth of triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    check girth(g) == 3

  test "girth of tree (acyclic)":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    check girth(g) == -1

  test "girth of square":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4), (4,1)])
    check girth(g) == 4

suite "Link Prediction":
  test "common neighbors":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3), (2,4), (3,4)])
    check commonNeighbors(g, 1, 4) == 2  # 2 and 3

  test "jaccard coefficient":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3)])
    let jc = jaccardCoefficient(g, 1, 2)
    # N(1) = {2,3}, N(2) = {1,3}, intersection = {3}, union = {1,2,3}
    check abs(jc - 1.0/3.0) < 1e-10

  test "adamic adar":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3)])
    let aa = adamicAdar(g, 1, 2)
    check aa > 0.0  # common neighbor 3 has degree 2

  test "preferential attachment":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4)])
    check preferentialAttachment(g, 1, 4) == 2 * 1  # deg(1)=2, deg(4)=1

  test "resource allocation":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3)])
    let ra = resourceAllocationIndex(g, 1, 2)
    check ra > 0.0

  test "predicted edges":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3), (2,4)])
    # Edge (3,4) is missing; nodes 3 and 4 share common neighbor 2
    let preds = predictedEdges(g, topK = 3)
    check preds.len <= 3
    var found = false
    for (u, v, score) in preds:
      if (u == 3 and v == 4) or (u == 4 and v == 3):
        found = true
    check found

suite "k-Core":
  test "core numbers - triangle with pendant":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (3,4)])
    let cores = coreNumber(g)
    check cores[1] == 2
    check cores[2] == 2
    check cores[3] == 2
    check cores[4] == 1

  test "kCore subgraph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (3,4)])
    let k2 = kCore(g, 2)
    check k2.numberOfNodes() == 3
    check k2.hasNode(1)
    check k2.hasNode(2)
    check k2.hasNode(3)
    check not k2.hasNode(4)

  test "kShell":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (3,4)])
    let shell1 = kShell(g, 1)
    check shell1.hasNode(4)
    check not shell1.hasNode(1)

  test "kCrust":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (3,4)])
    let crust1 = kCrust(g, 1)
    # kCrust(k=1): nodes with core number <= 1
    check crust1.hasNode(4)
    check not crust1.hasNode(1)

  test "kCorona":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (3,4)])
    # cores: 1->2, 2->2, 3->2, 4->1
    # kCorona(k=2): nodes in 2-core with exactly 2 neighbors in 2-core
    # node 1: neighbors in 2-core = {2,3} -> count=2, included
    # node 2: neighbors in 2-core = {1,3} -> count=2, included
    # node 3: neighbors in 2-core = {1,2} -> count=2, included
    let corona2 = kCorona(g, 2)
    check corona2.hasNode(1)
    check corona2.hasNode(2)
    check corona2.hasNode(3)
    check not corona2.hasNode(4)

suite "Network Statistics":
  test "info":
    var g = newGraph[int](name = "test")
    g.addEdgesFrom([(1,2), (2,3)])
    check "test" in info(g)
    check "3 nodes" in info(g)

  test "degree histogram":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3)])
    let hist = degreeHistogram(g)
    check hist[2] == 3  # all nodes degree 2

  test "average degree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3)])
    check abs(averageDegree(g) - 2.0) < 1e-10

  test "degree assortativity of complete graph":
    let g = completeGraph[int](5)
    # Complete graph: all same degree, assortativity should be close to 0
    # (or undefined, handled as 0)
    let r = degreeAssortativity(g)
    check abs(r) < 1e-10 or r.classify == fcNan

  test "density":
    let g = completeGraph[int](5)
    check abs(stats.density(g) - 1.0) < 1e-10

  test "averageShortestPathLength":
    let g = pathGraph[int](4)
    # Pairs and distances: (1,2)=1, (1,3)=2, (1,4)=3, (2,3)=1, (2,4)=2, (3,4)=1
    # Each undirected pair counted twice in BFS; average = (1+2+3+1+2+1)*2 / (4*3) = 20/12
    let avg = averageShortestPathLength(g)
    check abs(avg - 20.0/12.0) < 1e-10

  test "averageShortestPathLength on disconnected graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (3,4)])
    # Only reachable pairs counted; disconnected pairs ignored
    let avg = averageShortestPathLength(g)
    check avg > 0.0

  test "reciprocity":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    check abs(reciprocity(g) - 1.0) < 1e-10

suite "Cliques":
  test "find cliques in triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    let cliques = findCliques(g)
    check cliques.len == 1
    check cliques[0].len == 3

  test "clique number":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3), (3,4)])
    check cliqueNumber(g) == 3

  test "max clique":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    let mc = maxClique(g)
    check mc.len == 3

  test "cliques in K5":
    let g = completeGraph[int](5)
    check cliqueNumber(g) == 5

  test "number of cliques in triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    check numberOfCliques(g) == 1

  test "number of cliques in path":
    let g = pathGraph[int](4)
    # Path has 3 maximal cliques (each edge is a maximal clique)
    check numberOfCliques(g) == 3

suite "Independent Set":
  test "isIndependentSet":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    check isIndependentSet(g, [1, 3].toHashSet) == true
    check isIndependentSet(g, [1, 2].toHashSet) == false

  test "maximum independent set":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    let mis = maximumIndependentSet(g)
    check isIndependentSet(g, mis) == true
    check mis.len >= 2  # optimal is {1,3} or {2,4}

  test "minimum vertex cover":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let vc = independent_set.minimumVertexCover(g)
    # Every edge must have at least one endpoint in vc
    for (u, v) in g.edges:
      check u in vc or v in vc

suite "Dominating Set":
  test "isDominatingSet":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    check isDominatingSet(g, [2, 3].toHashSet) == true
    check isDominatingSet(g, [1].toHashSet) == false

  test "minimum dominating set":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    let ds = minimumDominatingSet(g)
    check isDominatingSet(g, ds) == true

  test "domination number of star":
    let g = starGraph[int](5)
    # Center node alone dominates all
    check dominationNumber(g) == 1

suite "Graph Coloring":
  test "greedy coloring of triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    let col = greedyColor(g)
    check isProperColoring(g, col) == true

  test "chromatic number of complete graph":
    let g = completeGraph[int](4)
    check chromaticNumber(g) == 4

  test "bipartite graph needs 2 colors":
    let g = completeBipartiteGraph(3, 3)
    let col = greedyColor(g)
    check isProperColoring(g, col)
    var colors = initHashSet[int]()
    for n, c in col:
      colors.incl(c)
    check colors.len == 2

  test "coloring strategies":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4), (4,1)])
    for strategy in ["largest_first", "smallest_last", "sequential"]:
      let col = greedyColor(g, strategy)
      check isProperColoring(g, col) == true

suite "Bipartite":
  test "isBipartite - cycle even":
    let g = cycleGraph[int](4)
    check isBipartite(g) == true

  test "isBipartite - cycle odd":
    let g = cycleGraph[int](5)
    check isBipartite(g) == false

  test "isBipartite - complete bipartite":
    let g = completeBipartiteGraph(3, 3)
    check isBipartite(g) == true

  test "bipartite sets":
    let g = completeBipartiteGraph(3, 3)
    let (setA, setB) = bipartiteSets(g)
    check setA.len == 3
    check setB.len == 3

  test "maximum matching":
    let g = completeBipartiteGraph(3, 3)
    let matching = maximumMatching(g)
    check matching.len == 3  # perfect matching

  test "not bipartite raises":
    let g = completeGraph[int](3)
    expect NimNetError:
      discard bipartiteSets(g)

  test "minimum vertex cover":
    let g = completeBipartiteGraph(3, 3)
    let cover = bipartite.minimumVertexCover(g)
    # By König's theorem, |min vertex cover| == |max matching| == 3
    check cover.len == 3
    # Every edge must have at least one endpoint in the cover
    for (u, v) in g.edges:
      check u in cover or v in cover

suite "Euler":
  test "isEulerian - cycle":
    let g = cycleGraph[int](5)
    check isEulerian(g) == true

  test "isEulerian - path":
    let g = pathGraph[int](4)
    check isEulerian(g) == false

  test "isSemiEulerian - path":
    let g = pathGraph[int](4)
    check isSemiEulerian(g) == true

  test "eulerian circuit on cycle":
    let g = cycleGraph[int](5)
    let circuit = eulerianCircuit(g)
    check circuit.len == 6  # visits all 5 edges + return to start

  test "eulerian path on path graph":
    let g = pathGraph[int](4)
    let path = eulerianPath(g)
    check path.len == 4  # visits all 3 edges

  test "no circuit raises":
    let g = pathGraph[int](4)
    expect NimNetError:
      discard eulerianCircuit(g)

  test "isHamiltonian - complete":
    let g = completeGraph[int](4)
    check isHamiltonian(g) == true

  test "isHamiltonian - path (no cycle possible)":
    let g = pathGraph[int](4)
    check isHamiltonian(g) == false

  test "isEulerianDirected - directed cycle":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1)])
    check isEulerianDirected(dg) == true

  test "isEulerianDirected - unbalanced degrees":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check isEulerianDirected(dg) == false

suite "Generators":
  test "complete graph":
    let g = completeGraph[int](5)
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 10

  test "cycle graph":
    let g = cycleGraph[int](6)
    check g.numberOfNodes() == 6
    check g.numberOfEdges() == 6

  test "path graph":
    let g = pathGraph[int](5)
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 4

  test "star graph":
    let g = starGraph[int](5)
    check g.numberOfNodes() == 6
    check g.degree(0) == 5

  test "wheel graph":
    let g = wheelGraph[int](5)
    check g.numberOfNodes() == 6
    check g.degree(0) == 5  # hub

  test "grid graph":
    let g = gridGraph(3, 4)
    check g.numberOfNodes() == 12

  test "complete bipartite":
    let g = completeBipartiteGraph(3, 4)
    check g.numberOfNodes() == 7
    check g.numberOfEdges() == 12

  test "petersen graph":
    let g = petersenGraph()
    check g.numberOfNodes() == 10
    check g.numberOfEdges() == 15

  test "karate club":
    let g = karateClubGraph()
    check g.numberOfNodes() == 34

  test "erdos renyi":
    let g = erdosRenyiGraph(100, 0.1, seed = 42)
    check g.numberOfNodes() == 100

  test "barabasi albert":
    let g = barabasiAlbertGraph(50, 2, seed = 42)
    check g.numberOfNodes() == 50

  test "watts strogatz":
    let g = wattsStrogatzGraph(20, 4, 0.3, seed = 42)
    check g.numberOfNodes() == 20

  test "balanced tree":
    let g = balancedTree(2, 3)
    check g.numberOfNodes() == 15  # 1 + 2 + 4 + 8

  test "random tree":
    let g = randomTree(20, seed = 42)
    check g.numberOfNodes() == 20
    check g.numberOfEdges() == 19

suite "I/O":
  test "JSON graph round-trip":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let j = toJsonNode(g)
    check j["directed"].getBool() == false
    check j["nodes"].len == 3

  test "DOT string":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2)])
    let dot = toDotString(g)
    check "graph" in dot
    check "--" in dot

  test "DOT string directed":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2)])
    let dot = toDotString(dg)
    check "digraph" in dot
    check "->" in dot

suite "Operators":
  test "complement":
    let g = pathGraph[int](4)
    let comp = complement(g)
    # path 0-1-2-3 complement has edges: 0-2, 0-3, 1-3
    check comp.numberOfEdges() == 3

  test "union":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1,2)])
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(2,3)])
    let u = union(g1, g2)
    check u.numberOfNodes() == 3
    check u.numberOfEdges() == 2

  test "intersection":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1,2), (2,3)])
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(2,3), (3,4)])
    let inter = intersection(g1, g2)
    check inter.numberOfEdges() == 1
    check inter.hasEdge(2, 3)

  test "relabel nodes":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let mapping = {1: 10, 2: 20, 3: 30}.toTable
    let rg = relabelNodes(g, mapping)
    check rg.hasNode(10)
    check rg.hasEdge(10, 20)

  test "toDirected / toUndirected":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let dg = toDirected(g)
    check dg.numberOfEdges() == 4  # each undirected edge -> 2 directed
    let ug = toUndirected(dg)
    check ug.numberOfEdges() == 2

suite "Convert":
  test "adjacency matrix":
    var g = newGraph[int]()
    g.addEdgesFrom([(0,1), (1,2)])
    let (nodes, mat) = toAdjacencyMatrix(g)
    check nodes.len == 3
    check mat.len == 3

  test "from edge list":
    let g = fromEdgeList(@[(1,2), (2,3), (3,1)])
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 3

  test "degree sequence":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,3)])
    let ds = degreeSequence(g)
    check ds.len == 3
    # All degree 2, sorted descending
    check ds[0] == 2
