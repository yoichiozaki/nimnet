import std/[unittest, tables, sets, math, os, strutils, hashes]
import nimnet
import nimnet/algorithms/spectral as spec
import nimnet/algorithms/layout as lay
import nimnet/algorithms/parallel as par
import nimnet/io/svg as svgio
import nimnet/datasets as ds
import nimnet/views as vw
import nimnet/multigraph as mg
import nimnet/compact as cpt
import nimnet/static_graph as sg

suite "Datasets - Additional":
  test "karateClubGraph basic properties":
    let g = karateClubGraph()
    check g.numberOfNodes == 34
    check g.numberOfEdges == 78

  test "davisWomenGraph basic properties":
    let g = ds.davisWomenGraph()
    check g.numberOfNodes == 32  # 18 women + 14 events
    check g.numberOfEdges > 0
    check g.hasNode("Evelyn")
    check g.hasNode("E1")

  test "loadFromEdgeListString":
    let data = """
# Comment
1 2
2 3
3 1
"""
    let g = loadFromEdgeListString[int](data)
    check g.numberOfNodes == 3
    check g.numberOfEdges == 3

suite "Spectral Algorithms":
  test "laplacianMatrix triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let (nodes, lap) = spec.laplacianMatrix(g)
    check nodes.len == 3
    check lap.len == 3
    # Each row sums to 0
    for row in lap:
      var s = 0.0
      for v in row: s += v
      check abs(s) < 1e-10

  test "laplacianMatrix diagonal is degree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let (_, lap) = spec.laplacianMatrix(g)
    for i in 0 ..< lap.len:
      check abs(lap[i][i] - 2.0) < 1e-10  # each node has degree 2

  test "normalizedLaplacian triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let (_, nlap) = spec.normalizedLaplacian(g)
    check nlap.len == 3
    # Diagonal should be 1.0 for nodes with degree > 0
    for i in 0 ..< nlap.len:
      check abs(nlap[i][i] - 1.0) < 1e-10

  test "adjacencyMatrix triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let (_, adj) = spec.adjacencyMatrix(g)
    check adj.len == 3
    # Symmetric
    for i in 0 ..< adj.len:
      for j in 0 ..< adj.len:
        check abs(adj[i][j] - adj[j][i]) < 1e-10

  test "algebraicConnectivity complete graph K4":
    var g = newGraph[int]()
    for i in 0 ..< 4:
      for j in (i+1) ..< 4:
        g.addEdge(i, j)
    let ac = spec.algebraicConnectivity(g)
    # For K_n, algebraic connectivity = n
    check ac > 2.0  # should be ~4.0 for K4

  test "algebraicConnectivity path":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 3)])
    let ac = spec.algebraicConnectivity(g)
    check ac > 0.0
    check ac < 1.0  # path has small algebraic connectivity

  test "spectralBisection":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 3)])
    let (part1, part2) = spec.spectralBisection(g)
    check part1.len + part2.len == 4
    check part1.len > 0
    check part2.len > 0

  test "adjacencySpectrum K3":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
    let spectralRadius = spec.adjacencySpectrum(g)
    # For K3, spectral radius = 2
    check abs(spectralRadius - 2.0) < 0.1

  test "fiedlerVector":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 3)])
    let (nodes, vec) = spec.fiedlerVector(g)
    check nodes.len == 4
    check vec.len == 4

suite "Layout Algorithms":
  test "circularLayout positions":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
    let pos = lay.circularLayout(g)
    check pos.len == 3
    # All positions should be on the unit circle
    for n, p in pos:
      let dist = sqrt(p.x * p.x + p.y * p.y)
      check abs(dist - 1.0) < 0.01

  test "circularLayout DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let pos = lay.circularLayout(g)
    check pos.len == 3

  test "randomLayout":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2)])
    let pos = lay.randomLayout(g, seed = 42)
    check pos.len == 3
    # Positions should be in [0, 1]
    for n, p in pos:
      check p.x >= 0.0 and p.x <= 1.0
      check p.y >= 0.0 and p.y <= 1.0

  test "springLayout produces positions":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 3), (3, 0)])
    let pos = lay.springLayout(g, iterations = 20, seed = 42)
    check pos.len == 4

  test "springLayout DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let pos = lay.springLayout(g, iterations = 20, seed = 42)
    check pos.len == 3

  test "shellLayout":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 3)])
    let pos = lay.shellLayout(g, shells = @[@[0, 1], @[2, 3]])
    check pos.len == 4

  test "springLayout empty graph":
    var g = newGraph[int]()
    let pos = lay.springLayout(g, seed = 42)
    check pos.len == 0

  test "springLayout single node":
    var g = newGraph[int]()
    g.addNode(1)
    let pos = lay.springLayout(g, seed = 42)
    check pos.len == 1

suite "SVG Output":
  test "toSvgString produces valid SVG":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
    let pos = lay.circularLayout(g)
    let svg = svgio.toSvgString(g, pos)
    check svg.contains("<svg")
    check svg.contains("</svg>")
    check svg.contains("<circle")
    check svg.contains("<line")

  test "toSvgString custom options":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let pos = lay.circularLayout(g)
    var opts = defaultSvgOptions()
    opts.width = 400
    opts.height = 300
    opts.showLabels = false
    let svg = svgio.toSvgString(g, pos, opts)
    check svg.contains("width=\"400\"")
    check svg.contains("height=\"300\"")
    check not svg.contains("<text")

  test "writeSvg file output":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
    let pos = lay.circularLayout(g)
    let filename = "test_output.svg"
    svgio.writeSvg(g, pos, filename)
    check fileExists(filename)
    let content = readFile(filename)
    check content.contains("<svg")
    check content.contains("</svg>")
    removeFile(filename)

  test "writeSvg DiGraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(1, 2)
    let pos = lay.circularLayout(dg)
    let filename = "test_digraph_output.svg"
    svgio.writeSvg(dg, pos, filename)
    check fileExists(filename)
    let content = readFile(filename)
    check content.contains("marker-end")  # arrows
    check content.contains("</svg>")
    removeFile(filename)

  test "toSvgString empty graph":
    var g = newGraph[int]()
    let pos = lay.circularLayout(g)
    let svg = svgio.toSvgString(g, pos)
    check svg.contains("<svg")
    check svg.contains("</svg>")

suite "Nodeable Concept":
  test "int satisfies Nodeable":
    let x: int = 42
    check hash(x) is Hash
    check (x == x)
    check ($x == "42")

  test "string satisfies Nodeable":
    let s = "hello"
    check hash(s) is Hash
    check (s == s)
    check ($s == "hello")

suite "GraphView":
  test "view basic operations":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let v = vw.view(g)
    check v.len == 3
    check v.numberOfNodes == 3
    check v.numberOfEdges == 3
    check v.hasNode(1)
    check v.hasEdge(1, 2)
    check v.degree(1) == 2

  test "view iteration":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    let v = vw.view(g)
    var nodeCount = 0
    for n in v.nodes:
      nodeCount += 1
    check nodeCount == 3
    var edgeCount = 0
    for e in v.edges:
      edgeCount += 1
    check edgeCount == 2

  test "DiGraphView":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let v = vw.view(dg)
    check v.len == 3
    check v.numberOfEdges == 2
    check v.hasEdge(1, 2)
    check not v.hasEdge(2, 1)

suite "MultiGraph":
  test "basic operations":
    var g = mg.newMultiGraph[int]()
    let k1 = g.addEdge(1, 2)
    let k2 = g.addEdge(1, 2)  # parallel edge
    check g.numberOfNodes == 2
    check g.numberOfEdges == 2
    check k1 != k2
    check g.hasEdge(1, 2)

  test "degree counts parallel edges":
    var g = mg.newMultiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 3)
    check g.degree(1) == 3  # two edges to 2 + one to 3

  test "remove edge by key":
    var g = mg.newMultiGraph[int]()
    let k1 = g.addEdge(1, 2)
    let k2 = g.addEdge(1, 2)
    g.removeEdge(1, 2, k1)
    check g.numberOfEdges == 1
    check g.hasEdge(1, 2)  # k2 still exists

  test "MultiDiGraph":
    var g = mg.newMultiDiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 2)
    discard g.addEdge(2, 1)
    check g.numberOfNodes == 2
    check g.numberOfEdges == 3
    check g.outDegree(1) == 2
    check g.inDegree(1) == 1

  test "string representation":
    var g = mg.newMultiGraph[int]()
    discard g.addEdge(1, 2)
    check ($g).contains("MultiGraph")

suite "CompactGraph (CSR)":
  test "convert and back":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
    let cg = cpt.toCompact(g)
    check cg.numberOfNodes == 3
    check cg.numberOfEdges == 3
    let g2 = cg.toGraph()
    check g2.numberOfNodes == 3
    check g2.numberOfEdges == 3

  test "BFS on CompactGraph":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 3)])
    let cg = cpt.toCompact(g)
    # Find index of node 0
    var startIdx = 0
    for i, n in cg.nodeList:
      if n == 0: startIdx = i
    let order = cg.bfsCSR(startIdx)
    check order.len == 4

  test "CSR neighbor iteration":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (0, 2), (0, 3)])
    let cg = cpt.toCompact(g)
    var idx0 = 0
    for i, n in cg.nodeList:
      if n == 0: idx0 = i
    check cg.degreeCSR(idx0) == 3

  test "CompactDiGraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(0, 2)
    dg.addEdge(1, 2)
    let cdg = cpt.toCompact(dg)
    check cdg.numberOfNodes == 3
    check cdg.numberOfEdges == 3

suite "Static Graph Construction":
  test "staticGraph":
    let g = sg.staticGraph[int]([(1, 2), (2, 3), (3, 1)])
    check g.numberOfNodes == 3
    check g.numberOfEdges == 3

  test "staticDiGraph":
    let dg = sg.staticDiGraph[int]([(1, 2), (2, 3)])
    check dg.numberOfNodes == 3
    check dg.numberOfEdges == 2

suite "Parallel Algorithms":
  test "parallelPageRank":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
    let pr = par.parallelPageRank(g)
    check pr.len == 3
    # All nodes should have equal PageRank in a cycle
    var sum = 0.0
    for n, val in pr:
      sum += val
    check abs(sum - 1.0) < 0.01

  test "parallelBetweennessCentrality":
    # Star graph: center has high betweenness
    var g = newGraph[int]()
    for i in 1 .. 4:
      g.addEdge(0, i)
    let bc = par.parallelBetweennessCentrality(g)
    check bc.len == 5
    # Center node should have highest betweenness
    check bc[0] > bc[1]

  test "parallelPageRank karate club":
    let g = karateClubGraph()
    let pr = par.parallelPageRank(g)
    check pr.len == 34
    var sum = 0.0
    for n, val in pr:
      sum += val
    check abs(sum - 1.0) < 0.01
