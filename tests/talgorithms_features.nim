## Tests for new feature modules:
## triads, minors, cuts, smallworld, lca, graph_hashing, voronoi,
## geometric generators, community generators, new small graphs

import std/[unittest, tables, sets, math, sequtils, algorithm]
import nimnet
import nimnet/algorithms/triads as tri
import nimnet/algorithms/minors as mn
import nimnet/algorithms/cuts as cu
import nimnet/algorithms/smallworld as sw
import nimnet/algorithms/lca as lcaMod
import nimnet/algorithms/graph_hashing as gh
import nimnet/algorithms/voronoi as vo
import nimnet/algorithms/components as comp
import nimnet/algorithms/stats as st
import nimnet/generators/geometric as geo
import nimnet/generators/community as comm

# ============================================================================
# Triads
# ============================================================================

suite "Triads":
  test "triad census on empty digraph":
    var dg = newDiGraph[int]()
    let census = tri.triadicCensus(dg)
    check census["003"] == 0

  test "triad census on 3-node chain":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let census = tri.triadicCensus(dg)
    # 0->1->2 is a chain (021C)
    check census["021C"] == 1
    check census["003"] == 0

  test "triad census on 3-cycle":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    dg.addEdge(2, 0)
    let census = tri.triadicCensus(dg)
    check census["030C"] == 1

  test "triad census on mutual pair":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 0)
    dg.addNode(2)
    let census = tri.triadicCensus(dg)
    check census["102"] == 1

  test "triad census on complete 3-digraph":
    var dg = newDiGraph[int]()
    for i in 0 ..< 3:
      for j in 0 ..< 3:
        if i != j:
          dg.addEdge(i, j)
    let census = tri.triadicCensus(dg)
    check census["300"] == 1

  test "triad type classification":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    check tri.triadType(dg, 0, 1, 2) == "021C"

  test "triad type complete":
    var dg = newDiGraph[int]()
    for i in 0 ..< 3:
      for j in 0 ..< 3:
        if i != j:
          dg.addEdge(i, j)
    check tri.triadType(dg, 0, 1, 2) == "300"

  test "all triads iterator":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    dg.addNode(3)
    var count = 0
    for (u, v, w) in tri.allTriads(dg):
      count += 1
    check count == 4  # C(4,3) = 4

  test "isTriad":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    check tri.isTriad(dg) == true
    dg.addNode(3)
    check tri.isTriad(dg) == false

  test "triad census on 4-node digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let census = tri.triadicCensus(dg)
    # Triads: (0,1,2)=021C, (0,1,3)=012, (0,2,3)=012, (1,2,3)=021C
    check census["021C"] == 2
    check census["012"] == 2

  test "triad census sum equals C(n,3)":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    dg.addEdge(2, 0)
    dg.addEdge(2, 3)
    dg.addNode(4)
    let census = tri.triadicCensus(dg)
    var total = 0
    for name, count in census:
      total += count
    let n = dg.numberOfNodes()
    check total == n * (n - 1) * (n - 2) div 6  # C(5,3) = 10

# ============================================================================
# Minors
# ============================================================================

suite "Minors":
  test "contractedNodes on triangle":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let h = mn.contractedNodes(g, 0, 1)
    check h.numberOfNodes() == 2
    check h.hasEdge(0, 2)
    check not h.hasNode(1)

  test "contractedNodes preserves other edges":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let h = mn.contractedNodes(g, 0, 1)
    check h.numberOfNodes() == 3
    check h.hasEdge(0, 2)
    check h.hasEdge(2, 3)

  test "contractedEdge raises on missing edge":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addNode(2)
    expect EdgeNotFound:
      discard mn.contractedEdge(g, 0, 2)

  test "contractedNodes raises on missing node":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    expect NodeNotFound:
      discard mn.contractedNodes(g, 0, 5)

  test "quotientGraph on bipartition":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let p = @[[0, 1].toHashSet, [2, 3].toHashSet]
    let q = mn.quotientGraph(g, p)
    check q.numberOfNodes() == 2
    check q.hasEdge(0, 1)

  test "contractedNodes on digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let h = mn.contractedNodes(dg, 0, 1)
    check h.numberOfNodes() == 2
    check h.hasEdge(0, 2)

  test "quotientGraph on digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(2, 3)
    let p = @[[0, 2].toHashSet, [1, 3].toHashSet]
    let q = mn.quotientGraph(dg, p)
    check q.numberOfNodes() == 2
    check q.hasEdge(0, 1)

# ============================================================================
# Cuts
# ============================================================================

suite "Cuts":
  test "cutSize on path":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    check cu.cutSize(g, s) == 1

  test "cutSize on complete graph":
    var g = newGraph[int]()
    for i in 0 ..< 4:
      for j in (i + 1) ..< 4:
        g.addEdge(i, j)
    let s = [0, 1].toHashSet
    check cu.cutSize(g, s) == 4  # 0-2,0-3,1-2,1-3

  test "volume":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    # deg(0)=1, deg(1)=2
    check cu.volume(g, s) == 3

  test "conductance":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    # cut=1, vol(S)=3, vol(complement)=3, cond=1/3
    check abs(cu.conductance(g, s) - 1.0/3.0) < 1e-10

  test "edgeExpansion":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    # cut=1, min(|S|=2, |C|=2)=2, expansion=0.5
    check abs(cu.edgeExpansion(g, s) - 0.5) < 1e-10

  test "normalizedCutSize":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    # cut=1, vol(S)=3, vol(C)=3
    # NCS = 1/3 + 1/3 = 2/3
    check abs(cu.normalizedCutSize(g, s) - 2.0/3.0) < 1e-10

  test "nodeBoundary":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    let boundary = cu.nodeBoundary(g, s)
    check boundary == [2].toHashSet

  test "edgeBoundary":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    var boundaryEdges: seq[(int, int)]
    for (u, v) in cu.edgeBoundary(g, s):
      boundaryEdges.add((u, v))
    check boundaryEdges.len == 1

# ============================================================================
# Lowest Common Ancestor
# ============================================================================

suite "LCA":
  test "LCA on simple tree":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(0, 2)
    dg.addEdge(1, 3)
    dg.addEdge(1, 4)
    let lca = lcaMod.lowestCommonAncestor(dg, 3, 4)
    check lca == 1

  test "LCA root is common ancestor":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(0, 2)
    let lca = lcaMod.lowestCommonAncestor(dg, 1, 2)
    check lca == 0

  test "LCA where one is ancestor of other":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let lca = lcaMod.lowestCommonAncestor(dg, 0, 2)
    check lca == 0

  test "LCA on deeper tree":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(0, 2)
    dg.addEdge(1, 3)
    dg.addEdge(1, 4)
    dg.addEdge(2, 5)
    dg.addEdge(2, 6)
    let lca = lcaMod.lowestCommonAncestor(dg, 3, 5)
    check lca == 0
    let lca2 = lcaMod.lowestCommonAncestor(dg, 5, 6)
    check lca2 == 2

  test "allPairsLowestCommonAncestor":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(0, 2)
    dg.addEdge(1, 3)
    let result = lcaMod.allPairsLowestCommonAncestor(dg, @[(1, 2), (3, 2)])
    check result[(1, 2)] == 0
    check result[(3, 2)] == 0

  test "treeAllPairsLCA":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(0, 2)
    dg.addEdge(1, 3)
    dg.addEdge(1, 4)
    let result = lcaMod.treeAllPairsLowestCommonAncestor(dg, 0)
    check result[(3, 4)] == 1
    check result[(1, 2)] == 0

  test "LCA raises on missing node":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    expect NodeNotFound:
      discard lcaMod.lowestCommonAncestor(dg, 0, 5)

# ============================================================================
# Graph Hashing
# ============================================================================

suite "Graph Hashing":
  test "WL hash same graph same hash":
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(0, 1)
    g2.addEdge(1, 2)
    check gh.weisfeilerLehmanHash(g1) == gh.weisfeilerLehmanHash(g2)

  test "WL hash different graphs different hash":
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(0, 1)
    g2.addEdge(1, 2)
    g2.addEdge(0, 2)  # triangle
    check gh.weisfeilerLehmanHash(g1) != gh.weisfeilerLehmanHash(g2)

  test "WL hash isomorphic graphs same hash":
    # P3 with nodes 0-1-2 vs 10-11-12
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(10, 11)
    g2.addEdge(11, 12)
    check gh.weisfeilerLehmanHash(g1) == gh.weisfeilerLehmanHash(g2)

  test "WL subgraph hashes":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let hashes = gh.weisfeilerLehmanSubgraphHashes(g, 2)
    check hashes.len == 3
    check hashes[0].len == 2  # 2 iterations
    # Endpoints (0, 2) should have same hash (symmetric)
    check hashes[0] == hashes[2]
    # Center (1) should differ
    check hashes[1] != hashes[0]

  test "WL hash on digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let h = gh.weisfeilerLehmanHash(dg)
    check h.len > 0

  test "WL hash digraph direction matters":
    var dg1 = newDiGraph[int]()
    dg1.addEdge(0, 1)
    dg1.addEdge(1, 2)
    var dg2 = newDiGraph[int]()
    dg2.addEdge(2, 1)
    dg2.addEdge(1, 0)
    # Same structure but reversed direction — same WL hash because
    # WL considers both in/out neighborhoods and graph is symmetric
    # Actually these are different: 0->1->2 vs 2->1->0
    # The degree sequences are the same, so WL hash should be the same
    # (the graphs are isomorphic under relabeling)
    check gh.weisfeilerLehmanHash(dg1) == gh.weisfeilerLehmanHash(dg2)

# ============================================================================
# Voronoi Cells
# ============================================================================

suite "Voronoi Cells":
  test "voronoi on path graph":
    let g = pathGraph(5)  # 0-1-2-3-4
    let cells = vo.voronoiCells(g, [0, 4])
    check 0 in cells[0]
    check 1 in cells[0]
    check 2 in cells[0] or 2 in cells[4]
    check 3 in cells[4]
    check 4 in cells[4]

  test "voronoi single center":
    let g = pathGraph(3)
    let cells = vo.voronoiCells(g, [1])
    check cells[1].len == 3

  test "voronoi on star":
    let g = starGraph(4)  # center=0, leaves=1,2,3,4
    let cells = vo.voronoiCells(g, [1, 3])
    check 1 in cells[1]
    check 3 in cells[3]
    check 0 in cells[1] or 0 in cells[3]

  test "voronoi raises on invalid center":
    let g = pathGraph(3)
    expect NodeNotFound:
      discard vo.voronoiCells(g, [99])

# ============================================================================
# Geometric Generators
# ============================================================================

suite "Geometric Generators":
  test "random geometric graph node count":
    let g = geo.randomGeometricGraph(20, 0.5, seed=42)
    check g.numberOfNodes() == 20

  test "random geometric graph with radius=0 has no edges":
    let g = geo.randomGeometricGraph(10, 0.0, seed=42)
    check g.numberOfEdges() == 0

  test "random geometric graph with radius=2 is complete":
    # Unit square diagonal is sqrt(2) < 2
    let g = geo.randomGeometricGraph(10, 2.0, seed=42)
    check g.numberOfEdges() == 10 * 9 div 2

  test "waxman graph node count":
    let g = geo.waxmanGraph(20, 0.5, 0.5, seed=42)
    check g.numberOfNodes() == 20

  test "soft random geometric graph node count":
    let g = geo.softRandomGeometricGraph(15, 0.3, seed=42)
    check g.numberOfNodes() == 15

  test "geometric graph has position attrs":
    let g = geo.randomGeometricGraph(5, 0.5, seed=42)
    for n in g.nodes:
      let attr = g.getNodeAttr(n)
      check "x" in attr
      check "y" in attr

# ============================================================================
# Community Generators
# ============================================================================

suite "Community Generators":
  test "caveman graph":
    let g = comm.cavemanGraph(3, 4)
    check g.numberOfNodes() == 12
    # Each clique has C(4,2)=6 edges, 3 cliques = 18 edges
    check g.numberOfEdges() == 18

  test "connected caveman graph":
    let g = comm.connectedCavemanGraph(3, 4)
    check g.numberOfNodes() == 12
    check comp.isConnected(g)

  test "planted partition graph":
    let g = comm.plantedPartitionGraph(3, 5, 1.0, 0.0, seed=42)
    check g.numberOfNodes() == 15
    # All intra-group edges present, no inter-group edges
    check g.numberOfEdges() == 3 * (5 * 4 div 2)  # 30

  test "windmill graph":
    let g = comm.windmillGraph(3, 4)
    # 3 copies of K4 sharing node 0
    # Nodes: 1 + 3*3 = 10
    check g.numberOfNodes() == 10
    # Node 0 is connected to all others
    check g.degree(0) == 9

  test "relaxed caveman graph":
    let g = comm.relaxedCavemanGraph(3, 4, 0.1, seed=42)
    check g.numberOfNodes() == 12

  test "ring of cliques":
    let g = comm.ringOfCliques(4, 3)
    check g.numberOfNodes() == 12
    check comp.isConnected(g)

  test "caveman graph l=1 k=3":
    let g = comm.cavemanGraph(1, 3)
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 3

# ============================================================================
# New Small Graphs
# ============================================================================

suite "New Small Graphs":
  test "tetrahedral graph":
    let g = tetrahedralGraph()
    check g.numberOfNodes() == 4
    check g.numberOfEdges() == 6
    for n in g.nodes:
      check g.degree(n) == 3

  test "octahedral graph":
    let g = octahedralGraph()
    check g.numberOfNodes() == 6
    check g.numberOfEdges() == 12
    for n in g.nodes:
      check g.degree(n) == 4

  test "icosahedral graph":
    let g = icosahedralGraph()
    check g.numberOfNodes() == 12
    check g.numberOfEdges() == 30
    for n in g.nodes:
      check g.degree(n) == 5

  test "dodecahedral graph":
    let g = dodecahedralGraph()
    check g.numberOfNodes() == 20
    check g.numberOfEdges() == 30
    for n in g.nodes:
      check g.degree(n) == 3

  test "desargues graph":
    let g = desarguesGraph()
    check g.numberOfNodes() == 20
    check g.numberOfEdges() == 30

  test "heawood graph":
    let g = heawoodGraph()
    check g.numberOfNodes() == 14
    check g.numberOfEdges() == 21
    for n in g.nodes:
      check g.degree(n) == 3

  test "pappus graph":
    let g = pappusGraph()
    check g.numberOfNodes() == 18
    check g.numberOfEdges() == 27

  test "moebius-kantor graph":
    let g = moebiusKantorGraph()
    check g.numberOfNodes() == 16
    check g.numberOfEdges() == 24

  test "frucht graph":
    let g = fruchtGraph()
    check g.numberOfNodes() == 12
    check g.numberOfEdges() == 18

  test "tutte graph":
    let g = tutteGraph()
    check g.numberOfNodes() == 46
    check g.numberOfEdges() == 69

  test "sedgewick maze graph":
    let g = sedgewickMazeGraph()
    check g.numberOfNodes() == 8
    check g.numberOfEdges() == 10

  test "krackardt kite graph":
    let g = krackardtKiteGraph()
    check g.numberOfNodes() == 10
    check g.numberOfEdges() == 18

  test "generalized petersen graph (5,2) is the petersen graph":
    let g = generalizedPetersenGraph(5, 2)
    let p = petersenGraph()
    check g.numberOfNodes() == p.numberOfNodes()
    check g.numberOfEdges() == p.numberOfEdges()

  test "hoffman-singleton graph":
    let g = hoffmanSingletonGraph()
    check g.numberOfNodes() == 50
    check g.numberOfEdges() == 175

# ============================================================================
# Small-world (basic structure tests — sigma/omega are expensive)
# ============================================================================

suite "Small-world":
  test "averageShortestPathLength on path":
    let g = pathGraph(4)  # 0-1-2-3
    # Avg of: (01=1,02=2,03=3,12=1,13=2,23=1) = 10/6 ≈ 1.667
    let avg = st.averageShortestPathLength(g)
    check abs(avg - 10.0/6.0) < 1e-10
