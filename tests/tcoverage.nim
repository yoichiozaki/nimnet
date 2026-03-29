## Coverage improvement tests — targeting untested edge cases and code paths
##
## This file adds test coverage for:
## - types.nim helper functions (getStr, getAttrFloat, getWeight edge cases)
## - digraph.nim iterators (inDegreeIter, outDegreeIter)
## - operators.nim edge cases (complement, intersection, difference, relabel errors)
## - convert.nim (fromAdjacencyMatrix directed, degreeSequence)
## - multigraph.nim (degree, removeNode, neighbors, edge iteration)
## - views.nim (degree, hasEdge, getEdgeAttr, DiGraphView ops)
## - I/O modules (pajek, graph6, svg edge cases)
## - graph.nim / digraph.nim (copy, clear, density, self-loops, isolated nodes)

import std/[unittest, tables, sets, math, json, os, strutils, sequtils]
import nimnet
import nimnet/graph as graph
import nimnet/digraph as digraphmod
import nimnet/operators as ops
import nimnet/convert as conv
import nimnet/multigraph as mg
import nimnet/views as vw
import nimnet/compact as cpt
import nimnet/io/pajek as pj
import nimnet/io/graph6 as g6
import nimnet/io/svg as svgio
import nimnet/io/gml as gmlio
import nimnet/io/graphml as xmlio
import nimnet/io/gexf as gexfio
import nimnet/io/edgelist as elio
import nimnet/io/dot as dotio

# ============================================================================
# types.nim — helper coverage
# ============================================================================
suite "types.nim helpers":
  test "getStr with string value":
    var attr = newEdgeAttr()
    attr["color"] = newJString("red")
    check types.getStr(attr, "color") == "red"
    check types.getStr(attr, "missing") == ""
    check types.getStr(attr, "missing", "default") == "default"

  test "getStr with float value":
    var attr = newEdgeAttr()
    attr["weight"] = newJFloat(3.14)
    let s = types.getStr(attr, "weight")
    check s.contains("3.14")

  test "getStr with int value":
    var attr = newEdgeAttr()
    attr["count"] = newJInt(42)
    check types.getStr(attr, "count") == "42"

  test "getStr with bool value":
    var attr = newEdgeAttr()
    attr["active"] = newJBool(true)
    check types.getStr(attr, "active") == "true"

  test "getStr with nil attr":
    var attr: EdgeAttr = nil
    check types.getStr(attr, "key") == ""
    check types.getStr(attr, "key", "fallback") == "fallback"

  test "getStr with non-object JSON":
    var attr = newJString("not an object")
    check types.getStr(EdgeAttr(attr), "key") == ""

  test "getAttrFloat with float value":
    var attr = newEdgeAttr()
    attr["cost"] = newJFloat(9.99)
    check abs(attr.getAttrFloat("cost") - 9.99) < 1e-10

  test "getAttrFloat with int value":
    var attr = newEdgeAttr()
    attr["count"] = newJInt(7)
    check abs(attr.getAttrFloat("count") - 7.0) < 1e-10

  test "getAttrFloat with string value":
    var attr = newEdgeAttr()
    attr["weight"] = newJString("2.5")
    check abs(attr.getAttrFloat("weight") - 2.5) < 1e-10

  test "getAttrFloat with invalid string":
    var attr = newEdgeAttr()
    attr["weight"] = newJString("not_a_number")
    check abs(attr.getAttrFloat("weight", 99.0) - 99.0) < 1e-10

  test "getAttrFloat with nil attr":
    var attr: EdgeAttr = nil
    check abs(attr.getAttrFloat("key", 5.0) - 5.0) < 1e-10

  test "getAttrFloat missing key":
    var attr = newEdgeAttr()
    check abs(attr.getAttrFloat("missing", 1.0) - 1.0) < 1e-10

  test "getWeight with nil attr":
    var attr: EdgeAttr = nil
    check abs(attr.getWeight() - 1.0) < 1e-10
    check abs(attr.getWeight(0.0) - 0.0) < 1e-10

  test "getWeight with JInt value":
    var attr = newEdgeAttr()
    attr["weight"] = newJInt(5)
    check abs(attr.getWeight() - 5.0) < 1e-10

  test "getWeight with JString valid float":
    var attr = newEdgeAttr()
    attr["weight"] = newJString("3.14")
    check abs(attr.getWeight() - 3.14) < 1e-10

  test "getWeight with JString invalid":
    var attr = newEdgeAttr()
    attr["weight"] = newJString("abc")
    check abs(attr.getWeight(99.0) - 99.0) < 1e-10

  test "getWeight with non-object JSON":
    var attr = newJArray()
    check abs(EdgeAttr(attr).getWeight(7.0) - 7.0) < 1e-10

  test "weight= setter on nil attr":
    var attr: EdgeAttr = nil
    attr.weight = 42.0
    check not attr.isNil
    check abs(attr.getWeight() - 42.0) < 1e-10

  test "newNodeAttr constructors":
    let a = newNodeAttr()
    check a.kind == JObject
    check a.len == 0
    let b = newNodeAttr({"name": "Alice", "role": "admin"})
    check b["name"].getStr() == "Alice"
    check b["role"].getStr() == "admin"

  test "newEdgeAttr from pairs":
    let a = newEdgeAttr({"color": "blue", "style": "dashed"})
    check a["color"].getStr() == "blue"
    check a["style"].getStr() == "dashed"

# ============================================================================
# digraph.nim — iterator coverage
# ============================================================================
suite "DiGraph iterators":
  test "inDegreeIter":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    var inDegs = initTable[int, int]()
    for (n, d) in g.inDegreeIter:
      inDegs[n] = d
    check inDegs[1] == 0
    check inDegs[2] == 1
    check inDegs[3] == 2

  test "outDegreeIter":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    var outDegs = initTable[int, int]()
    for (n, d) in g.outDegreeIter:
      outDegs[n] = d
    check outDegs[1] == 2
    check outDegs[2] == 1
    check outDegs[3] == 0

  test "degree iterator for DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    var degs = initTable[int, int]()
    for (n, d) in g.degree:
      degs[n] = d
    check degs[1] == 1  # out=1, in=0
    check degs[2] == 2  # out=1, in=1
    check degs[3] == 1  # out=0, in=1

  test "DiGraph density":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 1)
    g.addEdge(1, 3)
    # 3 edges, 3 nodes => 3 / (3*2) = 0.5
    check abs(g.density() - 0.5) < 1e-10

  test "DiGraph density single node":
    var g = newDiGraph[int]()
    g.addNode(1)
    check abs(g.density()) < 1e-10

  test "DiGraph numberOfSelfLoops":
    var g = newDiGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 2)
    check g.numberOfSelfLoops() == 2

  test "DiGraph isEmpty and isDirected":
    var g = newDiGraph[int]()
    g.addNode(1)
    check g.isEmpty() == true
    check g.isDirected() == true
    g.addEdge(1, 2)
    check g.isEmpty() == false

  test "DiGraph copy":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let g2 = g.copy()
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 2
    check g2.hasEdge(1, 2)

  test "DiGraph clear":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.clear()
    check g.numberOfNodes() == 0
    check g.numberOfEdges() == 0

  test "DiGraph reverse":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let r = g.reverse()
    check r.hasEdge(2, 1)
    check r.hasEdge(3, 2)
    check not r.hasEdge(1, 2)

# ============================================================================
# graph.nim — edge cases
# ============================================================================
suite "Graph edge cases":
  test "Graph density":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(1, 3)
    # K3: 3 edges, 3 nodes => 3 / (3*2/2) = 1.0
    check abs(graph.density(g) - 1.0) < 1e-10

  test "Graph density single node":
    var g = newGraph[int]()
    g.addNode(1)
    check abs(graph.density(g)) < 1e-10

  test "Graph copy":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addWeightedEdge(2, 3, 5.0)
    let g2 = g.copy()
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 2
    check abs(g2.getEdgeAttr(2, 3).getWeight() - 5.0) < 1e-10

  test "Graph clear":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.clear()
    check g.numberOfNodes() == 0
    check g.numberOfEdges() == 0

  test "Graph self-loops":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    check g.numberOfNodes() == 2
    check g.hasSelfLoop(1)
    check g.numberOfSelfLoops() == 1

  test "neighbors of isolated node":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    g.addEdge(2, 3)
    var count = 0
    for _ in g.neighbors(1):
      count.inc
    check count == 0

  test "removeNode removes incident edges":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    g.removeNode(1)
    check g.numberOfNodes() == 2
    check g.numberOfEdges() == 1
    check not g.hasNode(1)

  test "removeEdge":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.removeEdge(1, 2)
    check g.numberOfEdges() == 1
    check not g.hasEdge(1, 2)

  test "Graph isEmpty":
    var g = newGraph[int]()
    g.addNode(1)
    check g.isEmpty() == true
    g.addEdge(1, 2)
    check g.isEmpty() == false

  test "Graph info string":
    var g = newGraph[int](name = "TestGraph")
    g.addEdge(1, 2)
    let s = $g
    check "TestGraph" in s or "Graph" in s

# ============================================================================
# operators.nim — edge cases
# ============================================================================
suite "Operators edge cases":
  test "complement of single node":
    var g = newGraph[int]()
    g.addNode(1)
    let c = complement(g)
    check c.numberOfNodes() == 1
    check c.numberOfEdges() == 0

  test "complement of complete graph":
    let g = completeGraph[int](4)
    let c = complement(g)
    check c.numberOfNodes() == 4
    check c.numberOfEdges() == 0

  test "complement of DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addNode(3)
    let c = complement(g)
    check c.numberOfNodes() == 3
    # K3 directed has 6 edges, minus 1 existing = 5
    check c.numberOfEdges() == 5
    check not c.hasEdge(1, 2)
    check c.hasEdge(2, 1)

  test "intersection with disjoint graphs":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(3, 4)
    let i = intersection(g1, g2)
    check i.numberOfNodes() == 0
    check i.numberOfEdges() == 0

  test "intersection with shared edges":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    g1.addEdge(2, 3)
    var g2 = newGraph[int]()
    g2.addEdge(1, 2)
    g2.addEdge(3, 4)
    let i = intersection(g1, g2)
    check i.hasEdge(1, 2)
    check not i.hasEdge(2, 3)

  test "intersection of DiGraphs":
    var g1 = newDiGraph[int]()
    g1.addEdge(1, 2)
    g1.addEdge(2, 3)
    var g2 = newDiGraph[int]()
    g2.addEdge(1, 2)
    g2.addEdge(3, 1)
    let i = intersection(g1, g2)
    check i.hasEdge(1, 2)
    check not i.hasEdge(2, 3)

  test "difference":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    g1.addEdge(2, 3)
    g1.addEdge(3, 4)
    var g2 = newGraph[int]()
    g2.addEdge(1, 2)
    let d = difference(g1, g2)
    check d.numberOfEdges() == 2
    check not d.hasEdge(1, 2)
    check d.hasEdge(2, 3)
    check d.hasEdge(3, 4)

  test "compose":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(2, 3)
    let c = compose(g1, g2)
    check c.numberOfEdges() == 2

  test "relabelNodes error on missing mapping":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    var mapping = initTable[int, string]()
    mapping[1] = "A"
    # mapping[2] is missing — should raise
    expect(NimNetError):
      discard relabelNodes(g, mapping)

  test "relabelNodes DiGraph error":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    var mapping = initTable[int, string]()
    mapping[1] = "A"
    expect(NimNetError):
      discard relabelNodes(g, mapping)

  test "toDirected preserves self-loops":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    let dg = toDirected(g)
    check dg.hasEdge(1, 1)
    check dg.hasEdge(1, 2)
    check dg.hasEdge(2, 1)
    # Self-loop should only appear once, not duplicated
    check dg.numberOfEdges() == 3

  test "toUndirected merges reciprocal edges":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 1)
    g.addEdge(2, 3)
    let ug = toUndirected(g)
    check ug.numberOfEdges() == 2
    check ug.hasEdge(1, 2)
    check ug.hasEdge(2, 3)

  test "union of DiGraphs":
    var g1 = newDiGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newDiGraph[int]()
    g2.addEdge(2, 3)
    let u = union(g1, g2)
    check u.numberOfEdges() == 2
    check u.hasEdge(1, 2)
    check u.hasEdge(2, 3)

  test "disjointUnion of DiGraphs":
    var g1 = newDiGraph[int]()
    g1.addEdge(0, 1)
    var g2 = newDiGraph[int]()
    g2.addEdge(0, 1)
    let u = disjointUnion(g1, g2)
    check u.numberOfNodes() == 4
    check u.numberOfEdges() == 2

# ============================================================================
# convert.nim — edge cases
# ============================================================================
suite "Convert edge cases":
  test "fromAdjacencyMatrix basic":
    let mat = @[@[0.0, 1.0, 0.0],
                @[1.0, 0.0, 1.0],
                @[0.0, 1.0, 0.0]]
    let g = fromAdjacencyMatrix(mat)
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 2

  test "fromAdjacencyMatrix weighted":
    let mat = @[@[0.0, 2.5],
                @[2.5, 0.0]]
    let g = fromAdjacencyMatrix(mat)
    check g.numberOfEdges() == 1
    check abs(g.getEdgeAttr(0, 1).getWeight() - 2.5) < 1e-10

  test "degreeSequence":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(1, 4)
    let ds = degreeSequence(g)
    check ds[0] == 3  # highest degree first
    check ds.len == 4

  test "degreeSequence isolated nodes":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    g.addEdge(3, 4)
    let ds = degreeSequence(g)
    check ds.len == 4
    check ds[^1] == 0  # isolated nodes have degree 0

  test "toAdjacencyMatrix DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let (nodes, mat) = toAdjacencyMatrix(g)
    check nodes.len == 3
    # Verify asymmetry: 0→1 exists but 1→0 doesn't
    let i0 = nodes.find(0)
    let i1 = nodes.find(1)
    check mat[i0][i1] != 0.0
    check mat[i1][i0] == 0.0

  test "fromEdgeList empty":
    let g = fromEdgeList[int](@[])
    check g.numberOfNodes() == 0
    check g.numberOfEdges() == 0

  test "fromEdgeListDirected":
    let g = fromEdgeListDirected[int](@[(1, 2), (2, 3)])
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 2
    check g.hasEdge(1, 2)
    check not g.hasEdge(2, 1)

# ============================================================================
# multigraph.nim — coverage
# ============================================================================
suite "MultiGraph coverage":
  test "MultiGraph degree":
    var g = newMultiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 3)
    check g.degree(1) == 3  # 2 parallel + 1
    check g.degree(2) == 2

  test "MultiGraph removeNode":
    var g = newMultiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 3)
    discard g.addEdge(2, 3)
    g.removeNode(1)
    check not g.hasNode(1)
    check g.numberOfNodes() == 2

  test "MultiGraph neighbors":
    var g = newMultiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 3)
    discard g.addEdge(1, 2)  # parallel edge
    var nbrs: seq[int]
    for n in g.neighbors(1):
      nbrs.add(n)
    check 2 in nbrs
    check 3 in nbrs

  test "MultiGraph edge iteration":
    var g = newMultiGraph[int]()
    let k1 = g.addEdge(1, 2)
    let k2 = g.addEdge(1, 2)
    var edgeKeys: seq[int]
    for (u, v, key) in g.edges:
      edgeKeys.add(key)
    check edgeKeys.len == 2

  test "MultiGraph removeEdge by key":
    var g = newMultiGraph[int]()
    let k1 = g.addEdge(1, 2)
    let k2 = g.addEdge(1, 2)
    g.removeEdge(1, 2, k1)
    check g.hasEdge(1, 2)  # still has k2
    check g.numberOfEdges() == 1

  test "MultiGraph addWeightedEdge":
    var g = newMultiGraph[int]()
    let k = g.addWeightedEdge(1, 2, 3.5)
    check k >= 0
    check g.hasEdge(1, 2)

  test "MultiGraph string representation":
    var g = newMultiGraph[int]()
    discard g.addEdge(1, 2)
    let s = $g
    check "MultiGraph" in s

  test "MultiDiGraph basic":
    var g = newMultiDiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 2)
    discard g.addEdge(2, 1)
    check g.numberOfNodes() == 2
    check g.numberOfEdges() == 3

  test "MultiDiGraph inDegree and outDegree":
    var g = newMultiDiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 2)
    discard g.addEdge(3, 2)
    check g.inDegree(2) == 3
    check g.outDegree(1) == 2

  test "MultiDiGraph successors and predecessors":
    var g = newMultiDiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(3, 2)
    var succs: seq[int]
    for n in g.successors(1):
      succs.add(n)
    check 2 in succs
    var preds: seq[int]
    for n in g.predecessors(2):
      preds.add(n)
    check 1 in preds
    check 3 in preds

  test "MultiDiGraph removeEdge and removeNode":
    var g = newMultiDiGraph[int]()
    let k1 = g.addEdge(1, 2)
    discard g.addEdge(2, 3)
    g.removeEdge(1, 2, k1)
    check not g.hasEdge(1, 2)
    g.removeNode(2)
    check not g.hasNode(2)

  test "MultiDiGraph string representation":
    var g = newMultiDiGraph[int]()
    discard g.addEdge(1, 2)
    let s = $g
    check "MultiDiGraph" in s

# ============================================================================
# views.nim — coverage
# ============================================================================
suite "Views coverage":
  test "GraphView degree and hasEdge":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let v = view(g)
    check v.degree(2) == 2
    check v.hasEdge(1, 2)
    check not v.hasEdge(1, 3)

  test "GraphView getEdgeAttr":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 5.0)
    let v = view(g)
    let attr = v.getEdgeAttr(1, 2)
    check abs(attr.getWeight() - 5.0) < 1e-10

  test "GraphView subscript":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let v = view(g)
    let nbrs = v[1]  # adjacency table for node 1
    check 2 in nbrs
    check 3 in nbrs

  test "GraphView edge subscript":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.0)
    let v = view(g)
    let attr = v[1, 2]  # edge attribute
    check abs(attr.getWeight() - 3.0) < 1e-10

  test "DiGraphView ops":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 2)
    let v = view(g)
    check v.len == 3
    check v.numberOfNodes() == 3
    check v.numberOfEdges() == 3
    check v.hasNode(1)
    check v.hasEdge(1, 2)
    check v.inDegree(2) == 2
    check v.outDegree(2) == 1

  test "DiGraphView iteration":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let v = view(g)
    var nodeCount = 0
    for _ in v.nodes:
      nodeCount.inc
    check nodeCount == 3
    var edgeCount = 0
    for _ in v.edges:
      edgeCount.inc
    check edgeCount == 2

# ============================================================================
# compact.nim — edge cases
# ============================================================================
suite "CompactGraph edge cases":
  test "empty graph to compact":
    var g = newGraph[int]()
    let c = toCompact(g)
    check c.numberOfNodes() == 0
    check c.numberOfEdges() == 0

  test "single node compact":
    var g = newGraph[int]()
    g.addNode(1)
    let c = toCompact(g)
    check c.numberOfNodes() == 1
    check c.numberOfEdges() == 0

# ============================================================================
# I/O — Pajek format coverage
# ============================================================================
suite "Pajek I/O coverage":
  test "write and read Pajek undirected":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addWeightedEdge(2, 3, 4.5)
    g.addNode(4)  # isolated node
    let fname = "test_pajek_cov.net"
    pj.writePajek(g, fname)
    let g2 = pj.readPajek(fname)
    check g2.numberOfNodes() >= 3
    check g2.numberOfEdges() >= 2
    removeFile(fname)

  test "write and read Pajek directed":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let fname = "test_pajek_di_cov.net"
    pj.writePajek(g, fname)
    # Read back — readPajek returns Graph[int]
    let g2 = pj.readPajek(fname)
    check g2.numberOfNodes() >= 3
    removeFile(fname)

  test "Pajek with comments and empty lines":
    let data = "%% comment\n*Vertices 3\n1 \"n1\"\n2 \"n2\"\n3 \"n3\"\n\n*Edges\n1 2 1.0\n2 3 2.0\n"
    let fname = "test_pajek_comments.net"
    writeFile(fname, data)
    let g = pj.readPajek(fname)
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 2
    removeFile(fname)

# ============================================================================
# I/O — Graph6/Sparse6 format coverage
# ============================================================================
suite "Graph6 I/O coverage":
  test "writeGraph6 and readGraph6 roundtrip":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let s = g6.writeGraph6(g)
    let g2 = g6.readGraph6(s)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 3

  test "Graph6 empty graph":
    var g = newGraph[int]()
    g.addNode(0)
    let s = g6.writeGraph6(g)
    let g2 = g6.readGraph6(s)
    check g2.numberOfNodes() == 1
    check g2.numberOfEdges() == 0

  test "Graph6 single edge":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let s = g6.writeGraph6(g)
    let g2 = g6.readGraph6(s)
    check g2.numberOfNodes() == 2
    check g2.hasEdge(0, 1)

  test "Sparse6 roundtrip":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let s = g6.writeSparse6(g)
    let g2 = g6.readSparse6(s)
    check g2.numberOfNodes() == 2
    check g2.hasEdge(0, 1)

  test "Sparse6 empty graph":
    var g = newGraph[int]()
    g.addNode(0)
    let s = g6.writeSparse6(g)
    let g2 = g6.readSparse6(s)
    check g2.numberOfNodes() == 1
    check g2.numberOfEdges() == 0

  test "Graph6 with header prefix":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let encoded = g6.writeGraph6(g)
    let withHeader = ">>graph6<<" & encoded
    let g2 = g6.readGraph6(withHeader)
    check g2.numberOfNodes() == 2
    check g2.hasEdge(0, 1)

  test "Graph6 larger graph (10 nodes)":
    var g = newGraph[int]()
    for i in 0 ..< 10:
      g.addNode(i)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(3, 7)
    g.addEdge(5, 9)
    let s = g6.writeGraph6(g)
    let g2 = g6.readGraph6(s)
    check g2.numberOfNodes() == 10
    check g2.numberOfEdges() == 4

import nimnet/algorithms/layout as lay

# ============================================================================
# I/O — SVG edge cases
# ============================================================================
suite "SVG I/O coverage":
  test "SVG DiGraph writeSvg":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let pos = circularLayout(g)
    let fname = "test_svg_di_cov.svg"
    svgio.writeSvg(g, pos, fname)
    check fileExists(fname)
    let content = readFile(fname)
    check "<svg" in content
    removeFile(fname)

  test "SVG empty graph":
    var g = newGraph[int]()
    let pos = initTable[int, tuple[x, y: float]]()
    let s = svgio.toSvgString(g, pos)
    check "<svg" in s

  test "SVG single node":
    var g = newGraph[int]()
    g.addNode(1)
    let pos = circularLayout(g)
    let s = svgio.toSvgString(g, pos)
    check "<svg" in s

  test "SVG writeSvg to file":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let pos = circularLayout(g)
    let fname = "test_svg_cov.svg"
    svgio.writeSvg(g, pos, fname)
    check fileExists(fname)
    let content = readFile(fname)
    check "<svg" in content
    removeFile(fname)

  test "SVG with custom options":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let pos = circularLayout(g)
    var opts = defaultSvgOptions()
    opts.showLabels = false
    opts.nodeColor = "#FF0000"
    let s = svgio.toSvgString(g, pos, opts)
    check "<svg" in s
    check "#FF0000" in s

# ============================================================================
# I/O — GML, GraphML, GEXF edge cases
# ============================================================================
suite "I/O additional coverage":
  test "GML write and read DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addWeightedEdge(2, 3, 5.0)
    let fname = "test_gml_di_cov.gml"
    gmlio.writeGml(g, fname)
    let g2 = gmlio.readGml(fname)
    check g2.numberOfNodes() >= 3
    removeFile(fname)

  test "GraphML write and read DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addWeightedEdge(2, 3, 4.0)
    let fname = "test_graphml_di_cov.graphml"
    xmlio.writeGraphml(g, fname)
    let g2 = xmlio.readGraphml(fname)  # returns Graph[string]
    check g2.numberOfNodes() >= 3
    removeFile(fname)

  test "GEXF write and read":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addWeightedEdge(2, 3, 2.5)
    let fname = "test_gexf_cov.gexf"
    gexfio.writeGexf(g, fname)
    let g2 = gexfio.readGexf(fname)
    check g2.numberOfNodes() >= 3
    removeFile(fname)

  test "GEXF write DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let fname = "test_gexf_di_cov.gexf"
    gexfio.writeGexf(g, fname)
    check fileExists(fname)
    removeFile(fname)

  test "edge list write DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let fname = "test_edgelist_di_cov.txt"
    elio.writeEdgelistDigraph(g, fname)
    check fileExists(fname)
    let content = readFile(fname)
    check content.len > 0
    removeFile(fname)

  test "DOT write DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.setEdgeAttr(1, 2, "label", "test")
    let fname = "test_dot_di_cov.dot"
    dotio.writeDot(g, fname)
    check fileExists(fname)
    let content = readFile(fname)
    check "digraph" in content
    removeFile(fname)

  test "DOT write undirected with attrs":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.setEdgeAttr(1, 2, "color", "red")
    g.setNodeAttr(1, "label", "Node1")
    let fname = "test_dot_cov.dot"
    dotio.writeDot(g, fname)
    let content = readFile(fname)
    check "graph" in content
    removeFile(fname)

  test "GML with graph name":
    var g = newGraph[int](name = "TestGML")
    g.addEdge(1, 2)
    let fname = "test_gml_name_cov.gml"
    gmlio.writeGml(g, fname)
    let content = readFile(fname)
    check "TestGML" in content
    removeFile(fname)

  test "GML with node labels":
    var g = newGraph[int]()
    g.addNode(1)
    g.setNodeAttr(1, "label", "NodeOne")
    g.addEdge(1, 2)
    let fname = "test_gml_label_cov.gml"
    gmlio.writeGml(g, fname)
    let content = readFile(fname)
    check "NodeOne" in content
    removeFile(fname)

# ============================================================================
# Additional algorithm edge cases
# ============================================================================
suite "Algorithm edge cases":
  test "shortest path no path exists":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addNode(3)  # disconnected
    expect(NimNetNoPath):
      discard shortestPath(g, 1, 3)

  test "shortest path same source and target":
    var g = newGraph[int]()
    g.addNode(1)
    let p = shortestPath(g, 1, 1)
    check p == @[1]

  test "BFS on disconnected graph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addNode(3)
    var visited = initHashSet[int]()
    visited.incl(1)
    for (u, v) in bfsEdges(g, 1):
      visited.incl(v)
    check 1 in visited
    check 2 in visited
    check 3 notin visited

  test "closeness centrality disconnected":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addNode(3)
    let cc = closenessCentrality(g)
    check cc[3] == 0.0  # disconnected node

  test "clustering coefficient of complete graph":
    let g = completeGraph[int](5)
    let cc = clustering(g)
    for n, c in cc:
      check abs(c - 1.0) < 1e-10

  test "isTree with single node":
    var g = newGraph[int]()
    g.addNode(1)
    check isTree(g) == true

  test "isTree with cycle":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 1)
    check isTree(g) == false

  test "pageRank on small graph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 1)
    let pr = pageRank(g)
    # In a symmetric cycle, all ranks should be equal
    check abs(pr[1] - pr[2]) < 0.05
    check abs(pr[2] - pr[3]) < 0.05

  test "topologicalSort":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(1, 3)
    let ts = topologicalSort(g)
    check ts.len == 3
    # 1 should come before 2 and 3
    check ts.find(1) < ts.find(2)
    check ts.find(1) < ts.find(3)

  test "topologicalSort with cycle raises":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 1)
    expect(HasACycle):
      discard topologicalSort(g)

  test "NodeNotFound exceptions":
    var g = newGraph[int]()
    g.addNode(1)
    expect(NodeNotFound):
      discard g.degree(99)

  test "EdgeNotFound exceptions":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    expect(EdgeNotFound):
      discard g.getEdgeAttr(1, 2)
