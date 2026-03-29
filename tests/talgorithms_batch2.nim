## Tests for batch 2 features:
## degree_sequence generators, directed generators, similarity,
## Bellman-Ford enhancements, powerLawCluster, Pajek I/O, Graph6 I/O

import std/[unittest, tables, sets, math, os]
import nimnet
import nimnet/generators/degree_sequence as ds
import nimnet/generators/directed as dgen
import nimnet/algorithms/similarity as sim
import nimnet/algorithms/components as comp
import nimnet/io/pajek
import nimnet/io/graph6

# ============================================================================
# Degree Sequence Generators
# ============================================================================

suite "Degree Sequence Generators":
  test "isGraphical valid sequence":
    check ds.isGraphical([2, 2, 2])  # triangle
    check ds.isGraphical([3, 3, 3, 3])  # K4
    check ds.isGraphical([1, 1])  # single edge
    check ds.isGraphical([0])  # isolated node

  test "isGraphical invalid sequence":
    check not ds.isGraphical([3, 1, 1])  # impossible
    check not ds.isGraphical([1, 1, 1])  # odd sum
    check not ds.isGraphical([-1])  # negative

  test "isGraphical empty":
    check ds.isGraphical(newSeq[int]())

  test "havelHakimiGraph triangle":
    let g = ds.havelHakimiGraph([2, 2, 2])
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 3

  test "havelHakimiGraph K4":
    let g = ds.havelHakimiGraph([3, 3, 3, 3])
    check g.numberOfNodes() == 4
    check g.numberOfEdges() == 6

  test "havelHakimiGraph raises on non-graphical":
    expect NimNetError:
      discard ds.havelHakimiGraph([3, 1, 1])

  test "configurationModel node count":
    let g = ds.configurationModel([2, 2, 2, 2], seed=42)
    check g.numberOfNodes() == 4

  test "configurationModel raises on odd sum":
    expect NimNetError:
      discard ds.configurationModel([1, 1, 1])

  test "expectedDegreeGraph node count":
    let g = ds.expectedDegreeGraph([2.0, 2.0, 2.0, 2.0], seed=42)
    check g.numberOfNodes() == 4

  test "expectedDegreeGraph zero weights no edges":
    let g = ds.expectedDegreeGraph([0.0, 0.0, 0.0])
    check g.numberOfEdges() == 0

  test "degreeSequenceTree":
    let g = ds.degreeSequenceTree([1, 2, 1])
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 2

  test "degreeSequenceTree single node":
    let g = ds.degreeSequenceTree([0])
    check g.numberOfNodes() == 1
    check g.numberOfEdges() == 0

# ============================================================================
# Directed Graph Generators
# ============================================================================

suite "Directed Graph Generators":
  test "gnGraph node count":
    let dg = dgen.gnGraph(10, seed=42)
    check dg.numberOfNodes() == 10
    check dg.numberOfEdges() == 9  # each new node adds one edge

  test "gnGraph single node":
    let dg = dgen.gnGraph(1, seed=42)
    check dg.numberOfNodes() == 1
    check dg.numberOfEdges() == 0

  test "gnrGraph node count":
    let dg = dgen.gnrGraph(10, 0.5, seed=42)
    check dg.numberOfNodes() == 10
    check dg.numberOfEdges() == 9

  test "gnrGraph p=0 same as gnGraph":
    let dg = dgen.gnrGraph(10, 0.0, seed=42)
    check dg.numberOfNodes() == 10
    check dg.numberOfEdges() == 9

  test "gncGraph node count":
    let dg = dgen.gncGraph(10, seed=42)
    check dg.numberOfNodes() == 10
    check dg.numberOfEdges() >= 9  # at least 9 from basic attachment

  test "scaleFreeGraph node count":
    let dg = dgen.scaleFreeGraph(20, seed=42)
    check dg.numberOfNodes() == 20

  test "scaleFreeGraph raises on bad params":
    expect NimNetError:
      discard dgen.scaleFreeGraph(10, alpha=0.5, beta=0.5, gamma=0.5)

  test "randomKOutGraph":
    let dg = dgen.randomKOutGraph(10, 3, seed=42)
    check dg.numberOfNodes() == 10
    # Each node has exactly 3 outgoing edges
    for n in dg.nodes:
      var outDeg = 0
      for s in dg.successors(n):
        outDeg += 1
      check outDeg == 3

  test "randomKOutGraph raises k >= n":
    expect NimNetError:
      discard dgen.randomKOutGraph(5, 5)

# ============================================================================
# Similarity
# ============================================================================

suite "Similarity":
  test "simrank self-similarity is 1":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let scores = sim.simrankSimilarity(g)
    check scores[(0, 0)] == 1.0
    check scores[(1, 1)] == 1.0
    check scores[(2, 2)] == 1.0

  test "simrank symmetric":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let scores = sim.simrankSimilarity(g)
    check abs(scores[(0, 2)] - scores[(2, 0)]) < 1e-10

  test "simrank structurally equivalent nodes":
    var g = newGraph[int]()
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    let scores = sim.simrankSimilarity(g)
    # Nodes 0 and 1 are structurally equivalent (both connected only to 2)
    check scores[(0, 1)] > 0.0

  test "simrank digraph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 2)
    dg.addEdge(1, 2)
    let scores = sim.simrankSimilarity(dg)
    check scores[(0, 0)] == 1.0

  test "graphEditDistance same graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check sim.graphEditDistance(g, g) == 0

  test "graphEditDistance different graphs":
    var g1 = newGraph[int]()
    g1.addEdge(0, 1)
    var g2 = newGraph[int]()
    g2.addEdge(0, 1)
    g2.addEdge(1, 2)
    let d = sim.graphEditDistance(g1, g2)
    check d >= 1  # at least one node + one edge insertion

  test "graphEditDistance empty graphs":
    var g1 = newGraph[int]()
    var g2 = newGraph[int]()
    check sim.graphEditDistance(g1, g2) == 0

# ============================================================================
# Bellman-Ford Enhancements
# ============================================================================

suite "Bellman-Ford Enhancements":
  test "hasNegativeCycle undirected no negative":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check not hasNegativeCycle(g)

  test "hasNegativeCycle undirected with negative":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, -1.0)
    check hasNegativeCycle(g)

  test "hasNegativeCycle directed no negative":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(0, 1, 1.0)
    dg.addWeightedEdge(1, 2, 2.0)
    check not hasNegativeCycle(dg)

  test "hasNegativeCycle directed with negative cycle":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(0, 1, 1.0)
    dg.addWeightedEdge(1, 2, -5.0)
    dg.addWeightedEdge(2, 0, 1.0)
    check hasNegativeCycle(dg)

  test "bellmanFordDistances undirected":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(1, 2, 2.0)
    g.addWeightedEdge(0, 2, 5.0)
    let d = bellmanFordDistances(g, 0)
    check abs(d[0] - 0.0) < 1e-10
    check abs(d[1] - 1.0) < 1e-10
    check abs(d[2] - 3.0) < 1e-10

  test "bellmanFordDistances directed":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(0, 1, 1.0)
    dg.addWeightedEdge(1, 2, 2.0)
    dg.addWeightedEdge(0, 2, 10.0)
    let d = bellmanFordDistances(dg, 0)
    check abs(d[0] - 0.0) < 1e-10
    check abs(d[1] - 1.0) < 1e-10
    check abs(d[2] - 3.0) < 1e-10

  test "bellmanFordDistances raises on negative cycle":
    var dg = newDiGraph[int]()
    dg.addWeightedEdge(0, 1, 1.0)
    dg.addWeightedEdge(1, 2, -5.0)
    dg.addWeightedEdge(2, 0, 1.0)
    expect NimNetUnfeasible:
      discard bellmanFordDistances(dg, 0)

# ============================================================================
# Power-law Cluster Generator
# ============================================================================

suite "Power-law Cluster Generator":
  test "powerLawClusterGraph node count":
    let g = powerLawClusterGraph(20, 2, 0.5, seed=42)
    check g.numberOfNodes() == 20

  test "powerLawClusterGraph p=0 is BA":
    let g = powerLawClusterGraph(20, 2, 0.0, seed=42)
    check g.numberOfNodes() == 20
    check comp.isConnected(g)

  test "powerLawClusterGraph raises on bad m":
    expect NimNetError:
      discard powerLawClusterGraph(5, 0, 0.5)

# ============================================================================
# Pajek I/O
# ============================================================================

suite "Pajek I/O":
  test "write and read undirected Pajek":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let tmpFile = "test_pajek_undirected.net"
    writePajek(g, tmpFile)
    let g2 = readPajek(tmpFile)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 2
    removeFile(tmpFile)

  test "write and read directed Pajek":
    var dg = newDiGraph[int]()
    dg.addEdge(1, 2)
    dg.addEdge(2, 3)
    let tmpFile = "test_pajek_directed.net"
    writePajek(dg, tmpFile)
    let dg2 = readPajekDigraph(tmpFile)
    check dg2.numberOfNodes() == 3
    check dg2.numberOfEdges() == 2
    removeFile(tmpFile)

  test "Pajek with weights":
    var g = newGraph[int]()
    g.addWeightedEdge(1, 2, 3.5)
    let tmpFile = "test_pajek_weighted.net"
    writePajek(g, tmpFile)
    let g2 = readPajek(tmpFile)
    check g2.numberOfNodes() == 2
    check g2.numberOfEdges() == 1
    removeFile(tmpFile)

# ============================================================================
# Graph6 I/O
# ============================================================================

suite "Graph6 I/O":
  test "write and read Graph6 triangle":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let s = writeGraph6(g)
    let g2 = readGraph6(s)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 3

  test "write and read Graph6 path":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let s = writeGraph6(g)
    let g2 = readGraph6(s)
    check g2.numberOfNodes() == 4
    check g2.numberOfEdges() == 3

  test "write and read Graph6 empty graph":
    var g = newGraph[int]()
    g.addNode(0)
    g.addNode(1)
    g.addNode(2)
    let s = writeGraph6(g)
    let g2 = readGraph6(s)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 0

  test "Graph6 K5":
    var g = newGraph[int]()
    for i in 0 ..< 5:
      for j in (i + 1) ..< 5:
        g.addEdge(i, j)
    let s = writeGraph6(g)
    let g2 = readGraph6(s)
    check g2.numberOfNodes() == 5
    check g2.numberOfEdges() == 10

  test "write and read Sparse6":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    let s = writeSparse6(g)
    check s[0] == ':'  # Sparse6 starts with ':'
    let g2 = readSparse6(s)
    check g2.numberOfNodes() == 4
    check g2.numberOfEdges() >= 2  # encoding may vary
