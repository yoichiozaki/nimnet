## Tests for new features - Batch 2
## Covers issues: #105, #108, #109, #110, #111, #112, #113, #114, #115,
## #116, #117, #118, #121, #123, #124, #129, #130, #131, #132, #133, #134, #135

import std/[unittest, tables, sets, math, sequtils, algorithm]
import nimnet

# ============================================================================
# Issue #121: Extended Centrality
# ============================================================================

suite "Extended Centrality (#121)":
  test "edge betweenness centrality":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let ebc = edgeBetweennessCentrality(g)
    # Middle edge (2,3) should have highest betweenness
    check ebc[(2, 3)] > ebc[(1, 2)]

  test "subgraph centrality":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let sc = subgraphCentrality(g)
    check sc.len == 3
    for n, v in sc:
      check v > 0.0

  test "dispersion":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (1, 3), (1, 4), (2, 3), (2, 4)])
    let d = dispersion(g, 1, 2)
    check d >= 0.0

  test "voteRank":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 5), (3, 5)])
    let vr = voteRank(g, 2)
    check vr.len == 2

  test "laplacian centrality":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let lc = laplacianCentrality(g)
    check lc.len == 3

  test "local and global reaching centrality":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 4)
    let lr = localReachingCentrality(dg, 1)
    check lr >= 0.0 and lr <= 1.0
    let gr = globalReachingCentrality(dg)
    check gr >= 0.0

  test "percolation centrality":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    var states = initTable[int, float]()
    states[1] = 1.0
    states[2] = 0.5
    states[3] = 0.0
    let pc = percolationCentrality(g, states)
    check pc.len == 3

  test "second order centrality":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let sc = secondOrderCentrality(g)
    check sc.len == 3

  test "trophic levels":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let tl = trophicLevels(dg)
    check tl.len == 3
    # Source should have level 1
    check tl[1] == 1.0

# ============================================================================
# Issue #108: Structural Holes
# ============================================================================

suite "Structural Holes (#108)":
  test "constraint on simple graph":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (1, 3), (2, 3)])
    let c = constraint(g)
    check c.len == 3
    for n, v in c:
      check v > 0.0

  test "effective size":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (1, 3), (2, 3)])
    let es = effectiveSize(g)
    check es.len == 3

  test "local constraint":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (1, 3), (2, 3)])
    let lc = localConstraint(g, 1, 2)
    check lc > 0.0

# ============================================================================
# Issue #109: K-Truss, Edge Cover
# ============================================================================

suite "K-Truss and Edge Cover (#109)":
  test "k-truss of triangle":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let t = kTruss(g, 3)
    check t.numberOfEdges() == 3

  test "k-truss removes non-triangle edges":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1), (4, 1)])
    let t = kTruss(g, 3)
    check t.numberOfEdges() == 3
    check not t.hasEdge(4, 1)

  test "onion layers":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1), (4, 1)])
    let layers = onionLayers(g)
    check layers.len == 4

  test "min edge cover":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let cover = minEdgeCover(g)
    check isEdgeCover(g, cover)

  test "isEdgeCover":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3)])
    check isEdgeCover(g, @[(1, 2), (2, 3)])
    check not isEdgeCover(g, @[(1, 2)])

# ============================================================================
# Issue #110: Chordal
# ============================================================================

suite "Chordal (#110)":
  test "triangle is chordal":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    check isChordal(g)

  test "4-cycle is not chordal":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 1)])
    check not isChordal(g)

  test "complete graph is chordal":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1), (1, 4), (2, 4), (3, 4)])
    check isChordal(g)

  test "perfect elimination order":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let peo = perfectEliminationOrder(g)
    check peo.len == 3

  test "chordal graph cliques":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let cliques = chordalGraphCliques(g)
    check cliques.len >= 1

# ============================================================================
# Issue #111: Graph Operators
# ============================================================================

suite "Graph Operators (#111)":
  test "symmetric difference":
    var g1 = newGraph[int]()
    g1.addEdgesFrom(@[(1, 2), (2, 3)])
    var g2 = newGraph[int]()
    g2.addEdgesFrom(@[(2, 3), (3, 4)])
    let sd = symmetricDifference(g1, g2)
    check sd.hasEdge(1, 2)
    check sd.hasEdge(3, 4)
    check not sd.hasEdge(2, 3)

  test "full join":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(3, 4)
    let fj = fullJoin(g1, g2)
    check fj.numberOfEdges() == 6  # 1 + 1 + 4 cross edges

  test "power graph":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let p = power(g, 2)
    check p.hasEdge(1, 3)
    check p.hasEdge(2, 4)

  test "corona product":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(1, 2)
    let cp = coronaProduct(g1, g2)
    check cp.numberOfNodes() > 2

  test "modular product":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(1, 2)
    let mp = modularProduct(g1, g2)
    check mp.numberOfNodes() == 4

# ============================================================================
# Issue #112: Tournament
# ============================================================================

suite "Tournament (#112)":
  test "is tournament":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(1, 3)
    check isTournament(dg)

  test "not tournament - missing edge":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    check not isTournament(dg)

  test "random tournament":
    let t = randomTournament(5)
    check isTournament(t)
    check t.numberOfNodes() == 5

  test "score sequence":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(1, 3)
    let ss = scoreSequence(dg)
    check ss.len == 3

  test "tournament hamiltonian path":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(1, 3)
    let path = tournamentHamiltonianPath(dg)
    check path.len == 3

  test "tournament reachability":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(1, 3)
    check isTournamentReachable(dg, 1, 3)

# ============================================================================
# Issue #113: Edge Swaps
# ============================================================================

suite "Edge Swaps (#113)":
  test "double edge swap preserves degree":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 1)])
    var origDeg = initTable[int, int]()
    for n in g.nodes:
      origDeg[n] = g.degree(n)
    doubleEdgeSwap(g, 10, 100, 42)
    for n in g.nodes:
      check g.degree(n) == origDeg[n]

  test "number of walks":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3)])
    let w = numberOfWalks(g, 2)
    check w[(1, 3)] == 1  # walk of length 2: 1->2->3

# ============================================================================
# Issue #114: Communicability
# ============================================================================

suite "Communicability (#114)":
  test "communicability on triangle":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let c = communicability(g)
    check c.len > 0
    # Should have entries for all pairs
    check c[(1, 1)] > 0.0

  test "closeness vitality":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let cv = closenessVitality(g)
    check cv.len == 3

# ============================================================================
# Issue #115: D-Separation and Dominance
# ============================================================================

suite "D-Separation and Dominance (#115)":
  test "d-separation in chain":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let x = [1].toHashSet
    let y = [3].toHashSet
    let z = [2].toHashSet
    check isDSeparator(dg, x, y, z)

  test "d-separation without separator":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let x = [1].toHashSet
    let y = [3].toHashSet
    let z = initHashSet[int]()
    check not isDSeparator(dg, x, y, z)

  test "immediate dominators":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(1, 3)
    dg.addEdge(2, 4)
    dg.addEdge(3, 4)
    let idom = immediateDominators(dg, 1)
    check idom[4] == 1  # 1 dominates 4

  test "dominance frontiers":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(1, 3)
    dg.addEdge(2, 4)
    dg.addEdge(3, 4)
    let df = dominanceFrontiers(dg, 1)
    check df.len > 0

# ============================================================================
# Issue #116: Polynomials
# ============================================================================

suite "Polynomials (#116)":
  test "tutte polynomial on single edge":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let (x, y) = (2.0, 1.0)
    let tp = tuttePolynomial(g, x, y)
    check tp > 0.0

  test "chromatic polynomial":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let cp = chromaticPolynomial(g, 3)
    check cp == 6  # 3! / 1 = 6 ways to color triangle with 3 colors

  test "non-randomness":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let (nr, eigenval) = nonRandomness(g)
    check nr >= 0.0 or nr < 0.0  # Just check it returns

# ============================================================================
# Issue #117: Network Flow Extensions
# ============================================================================

suite "Network Flow Extensions (#117)":
  test "spanner":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 1), (1, 3)])
    let sp = spanner(g, 3)
    check sp.numberOfNodes() == 4
    check sp.numberOfEdges() <= g.numberOfEdges()

  test "Stoer-Wagner min cut":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(3, 4, 3.0)
    g.addWeightedEdge(1, 4, 2.0)
    let (cutWeight, partition, _) = stoerWagnerMinCut(g)
    check cutWeight > 0.0
    check partition.len > 0

  test "Dinitz max flow":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(1, 2, 3.0)
    dg.addWeightedEdge(1, 3, 2.0)
    dg.addWeightedEdge(2, 4, 2.0)
    dg.addWeightedEdge(3, 4, 3.0)
    let (flowVal, flowDict) = dinitz(dg, 1, 4)
    check flowVal == 4.0

  test "Gomory-Hu tree":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.0)
    g.addWeightedEdge(2, 3, 2.0)
    g.addWeightedEdge(3, 1, 1.0)
    let tree = gomoryHuTree(g)
    check tree.numberOfNodes() == 3

# ============================================================================
# Issue #118: Node Classification and S-metric
# ============================================================================

suite "Node Classification (#118)":
  test "s-metric":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let s = sMetric(g)
    check s > 0.0

  test "harmonic function":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    var labels = initTable[int, int]()
    labels[1] = 0
    labels[4] = 1
    let result = harmonicFunction(g, labels)
    check result.len == 4

  test "local and global consistency":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    var labels = initTable[int, int]()
    labels[1] = 0
    labels[4] = 1
    let result = localAndGlobalConsistency(g, labels, alpha = 0.5)
    check result.len == 4

# ============================================================================
# Issue #105: Leiden Community Detection
# ============================================================================

suite "Leiden (#105)":
  test "leiden on simple graph":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    g.addEdgesFrom(@[(4, 5), (5, 6), (6, 4)])
    g.addEdge(3, 4)
    let communities = leidenCommunities(g, seed = 42)
    check communities.len > 0
    # All nodes should be assigned
    var allNodes = initHashSet[int]()
    for c in communities:
      for n in c:
        allNodes.incl(n)
    check allNodes.len == 6

  test "leiden on digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 1)
    let communities = leidenCommunities(dg, seed = 42)
    check communities.len > 0

# ============================================================================
# Issue #123: Extended Communities
# ============================================================================

suite "Extended Communities (#123)":
  test "kernighan-lin bisection":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    g.addEdgesFrom(@[(4, 5), (5, 6), (6, 4)])
    g.addEdge(3, 4)
    let (a, b) = kernighanLinBisection(g)
    check a.len + b.len == 6

  test "fluid communities":
    var g = newGraph[int]()
    # Two well-separated cliques connected by a single bridge
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1), (1, 4), (2, 4), (3, 4)])
    g.addEdgesFrom(@[(5, 6), (6, 7), (7, 5), (5, 8), (6, 8), (7, 8)])
    g.addEdge(4, 5)
    let comms = fluidCommunities(g, 2, seed = 42)
    check comms.len == 2

  test "coverage":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let partition = @[[1, 2, 3].toHashSet]
    let cov = coverage(g, partition)
    check cov == 1.0

  test "performance":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let partition = @[[1, 2, 3].toHashSet]
    let perf = performance(g, partition)
    check perf >= 0.0 and perf <= 1.0

  test "is partition":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3)])
    let p1 = @[[1, 2].toHashSet, [3].toHashSet]
    check isPartition(g, p1)
    let p2 = @[[1, 2].toHashSet]  # missing node 3
    check not isPartition(g, p2)

# ============================================================================
# Issue #124: Extended Components
# ============================================================================

suite "Extended Components (#124)":
  test "attracting components":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 2)  # {2,3} is attracting
    let ac = attractingComponents(dg)
    check ac.len >= 1

  test "is attracting component":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 2)
    let comp = [2, 3].toHashSet
    check isAttractingComponent(dg, comp)

  test "is semiconnected":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    check isSemiconnected(dg)

  test "not semiconnected":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(3, 4)  # no path from 2 to 3
    check not isSemiconnected(dg)

  test "biconnected component edges":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1), (3, 4)])
    var comps = newSeq[seq[(int, int)]]()
    for comp in biconnectedComponentEdges(g):
      comps.add(comp)
    check comps.len >= 2

  test "edge disjoint paths":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (1, 3), (2, 4), (3, 4)])
    let paths = edgeDisjointPaths(g, 1, 4)
    check paths >= 2

  test "node disjoint paths":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (1, 3), (2, 4), (3, 4)])
    let paths = nodeDisjointPaths(g, 1, 4)
    check paths >= 2

# ============================================================================
# Issue #129: Extended Coloring
# ============================================================================

suite "Extended Coloring (#129)":
  test "equitable coloring of path":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let colors = equitableColor(g, 2)
    # Check valid coloring
    for (u, v) in g.edges:
      check colors[u] != colors[v]

  test "equitable coloring of triangle":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let colors = equitableColor(g, 3)
    for (u, v) in g.edges:
      check colors[u] != colors[v]

# ============================================================================
# Issue #130: Extended Clique
# ============================================================================

suite "Extended Clique (#130)":
  test "enumerate all cliques":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    var cliques = newSeq[seq[int]]()
    for c in enumerateAllCliques(g):
      cliques.add(c)
    check cliques.len >= 7  # 3 singles + 3 pairs + 1 triple

  test "max weight clique":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let (clique, weight) = maxWeightClique(g)
    check clique.len >= 1
    check weight > 0.0

  test "node clique number":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let ncn = nodeCliqueNumber(g, 1)
    check ncn == 3  # Part of a 3-clique

# ============================================================================
# Issue #131: Extended Properties
# ============================================================================

suite "Extended Properties (#131)":
  test "is k-regular":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])  # 2-regular
    check isKRegular(g, 2)
    check not isKRegular(g, 3)

  test "is threshold graph":
    var g = newGraph[int]()
    g.addNode(1)  # Isolated
    g.addNode(2)
    g.addEdge(2, 1)  # Dominating
    check isThresholdGraph(g)

  test "moral graph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 3)
    dg.addEdge(2, 3)
    let mg = moralGraph(dg)
    check mg.hasEdge(1, 2)  # Parents of 3 are married
    check mg.hasEdge(1, 3)
    check mg.hasEdge(2, 3)

  test "flow hierarchy":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let fh = flowHierarchy(dg)
    check fh == 1.0  # No cycles, all edges are hierarchical

  test "flow hierarchy with cycle":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 1)
    let fh = flowHierarchy(dg)
    check fh == 0.0  # All edges in cycle

# ============================================================================
# Issue #132: Extended Bipartite
# ============================================================================

suite "Extended Bipartite (#132)":
  test "bipartite projection":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 3), (1, 4), (2, 3), (2, 4)])
    let topNodes = [1, 2].toHashSet
    let proj = bipartiteProjection(g, topNodes)
    check proj.hasEdge(1, 2)  # Both connected to 3 and 4

  test "bipartite weighted projection":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 3), (1, 4), (2, 3), (2, 4)])
    let topNodes = [1, 2].toHashSet
    let proj = bipartiteWeightedProjection(g, topNodes)
    check proj.hasEdge(1, 2)

  test "bipartite clustering":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 3), (1, 4), (2, 3), (2, 4)])
    let cc = bipartiteClustering(g)
    check cc.len == 4

  test "bipartite redundancy":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 3), (1, 4), (2, 3), (2, 4)])
    let red = bipartiteRedundancy(g)
    check red.len == 4

# ============================================================================
# Issue #133: K-Shortest Paths
# ============================================================================

suite "K-Shortest Paths (#133)":
  test "shortest simple paths":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (1, 3)])
    let paths = shortestSimplePaths(g, 1, 3)
    check paths.len == 2
    check paths[0] == @[1, 3]  # Direct path first

  test "shortest simple paths digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(1, 3)
    let paths = shortestSimplePaths(dg, 1, 3)
    check paths.len == 2

# ============================================================================
# Issue #134: Approximation Algorithms
# ============================================================================

suite "Approximation (#134)":
  test "approx node connectivity":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (1, 3), (2, 4), (3, 4)])
    let nc = approxNodeConnectivity(g)
    check nc >= 1

  test "steiner tree":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 5)])
    let terminalNodes = [1, 5].toHashSet
    let tree = steinerTree(g, terminalNodes)
    check tree.numberOfNodes() >= 2
    check tree.hasNode(1)
    check tree.hasNode(5)

  test "ramsey R2":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let (clique, indep) = ramseyR2(g)
    check clique.len >= 1 or indep.len >= 1

  test "max cut":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let (a, b) = maxCut(g)
    check a.len + b.len == 3

  test "approx max clique":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 1)])
    let clique = approxMaxClique(g)
    check clique.len >= 2

  test "approx diameter":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let d = approxDiameter(g)
    check d >= 2  # At least 2 since path of length 3

# ============================================================================
# Issue #135: Miscellaneous
# ============================================================================

suite "Miscellaneous (#135)":
  test "isMaximalMatching":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    check isMaximalMatching(g, @[(1, 2), (3, 4)])
    check not isMaximalMatching(g, @[(1, 2)])

  test "hyperWienerIndex":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3)])
    let hw = hyperWienerIndex(g)
    check hw > 0.0

  test "allTriplets":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 1)
    let trips = allTriplets(dg)
    check trips.len == 1  # C(3,3) = 1

  test "triadsByType":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 1)
    let byType = triadsByType(dg)
    check byType.len == 16  # All 16 types present as keys

  test "isDigraphical":
    check isDigraphical(@[1, 1], @[1, 1])
    check not isDigraphical(@[1, 2], @[1, 1])

  test "isMultigraphical":
    check isMultigraphical(@[2, 2])
    check not isMultigraphical(@[1, 2])

  test "isPseudographical":
    check isPseudographical(@[2, 2])
    check not isPseudographical(@[1, 2])

  test "boundary expansion":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let s = [1, 2].toHashSet
    let be = boundaryExpansion(g, s)
    check be > 0.0

  test "mixing expansion":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4)])
    let s = [1, 2].toHashSet
    let me = mixingExpansion(g, s)
    check me > 0.0

  test "tree broadcast center":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 5)])
    let center = treeBroadcastCenter(g)
    check center == 3  # Center of path

  test "tree broadcast time":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 5)])
    let bt = treeBroadcastTime(g)
    check bt == 2  # From center, max distance is 2

  test "random reference preserves degree":
    var g = newGraph[int]()
    g.addEdgesFrom(@[(1, 2), (2, 3), (3, 4), (4, 1)])
    var origDeg = initTable[int, int]()
    for n in g.nodes:
      origDeg[n] = g.degree(n)
    let ref_g = randomReference(g, 10, 42)
    for n in ref_g.nodes:
      check ref_g.degree(n) == origDeg[n]
