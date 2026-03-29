## Tests for new algorithm modules, generators, and I/O:
## distance_measures, simple_paths, efficiency, richclub, wiener,
## cycles, matching, graph_products, line_graph, lattice, gexf,
## classic generators (barbell, lollipop, ladder, etc.)

import std/[unittest, tables, sets, math, os, algorithm, sequtils, strutils]
import nimnet
import nimnet/algorithms/distance_measures as dm
import nimnet/algorithms/efficiency as eff
import nimnet/algorithms/richclub as rc
import nimnet/algorithms/wiener as wi
import nimnet/algorithms/cycles as cy
import nimnet/algorithms/matching as mat
import nimnet/algorithms/graph_products as gp

# ============================================================================
# Distance Measures
# ============================================================================

suite "Distance Measures":
  test "eccentricity of path graph":
    let g = pathGraph(5)  # 0-1-2-3-4
    check dm.eccentricity(g, 0) == 4
    check dm.eccentricity(g, 2) == 2
    check dm.eccentricity(g, 4) == 4

  test "diameter of path graph":
    let g = pathGraph(5)
    check dm.diameter(g) == 4

  test "radius of path graph":
    let g = pathGraph(5)
    check dm.radius(g) == 2

  test "center of path graph":
    let g = pathGraph(5)
    let c = dm.center(g)
    check 2 in c

  test "periphery of path graph":
    let g = pathGraph(5)
    let p = dm.periphery(g)
    check 0 in p
    check 4 in p

  test "diameter of complete graph":
    let g = completeGraph(5)
    check dm.diameter(g) == 1

  test "radius of complete graph":
    let g = completeGraph(5)
    check dm.radius(g) == 1

  test "eccentricityMap":
    let g = cycleGraph(4)  # 0-1-2-3-0
    let ecc = dm.eccentricityMap(g)
    for v in g.nodes:
      check ecc[v] == 2

  test "barycenter of path graph":
    let g = pathGraph(5)
    let bc = dm.barycenter(g)
    check 2 in bc

  test "diameter of cycle graph":
    let g = cycleGraph(6)
    check dm.diameter(g) == 3

# ============================================================================
# Simple Paths
# ============================================================================

suite "Simple Paths":
  test "allSimplePaths in undirected graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    let paths = allSimplePathsSeq(g, 1, 3)
    check paths.len == 2  # 1-3 direct and 1-2-3

  test "allSimplePaths with cutoff":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (1,3)])
    let paths = allSimplePathsSeq(g, 1, 3, cutoff = 1)
    check paths.len == 1  # only 1-3 direct

  test "allSimplePaths in directed graph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(1, 3)
    let paths = allSimplePathsSeq(dg, 1, 3)
    check paths.len == 2

  test "isSimplePath true":
    check isSimplePath(@[1, 2, 3])

  test "isSimplePath false — repeated node":
    check not isSimplePath(@[1, 2, 1])

  test "isSimplePath empty":
    var empty: seq[int]
    check not isSimplePath(empty)

  test "allSimplePaths source not in graph raises":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    expect NodeNotFound:
      discard allSimplePathsSeq(g, 99, 2)

  test "allSimplePaths no path returns empty":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    let paths = allSimplePathsSeq(g, 1, 2)
    check paths.len == 0

  test "allSimplePaths diamond graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (1,3), (2,4), (3,4)])
    let paths = allSimplePathsSeq(g, 1, 4)
    check paths.len == 2  # 1-2-4 and 1-3-4

# ============================================================================
# Efficiency
# ============================================================================

suite "Efficiency":
  test "globalEfficiency complete graph":
    let g = completeGraph(4)
    # All pairs at distance 1, so efficiency = 1.0
    check abs(eff.globalEfficiency(g) - 1.0) < 1e-10

  test "globalEfficiency empty graph":
    var g = newGraph[int]()
    check eff.globalEfficiency(g) == 0.0

  test "globalEfficiency path graph":
    let g = pathGraph(3)  # 0-1-2
    # Pairs: (0,1)=1, (0,2)=2, (1,2)=1
    # Sum of inverses (both directions): 2*(1/1 + 1/2 + 1/1) = 5
    # n*(n-1) = 6
    # Global efficiency = 5/6
    check abs(eff.globalEfficiency(g) - 5.0/6.0) < 1e-10

  test "localEfficiency of central node in star":
    let g = starGraph(3)  # center 0, leaves 1,2,3
    # Neighbors of 0 are {1,2,3} — no edges between them
    check eff.localEfficiency(g, 0) == 0.0

  test "localEfficiency of node in complete graph":
    let g = completeGraph(4)
    # Neighbors form K3, which has efficiency 1.0
    check abs(eff.localEfficiency(g, 0) - 1.0) < 1e-10

  test "averageLocalEfficiency":
    let g = completeGraph(4)
    check abs(eff.averageLocalEfficiency(g) - 1.0) < 1e-10

# ============================================================================
# Rich Club
# ============================================================================

suite "Rich Club":
  test "richClubCoefficient complete graph":
    let g = completeGraph(4)
    let phi = rc.richClubCoefficient(g)
    # All nodes have same degree, so phi(0) should be 1.0
    check abs(phi[0] - 1.0) < 1e-10

  test "richClubCoefficient star graph":
    let g = starGraph(4)  # center degree 4, leaves degree 1
    let phi = rc.richClubCoefficient(g)
    check phi.len > 0

  test "richClubCoefficient path graph":
    let g = pathGraph(5)
    let phi = rc.richClubCoefficient(g)
    check 0 in phi

# ============================================================================
# Wiener Index
# ============================================================================

suite "Wiener Index":
  test "wienerIndex of path graph":
    let g = pathGraph(4)  # 0-1-2-3
    # Distances: (0,1)=1, (0,2)=2, (0,3)=3, (1,2)=1, (1,3)=2, (2,3)=1
    # Sum = 1+2+3+1+2+1 = 10
    check wi.wienerIndex(g) == 10

  test "wienerIndex of complete graph":
    let g = completeGraph(4)
    # All pairs at distance 1, C(4,2) = 6 pairs
    check wi.wienerIndex(g) == 6

  test "wienerIndex single node":
    var g = newGraph[int]()
    g.addNode(0)
    check wi.wienerIndex(g) == 0

  test "averageShortestPathLength of complete graph (via stats)":
    let g = completeGraph(4)
    check abs(averageShortestPathLength(g) - 1.0) < 1e-10

  test "averageShortestPathLength of path (via stats)":
    let g = pathGraph(3)  # 0-1-2
    # (0,1)=1, (0,2)=2, (1,0)=1, (1,2)=1, (2,0)=2, (2,1)=1 → sum=8, pairs=6
    check abs(averageShortestPathLength(g) - 8.0/6.0) < 1e-10

# ============================================================================
# Cycles
# ============================================================================

suite "Cycles":
  test "cycleBasis of triangulated graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(0,1), (1,2), (2,0), (2,3), (3,0)])
    let basis = cy.cycleBasis(g)
    # Should have 2 independent cycles
    check basis.len >= 1

  test "cycleBasis of tree is empty":
    let g = pathGraph(4)
    let basis = cy.cycleBasis(g)
    check basis.len == 0

  test "cycleBasis of single cycle":
    let g = cycleGraph(4)
    let basis = cy.cycleBasis(g)
    check basis.len == 1

  test "simpleCyclesDirected — triangle":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    dg.addEdge(2, 0)
    let cycles = cy.simpleCyclesDirected(dg)
    check cycles.len >= 1

  test "simpleCyclesDirected — DAG has no cycles":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let cycles = cy.simpleCyclesDirected(dg)
    check cycles.len == 0

# ============================================================================
# Matching
# ============================================================================

suite "Matching":
  test "maximalMatching basic":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (3,4), (5,6)])
    let m = mat.maximalMatching(g)
    check m.len == 3

  test "isMatching valid":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (3,4)])
    check mat.isMatching(g, @[(1, 2), (3, 4)])

  test "isMatching invalid — shared node":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    check not mat.isMatching(g, @[(1, 2), (2, 3)])

  test "isPerfectMatching true":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (3,4)])
    check mat.isPerfectMatching(g, @[(1, 2), (3, 4)])

  test "isPerfectMatching false":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3)])
    check not mat.isPerfectMatching(g, @[(1, 2)])

  test "maximalMatching of path covers most nodes":
    let g = pathGraph(6)  # 0-1-2-3-4-5
    let m = mat.maximalMatching(g)
    check m.len >= 2

  test "maxWeightMatching returns valid matching":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    let m = mat.maxWeightMatching(g)
    check mat.isMatching(g, m)

  test "minWeightMatching returns valid matching":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,4)])
    let m = mat.minWeightMatching(g)
    check mat.isMatching(g, m)

# ============================================================================
# Graph Products
# ============================================================================

suite "Graph Products":
  test "cartesianProduct of two edges":
    let g1 = pathGraph(2)  # 0-1
    let g2 = pathGraph(2)  # 0-1
    let cp = gp.cartesianProduct(g1, g2)
    # C4 (4-cycle), 4 nodes, 4 edges
    check cp.numberOfNodes() == 4
    check cp.numberOfEdges() == 4

  test "tensorProduct of two edges":
    let g1 = pathGraph(2)  # 0-1
    let g2 = pathGraph(2)  # 0-1
    let tp = gp.tensorProduct(g1, g2)
    check tp.numberOfNodes() == 4
    check tp.numberOfEdges() == 2  # (0,0)-(1,1) and (0,1)-(1,0)

  test "strongProduct of two edges":
    let g1 = pathGraph(2)
    let g2 = pathGraph(2)
    let sp = gp.strongProduct(g1, g2)
    check sp.numberOfNodes() == 4
    # Strong product of K2 x K2 = K4: 4+1=5 edges? Actually it's complete
    check sp.numberOfEdges() >= 4

  test "lexicographicProduct of two edges":
    let g1 = pathGraph(2)
    let g2 = pathGraph(2)
    let lp = gp.lexicographicProduct(g1, g2)
    check lp.numberOfNodes() == 4
    check lp.numberOfEdges() >= 2

  test "cartesianProduct node count":
    let g1 = pathGraph(3)  # 3 nodes
    let g2 = pathGraph(2)  # 2 nodes
    let cp = gp.cartesianProduct(g1, g2)
    check cp.numberOfNodes() == 6

# ============================================================================
# Line Graph
# ============================================================================

suite "Line Graph":
  test "lineGraph of triangle":
    let g = cycleGraph(3)  # triangle: 3 edges
    let lg = lineGraph(g)
    check lg.numberOfNodes() == 3
    check lg.numberOfEdges() == 3  # each pair of edges shares an endpoint

  test "lineGraph of path":
    let g = pathGraph(4)  # 3 edges: 0-1, 1-2, 2-3
    let lg = lineGraph(g)
    check lg.numberOfNodes() == 3
    check lg.numberOfEdges() == 2  # adjacent edges

  test "lineGraph of star":
    let g = starGraph(3)  # 3 edges from center
    let lg = lineGraph(g)
    check lg.numberOfNodes() == 3
    check lg.numberOfEdges() == 3  # all pairs share the center

# ============================================================================
# Lattice Generators
# ============================================================================

suite "Lattice Generators":
  test "grid2dGraph dimensions":
    let g = grid2dGraph(3, 4)
    check g.numberOfNodes() == 12
    # 3*4 grid: (3-1)*4 + 3*(4-1) = 8+9 = 17 edges
    check g.numberOfEdges() == 17

  test "grid2dGraph periodic (torus)":
    let g = grid2dGraph(3, 3, periodic = true)
    check g.numberOfNodes() == 9
    # 3x3 torus: each node has degree 4 → 18 edges
    check g.numberOfEdges() == 18

  test "triangularLatticeGraph":
    let g = triangularLatticeGraph(3, 3)
    check g.numberOfNodes() == 9
    # Grid edges + diagonals
    check g.numberOfEdges() > 12

  test "hypercubeGraph Q3":
    let g = hypercubeGraph(3)
    check g.numberOfNodes() == 8
    check g.numberOfEdges() == 12  # Q3 has 12 edges

  test "hypercubeGraph Q1 is edge":
    let g = hypercubeGraph(1)
    check g.numberOfNodes() == 2
    check g.numberOfEdges() == 1

  test "hypercubeGraph Q4":
    let g = hypercubeGraph(4)
    check g.numberOfNodes() == 16
    check g.numberOfEdges() == 32  # Q4 has 32 edges

# ============================================================================
# Classic Generators (new)
# ============================================================================

suite "Classic Generators (extended)":
  test "nullGraph":
    let g = nullGraph()
    check g.numberOfNodes() == 0
    check g.numberOfEdges() == 0

  test "barbellGraph":
    let g = barbellGraph(3, 2)
    # 3 + 2 + 3 = 8 nodes
    check g.numberOfNodes() == 8
    # K3 (3 edges) + bridge (3 edges) + K3 (3 edges) = 9 edges
    check g.numberOfEdges() == 9

  test "lollipopGraph":
    let g = lollipopGraph(4, 3)
    # 4 + 3 = 7 nodes
    check g.numberOfNodes() == 7

  test "ladderGraph":
    let g = ladderGraph(4)
    check g.numberOfNodes() == 8
    # 3 + 3 + 4 = 10 edges
    check g.numberOfEdges() == 10

  test "circularLadderGraph":
    let g = circularLadderGraph(4)
    check g.numberOfNodes() == 8
    # 4 + 4 + 4 = 12 edges
    check g.numberOfEdges() == 12

  test "tadpoleGraph":
    let g = tadpoleGraph(4, 3)
    check g.numberOfNodes() == 7

  test "turanGraph":
    let g = turanGraph(6, 3)
    # T(6,3) = K_{2,2,2} = 12 edges
    check g.numberOfNodes() == 6
    check g.numberOfEdges() == 12

  test "bookGraph":
    let g = bookGraph(3)
    # 3 triangles sharing edge (0,1): nodes 0, 1, 2, 3, 4
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 7  # 1 + 2*3 = 7

  test "friendshipGraph":
    let g = friendshipGraph(3)
    # 3 triangles: center 0, pairs (1,2), (3,4), (5,6)
    check g.numberOfNodes() == 7
    check g.numberOfEdges() == 9

# ============================================================================
# GEXF I/O
# ============================================================================

suite "GEXF I/O":
  test "write and read undirected GEXF":
    var g = newGraph[int]()
    g.addEdgesFrom([(1,2), (2,3), (3,1)])
    let tmpFile = "test_gexf_undirected.gexf"
    writeGexf(g, tmpFile)
    let loaded = readGexf(tmpFile)
    check loaded.numberOfNodes() == 3
    check loaded.numberOfEdges() == 3
    removeFile(tmpFile)

  test "write and read directed GEXF":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let tmpFile = "test_gexf_directed.gexf"
    writeGexf(dg, tmpFile)
    let loaded = readGexfDirected(tmpFile)
    check loaded.numberOfNodes() == 3
    check loaded.numberOfEdges() == 2
    removeFile(tmpFile)

  test "GEXF file format structure":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let tmpFile = "test_gexf_struct.gexf"
    writeGexf(g, tmpFile)
    let content = readFile(tmpFile)
    check content.contains("gexf")
    check content.contains("undirected")
    check content.contains("<nodes>")
    check content.contains("<edges>")
    removeFile(tmpFile)
