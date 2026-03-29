## Coverage improvement tests — Phase 2
##
## Targeting deeper code paths to push coverage from 47% toward 70%+:
## - graph.nim: subgraph, edgeSubgraph, clearEdges, selfLoop iterators,
##   removeSelfLoops, nodeSeq, edgeSeq, adjacencyTable, operators (+/-)
## - digraph.nim: same + reverse, predecessors, clearEdges
## - types.nim: EdgeAttr compatibility ops ([], []=, contains, pairs, ==)
## - compact.nim: CompactDiGraph, toGraph roundtrip, bfsCSR, degreeCSR
## - static_graph.nim: staticGraph, staticDiGraph, staticWeightedGraph
## - convert.nim: fromAdjacencyMatrix directed, toAdjacencyMatrix roundtrip
## - multigraph.nim: MultiDiGraph addWeightedEdge, edge iteration, contains
## - views.nim: DiGraphView successors/predecessors
## - io/graph6.nim: Sparse6 larger, edge cases
## - io/pajek.nim: readPajekDigraph roundtrip
## - io/svg.nim: toSvgString DiGraph variant
## - algorithms: edge cases for coloring, dominating, independent_set, bipartite,
##   euler, core, link_prediction, properties, bridges, ego

import std/[unittest, tables, sets, math, json, os, strutils, sequtils, algorithm]
import nimnet
import nimnet/graph as graphmod
import nimnet/digraph as digraphmod
import nimnet/types as types
import nimnet/operators as ops
import nimnet/convert as conv
import nimnet/multigraph as mg
import nimnet/views as vw
import nimnet/compact as cpt
import nimnet/static_graph as sg
import nimnet/builder as bld
import nimnet/io/pajek as pj
import nimnet/io/graph6 as g6
import nimnet/io/svg as svgio
import nimnet/io/edgelist as elio
import nimnet/io/adjlist as adjio
import nimnet/io/gml as gmlio
import nimnet/io/graphml as xmlio
import nimnet/io/gexf as gexfio
import nimnet/io/dot as dotio
import nimnet/algorithms/layout as lay
import nimnet/algorithms/traversal as trav
import nimnet/algorithms/shortest_paths as sp
import nimnet/algorithms/components as comp
import nimnet/algorithms/centrality as cent
import nimnet/algorithms/clustering as clust
import nimnet/algorithms/community as comm
import nimnet/algorithms/louvain as louv
import nimnet/algorithms/mst as mstmod
import nimnet/algorithms/dag as dagmod
import nimnet/algorithms/flow as flowmod
import nimnet/algorithms/all_pairs_shortest as aps
import nimnet/algorithms/connectivity as conn
import nimnet/algorithms/isomorphism as iso
import nimnet/algorithms/tsp as tspmod
import nimnet/algorithms/properties as prop
import nimnet/algorithms/link_prediction as lp
import nimnet/algorithms/core as coremod
import nimnet/algorithms/stats as statsmod
import nimnet/algorithms/clique as clq
import nimnet/algorithms/independent_set as indset
import nimnet/algorithms/dominating as dom
import nimnet/algorithms/coloring as col
import nimnet/algorithms/bipartite as bip
import nimnet/algorithms/euler as eul
import nimnet/algorithms/bridges as brmod
import nimnet/algorithms/ego as egomod
import nimnet/algorithms/distance_measures as dm
import nimnet/algorithms/simple_paths as simpaths
import nimnet/algorithms/efficiency as eff
import nimnet/algorithms/richclub as rc
import nimnet/algorithms/wiener as wi
import nimnet/algorithms/cycles as cyc
import nimnet/algorithms/matching as mat
import nimnet/algorithms/graph_products as gp
import nimnet/algorithms/graph_hashing as gh
import nimnet/algorithms/similarity as sim
import nimnet/algorithms/minors as mn
import nimnet/algorithms/cuts as cu

# ============================================================================
# graph.nim — deeper code path coverage
# ============================================================================
suite "Graph subgraph & edge operations":
  test "subgraph with HashSet":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    g.setNodeAttr(1, "label", "A")
    let sub = g.subgraph([1, 2].toHashSet)
    check sub.numberOfNodes() == 2
    check sub.numberOfEdges() == 1
    check sub.hasEdge(1, 2)
    check not sub.hasEdge(2, 3)

  test "subgraph with openArray":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let sub = g.subgraph([2, 3])
    check sub.numberOfNodes() == 2
    check sub.numberOfEdges() == 1

  test "subgraph empty set":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let sub = g.subgraph(initHashSet[int]())
    check sub.numberOfNodes() == 0
    check sub.numberOfEdges() == 0

  test "subgraph with non-existent nodes":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let sub = g.subgraph([1, 99].toHashSet)
    check sub.numberOfNodes() == 1
    check sub.numberOfEdges() == 0

  test "edgeSubgraph":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    g.setNodeAttr(1, "label", "A")
    let sub = g.edgeSubgraph([(1, 2), (3, 4)])
    check sub.numberOfNodes() == 4
    check sub.numberOfEdges() == 2
    check sub.hasEdge(1, 2)
    check not sub.hasEdge(2, 3)
    check sub.hasEdge(3, 4)

  test "edgeSubgraph with non-existent edge":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let sub = g.edgeSubgraph([(1, 2), (5, 6)])
    check sub.numberOfNodes() == 2
    check sub.numberOfEdges() == 1

  test "clearEdges keeps nodes":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.clearEdges()
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 0
    check g.hasNode(1)

  test "selfLoopEdges iterator":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(2, 2)
    g.addEdge(1, 2)
    var loops: seq[(int, int)]
    for e in g.selfLoopEdges:
      loops.add(e)
    check loops.len == 2

  test "selfLoopNodes iterator":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    g.addNode(3)
    var slNodes: seq[int]
    for n in g.selfLoopNodes:
      slNodes.add(n)
    check slNodes.len == 1
    check 1 in slNodes

  test "removeSelfLoops":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(2, 2)
    g.addEdge(1, 2)
    g.removeSelfLoops()
    check g.numberOfSelfLoops() == 0
    check g.hasEdge(1, 2)
    check g.numberOfEdges() == 1

  test "nodeSeq and edgeSeq":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let ns = g.nodeSeq()
    check ns.len == 3
    let es = g.edgeSeq()
    check es.len == 2

  test "adjacencyTable":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let adj = g.adjacencyTable(1)
    check 2 in adj
    check 3 in adj

  test "adjacencyTable NodeNotFound":
    var g = newGraph[int]()
    g.addNode(1)
    expect(NodeNotFound):
      discard g.adjacencyTable(99)

  test "Graph + operator":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(2, 3)
    let g3 = g1 + g2
    check g3.numberOfNodes() == 3
    check g3.numberOfEdges() == 2

  test "Graph - operator":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    g1.addEdge(2, 3)
    var g2 = newGraph[int]()
    g2.addEdge(1, 2)
    let g3 = g1 - g2
    check g3.numberOfNodes() == 3
    check g3.numberOfEdges() == 1
    check g3.hasEdge(2, 3)
    check not g3.hasEdge(1, 2)

  test "Graph == operator":
    var g1 = newGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(1, 2)
    check g1 == g2

  test "addWeightedEdgesFrom":
    var g = newGraph[int]()
    g.addWeightedEdgesFrom([(u: 1, v: 2, weight: 1.5), (u: 2, v: 3, weight: 2.5)])
    check g.numberOfEdges() == 2
    check abs(g.weight(1, 2) - 1.5) < 1e-10
    check abs(g.weight(2, 3) - 2.5) < 1e-10

  test "setEdgeAttr by key-value":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.setEdgeAttr(1, 2, "color", "red")
    check g.getEdgeAttr(1, 2)["color"] == "red"

  test "setNodeAttr by key-value":
    var g = newGraph[int]()
    g.addNode(1)
    g.setNodeAttr(1, "label", "Hub")
    let attr = g.getNodeAttr(1)
    check attr["label"].getStr() == "Hub"

  test "nodesWithAttr iterator":
    var g = newGraph[int]()
    g.addNode(1)
    g.setNodeAttr(1, "color", "red")
    g.addNode(2)
    var count = 0
    for (n, attr) in g.nodesWithAttr:
      count.inc
    check count == 2

  test "edgesWithAttr iterator":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.0)
    g.addEdge(2, 3)
    var count = 0
    for (u, v, attr) in g.edgesWithAttr:
      count.inc
    check count == 2

  test "adjacency iterator":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    var count = 0
    for (n, adj) in g.adjacency:
      count.inc
    check count == 3

  test "degree with self-loop counts twice":
    var g = newGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    check g.degree(1) == 3  # self-loop=2 + edge=1

  test "weight accessor":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 7.5)
    check abs(g.weight(1, 2) - 7.5) < 1e-10

  test "weight accessor EdgeNotFound":
    var g = newGraph[int]()
    g.addNode(1)
    g.addNode(2)
    expect(EdgeNotFound):
      discard g.weight(1, 2)

  test "Graph name and $ string rep":
    var g = newGraph[int](name = "MyGraph")
    g.addEdge(1, 2)
    let s = $g
    check "MyGraph" in s

  test "Graph order and size":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check g.order() == 3
    check g.size() == 2

  test "density of empty graph":
    var g = newGraph[int]()
    check graphmod.density(g) == 0.0

  test "setEdgeAttr replaces both directions":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let attr = newEdgeAttr(5.0)
    g.setEdgeAttr(1, 2, attr)
    check abs(g.getEdgeAttr(2, 1).getWeight() - 5.0) < 1e-10

# ============================================================================
# digraph.nim — deeper code path coverage
# ============================================================================
suite "DiGraph subgraph & edge operations":
  test "DiGraph subgraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    g.setNodeAttr(1, "label", "A")
    let sub = g.subgraph([1, 2].toHashSet)
    check sub.numberOfNodes() == 2
    check sub.numberOfEdges() == 1
    check sub.hasEdge(1, 2)

  test "DiGraph subgraph openArray":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let sub = g.subgraph([2, 3])
    check sub.numberOfNodes() == 2
    check sub.hasEdge(2, 3)

  test "DiGraph edgeSubgraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    let sub = g.edgeSubgraph([(1, 2), (3, 4)])
    check sub.numberOfNodes() == 4
    check sub.numberOfEdges() == 2

  test "DiGraph clearEdges":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.clearEdges()
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 0

  test "DiGraph selfLoopEdges":
    var g = newDiGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(2, 2)
    g.addEdge(1, 2)
    var loops: seq[(int, int)]
    for e in g.selfLoopEdges:
      loops.add(e)
    check loops.len == 2

  test "DiGraph removeSelfLoops":
    var g = newDiGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    g.removeSelfLoops()
    check g.numberOfSelfLoops() == 0
    check g.hasEdge(1, 2)

  test "DiGraph nodeSeq and edgeSeq":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check g.nodeSeq().len == 3
    check g.edgeSeq().len == 2

  test "DiGraph adjacencyTable":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let adj = g.adjacencyTable(1)
    check 2 in adj
    check 3 in adj

  test "DiGraph adjacencyTable missing":
    var g = newDiGraph[int]()
    g.addNode(1)
    expect(NodeNotFound):
      discard g.adjacencyTable(99)

  test "DiGraph + operator":
    var g1 = newDiGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newDiGraph[int]()
    g2.addEdge(2, 3)
    let g3 = g1 + g2
    check g3.numberOfEdges() == 2
    check g3.hasEdge(1, 2)
    check g3.hasEdge(2, 3)

  test "DiGraph - operator":
    var g1 = newDiGraph[int]()
    g1.addEdge(1, 2)
    g1.addEdge(2, 3)
    var g2 = newDiGraph[int]()
    g2.addEdge(1, 2)
    let g3 = g1 - g2
    check g3.numberOfEdges() == 1
    check g3.hasEdge(2, 3)
    check not g3.hasEdge(1, 2)

  test "DiGraph == operator":
    var g1 = newDiGraph[int]()
    g1.addEdge(1, 2)
    var g2 = newDiGraph[int]()
    g2.addEdge(1, 2)
    check g1 == g2

  test "DiGraph addWeightedEdgesFrom":
    var g = newDiGraph[int]()
    g.addWeightedEdgesFrom([(u: 1, v: 2, weight: 1.5), (u: 2, v: 3, weight: 2.5)])
    check g.numberOfEdges() == 2
    check abs(g.weight(1, 2) - 1.5) < 1e-10

  test "DiGraph setEdgeAttr by key-value":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.setEdgeAttr(1, 2, "color", "blue")
    check g.getEdgeAttr(1, 2)["color"] == "blue"

  test "DiGraph setNodeAttr by key-value":
    var g = newDiGraph[int]()
    g.addNode(1)
    g.setNodeAttr(1, "label", "Hub")
    let attr = g.getNodeAttr(1)
    check attr["label"].getStr() == "Hub"

  test "DiGraph edgesWithAttr":
    var g = newDiGraph[int]()
    g.addWeightedEdge(1, 2, 3.0)
    g.addEdge(2, 3)
    var count = 0
    for (u, v, attr) in g.edgesWithAttr:
      count.inc
    check count == 2

  test "DiGraph predecessors iterator":
    var g = newDiGraph[int]()
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    var preds: seq[int]
    for p in g.predecessors(3):
      preds.add(p)
    check 1 in preds
    check 2 in preds

  test "DiGraph successors iterator":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    var succs: seq[int]
    for s in g.successors(1):
      succs.add(s)
    check 2 in succs
    check 3 in succs

  test "DiGraph hasSelfLoop":
    var g = newDiGraph[int]()
    g.addEdge(1, 1)
    g.addEdge(1, 2)
    check g.hasSelfLoop(1)
    check not g.hasSelfLoop(2)

  test "DiGraph reverse preserves node attrs":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.setNodeAttr(1, "color", "red")
    let r = g.reverse()
    check r.hasEdge(2, 1)
    check r.getNodeAttr(1)["color"].getStr() == "red"

  test "DiGraph weight accessor":
    var g = newDiGraph[int]()
    g.addWeightedEdge(1, 2, 4.0)
    check abs(g.weight(1, 2) - 4.0) < 1e-10

  test "DiGraph order size":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    check g.order() == 2
    check g.size() == 1

  test "DiGraph $ string":
    var g = newDiGraph[int](name = "MyDG")
    g.addEdge(1, 2)
    check "MyDG" in $g

# ============================================================================
# types.nim — EdgeAttr compatibility operators
# ============================================================================
suite "EdgeAttr compatibility operators":
  test "[] accessor weight":
    let attr = newEdgeAttr(3.14)
    check attr["weight"].contains("3.14")

  test "[] accessor extra key":
    var attr = newEdgeAttr()
    attr["color"] = "blue"
    check attr["color"] == "blue"

  test "[]= setter weight via string":
    var attr = newEdgeAttr()
    attr["weight"] = "7.5"
    check abs(attr.getWeight() - 7.5) < 1e-10

  test "[]= setter invalid weight string":
    var attr = newEdgeAttr()
    attr["weight"] = "notanumber"
    # Should silently keep old weight
    check abs(attr.getWeight() - 1.0) < 1e-10

  test "contains operator":
    var attr = newEdgeAttr()
    attr["color"] = "red"
    check "weight" in attr
    check "color" in attr
    check "missing" notin attr

  test "hasKey":
    var attr = newEdgeAttr()
    attr["x"] = "1"
    check attr.hasKey("weight")
    check attr.hasKey("x")
    check not attr.hasKey("y")

  test "len":
    var attr = newEdgeAttr()
    check attr.len == 1  # just weight
    attr["color"] = "red"
    check attr.len == 2

  test "pairs iterator":
    var attr = newEdgeAttr(2.0)
    attr["color"] = "red"
    var keys: seq[string]
    for (k, v) in attr.pairs:
      keys.add(k)
    check "weight" in keys
    check "color" in keys

  test "EdgeAttr equality":
    let a = newEdgeAttr(2.5)
    let b = newEdgeAttr(2.5)
    check a == b
    let c = newEdgeAttr(3.0)
    check a != c

  test "newEdgeAttr from pairs with weight":
    let a = newEdgeAttr({"weight": "3.0", "color": "red", "style": "dashed"})
    check abs(a.getWeight() - 3.0) < 1e-10
    check a["color"] == "red"
    check a["style"] == "dashed"

  test "newEdgeAttr from pairs with bad weight":
    let a = newEdgeAttr({"weight": "bad"})
    check abs(a.getWeight() - 1.0) < 1e-10  # fallback to default

  test "getStr default":
    let attr = newEdgeAttr()
    check types.getStr(attr, "nonexistent", "fallback") == "fallback"

# ============================================================================
# compact.nim — CompactDiGraph & deeper coverage
# ============================================================================
suite "CompactGraph deeper":
  test "CompactDiGraph from DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addWeightedEdge(0, 2, 3.0)
    let cg = toCompact(g)
    check cg.numberOfNodes() == 3
    check cg.numberOfEdges() == 3

  test "CompactDiGraph neighborsCSR":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    let cg = toCompact(g)
    # Find index for node 0
    var idx0 = -1
    for i, n in cg.nodeList:
      if n == 0: idx0 = i
    var nbrs: seq[int]
    for nb in cg.neighborsCSR(idx0):
      nbrs.add(nb)
    check nbrs.len == 2

  test "CompactGraph toGraph roundtrip":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addWeightedEdge(0, 2, 5.0)
    let cg = toCompact(g)
    let g2 = toGraph(cg)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 3
    check g2.hasEdge(0, 1)
    check g2.hasEdge(0, 2)

  test "CompactGraph bfsCSR":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let cg = toCompact(g)
    var idx0 = -1
    for i, n in cg.nodeList:
      if n == 0: idx0 = i
    let order = bfsCSR(cg, idx0)
    check order.len == 4
    check order[0] == idx0

  test "CompactGraph degreeCSR":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    let cg = toCompact(g)
    var idx0 = -1
    for i, n in cg.nodeList:
      if n == 0: idx0 = i
    check cg.degreeCSR(idx0) == 3

  test "CompactGraph weighted roundtrip":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 2.5)
    g.addWeightedEdge(1, 2, 3.5)
    let cg = toCompact(g)
    let g2 = toGraph(cg)
    check abs(g2.weight(0, 1) - 2.5) < 1e-10
    check abs(g2.weight(1, 2) - 3.5) < 1e-10

# ============================================================================
# static_graph.nim — compile-time graph construction
# ============================================================================
suite "StaticGraph":
  test "staticGraph basic":
    let g = staticGraph[int]([(1, 2), (2, 3), (3, 1)])
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 3

  test "staticDiGraph basic":
    let g = staticDiGraph[int]([(1, 2), (2, 3)])
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 2
    check g.hasEdge(1, 2)
    check not g.hasEdge(2, 1)

  test "staticWeightedGraph":
    let g = staticWeightedGraph[int]([(1, 2, 1.5), (2, 3, 2.5)])
    check g.numberOfEdges() == 2
    check abs(g.weight(1, 2) - 1.5) < 1e-10
    check abs(g.weight(2, 3) - 2.5) < 1e-10

# ============================================================================
# convert.nim — deeper coverage
# ============================================================================
suite "Convert deeper":
  test "fromAdjacencyMatrix directed flag":
    let mat = @[@[0.0, 1.0, 0.0],
                @[0.0, 0.0, 1.0],
                @[1.0, 0.0, 0.0]]
    let g = fromAdjacencyMatrix(mat, directed = true)
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 3

  test "toAdjacencyMatrix undirected roundtrip":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let (nodes, mat) = toAdjacencyMatrix(g)
    check nodes.len == 3
    # Matrix should be symmetric
    for i in 0 ..< nodes.len:
      for j in 0 ..< nodes.len:
        check abs(mat[i][j] - mat[j][i]) < 1e-10

  test "toAdjacencyMatrix DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let (nodes, mat) = toAdjacencyMatrix(g)
    let i0 = nodes.find(0)
    let i1 = nodes.find(1)
    check mat[i0][i1] != 0.0
    check mat[i1][i0] == 0.0

  test "fromEdgeList":
    let g = fromEdgeList[int](@[(1, 2), (2, 3)])
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 2

  test "degreeSequence sorted descending":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(1, 4)
    g.addEdge(2, 3)
    let ds = degreeSequence(g)
    check ds[0] >= ds[1]
    check ds[1] >= ds[2]

# ============================================================================
# views.nim — DiGraphView successors/predecessors
# ============================================================================
suite "Views deeper":
  test "DiGraphView successors":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let v = view(g)
    var succs: seq[int]
    for s in v.successors(1):
      succs.add(s)
    check 2 in succs
    check 3 in succs

  test "DiGraphView predecessors":
    var g = newDiGraph[int]()
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let v = view(g)
    var preds: seq[int]
    for p in v.predecessors(3):
      preds.add(p)
    check 1 in preds
    check 2 in preds

  test "GraphView nodes iterator":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addNode(3)
    let v = view(g)
    var count = 0
    for _ in v.nodes:
      count.inc
    check count == 3

  test "GraphView edges iterator":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let v = view(g)
    var count = 0
    for _ in v.edges:
      count.inc
    check count == 2

  test "GraphView neighbors iterator":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    let v = view(g)
    var nbrs: seq[int]
    for n in v.neighbors(1):
      nbrs.add(n)
    check nbrs.len == 2

  test "GraphView len and numberOfEdges":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let v = view(g)
    check v.len == 3
    check v.numberOfNodes() == 3
    check v.numberOfEdges() == 2

# ============================================================================
# multigraph.nim — MultiDiGraph deeper
# ============================================================================
suite "MultiDiGraph deeper":
  test "MultiDiGraph addWeightedEdge":
    var g = newMultiDiGraph[int]()
    let k = g.addWeightedEdge(1, 2, 3.5)
    check k >= 0
    check g.hasEdge(1, 2)

  test "MultiDiGraph hasEdge false":
    var g = newMultiDiGraph[int]()
    g.addNode(1)
    check not g.hasEdge(1, 2)

  test "MultiDiGraph contains":
    var g = newMultiDiGraph[int]()
    g.addNode(1)
    check 1 in g
    check 2 notin g

  test "MultiDiGraph edges iterator":
    var g = newMultiDiGraph[int]()
    let k1 = g.addEdge(1, 2)
    let k2 = g.addEdge(1, 2)
    let k3 = g.addEdge(2, 3)
    var count = 0
    for (u, v, key) in g.edges:
      count.inc
    check count == 3

  test "MultiDiGraph nodes iterator":
    var g = newMultiDiGraph[int]()
    g.addNode(1)
    g.addNode(2)
    g.addNode(3)
    var count = 0
    for _ in g.nodes:
      count.inc
    check count == 3

  test "MultiDiGraph removeEdge invalid key":
    var g = newMultiDiGraph[int]()
    let k = g.addEdge(1, 2)
    expect(EdgeNotFound):
      g.removeEdge(1, 2, 9999)

  test "MultiDiGraph removeNode with predecessors":
    var g = newMultiDiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(3, 2)
    discard g.addEdge(2, 3)
    g.removeNode(2)
    check not g.hasNode(2)
    check g.numberOfNodes() == 2

  test "MultiGraph removeEdge invalid key":
    var g = newMultiGraph[int]()
    let k = g.addEdge(1, 2)
    expect(EdgeNotFound):
      g.removeEdge(1, 2, 9999)

  test "MultiGraph contains operator":
    var g = newMultiGraph[int]()
    g.addNode(1)
    check 1 in g
    check 2 notin g

  test "MultiGraph numberOfEdges":
    var g = newMultiGraph[int]()
    discard g.addEdge(1, 2)
    discard g.addEdge(1, 2)
    discard g.addEdge(2, 3)
    check g.numberOfEdges() == 3

# ============================================================================
# I/O — Pajek DiGraph roundtrip
# ============================================================================
suite "Pajek DiGraph I/O":
  test "readPajekDigraph roundtrip":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addWeightedEdge(2, 3, 2.5)
    let fname = "test_pajek_digraph_cov2.net"
    pj.writePajek(g, fname)
    let g2 = pj.readPajekDigraph(fname)
    check g2.numberOfNodes() >= 3
    check g2.numberOfEdges() >= 2
    removeFile(fname)

  test "readPajekDigraph with Edges section":
    let data = "*Vertices 3\n1 \"a\"\n2 \"b\"\n3 \"c\"\n*Edges\n1 2 1.0\n2 3 1.0\n"
    let fname = "test_pajek_edges_cov2.net"
    writeFile(fname, data)
    let g = pj.readPajekDigraph(fname)
    check g.numberOfNodes() == 3
    check g.numberOfEdges() >= 2
    removeFile(fname)

# ============================================================================
# I/O — Graph6 / Sparse6 deeper
# ============================================================================
suite "Graph6 deeper":
  test "Sparse6 triangle roundtrip":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let s = g6.writeSparse6(g)
    let g2 = g6.readSparse6(s)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 3

  test "Sparse6 path graph":
    var g = newGraph[int]()
    for i in 0 ..< 5:
      g.addEdge(i, i + 1)
    let s = g6.writeSparse6(g)
    let g2 = g6.readSparse6(s)
    check g2.numberOfNodes() == 6
    check g2.numberOfEdges() == 5

  test "Graph6 K5 roundtrip":
    let g = completeGraph[int](5)
    let s = g6.writeGraph6(g)
    let g2 = g6.readGraph6(s)
    check g2.numberOfNodes() == 5
    check g2.numberOfEdges() == 10

  test "Graph6 no-edge graph":
    var g = newGraph[int]()
    for i in 0 ..< 4:
      g.addNode(i)
    let s = g6.writeGraph6(g)
    let g2 = g6.readGraph6(s)
    check g2.numberOfNodes() == 4
    check g2.numberOfEdges() == 0

# ============================================================================
# I/O — SVG DiGraph toSvgString
# ============================================================================
suite "SVG deeper":
  test "toSvgString DiGraph":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let pos = circularLayout(g)
    # DiGraph uses writeSvg file path; we test with file
    let fname = "test_svg_digraph_cov2.svg"
    svgio.writeSvg(g, pos, fname)
    let content = readFile(fname)
    check "<svg" in content
    check "marker" in content  # DiGraph should have arrow marker
    removeFile(fname)

  test "SVG custom options no labels":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    let pos = circularLayout(g)
    var opts = defaultSvgOptions()
    opts.showLabels = false
    let s = svgio.toSvgString(g, pos, opts)
    check "<circle" in s

  test "toSvgString with special chars":
    var g = newGraph[string]()
    g.addEdge("<a>", "&b")
    var pos = initTable[string, tuple[x, y: float]]()
    pos["<a>"] = (100.0, 100.0)
    pos["&b"] = (200.0, 200.0)
    let s = svgio.toSvgString(g, pos)
    check "&lt;" in s or "&amp;" in s  # xmlEscape should handle

# ============================================================================
# I/O — additional formats deeper
# ============================================================================
suite "IO additional deeper":
  test "adjacency list write and read":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addNode(4)
    let fname = "test_adjlist_cov2.txt"
    adjio.writeAdjlist(g, fname)
    let g2 = adjio.readAdjlist(fname)
    check g2.numberOfNodes() >= 3
    removeFile(fname)

  test "edge list write and read undirected":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let fname = "test_edgelist_cov2.txt"
    elio.writeEdgelist(g, fname)
    let g2 = elio.readEdgelist(fname)
    check g2.numberOfEdges() >= 2
    removeFile(fname)

  test "GML with weighted edges":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 5.5)
    g.addWeightedEdge(2, 3, 3.3)
    let fname = "test_gml_weighted_cov2.gml"
    gmlio.writeGml(g, fname)
    let g2 = gmlio.readGml(fname)
    check g2.numberOfEdges() >= 2
    removeFile(fname)

  test "GraphML undirected roundtrip":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addWeightedEdge(3, 4, 2.0)
    let fname = "test_graphml_cov2.graphml"
    xmlio.writeGraphml(g, fname)
    let g2 = xmlio.readGraphml(fname)
    check g2.numberOfNodes() >= 4
    removeFile(fname)

  test "GEXF DiGraph roundtrip":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let fname = "test_gexf_di_cov2.gexf"
    gexfio.writeGexf(g, fname)
    let g2 = gexfio.readGexf(fname)
    check g2.numberOfNodes() >= 3
    removeFile(fname)

  test "DOT undirected roundtrip":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let fname = "test_dot_cov2.dot"
    dotio.writeDot(g, fname)
    let content = readFile(fname)
    check "graph" in content
    removeFile(fname)

# ============================================================================
# Algorithm modules — deeper edge cases
# ============================================================================
suite "Algorithm deeper coverage":
  # ---------- coloring ----------
  test "greedyColor smallest_last":
    let g = completeGraph[int](4)
    let c = col.greedyColor(g, "smallest_last")
    check col.isProperColoring(g, c)

  test "greedyColor sequential":
    let g = completeGraph[int](4)
    let c = col.greedyColor(g, "sequential")
    check col.isProperColoring(g, c)

  test "greedyColor empty graph":
    var g = newGraph[int]()
    let c = col.greedyColor(g)
    check c.len == 0

  test "isProperColoring invalid":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    var bad = {1: 0, 2: 0}.toTable
    check not col.isProperColoring(g, bad)

  # ---------- dominating set ----------
  test "minimumDominatingSet on path":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    let ds = dom.minimumDominatingSet(g)
    check dom.isDominatingSet(g, ds)

  test "dominationNumber":
    let g = completeGraph[int](5)
    check dom.dominationNumber(g) == 1

  test "isDominatingSet false":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(3, 4)
    let ds = [1].toHashSet
    check not dom.isDominatingSet(g, ds)

  # ---------- independent set ----------
  test "maximumIndependentSet on path":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let mis = indset.maximumIndependentSet(g)
    check indset.isIndependentSet(g, mis)
    check mis.len >= 2

  test "minimumVertexCover":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let vc = indset.minimumVertexCover(g)
    # Every edge has at least one endpoint in vc
    for (u, v) in g.edges:
      check u in vc or v in vc

  test "isIndependentSet false":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    check not indset.isIndependentSet(g, [1, 2].toHashSet)

  # ---------- bipartite ----------
  test "isBipartite tree":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check bip.isBipartite(g)

  test "isBipartite odd cycle":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check not bip.isBipartite(g)

  test "bipartiteSets":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let (left, right) = bip.bipartiteSets(g)
    check left.len + right.len == 4

  test "maximumMatching bipartite":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    g.addEdge(4, 5)
    let m = bip.maximumMatching(g)
    check m.len == 3

  # ---------- euler ----------
  test "isEulerian K3":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check eul.isEulerian(g)

  test "isEulerian path is not":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check not eul.isEulerian(g)

  test "hasSemiEulerianPath":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check eul.isSemiEulerian(g)

  # ---------- core decomposition ----------
  test "coreNumber on triangle":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let cores = coremod.coreNumber(g)
    for n, c in cores:
      check c == 2

  test "kCore extraction":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    g.addEdge(3, 0)
    let sub = coremod.kCore(g, 2)
    check sub.numberOfNodes() == 3
    check not sub.hasNode(3)

  # ---------- link prediction ----------
  test "commonNeighbors":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let cn = lp.commonNeighbors(g, 0, 3)
    check cn >= 1  # node 2 is common

  test "jaccardCoefficient":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    let j = lp.jaccardCoefficient(g, 0, 1)
    check j > 0.0 and j <= 1.0

  test "adamicAdarIndex":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let aa = lp.adamicAdar(g, 0, 3)
    check aa > 0.0

  # ---------- properties ----------
  test "isForest":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    check prop.isForest(g)

  test "isRegular K3":
    let g = completeGraph[int](3)
    check prop.isRegular(g)

  test "isComplete":
    let g = completeGraph[int](4)
    check prop.isComplete(g)

  test "girth triangle":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check prop.girth(g) == 3

  # ---------- bridges ----------
  test "bridges on simple graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(2, 3)
    let b = brmod.bridges(g)
    check b.len == 1  # (2,3) is a bridge

  test "articulationPoints":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(2, 3)
    let ap = brmod.articulationPoints(g)
    check 2 in ap

  # ---------- ego ----------
  test "egoGraph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let ego = egomod.egoGraph(g, 1, 1)
    check ego.hasNode(0)
    check ego.hasNode(1)
    check ego.hasNode(2)
    check not ego.hasNode(3)

  # ---------- distance measures ----------
  test "diameter and radius":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check dm.diameter(g) == 3
    check dm.radius(g) == 2

  test "center and periphery":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let c = dm.center(g)
    check c.len >= 1
    let p = dm.periphery(g)
    check p.len >= 1

  test "eccentricity":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check dm.eccentricity(g, 0) == 2
    check dm.eccentricity(g, 1) == 1

  # ---------- simple paths ----------
  test "allSimplePaths":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let paths = simpaths.allSimplePathsSeq(g, 0, 3)
    check paths.len == 2

  # ---------- efficiency ----------
  test "globalEfficiency complete":
    let g = completeGraph[int](4)
    check abs(eff.globalEfficiency(g) - 1.0) < 1e-10

  test "localEfficiency":
    let g = completeGraph[int](4)
    let le = eff.localEfficiency(g, 0)
    check le > 0.0

  # ---------- richclub ----------
  test "richClubCoefficient":
    let g = completeGraph[int](5)
    let rcc = rc.richClubCoefficient(g)
    check rcc.len > 0

  # ---------- wiener ----------
  test "wienerIndex path":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    # Wiener = d(0,1)+d(0,2)+d(1,2) = 1+2+1 = 4
    check wi.wienerIndex(g) == 4

  # ---------- cycles ----------
  test "cycleBasis triangle":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let cb = cyc.cycleBasis(g)
    check cb.len == 1

  # ---------- matching ----------
  test "maximalMatching":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    g.addEdge(4, 5)
    let m = mat.maximalMatching(g)
    check m.len == 3

  # ---------- graph products ----------
  test "cartesianProduct":
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    var g2 = newGraph[int]()
    g2.addEdge(0, 1)
    let p = gp.cartesianProduct(g1, g2)
    check p.numberOfNodes() == 4
    check p.numberOfEdges() == 4

  test "tensorProduct":
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    var g2 = newGraph[int]()
    g2.addEdge(0, 1)
    let p = gp.tensorProduct(g1, g2)
    check p.numberOfNodes() == 4

  # ---------- graph hashing ----------
  test "weisfeilerLehmanHash same graph":
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(0, 1)
    g2.addEdge(1, 2)
    check gh.weisfeilerLehmanHash(g1) == gh.weisfeilerLehmanHash(g2)

  # ---------- similarity ----------
  test "simrankSimilarity":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let sr = sim.simrankSimilarity(g, maxIter = 5)
    check sr[(0, 0)] == 1.0

  # ---------- flow ----------
  test "maxFlow":
    var g = newDiGraph[int]()
    g.addWeightedEdge(0, 1, 10.0)
    g.addWeightedEdge(0, 2, 5.0)
    g.addWeightedEdge(1, 3, 8.0)
    g.addWeightedEdge(2, 3, 7.0)
    let (flow, _) = flowmod.edmondsKarp(g, 0, 3)
    check flow >= 12.0

  # ---------- connectivity ----------
  test "isConnected":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check comp.isConnected(g)

  test "isConnected disconnected":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addNode(2)
    check not comp.isConnected(g)

  # ---------- isomorphism ----------
  test "isIsomorphic same graph":
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = newGraph[int]()
    g2.addEdge(10, 11)
    g2.addEdge(11, 12)
    check iso.isIsomorphic(g1, g2)

  # ---------- MST ----------
  test "kruskalMST":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(1, 2, 2.0)
    g.addWeightedEdge(0, 2, 3.0)
    let mstEdges = mstmod.kruskalMST(g)
    check mstEdges.len >= 2

  test "primMST":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(1, 2, 2.0)
    g.addWeightedEdge(0, 2, 3.0)
    let mstEdges = mstmod.primMST(g)
    check mstEdges.len >= 2

  # ---------- all pairs shortest ----------
  test "floydWarshall":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let dist = aps.floydWarshall(g)
    check dist[0][2] == 2.0

  # ---------- TSP ----------
  test "tspNearestNeighbor":
    let g = completeGraph[int](4)
    let (tour, cost) = tspmod.tspNearestNeighbor(g, 0)
    check tour.len == 5  # n+1 (returns to start)
    check cost > 0.0

  # ---------- minors ----------
  test "contractedEdge":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let g2 = mn.contractedEdge(g, 1, 2)
    check g2.numberOfNodes() == 3

  # ---------- cuts ----------
  test "cutSize and conductance":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    check cu.cutSize(g, s) >= 1
    let c = cu.conductance(g, s)
    check c > 0.0 and c <= 1.0

  test "nodeBoundary":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = [0, 1].toHashSet
    let boundary = cu.nodeBoundary(g, s)
    check 2 in boundary

  # ---------- stats ----------
  test "degreeHistogram":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    let hist = statsmod.degreeHistogram(g)
    check hist.len > 0

  test "info string":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let s = statsmod.info(g)
    check s.len > 0

  # ---------- centrality algorithms ----------
  test "betweennessCentrality":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let bc = cent.betweennessCentrality(g)
    check bc[1] > bc[0]  # node 1 is more central

  test "eigenvectorCentrality":
    let g = completeGraph[int](4)
    let ec = cent.eigenvectorCentrality(g)
    check ec.len == 4

  test "katzCentrality":
    let g = completeGraph[int](3)
    let kc = cent.katzCentrality(g)
    check kc.len == 3

  # ---------- Louvain ----------
  test "louvainCommunities":
    var g = newGraph[int]()
    # Two cliques connected by bridge
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    g.addEdge(3, 4)
    g.addEdge(4, 5)
    g.addEdge(3, 5)
    g.addEdge(2, 3)
    let communities = louv.louvainCommunities(g)
    check communities.len >= 1

  # ---------- DAG ----------
  test "ancestors and descendants":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 3)
    let anc = dagmod.ancestors(g, 2)
    check 0 in anc
    check 1 in anc
    let desc = dagmod.descendants(g, 0)
    check 1 in desc
    check 2 in desc
    check 3 in desc

  # ---------- components ----------
  test "connectedComponents":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    let ccs = comp.connectedComponents(g)
    check ccs.len == 2

  test "stronglyConnectedComponents":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addNode(3)
    let sccs = comp.stronglyConnectedComponents(g)
    check sccs.len == 2

  # ---------- transitivity ----------
  test "transitivity":
    let g = completeGraph[int](4)
    let t = clust.transitivity(g)
    check abs(t - 1.0) < 1e-10

# ============================================================================
# Generator deeper coverage
# ============================================================================
suite "Generator deeper":
  test "starGraph":
    let g = starGraph[int](5)
    check g.numberOfNodes() == 6
    check g.numberOfEdges() == 5

  test "wheelGraph":
    let g = wheelGraph[int](5)
    check g.numberOfNodes() == 6

  test "pathGraph":
    let g = pathGraph[int](5)
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 4

  test "cycleGraph":
    let g = cycleGraph[int](5)
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 5

  test "completeGraph":
    let g = completeGraph[int](5)
    check g.numberOfNodes() == 5
    check g.numberOfEdges() == 10

  test "gridGraph":
    let g = gridGraph(3, 3)
    check g.numberOfNodes() == 9

  test "barbellGraph":
    let g = barbellGraph(3, 2)
    check g.numberOfNodes() == 8

  test "ladderGraph":
    let g = ladderGraph(3)
    check g.numberOfNodes() == 6

  test "lollipopGraph":
    let g = lollipopGraph(4, 2)
    check g.numberOfNodes() == 6

  test "erdosRenyiGraph":
    let g = erdosRenyiGraph(50, 0.1, seed = 42)
    check g.numberOfNodes() == 50

  test "barabasiAlbertGraph":
    let g = barabasiAlbertGraph(50, 2, seed = 42)
    check g.numberOfNodes() == 50

  test "wattsStrogatzGraph":
    let g = wattsStrogatzGraph(20, 4, 0.3, seed = 42)
    check g.numberOfNodes() == 20

  test "balancedTree":
    let g = balancedTree(2, 3)
    check g.numberOfNodes() == 15  # 1+2+4+8

  test "randomTree":
    let g = randomTree(10, seed = 42)
    check g.numberOfNodes() == 10
    check g.numberOfEdges() == 9

  test "lineGraph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let lg = lineGraph(g)
    check lg.numberOfNodes() == 3

  test "grid2dGraph":
    let g = grid2dGraph(3, 4)
    check g.numberOfNodes() == 12

  test "grid2dGraph periodic":
    let g = grid2dGraph(3, 3, periodic = true)
    check g.numberOfNodes() == 9
    # Periodic should have more edges than non-periodic
    let g2 = grid2dGraph(3, 3, periodic = false)
    check g.numberOfEdges() > g2.numberOfEdges()

  test "triangularLattice":
    let g = triangularLatticeGraph(3, 3)
    check g.numberOfNodes() > 0

  test "hypercubeGraph":
    let g = hypercubeGraph(3)
    check g.numberOfNodes() == 8

  test "randomGeometricGraph":
    let g = randomGeometricGraph(50, 0.3)
    check g.numberOfNodes() == 50

  test "cavemanGraph":
    let g = cavemanGraph(3, 4)
    check g.numberOfNodes() == 12

  test "connectedCavemanGraph":
    let g = connectedCavemanGraph(3, 4)
    check g.numberOfNodes() == 12

  test "plantedPartitionGraph":
    let g = plantedPartitionGraph(3, 4, 0.8, 0.1)
    check g.numberOfNodes() == 12

  test "ringOfCliques":
    let g = ringOfCliques(3, 4)
    check g.numberOfNodes() == 12

  test "petersenGraph":
    let g = petersenGraph()
    check g.numberOfNodes() == 10
    check g.numberOfEdges() == 15
