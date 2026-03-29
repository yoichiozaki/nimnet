## Tests for newly implemented features from NetworkX gap analysis
## Covers: #119, #106, #107, #122, #126, #125, #128

import std/[unittest, tables, sets, math, sequtils, algorithm]
import nimnet

# ============================================================================
# Issue #119: Isolates, local bridges, chain decomposition
# ============================================================================

suite "Isolates (#119)":
  test "isolates on empty graph":
    let g = newGraph[int]()
    check numberOfIsolates(g) == 0

  test "isolates on graph with isolated nodes":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    g.addNode(3)
    g.addEdge(1, 2)
    check isIsolate(g, 3) == true
    check isIsolate(g, 1) == false
    check numberOfIsolates(g) == 1
    var iso: seq[int]
    for n in isolates(g):
      iso.add(n)
    check iso == @[3]

  test "isolates on DiGraph":
    var dg = newDiGraph[int]()
    dg.addNode(1)
    dg.addNode(2)
    dg.addEdge(1, 2)
    dg.addNode(3)
    check isIsolate(dg, 3) == true
    check isIsolate(dg, 1) == false
    check numberOfIsolates(dg) == 1

  test "all nodes isolated":
    var g = newGraph[int]()
    g.addNodesFrom([1, 2, 3])
    check numberOfIsolates(g) == 3

  test "no isolates":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    check numberOfIsolates(g) == 0

suite "Local Bridges (#119)":
  test "no local bridges in triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    check localBridges(g).len == 0

  test "all edges are local bridges in a path":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
    check localBridges(g).len == 3

  test "local bridge with span in cycle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4), (4, 1)])
    let lb = localBridges(g)
    check lb.len > 0

suite "Chain Decomposition (#119)":
  test "chain decomposition of tree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (2, 4)])
    check chainDecomposition(g).len == 0

  test "chain decomposition of cycle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    check chainDecomposition(g).len >= 1

  test "chain decomposition of empty graph":
    let g = newGraph[int]()
    check chainDecomposition(g).len == 0

# ============================================================================
# Issue #106: Harmonic centrality
# ============================================================================

suite "Harmonic Centrality (#106)":
  test "complete graph K3":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let hc = harmonicCentrality(g)
    for n in g.nodes:
      check abs(hc[n] - 1.0) < 1e-10

  test "path graph P3":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    let hc = harmonicCentrality(g)
    check abs(hc[2] - 1.0) < 1e-10
    check abs(hc[1] - 0.75) < 1e-10

  test "disconnected graph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addNode(3)
    let hc = harmonicCentrality(g)
    check abs(hc[3] - 0.0) < 1e-10
    check abs(hc[1] - 0.5) < 1e-10

  test "empty graph":
    let g = newGraph[int]()
    check harmonicCentrality(g).len == 0

  test "directed graph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let hc = harmonicCentrality(dg)
    check abs(hc[3] - 0.75) < 1e-10
    check abs(hc[1] - 0.0) < 1e-10

# ============================================================================
# Issue #107: Directed reciprocity
# ============================================================================

suite "Directed Reciprocity (#107)":
  test "fully reciprocal":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 1)
    dg.addEdge(2, 3); dg.addEdge(3, 2)
    check abs(reciprocity(dg) - 1.0) < 1e-10

  test "no reciprocal edges":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 3); dg.addEdge(3, 1)
    check abs(reciprocity(dg) - 0.0) < 1e-10

  test "partial reciprocity":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 1); dg.addEdge(2, 3)
    check abs(reciprocity(dg) - 2.0/3.0) < 1e-10

  test "empty digraph":
    let dg = newDiGraph[int]()
    check abs(reciprocity(dg) - 0.0) < 1e-10

  test "overall reciprocity alias":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 1)
    check abs(overallReciprocity(dg) - 1.0) < 1e-10

# ============================================================================
# Issue #122: Extended clustering
# ============================================================================

suite "Extended Clustering (#122)":
  test "square clustering on diamond graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)])
    let sc = squareClustering(g)
    # Nodes 2 and 3 participate in squares (1-2-4-3 is a 4-cycle)
    check sc.len == 4

  test "square clustering all nodes":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    let sc = squareClustering(g)
    for n in g.nodes:
      check sc[n] >= 0.0

  test "generalized degree on triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let gd = generalizedDegree(g, 1)
    # Each edge from 1 (to 2 and to 3) has exactly 1 triangle
    check gd[1] == 2

  test "generalized degree all nodes":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    let gd = generalizedDegree(g)
    check gd.len == 3

  test "all triangles in K4":
    var g = newGraph[int]()
    for i in 1..4:
      for j in i+1..4:
        g.addEdge(i, j)
    let tri = allTriangles(g)
    check tri.len == 4  # C(4,3) = 4

  test "all triangles in path":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    check allTriangles(g).len == 0

# ============================================================================
# Issue #126: Extended traversal
# ============================================================================

suite "Extended Traversal (#126)":
  test "descendants at distance 0":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
    let d = descendantsAtDistance(g, 1, 0)
    check 1 in d

  test "descendants at distance 2":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
    let d = descendantsAtDistance(g, 1, 2)
    check 3 in d
    check 1 notin d
    check 2 notin d

  test "descendants at distance digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 3)
    let d = descendantsAtDistance(dg, 1, 1)
    check 2 in d

  test "edge BFS":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    var edges: seq[(int, int)]
    for e in edgeBfs(g, 1):
      edges.add(e)
    check edges.len == 3  # All 3 edges in the triangle

  test "edge DFS":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    var edges: seq[(int, int)]
    for e in edgeDfs(g, 1):
      edges.add(e)
    check edges.len == 3

  test "DFS predecessors":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (2, 4)])
    let pred = dfsPredecessors(g, 1)
    check pred.len >= 2  # At least 2 nodes have a predecessor

  test "DFS successors":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (2, 4)])
    let succ = dfsSuccessors(g, 1)
    check succ.len >= 1

  test "DFS predecessors digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 3)
    let pred = dfsPredecessors(dg, 1)
    check pred[2] == 1
    check pred[3] == 2

  test "DFS successors digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(1, 3)
    let succ = dfsSuccessors(dg, 1)
    check succ[1].len == 2

# ============================================================================
# Issue #125: Extended DAG
# ============================================================================

suite "Extended DAG (#125)":
  test "topological generations":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 3); dg.addEdge(2, 3); dg.addEdge(3, 4)
    let gens = topologicalGenerations(dg)
    check gens.len == 3
    check gens[0].sorted == @[1, 2]
    check gens[1] == @[3]
    check gens[2] == @[4]

  test "topological generations cycle raises":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 1)
    expect HasACycle:
      discard topologicalGenerations(dg)

  test "all topological sorts empty":
    let dg = newDiGraph[int]()
    check allTopologicalSorts(dg) == @[newSeq[int]()]

  test "all topological sorts diamond":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(1, 3); dg.addEdge(2, 4); dg.addEdge(3, 4)
    let sorts = allTopologicalSorts(dg)
    check sorts.len == 2  # 1,2,3,4 and 1,3,2,4
    for s in sorts:
      check s[0] == 1
      check s[3] == 4

  test "lexicographical topological sort":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 3); dg.addEdge(2, 3); dg.addEdge(3, 4)
    let s = lexicographicalTopologicalSort(dg)
    check s == @[1, 2, 3, 4]

  test "dag longest path length":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 3); dg.addEdge(3, 4)
    check dagLongestPathLength(dg) == 3

  test "antichains on diamond":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(1, 3); dg.addEdge(2, 4); dg.addEdge(3, 4)
    let ac = antichains(dg)
    # {2, 3} is an antichain (neither is ancestor of the other)
    var found = false
    for a in ac:
      if a.sorted == @[2, 3]:
        found = true
    check found

# ============================================================================
# Issue #128: Extended Euler and cycles
# ============================================================================

suite "Extended Euler (#128)":
  test "hasEulerianPath on Eulerian graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    check hasEulerianPath(g) == true

  test "hasEulerianPath on semi-Eulerian graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    check hasEulerianPath(g) == true

  test "hasEulerianPath on non-Eulerian graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (1, 4)])
    check hasEulerianPath(g) == false

  test "hasEulerianPath directed":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 3); dg.addEdge(3, 1)
    check hasEulerianPath(dg) == true

suite "Extended Cycles (#128)":
  test "minimum cycle basis of triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let mcb = minimumCycleBasis(g)
    check mcb.len == 1

  test "minimum cycle basis of K4":
    var g = newGraph[int]()
    for i in 1..4:
      for j in i+1..4:
        g.addEdge(i, j)
    let mcb = minimumCycleBasis(g)
    # K4 has 3 independent cycles
    check mcb.len == 3

# =============================================================================
# #120 — Extended Assortativity
# =============================================================================
suite "Extended Assortativity (#120)":
  test "degree Pearson correlation":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4), (4, 5)])
    let r = degreePearsonCorrelation(g)
    # Path graph has negative assortativity
    check r < 0.5

  test "degree Pearson correlation single edge":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    # Single edge – both degrees equal, NaN → return 0.0
    let r = degreePearsonCorrelation(g)
    check r >= -1.0 and r <= 1.0

  test "average neighbor degree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (2, 3)])
    let avgN = averageNeighborDegree(g)
    check avgN.len == 3
    # Node 1: neighbors are 2(deg2) and 3(deg2) → avg = 2.0
    check avgN[1] == 2.0

  test "average degree connectivity":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (2, 3), (3, 4)])
    let adc = averageDegreeConnectivity(g)
    check adc.len > 0

  test "degree mixing matrix":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    let m = degreeMixingMatrix(g)
    check m.len > 0

# =============================================================================
# #127 — Extended Tree / MST
# =============================================================================
suite "Extended Tree/MST (#127)":
  test "maximum spanning tree":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 3.0)
    g.addWeightedEdge(1, 3, 2.0)
    let mst = maximumSpanningTree(g)
    check mst.numberOfEdges() == 2
    # Should include edges with weights 3.0 and 2.0
    let w = maximumSpanningTreeWeight(g)
    check w == 5.0

  test "Boruvka MST":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(1, 3, 3.0)
    let mst = boruvkaMST(g)
    check mst.numberOfEdges() == 2
    # Minimum spanning tree weights: 1.0 + 2.0 = 3.0
    var totalWeight = 0.0
    for (u, v) in mst.edges:
      totalWeight += mst[u, v].getWeight()
    check totalWeight == 3.0

  test "isArborescence true":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(1, 3); dg.addEdge(2, 4)
    check isArborescence(dg) == true

  test "isArborescence false - multiple roots":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(3, 4)
    check isArborescence(dg) == false

  test "isBranching true":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(3, 4)
    check isBranching(dg) == true

  test "isBranching false - cycle":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2); dg.addEdge(2, 1)
    check isBranching(dg) == false

  test "tree centroid of path":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4), (4, 5)])
    let c = treeCentroid(g)
    check c.len == 1
    check c[0] == 3

  test "tree centroid of star":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (1, 4), (1, 5)])
    let c = treeCentroid(g)
    check c.len == 1
    check c[0] == 1
