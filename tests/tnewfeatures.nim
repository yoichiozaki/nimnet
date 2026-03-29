## Tests for newly implemented features from NetworkX gap analysis

import std/[unittest, tables, sets, math, sequtils, algorithm]
import nimnet

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
  test "local bridges on triangle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    check localBridges(g).len == 0

  test "local bridges on path":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
    let lb = localBridges(g)
    check lb.len == 3

  test "local bridge with span":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4), (4, 1)])
    let lb = localBridges(g)
    check lb.len > 0

suite "Chain Decomposition (#119)":
  test "chain decomposition of tree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (2, 4)])
    let chains = chainDecomposition(g)
    check chains.len == 0

  test "chain decomposition of cycle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let chains = chainDecomposition(g)
    check chains.len >= 1

  test "chain decomposition of empty graph":
    let g = newGraph[int]()
    check chainDecomposition(g).len == 0

suite "Harmonic Centrality (#106)":
  test "harmonic centrality complete graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let hc = harmonicCentrality(g)
    for n in g.nodes:
      check abs(hc[n] - 1.0) < 1e-10

  test "harmonic centrality path graph":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3)])
    let hc = harmonicCentrality(g)
    check abs(hc[2] - 1.0) < 1e-10
    check abs(hc[1] - 0.75) < 1e-10

  test "harmonic centrality disconnected":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addNode(3)
    let hc = harmonicCentrality(g)
    check abs(hc[3] - 0.0) < 1e-10
    check abs(hc[1] - 0.5) < 1e-10

  test "harmonic centrality empty graph":
    let g = newGraph[int]()
    check harmonicCentrality(g).len == 0

  test "harmonic centrality digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let hc = harmonicCentrality(dg)
    check abs(hc[3] - 0.75) < 1e-10
    check abs(hc[1] - 0.0) < 1e-10

suite "Directed Reciprocity (#107)":
  test "fully reciprocal digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 1)
    dg.addEdge(2, 3)
    dg.addEdge(3, 2)
    check abs(reciprocity(dg) - 1.0) < 1e-10

  test "no reciprocal edges":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    dg.addEdge(3, 1)
    check abs(reciprocity(dg) - 0.0) < 1e-10

  test "partial reciprocity":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 1)
    dg.addEdge(2, 3)
    check abs(reciprocity(dg) - 2.0/3.0) < 1e-10

  test "empty digraph reciprocity":
    let dg = newDiGraph[int]()
    check abs(reciprocity(dg) - 0.0) < 1e-10

  test "overall reciprocity alias":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 1)
    check abs(overallReciprocity(dg) - 1.0) < 1e-10
