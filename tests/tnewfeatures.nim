## Tests for newly implemented features from NetworkX gap analysis
## Issues: #119 (isolates, local bridges, chain decomposition)
##         #106 (harmonic centrality)
##         #107 (reciprocity)
##         #122 (extended clustering)
##         #126 (extended traversal)
##         #125 (extended DAG)
##         #128 (extended Euler & cycles)
##         #120 (extended assortativity)
##         #121 (additional centrality)
##         #127 (extended tree/MST)
##         And more as implemented

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
    # No local bridges in a triangle
    check localBridges(g).len == 0

  test "local bridges on path":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4)])
    let lb = localBridges(g)
    # All edges in a path are local bridges
    check lb.len == 3

  test "local bridge with span":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 4), (4, 1)])
    # 1-2 and 3-4 are not local bridges (part of 4-cycle with shortcuts)
    # Actually in a 4-cycle, 1-2 has common neighbor? No:
    # neighbors of 1: {2, 4}, neighbors of 2: {1, 3}
    # Common: none. So 1-2 IS a local bridge with span 3
    let lb = localBridges(g)
    check lb.len > 0

suite "Chain Decomposition (#119)":
  test "chain decomposition of tree":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (1, 3), (2, 4)])
    # Tree has no back edges => no chains
    let chains = chainDecomposition(g)
    check chains.len == 0

  test "chain decomposition of cycle":
    var g = newGraph[int]()
    g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])
    let chains = chainDecomposition(g)
    # One cycle => one chain
    check chains.len >= 1

  test "chain decomposition of empty graph":
    let g = newGraph[int]()
    check chainDecomposition(g).len == 0
