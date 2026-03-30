## Tests for new features — issues #141-#154
## Graph utilities, generators, I/O, spectral, layouts, exceptions

import std/[unittest, tables, sets, json, math, strutils]
import nimnet

# ===========================================================================
# #154 — Exceptions
# ===========================================================================
suite "New exception types (#154)":
  test "NimNetNoCycle exists":
    let e = newException(NimNetNoCycle, "no cycle")
    check e.msg == "no cycle"

  test "NimNetUnbounded exists":
    let e = newException(NimNetUnbounded, "unbounded")
    check e.msg == "unbounded"

  test "PowerIterationFailedConvergence exists":
    let e = newException(PowerIterationFailedConvergence, "no convergence")
    check e.msg == "no convergence"

  test "ExceededMaxIterations exists":
    let e = newException(ExceededMaxIterations, "too many iterations")
    check e.msg == "too many iterations"

  test "AmbiguousSolution exists":
    let e = newException(AmbiguousSolution, "ambiguous")
    check e.msg == "ambiguous"

  test "NimNetAlgorithmError exists":
    let e = newException(NimNetAlgorithmError, "algo error")
    check e.msg == "algo error"

  test "NimNetPointlessConcept exists":
    let e = newException(NimNetPointlessConcept, "pointless")
    check e.msg == "pointless"

# ===========================================================================
# #141 — Graph utilities
# ===========================================================================
suite "Graph utilities (#141)":
  test "freeze and isFrozen — Graph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    check not g.isFrozen
    g.freeze()
    check g.isFrozen

  test "freeze and isFrozen — DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    check not dg.isFrozen
    dg.freeze()
    check dg.isFrozen

  test "isWeighted — unweighted":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    check not isWeighted(g)

  test "isWeighted — weighted":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 2.5)
    check isWeighted(g)

  test "isNegativelyWeighted":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, -1.0)
    check isNegativelyWeighted(g)

  test "isMultigraph always false":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    check not isMultigraph(g)

  test "display produces output":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let s = display(g)
    check s.len > 0

  test "createEmptyCopy — Graph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let ec = createEmptyCopy(g)
    check ec.numberOfNodes == 3
    check ec.numberOfEdges == 0

  test "createEmptyCopy — DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    let ec = createEmptyCopy(dg)
    check ec.numberOfNodes == 2
    check ec.numberOfEdges == 0

  test "nonEdges iterator":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addNode(2)
    var ne: seq[(int, int)]
    for e in nonEdges(g):
      ne.add(e)
    check ne.len > 0  # 0-2 and 1-2 are non-edges

  test "pathWeight":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.0)
    g.addWeightedEdge(2, 3, 4.0)
    check abs(pathWeight(g, @[1, 2, 3]) - 7.0) < 1e-10

  test "isPath valid":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check isPath(g, @[1, 2, 3])
    check not isPath(g, @[1, 3])

  test "pairwise":
    let s = @[1, 2, 3, 4]
    let p = pairwise(s)
    check p == @[(1, 2), (2, 3), (3, 4)]

  test "generateUniqueNode":
    var g = newGraph[int]()
    g.addNode(0)
    g.addNode(1)
    let u = generateUniqueNode(g)
    check u notin [0, 1]

  test "reverseCuthillMckeeOrdering":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let order = reverseCuthillMckeeOrdering(g)
    check order.len == 4

# ===========================================================================
# #153 — Convert extensions
# ===========================================================================
suite "Convert extensions (#153)":
  test "toDictOfDicts and fromDictOfDicts":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let d = toDictOfDicts(g)
    check 1 in d
    check 2 in d[1]
    let g2 = fromDictOfDicts(d)
    check g2.hasEdge(1, 2)
    check g2.hasEdge(2, 3)

  test "toDictOfLists and fromDictOfLists":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let d = toDictOfLists(g)
    check 1 in d
    let g2 = fromDictOfLists(d)
    check g2.hasEdge(1, 2)

  test "toEdgeList":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let el = toEdgeList(g)
    check el.len == 2

  test "convertNodeLabelsToIntegers":
    var g = newGraph[string]()
    g.addEdge("a", "b")
    g.addEdge("b", "c")
    let ig = convertNodeLabelsToIntegers(g)
    check ig.numberOfNodes == 3
    check ig.numberOfEdges == 2

# ===========================================================================
# #142 — Classic generators
# ===========================================================================
suite "Classic generators (#142)":
  test "completeMultipartiteGraph":
    let g = completeMultipartiteGraph(@[2, 3])
    check g.numberOfNodes == 5

  test "circulantGraph":
    let g = circulantGraph(6, @[1, 2])
    check g.numberOfNodes == 6
    check g.hasEdge(0, 1)
    check g.hasEdge(0, 2)

  test "dorogovtsevGoltsevMendesGraph gen 0":
    let g = dorogovtsevGoltsevMendesGraph(0)
    check g.numberOfNodes == 2

  test "dorogovtsevGoltsevMendesGraph gen 2":
    let g = dorogovtsevGoltsevMendesGraph(2)
    check g.numberOfNodes > 2

  test "fullRaryTree":
    let g = fullRaryTree(2, 7)
    check g.numberOfNodes == 7

  test "kneserGraph":
    let g = kneserGraph(5, 2)
    check g.numberOfNodes == 10  # C(5,2) = 10

# ===========================================================================
# #143 — Small generators
# ===========================================================================
suite "Small generators (#143)":
  test "houseXGraph":
    let g = houseXGraph()
    check g.numberOfNodes == 5

  test "chvatalGraph":
    let g = chvatalGraph()
    check g.numberOfNodes == 12
    check g.numberOfEdges == 24

  test "truncatedCubeGraph":
    let g = truncatedCubeGraph()
    check g.numberOfNodes == 24

  test "truncatedTetrahedronGraph":
    let g = truncatedTetrahedronGraph()
    check g.numberOfNodes == 12

  test "lcfGraph":
    let g = lcfGraph(10, @[5, -5], 5)
    check g.numberOfNodes == 10

# ===========================================================================
# #144 — Random generators
# ===========================================================================
suite "Random generators (#144)":
  test "connectedWattsStrogatzGraph":
    let g = connectedWattsStrogatzGraph(20, 4, 0.3, seed = 42)
    check g.numberOfNodes == 20

  test "dualBarabasiAlbertGraph":
    let g = dualBarabasiAlbertGraph(20, 1, 2, 0.5, seed = 42)
    check g.numberOfNodes == 20

  test "extendedBarabasiAlbertGraph":
    let g = extendedBarabasiAlbertGraph(20, 2, 0.3, 0.3, seed = 42)
    check g.numberOfNodes == 20

  test "randomLobster":
    let g = randomLobster(10, 0.5, 0.5, seed = 42)
    check g.numberOfNodes >= 10

  test "randomPowerlawTree":
    let g = randomPowerlawTree(10, 2.5, seed = 42)
    check g.numberOfNodes == 10

# ===========================================================================
# #145 — Lattice & Expanders
# ===========================================================================
suite "Lattice & Expander generators (#145)":
  test "hexagonalLatticeGraph":
    let g = hexagonalLatticeGraph(2, 2)
    check g.numberOfNodes > 0

  test "gridGraph multi-dim":
    let g = gridGraph(@[3, 3])
    check g.numberOfNodes == 9

  test "gridGraph 3D":
    let g = gridGraph(@[2, 2, 2])
    check g.numberOfNodes == 8

  test "margulisGabberGalilGraph":
    let g = margulisGabberGalilGraph(3)
    check g.numberOfNodes == 9

  test "chordalCycleGraph":
    let g = chordalCycleGraph(5)
    check g.numberOfNodes == 5

  test "paleyGraph":
    let g = paleyGraph(5)
    check g.numberOfNodes == 5

# ===========================================================================
# #146 — Duplication, degree seq, geometric
# ===========================================================================
suite "Duplication & directed degree seq (#146)":
  test "duplicationDivergenceGraph":
    let g = duplicationDivergenceGraph(10, 0.5, seed = 42)
    check g.numberOfNodes == 10

  test "partialDuplicationGraph":
    let g = partialDuplicationGraph(10, 2, 0.5, seed = 42)
    check g.numberOfNodes == 10

  test "directedConfigurationModel":
    let dg = directedConfigurationModel(@[1, 1, 0], @[0, 1, 1], seed = 42)
    check dg.numberOfNodes == 3

  test "directedHavelHakimiGraph":
    let dg = directedHavelHakimiGraph(@[1, 1, 0], @[0, 1, 1])
    check dg.numberOfNodes == 3

  test "randomDegreeSequenceGraph":
    let g = randomDegreeSequenceGraph(@[2, 2, 2], seed = 42)
    check g.numberOfNodes == 3

  test "geographicalThresholdGraph":
    let g = geographicalThresholdGraph(10, 0.5, seed = 42)
    check g.numberOfNodes == 10

  test "navigableSmallWorldGraph":
    let g = navigableSmallWorldGraph(5, seed = 42)
    check g.numberOfNodes == 25

# ===========================================================================
# #147 — Line/ego/stochastic/internet/intersection
# ===========================================================================
suite "Line & ego & stochastic (#147)":
  test "egoGraph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let eg = egoGraph(g, 1, 1)
    check eg.hasNode(0)
    check eg.hasNode(1)
    check eg.hasNode(2)
    check not eg.hasNode(3)

  test "stochasticGraph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let sg = stochasticGraph(g)
    check sg.numberOfNodes == 3

  test "randomInternetAsGraph":
    let g = randomInternetAsGraph(10, seed = 42)
    check g.numberOfNodes == 10

  test "uniformRandomIntersectionGraph":
    let g = uniformRandomIntersectionGraph(5, 3, 0.5, seed = 42)
    check g.numberOfNodes == 5

  test "kRandomIntersectionGraph":
    let g = kRandomIntersectionGraph(5, 3, 2, seed = 42)
    check g.numberOfNodes == 5

  test "davisSouthernWomenGraph":
    let g = davisSouthernWomenGraph()
    check g.numberOfNodes > 0

# ===========================================================================
# #148 — Community generators
# ===========================================================================
suite "Community generators (#148)":
  test "gaussianRandomPartitionGraph":
    let g = gaussianRandomPartitionGraph(20, 5, 1.0, 0.5, 0.01, seed = 42)
    check g.numberOfNodes == 20

  test "randomPartitionGraph":
    let g = randomPartitionGraph(@[5, 5, 5], 0.5, 0.01, seed = 42)
    check g.numberOfNodes == 15

  test "lfrBenchmarkGraph":
    let g = lfrBenchmarkGraph(20, 2.5, 1.5, 0.3, seed = 42)
    check g.numberOfNodes == 20

# ===========================================================================
# #149 — Tree/nonisomorphic/triad/joint/mycielski/harary/misc
# ===========================================================================
suite "Tree & misc generators (#149)":
  test "prefixTree":
    let g = prefixTree(@[@[1, 2, 3], @[1, 2, 4], @[1, 5]])
    check g.numberOfNodes > 0

  test "randomLabeledTree":
    let g = randomLabeledTree(10, seed = 42)
    check g.numberOfNodes == 10
    check g.numberOfEdges == 9

  test "nonisomorphicTrees":
    let trees = nonisomorphicTrees(5)
    check trees.len > 0

  test "numberOfNonisomorphicTrees":
    check numberOfNonisomorphicTrees(1) >= 1
    check numberOfNonisomorphicTrees(4) >= 1

  test "triadGraph 003":
    let g = triadGraph("003")
    check g.numberOfNodes == 3
    check g.numberOfEdges == 0

  test "triadGraph 102":
    let g = triadGraph("102")
    check g.numberOfNodes == 3

  test "mycielskiGraph":
    let g = mycielskiGraph(3)
    check g.numberOfNodes > 0

  test "mycielskian":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let mg = mycielskian(g)
    check mg.numberOfNodes > g.numberOfNodes

  test "hnmHararyGraph":
    let g = hnmHararyGraph(5, 7)
    check g.numberOfNodes == 5
    check g.numberOfEdges == 7

  test "hknHararyGraph":
    let g = hknHararyGraph(2, 5)
    check g.numberOfNodes == 5

  test "randomCograph":
    let g = randomCograph(4, seed = 42)
    check g.numberOfNodes > 0

  test "intervalGraph":
    let g = intervalGraph(@[(0.0, 1.0), (0.5, 1.5), (2.0, 3.0)])
    check g.numberOfNodes == 3
    check g.hasEdge(0, 1)
    check not g.hasEdge(0, 2)

  test "sudokuGraph":
    let g = sudokuGraph(2)
    check g.numberOfNodes == 16  # 4x4 grid

  test "visibilityGraph":
    let g = visibilityGraph(@[3.0, 1.0, 2.0, 1.0, 4.0])
    check g.numberOfNodes == 5

  test "isValidJointDegree":
    var jd = initTable[(int, int), int]()
    jd[(1, 2)] = 2
    jd[(2, 2)] = 1
    # Just check it runs without crash
    discard isValidJointDegree(jd)

  test "jointDegreeGraph":
    var jd = initTable[(int, int), int]()
    jd[(1, 2)] = 2
    jd[(2, 2)] = 1
    let g = jointDegreeGraph(jd, seed = 42)
    check g.numberOfNodes > 0

# ===========================================================================
# #150 — I/O formats
# ===========================================================================
suite "I/O formats (#150)":
  test "writeMultilineAdjlist and readMultilineAdjlist":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let data = writeMultilineAdjlist(g)
    check data.len > 0
    let g2 = readMultilineAdjlist(data)
    check g2.numberOfNodes == 3

  test "readLeda":
    let ledaData = """LEDA.GRAPH
string
string
-2
3
|{node1}|
|{node2}|
|{node3}|
2
1 2 0 |{edge1}|
2 3 0 |{edge2}|
"""
    let g = readLeda(ledaData)
    check g.numberOfNodes == 3

  test "writeNetworkText":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let text = writeNetworkText(g)
    check text.len > 0

  test "cytoscapeData":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let js = cytoscapeData(g)
    check "elements" in js

  test "cytoscapeGraph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let js = cytoscapeData(g)
    let g2 = cytoscapeGraph(js)
    check g2.numberOfNodes == 2

  test "treeData and treeGraph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    let js = treeData(g, 0)
    check "id" in js
    let g2 = treeGraph(js)
    check g2.numberOfNodes == 3

  test "adjacencyData and adjacencyGraph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let js = adjacencyData(g)
    check js.kind == JArray
    let g2 = adjacencyGraph(js)
    check g2.numberOfNodes == 3

# ===========================================================================
# #151 — Spectral / Linear Algebra
# ===========================================================================
suite "Spectral & Linear Algebra (#151)":
  test "incidenceMatrix — Graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let (nodes, edges, mat) = incidenceMatrix(g)
    check nodes.len == 3
    check edges.len == 2
    check mat.len == 3
    check mat[0].len == 2

  test "incidenceMatrix — DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let (nodes, edges, mat) = incidenceMatrix(dg)
    check nodes.len == 3
    check edges.len == 2

  test "directedLaplacianMatrix":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let (nodes, mat) = directedLaplacianMatrix(dg)
    check nodes.len == 3
    check mat.len == 3

  test "betheHessianMatrix":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let (nodes, mat) = betheHessianMatrix(g)
    check nodes.len == 3
    check mat.len == 3

  test "modularityMatrix":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let (nodes, mat) = modularityMatrix(g)
    check nodes.len == 3

  test "directedModularityMatrix":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let (nodes, mat) = directedModularityMatrix(dg)
    check nodes.len == 3

  test "betheHessianSpectrum":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let sp = betheHessianSpectrum(g)
    check sp.len == 3

  test "normalizedLaplacianSpectrum":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let sp = normalizedLaplacianSpectrum(g)
    check sp.len == 3

  test "modularitySpectrum":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let sp = modularitySpectrum(g)
    check sp.len == 3

  test "spectralOrdering":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let order = spectralOrdering(g)
    check order.len == 4

# ===========================================================================
# #152 — Layout algorithms
# ===========================================================================
suite "Layout algorithms (#152)":
  test "spectralLayout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let pos = spectralLayout(g)
    check pos.len == 3

  test "kamadaKawaiLayout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let pos = kamadaKawaiLayout(g)
    check pos.len == 3

  test "spiralLayout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let pos = spiralLayout(g)
    check pos.len == 3

  test "bipartiteLayout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    let topNodes = toHashSet([0])
    let pos = bipartiteLayout(g, topNodes)
    check pos.len == 3

  test "multipartiteLayout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let pos = multipartiteLayout(g, @[@[0], @[1], @[2]])
    check pos.len == 3

  test "arfLayout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let pos = arfLayout(g, iterations = 10, seed = 42)
    check pos.len == 3

  test "forceAtlas2Layout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let pos = forceAtlas2Layout(g, iterations = 10, seed = 42)
    check pos.len == 3

  test "planarLayout":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let pos = planarLayout(g)
    check pos.len == 3

# ===========================================================================
# SubgraphView (part of #154)
# ===========================================================================
suite "SubgraphView":
  test "subgraphView basic":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let sv = subgraphView(g, proc(n: int): bool = n < 3)
    check sv.numberOfNodes == 3
    check sv.hasNode(0)
    check sv.hasNode(2)
    check not sv.hasNode(3)
