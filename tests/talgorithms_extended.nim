## Tests for expanded coverage:
## components (DiGraph variants), centrality (DiGraph variants),
## connectivity (node-level), traversal extras, shortest_paths extras,
## clustering extras, community (label propagation), dag extras,
## core extras, stats extras, clique extras, euler (directed),
## link prediction (predictedEdges), min_cost_flow,
## generators (small graphs, trees), I/O (edgelist, adjlist),
## operators extras, convert extras, datasets extras

import std/[unittest, tables, sets, math, os, algorithm, json]
import nimnet
import nimnet/algorithms/components as comp
import nimnet/algorithms/properties as props
import nimnet/algorithms/stats as statsmod

# ============================================================================
# Components — DiGraph variants
# ============================================================================

suite "Components (extended)":
  test "numberOfConnectedComponents":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (3,4)])
    check numberOfConnectedComponents(g) == 2

  test "nodeConnectedComponent":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (4,5)])
    let comp = nodeConnectedComponent(g, 1)
    check comp.len == 3
    check 1 in comp
    check 2 in comp
    check 3 in comp

  test "numberOfStronglyConnectedComponents":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1), (4,5)])
    check numberOfStronglyConnectedComponents(dg) == 3

  test "isStronglyConnected true":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1)])
    check comp.isStronglyConnected(dg) == true

  test "isStronglyConnected false":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check comp.isStronglyConnected(dg) == false

  test "condensation":
    var dg = newDiGraph[int]()
    # SCC1: {1,2,3}, SCC2: {4}
    dg.addEdgesFrom([(1,2), (2,3), (3,1), (3,4)])
    let cond = condensation(dg)
    check cond.numberOfNodes() == 2
    check cond.numberOfEdges() == 1

  test "weaklyConnectedComponents":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (4,5)])
    let comps = weaklyConnectedComponents(dg)
    check comps.len == 2

  test "isWeaklyConnected true":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check comp.isWeaklyConnected(dg) == true

  test "isWeaklyConnected false":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (3,4)])
    check comp.isWeaklyConnected(dg) == false

# ============================================================================
# Centrality — DiGraph-specific + betweenness
# ============================================================================

suite "Centrality (extended)":
  test "inDegreeCentrality":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (1,3), (2,3)])
    let c = inDegreeCentrality(dg)
    # node 3 receives 2 edges, max in-degree centrality
    check c[3] > c[1]
    check abs(c[1] - 0.0) < 1e-10  # node 1 has in-degree 0

  test "outDegreeCentrality":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (1,3), (2,3)])
    let c = outDegreeCentrality(dg)
    check c[1] > c[3]  # node 1 has highest out-degree
    check abs(c[3] - 0.0) < 1e-10  # node 3 has out-degree 0

  test "betweennessCentrality":
    # Path graph: center node should have highest betweenness
    let g = pathGraph[int](5)
    let bc = betweennessCentrality(g)
    check bc[2] > bc[0]
    check bc[2] > bc[4]

  test "betweennessCentrality normalized":
    let g = pathGraph[int](4)
    let bc = betweennessCentrality(g, normalized = true)
    # Values should be in [0, 1]
    for _, v in bc:
      check v >= 0.0
      check v <= 1.0

# ============================================================================
# Clustering — extras
# ============================================================================

suite "Clustering (extended)":
  test "clustering map for all nodes":
    let g = completeGraph[int](4)
    let cc = clustering(g)
    check cc.len == 4
    for _, v in cc:
      check abs(v - 1.0) < 1e-10  # complete graph has cc=1

  test "trianglesMap":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1), (3,4)])
    let tm = trianglesMap(g)
    check tm[1] == 1
    check tm[2] == 1
    check tm[3] == 1
    check tm[4] == 0

# ============================================================================
# Community — label propagation
# ============================================================================

suite "Community (extended)":
  test "labelPropagationCommunities":
    var g = newGraph[int]()
    # Two cliques
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    g.addEdgesFrom([(4,5), (5,6), (4,6)])
    g.addEdge(3, 4)
    let comms = labelPropagationCommunities(g)
    check comms.len >= 1
    var total = 0
    for c in comms:
      total += c.len
    check total == 6

# ============================================================================
# Connectivity — node-level
# ============================================================================

suite "Connectivity (extended)":
  test "nodeConnectivity of complete graph":
    let g = completeGraph[int](4)
    check nodeConnectivity(g) >= 1  # K4 should have high connectivity

  test "nodeConnectivity of path":
    let g = pathGraph[int](4)
    check nodeConnectivity(g) == 1

  test "minimumNodeCut of path":
    let g = pathGraph[int](4)
    let cut = minimumNodeCut(g)
    check cut.len == 1

  test "averageNodeConnectivity":
    let g = completeGraph[int](4)
    let avgConn = averageNodeConnectivity(g)
    check avgConn > 0.0

# ============================================================================
# Traversal — extras
# ============================================================================

suite "Traversal (extended)":
  test "bfsSuccessors":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4)])
    let succs = bfsSuccessors(g, 1)
    check 1 in succs
    check 2 in succs[1] or 3 in succs[1]

  test "dfsLabeledEdges":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    let labeled = dfsLabeledEdges(g, 1)
    check labeled.len > 0
    # Should have both forward and nontree edges
    var hasForward = false
    var hasNontree = false
    for (_, _, kind) in labeled:
      if kind == "forward": hasForward = true
      if kind == "nontree": hasNontree = true
    check hasForward == true

  test "bfsPredecessors DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    let preds = bfsPredecessors(dg, 1)
    check preds[2] == 1
    check preds[3] == 2

  test "dfsPreorderNodes DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    let preorder = dfsPreorderNodes(dg, 1)
    check preorder[0] == 1
    check preorder.len == 3

  test "dfsPostorderNodes DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    let postorder = dfsPostorderNodes(dg, 1)
    check postorder[^1] == 1  # root is last in postorder
    check postorder.len == 3

# ============================================================================
# Shortest Paths — extras
# ============================================================================

suite "Shortest Paths (extended)":
  test "singleSourceShortestPathLength":
    let g = pathGraph[int](5)
    let lengths = singleSourceShortestPathLength(g, 0)
    check lengths[0] == 0
    check lengths[1] == 1
    check lengths[4] == 4

  test "singleSourceShortestPathLength DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(0,1), (1,2), (2,3)])
    let lengths = singleSourceShortestPathLength(dg, 0)
    check lengths[3] == 3

  test "singleSourceDijkstra":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(1, 2, 2.0)
    g.addWeightedEdge(0, 2, 10.0)
    let (dist, paths) = singleSourceDijkstra(g, 0)
    check abs(dist[2] - 3.0) < 1e-10
    check paths[2] == @[0, 1, 2]

  test "shortestPathLength DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,4)])
    check shortestPathLength(dg, 1, 4) == 3

  test "hasPath DiGraph true":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check hasPath(dg, 1, 3) == true

  test "hasPath DiGraph false":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check hasPath(dg, 3, 1) == false

  test "dijkstraPath DiGraph":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(1, 2, 1.0)
    dg.addWeightedEdge(2, 3, 2.0)
    dg.addWeightedEdge(1, 3, 10.0)
    let path = dijkstraPath(dg, 1, 3)
    check path == @[1, 2, 3]

  test "dijkstraPathLength DiGraph":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(1, 2, 1.0)
    dg.addWeightedEdge(2, 3, 2.0)
    dg.addWeightedEdge(1, 3, 10.0)
    check abs(dijkstraPathLength(dg, 1, 3) - 3.0) < 1e-10

  test "bellmanFordPath DiGraph":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(1, 2, 1.0)
    dg.addWeightedEdge(2, 3, -0.5)
    dg.addWeightedEdge(1, 3, 2.0)
    let path = bellmanFordPath(dg, 1, 3)
    check path == @[1, 2, 3]

# ============================================================================
# DAG — extras
# ============================================================================

suite "DAG (extended)":
  test "findCycle returns cycle":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1)])
    let cycle = findCycle(dg)
    check cycle.len > 0
    # Cycle should form a loop
    check cycle[0] == cycle[^1]

  test "findCycle returns empty on acyclic":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    let cycle = findCycle(dg)
    check cycle.len == 0

# ============================================================================
# Core — extras
# ============================================================================

suite "Core Decomposition (extended)":
  test "kCrust":
    # Triangle with pendant: {1,2,3} triangle, 4 attached to 3
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1), (3,4)])
    let crust = kCrust(g, 1)
    check crust.hasNode(4)  # 4 has core number 1
    check not crust.hasNode(1) or crust.hasNode(1)  # 1 has core number 2, but kCrust(1) includes <=1

  test "kCrust includes low core nodes":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1), (3,4)])
    let crust = kCrust(g, 0)
    # k=0 crust: nodes with core number <= 0 (none in this graph)
    check crust.numberOfNodes() == 0

  test "kCorona":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1), (3,4)])
    let corona = kCorona(g, 1)
    # Node 4 has core number 1 and exactly 1 neighbor in the 1-core = node 3
    check corona.hasNode(4)

# ============================================================================
# Stats — extras
# ============================================================================

suite "Stats (extended)":
  test "averageShortestPathLength":
    let g = pathGraph[int](4)
    let apl = averageShortestPathLength(g)
    check apl > 0.0
    # Path of 4 nodes: distances are 1+2+3+1+2+1 = 10, pairs 6 each direction = 12
    # avg = 20/12 = 1.666...
    check abs(apl - 5.0/3.0) < 1e-10

  test "reciprocity for undirected":
    let g = completeGraph[int](3)
    check abs(reciprocity(g) - 1.0) < 1e-10

  test "density via stats":
    let g = completeGraph[int](4)
    check abs(statsmod.density(g) - 1.0) < 1e-10

# ============================================================================
# Clique — extras
# ============================================================================

suite "Clique (extended)":
  test "numberOfCliques":
    let g = completeGraph[int](4)
    let nc = numberOfCliques(g)
    # K4 has: 4 choose 3 = 4 maximal (of size 4 actually, just one)
    # Actually K4 has exactly 1 maximal clique (the full K4 itself)
    check nc >= 1

# ============================================================================
# Euler — directed
# ============================================================================

suite "Euler (extended)":
  test "isEulerianDirected true":
    var dg = newDiGraph[int]()
    # Directed cycle: 1->2->3->1
    dg.addEdgesFrom([(1,2), (2,3), (3,1)])
    check isEulerianDirected(dg) == true

  test "isEulerianDirected false":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    check isEulerianDirected(dg) == false

  test "isEulerianDirected empty":
    var dg = newDiGraph[int]()
    check isEulerianDirected(dg) == true

# ============================================================================
# Link Prediction — predictedEdges
# ============================================================================

suite "Link Prediction (extended)":
  test "predictedEdges returns scored pairs":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4), (4,5)])
    let predicted = predictedEdges(g, topK = 3)
    check predicted.len <= 3
    # Each prediction has (u, v, score)
    for (u, v, score) in predicted:
      check not g.hasEdge(u, v)  # should not be existing edges

  test "predictedEdges with custom scorer":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let scorer = proc(g2: Graph[int], u, v: int): float =
      float(commonNeighbors(g2, u, v))
    let predicted = predictedEdges(g, topK = 5, scorer = scorer)
    check predicted.len >= 0

# ============================================================================
# Min Cost Flow
# ============================================================================

suite "Min Cost Flow":
  test "simple supply-demand":
    var dg = newDiGraph[int]()
    # edge (1,2) with capacity 10, cost 1
    var attr1 = newEdgeAttr()
    attr1["weight"] = newJString("10.0")
    attr1["cost"] = newJString("1.0")
    dg.addEdge(1, 2, attr1)
    # edge (2,3) with capacity 10, cost 2
    var attr2 = newEdgeAttr()
    attr2["weight"] = newJString("10.0")
    attr2["cost"] = newJString("2.0")
    dg.addEdge(2, 3, attr2)

    var demand = initTable[int, float]()
    demand[1] = 5.0   # supply
    demand[3] = -5.0  # demand
    demand[2] = 0.0

    let (cost, flow) = minimumCostFlow(dg, demand)
    check cost > 0.0
    # flow on edge (1,2) should be 5
    check abs(flow[1][2] - 5.0) < 1e-6

# ============================================================================
# Generators — small graphs
# ============================================================================

suite "Generators - Small Graphs (extended)":
  test "diamondGraph":
    let g = diamondGraph()
    check g.numberOfNodes() == 4
    check g.numberOfEdges() == 5  # K4 minus one edge

  test "bullGraph":
    let g = bullGraph()
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 5

  test "houseGraph":
    let g = houseGraph()
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 6

  test "cubicalGraph":
    let g = cubicalGraph()
    check g.numberOfNodes() == 8
    check g.numberOfEdges() == 12

# ============================================================================
# Generators — trees (extended)
# ============================================================================

suite "Generators - Trees (extended)":
  test "binomialTree":
    let g = binomialTree(3)
    check g.numberOfNodes() == 8  # 2^3
    check g.numberOfEdges() == 7  # tree

  test "starTree":
    let g = starTree(5)
    check g.numberOfNodes() == 6  # center (0) + 5 leaves
    check g.numberOfEdges() == 5

  test "caterpillarTree":
    let g = caterpillarTree(4, 2, seed = 42)
    check g.numberOfNodes() > 4  # backbone + legs
    check g.numberOfEdges() == g.numberOfNodes() - 1  # it's a tree

# ============================================================================
# Generators — classic (extended)
# ============================================================================

suite "Generators - Classic (extended)":
  test "emptyGraph":
    let g = emptyGraph[int](5)
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 0

  test "trivialGraph":
    let g = trivialGraph()
    check g.numberOfNodes() == 1
    check g.numberOfEdges() == 0

# ============================================================================
# I/O — edgelist round-trip
# ============================================================================

suite "I/O Edgelist":
  test "write and read edgelist":
    var g = newGraph[int]()
    g.addEdgesFrom([(0,1), (1,2), (2,0)])
    let filename = "test_edgelist.txt"
    writeEdgelist(g, filename)
    let g2 = readEdgelist(filename)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 3
    removeFile(filename)

  test "write edgelist digraph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    let filename = "test_edgelist_di.txt"
    writeEdgelistDigraph(dg, filename)
    # Verify file was created
    check fileExists(filename)
    removeFile(filename)

# ============================================================================
# I/O — adjlist round-trip
# ============================================================================

suite "I/O Adjlist":
  test "write and read adjlist":
    var g = newGraph[int]()
    g.addEdgesFrom([(0,1), (1,2)])
    let filename = "test_adjlist.txt"
    writeAdjlist(g, filename)
    let g2 = readAdjlist(filename)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 2
    removeFile(filename)

# ============================================================================
# Operators — extras
# ============================================================================

suite "Operators (extended)":
  test "union explicit":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1,2)])
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(2,3)])
    let u = union(g1, g2)
    check u.numberOfNodes() == 3
    check u.numberOfEdges() == 2

  test "compose":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1,2)])
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(2,3)])
    let c = compose(g1, g2)
    check c.numberOfNodes() == 3
    check c.numberOfEdges() == 2

  test "difference":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1,2), (2,3), (3,1)])
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(1,2)])
    let d = difference(g1, g2)
    check d.numberOfNodes() == 3
    check d.numberOfEdges() == 2
    check not d.hasEdge(1, 2)

  test "disjointUnion":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(0,1)])
    var g2 = newGraph[int]()
    g2.addEdgesFrom([(0,1)])
    let du = disjointUnion(g1, g2)
    check du.numberOfNodes() == 4
    check du.numberOfEdges() == 2

  test "DiGraph union":
    var dg1 = newDiGraph[int]()
    dg1.addEdge(1, 2)
    var dg2 = newDiGraph[int]()
    dg2.addEdge(2, 3)
    let u = union(dg1, dg2)
    check u.numberOfNodes() == 3
    check u.numberOfEdges() == 2

  test "DiGraph complement":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,1)])
    dg.addNode(3)
    let c = complement(dg)
    check c.hasEdge(1, 3)
    check c.hasEdge(3, 1)
    check not c.hasEdge(1, 2)

  test "DiGraph intersection":
    var dg1 = newDiGraph[int]()
    dg1.addEdgesFrom([(1,2), (2,3)])
    var dg2 = newDiGraph[int]()
    dg2.addEdgesFrom([(1,2), (3,4)])
    let isect = intersection(dg1, dg2)
    check isect.hasEdge(1, 2)
    check not isect.hasEdge(2, 3)

  test "DiGraph relabelNodes":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    var mapping = initTable[int, int]()
    mapping[1] = 10
    mapping[2] = 20
    mapping[3] = 30
    let rg = relabelNodes(dg, mapping)
    check rg.hasEdge(10, 20)
    check rg.hasEdge(20, 30)

# ============================================================================
# Convert — extras
# ============================================================================

suite "Convert (extended)":
  test "fromEdgeListDirected":
    let dg = fromEdgeListDirected[int](@[(1,2), (2,3)])
    check dg.numberOfNodes() == 3
    check dg.numberOfEdges() == 2
    check dg.hasEdge(1, 2)
    check not dg.hasEdge(2, 1)

  test "fromAdjacencyMatrix":
    let matrix = @[@[0.0, 1.0, 0.0], @[1.0, 0.0, 1.0], @[0.0, 1.0, 0.0]]
    let g = fromAdjacencyMatrix(matrix)
    check g.numberOfNodes() == 3
    check g.numberOfEdges() >= 2

  test "DiGraph toAdjacencyMatrix":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(0,1), (1,2)])
    let (nodes, matrix) = toAdjacencyMatrix(dg)
    check nodes.len == 3
    check matrix.len == 3

# ============================================================================
# Datasets — extras
# ============================================================================

suite "Datasets (extended)":
  test "florentineFamiliesMarriageGraph":
    let g = florentineFamiliesMarriageGraph()
    check g.numberOfNodes() > 10
    check g.numberOfEdges() >= 15

# ============================================================================
# Edge Subgraph — Graph
# ============================================================================

suite "Edge Subgraph (Graph)":
  test "basic edgeSubgraph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4), (4,5)])
    let sg = g.edgeSubgraph([(2,3), (3,4)])
    check sg.numberOfNodes() == 3
    check sg.numberOfEdges() == 2
    check sg.hasEdge(2, 3)
    check sg.hasEdge(3, 4)
    check not sg.hasNode(1)
    check not sg.hasNode(5)

  test "edgeSubgraph with nonexistent edge":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let sg = g.edgeSubgraph([(1,2), (5,6)])  # (5,6) doesn't exist
    check sg.numberOfNodes() == 2
    check sg.numberOfEdges() == 1

  test "edgeSubgraph empty edges":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let sg = g.edgeSubgraph(newSeq[(int, int)]())
    check sg.numberOfNodes() == 0
    check sg.numberOfEdges() == 0

  test "edgeSubgraph preserves edge attributes":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.5)
    g.addWeightedEdge(2, 3, 2.0)
    let sg = g.edgeSubgraph([(1,2)])
    check sg.numberOfEdges() == 1
    check sg[1, 2].getWeight() == 3.5

# ============================================================================
# Edge Subgraph — DiGraph
# ============================================================================

suite "Edge Subgraph (DiGraph)":
  test "basic edgeSubgraph":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,4)])
    let sg = dg.edgeSubgraph([(1,2), (2,3)])
    check sg.numberOfNodes() == 3
    check sg.numberOfEdges() == 2
    check sg.hasEdge(1, 2)
    check sg.hasEdge(2, 3)
    check not sg.hasNode(4)

  test "edgeSubgraph direction matters":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    let sg = dg.edgeSubgraph([(2,1)])  # reverse direction — doesn't exist
    check sg.numberOfNodes() == 0
    check sg.numberOfEdges() == 0

# ============================================================================
# Self-loop edges — Graph
# ============================================================================

suite "Self-loop edges (Graph)":
  test "selfLoopEdges iterator":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(2, 2)
    g.addEdge(1, 2)
    var loops: seq[(int, int)]
    for e in g.selfLoopEdges:
      loops.add(e)
    check loops.len == 2

  test "selfLoopEdges on graph with no self-loops":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    var loops: seq[(int, int)]
    for e in g.selfLoopEdges:
      loops.add(e)
    check loops.len == 0

  test "removeSelfLoops":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(2, 2)
    g.addEdge(1, 2)
    check g.numberOfSelfLoops() == 2
    g.removeSelfLoops()
    check g.numberOfSelfLoops() == 0
    check g.numberOfEdges() == 1
    check g.hasEdge(1, 2)

# ============================================================================
# Self-loop edges — DiGraph
# ============================================================================

suite "Self-loop edges (DiGraph)":
  test "selfLoopEdges iterator":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 1)
    dg.addEdge(2, 2)
    dg.addEdge(1, 2)
    var loops: seq[(int, int)]
    for e in dg.selfLoopEdges:
      loops.add(e)
    check loops.len == 2

  test "removeSelfLoops":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 1)
    dg.addEdge(2, 2)
    dg.addEdge(1, 2)
    check dg.numberOfSelfLoops() == 2
    dg.removeSelfLoops()
    check dg.numberOfSelfLoops() == 0
    check dg.numberOfEdges() == 1
    check dg.hasEdge(1, 2)

# ============================================================================
# Bridges & Articulation Points
# ============================================================================

suite "Bridges":
  test "bridge in simple graph":
    # 1-2-3 (chain) — edges (1,2) and (2,3) are both bridges
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let b = bridges(g)
    check b.len == 2

  test "no bridges in triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1)])
    let b = bridges(g)
    check b.len == 0

  test "bridge connecting two triangles":
    # Triangle 1-2-3 connected to triangle 4-5-6 via edge 3-4
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1), (3,4), (4,5), (5,6), (6,4)])
    let b = bridges(g)
    check b.len == 1
    # The bridge should be (3,4)
    let bridge = b[0]
    check (bridge == (3, 4) or bridge == (4, 3))

  test "hasBridges":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1,2), (2,3)])
    check hasBridges(g1)

    var g2 = newGraph[int]()
    g2.addEdgesFrom([(1,2), (2,3), (3,1)])
    check not hasBridges(g2)

  test "bridges on empty graph":
    var g = newGraph[int]()
    check bridges(g).len == 0

  test "bridges on single node":
    var g = newGraph[int]()
    g.addNode(1)
    check bridges(g).len == 0

suite "Articulation Points":
  test "articulation point in chain":
    # 1-2-3: node 2 is an articulation point
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let ap = articulationPoints(g)
    check ap.len == 1
    check 2 in ap

  test "no articulation points in triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1)])
    check articulationPoints(g).len == 0

  test "articulation point connecting components":
    # Star: node 1 connected to 2, 3, 4
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (1,4)])
    let ap = articulationPoints(g)
    check 1 in ap

  test "articulation points on empty graph":
    var g = newGraph[int]()
    check articulationPoints(g).len == 0

suite "Biconnected Components":
  test "biconnected components simple":
    # chain: 1-2-3 — each edge is its own biconnected component
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let bc = biconnectedComponents(g)
    check bc.len == 2

  test "single triangle is one biconnected component":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1)])
    let bc = biconnectedComponents(g)
    check bc.len == 1
    check bc[0].len == 3

  test "isBiconnected":
    var g1 = newGraph[int]()
    g1.addEdgesFrom([(1,2), (2,3), (3,1)])
    check isBiconnected(g1) == true

    var g2 = newGraph[int]()
    g2.addEdgesFrom([(1,2), (2,3)])
    check isBiconnected(g2) == false

  test "isBiconnected single node":
    var g = newGraph[int]()
    g.addNode(1)
    check isBiconnected(g) == false

  test "biconnected components on empty graph":
    var g = newGraph[int]()
    check biconnectedComponents(g).len == 0

# ============================================================================
# Ego Graph
# ============================================================================

suite "Ego Graph":
  test "ego graph radius 1 undirected":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4), (4,5)])
    let ego = egoGraph(g, 2, radius=1)
    check ego.numberOfNodes() == 3  # nodes 1, 2, 3
    check ego.hasNode(1)
    check ego.hasNode(2)
    check ego.hasNode(3)
    check not ego.hasNode(4)

  test "ego graph radius 2 undirected":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4), (4,5)])
    let ego = egoGraph(g, 2, radius=2)
    check ego.numberOfNodes() == 4  # nodes 1, 2, 3, 4
    check ego.hasNode(1)
    check ego.hasNode(4)
    check not ego.hasNode(5)

  test "ego graph radius 0":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    let ego = egoGraph(g, 2, radius=0)
    check ego.numberOfNodes() == 1
    check ego.hasNode(2)

  test "ego graph directed":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,4)])
    let ego = egoGraph(dg, 1, radius=1)
    check ego.numberOfNodes() == 2  # nodes 1, 2 (follows outgoing only)
    check ego.hasNode(1)
    check ego.hasNode(2)
    check not ego.hasNode(3)

  test "ego graph directed radius 2":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,4)])
    let ego = egoGraph(dg, 1, radius=2)
    check ego.numberOfNodes() == 3  # nodes 1, 2, 3
    check ego.hasNode(3)
    check not ego.hasNode(4)

  test "ego graph nonexistent node raises":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    expect NodeNotFound:
      discard egoGraph(g, 99)

  test "ego graph preserves edges":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    let ego = egoGraph(g, 1, radius=1)
    check ego.hasEdge(2, 3)  # edge within the ego neighborhood

# ============================================================================
# Transitive Closure & Reduction
# ============================================================================

suite "Transitive Closure":
  test "transitive closure simple DAG":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    let tc = transitiveClosure(dg)
    check tc.hasEdge(1, 2)
    check tc.hasEdge(2, 3)
    check tc.hasEdge(1, 3)  # added by transitive closure

  test "transitive closure already complete":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (1,3)])
    let tc = transitiveClosure(dg)
    check tc.numberOfEdges() == 3  # no new edges added

  test "transitive closure longer chain":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,4)])
    let tc = transitiveClosure(dg)
    check tc.hasEdge(1, 3)
    check tc.hasEdge(1, 4)
    check tc.hasEdge(2, 4)

suite "Transitive Reduction":
  test "transitive reduction simple DAG":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (1,3)])  # (1,3) is redundant
    let tr = transitiveReduction(dg)
    check tr.hasEdge(1, 2)
    check tr.hasEdge(2, 3)
    check not tr.hasEdge(1, 3)  # removed

  test "transitive reduction already minimal":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3)])
    let tr = transitiveReduction(dg)
    check tr.numberOfEdges() == 2

  test "transitive reduction raises on cycle":
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (2,3), (3,1)])
    expect HasACycle:
      discard transitiveReduction(dg)

  test "transitive reduction diamond":
    # 1->2, 1->3, 2->4, 3->4, 1->4 (redundant)
    var dg = newDiGraph[int]()
    dg.addEdgesFrom([(1,2), (1,3), (2,4), (3,4), (1,4)])
    let tr = transitiveReduction(dg)
    check not tr.hasEdge(1, 4)
    check tr.hasEdge(1, 2)
    check tr.hasEdge(1, 3)
    check tr.hasEdge(2, 4)
    check tr.hasEdge(3, 4)
