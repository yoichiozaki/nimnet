## Tests for parallel algorithm implementations.
## Verifies that parallel versions produce results matching sequential versions.

import std/[unittest, tables, math, sets, sequtils, algorithm]
import nimnet
import nimnet/algorithms/parallel as par
import nimnet/generators/random as rng

const Eps = 1e-6

# ============================================================================
# Helpers
# ============================================================================

proc approxEqual(a, b: float, eps: float = Eps): bool =
  abs(a - b) < eps

proc approxEqualTable[N](a, b: Table[N, float], eps: float = Eps): bool =
  if a.len != b.len: return false
  for k, v in a:
    if k notin b: return false
    if not approxEqual(v, b[k], eps): return false
  return true

# ============================================================================
# Small graphs
# ============================================================================

suite "Parallel Betweenness Centrality":
  test "triangle graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let seq_bc = betweennessCentrality(g)
    let par_bc = par.parallelBetweennessCentrality(g)
    check approxEqualTable(seq_bc, par_bc)

  test "path graph":
    var g = newGraph[int]()
    for i in 0 ..< 5:
      g.addEdge(i, i + 1)
    let seq_bc = betweennessCentrality(g)
    let par_bc = par.parallelBetweennessCentrality(g)
    check approxEqualTable(seq_bc, par_bc)

  test "star graph":
    var g = newGraph[int]()
    for i in 1 .. 5:
      g.addEdge(0, i)
    let seq_bc = betweennessCentrality(g)
    let par_bc = par.parallelBetweennessCentrality(g)
    check approxEqualTable(seq_bc, par_bc)

  test "empty graph":
    var g = newGraph[int]()
    g.addNode(0)
    g.addNode(1)
    let par_bc = par.parallelBetweennessCentrality(g)
    check par_bc[0] == 0.0
    check par_bc[1] == 0.0

  test "single node":
    var g = newGraph[int]()
    g.addNode(0)
    let par_bc = par.parallelBetweennessCentrality(g)
    check par_bc[0] == 0.0

  test "unnormalized":
    var g = newGraph[int]()
    for i in 0 ..< 5:
      g.addEdge(i, i + 1)
    let seq_bc = betweennessCentrality(g, normalized = false)
    let par_bc = par.parallelBetweennessCentrality(g, normalized = false)
    check approxEqualTable(seq_bc, par_bc)

  test "medium random graph":
    let g = rng.erdosRenyiGraph(50, 0.3)
    let seq_bc = betweennessCentrality(g)
    let par_bc = par.parallelBetweennessCentrality(g)
    check approxEqualTable(seq_bc, par_bc, 1e-5)

suite "Parallel Closeness Centrality":
  test "triangle graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let seq_cc = closenessCentrality(g)
    let par_cc = par.parallelClosenessCentrality(g)
    check approxEqualTable(seq_cc, par_cc)

  test "path graph":
    var g = newGraph[int]()
    for i in 0 ..< 5:
      g.addEdge(i, i + 1)
    let seq_cc = closenessCentrality(g)
    let par_cc = par.parallelClosenessCentrality(g)
    check approxEqualTable(seq_cc, par_cc)

  test "disconnected graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    let seq_cc = closenessCentrality(g)
    let par_cc = par.parallelClosenessCentrality(g)
    check approxEqualTable(seq_cc, par_cc)

  test "single node":
    var g = newGraph[int]()
    g.addNode(0)
    let par_cc = par.parallelClosenessCentrality(g)
    check par_cc[0] == 0.0

  test "medium random graph":
    let g = rng.erdosRenyiGraph(50, 0.3)
    let seq_cc = closenessCentrality(g)
    let par_cc = par.parallelClosenessCentrality(g)
    check approxEqualTable(seq_cc, par_cc, 1e-5)

suite "Parallel Clustering Coefficient":
  test "triangle graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let seq_cl = clustering(g)
    let par_cl = par.parallelClustering(g)
    check approxEqualTable(seq_cl, par_cl)

  test "star graph (no triangles)":
    var g = newGraph[int]()
    for i in 1 .. 5:
      g.addEdge(0, i)
    let seq_cl = clustering(g)
    let par_cl = par.parallelClustering(g)
    check approxEqualTable(seq_cl, par_cl)

  test "complete graph K5":
    var g = newGraph[int]()
    for i in 0 ..< 5:
      for j in i + 1 ..< 5:
        g.addEdge(i, j)
    let par_cl = par.parallelClustering(g)
    for node, coeff in par_cl:
      check approxEqual(coeff, 1.0)

  test "single node":
    var g = newGraph[int]()
    g.addNode(0)
    let par_cl = par.parallelClustering(g)
    check par_cl[0] == 0.0

  test "medium random graph":
    let g = rng.erdosRenyiGraph(50, 0.3)
    let seq_cl = clustering(g)
    let par_cl = par.parallelClustering(g)
    check approxEqualTable(seq_cl, par_cl, 1e-5)

suite "Parallel PageRank (undirected)":
  test "triangle graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let seq_pr = par.parallelPageRank(g)
    # All nodes symmetric → equal rank
    for node, rank in seq_pr:
      check approxEqual(rank, 1.0 / 3.0, 0.01)

  test "star graph":
    var g = newGraph[int]()
    for i in 1 .. 4:
      g.addEdge(0, i)
    let pr = par.parallelPageRank(g)
    # Center should have highest rank
    var maxNode = 0
    var maxRank = 0.0
    for node, rank in pr:
      if rank > maxRank:
        maxRank = rank
        maxNode = node
    check maxNode == 0

  test "empty graph":
    var g = newGraph[int]()
    let pr = par.parallelPageRank(g)
    check pr.len == 0

  test "single node":
    var g = newGraph[int]()
    g.addNode(0)
    let pr = par.parallelPageRank(g)
    check approxEqual(pr[0], 1.0, 0.01)

  test "medium random graph ranks sum to 1":
    let g = rng.erdosRenyiGraph(50, 0.3)
    let pr = par.parallelPageRank(g)
    var total = 0.0
    for node, rank in pr:
      total += rank
    check approxEqual(total, 1.0, 0.01)

suite "Parallel PageRank (directed)":
  test "simple chain":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let pr = par.parallelPageRank(g)
    # Symmetric cycle → roughly equal rank
    for node, rank in pr:
      check approxEqual(rank, 1.0 / 3.0, 0.05)

  test "empty digraph":
    var g = newDiGraph[int]()
    let pr = par.parallelPageRank(g)
    check pr.len == 0

  test "sink node absorbs rank":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addNode(1)
    g.addNode(2)
    let pr = par.parallelPageRank(g)
    # Nodes 1 and 2 are sinks, they receive rank from 0
    check pr[1] > pr[0] or pr[2] > pr[0]

  test "ranks sum to 1":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 0)
    g.addEdge(1, 3)
    let pr = par.parallelPageRank(g)
    var total = 0.0
    for node, rank in pr:
      total += rank
    check approxEqual(total, 1.0, 0.01)

suite "Parallel Johnson's All-Pairs Shortest Paths":
  test "simple triangle":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let seq_j = johnsons(g)
    let par_j = par.parallelJohnsons(g)
    for src in seq_j.keys:
      for dst in seq_j[src].keys:
        check approxEqual(seq_j[src][dst], par_j[src][dst])

  test "weighted graph":
    var g = newDiGraph[int]()
    g.addWeightedEdge(0, 1, 3.0)
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(0, 2, 10.0)
    let par_j = par.parallelJohnsons(g)
    check approxEqual(par_j[0][2], 4.0) # 0→1→2 = 3+1

  test "single node":
    var g = newDiGraph[int]()
    g.addNode(0)
    let par_j = par.parallelJohnsons(g)
    check par_j[0][0] == 0.0

  test "empty graph":
    var g = newDiGraph[int]()
    let par_j = par.parallelJohnsons(g)
    check par_j.len == 0

  test "medium graph consistency":
    var g = newDiGraph[int]()
    for i in 0 ..< 20:
      for j in 0 ..< 20:
        if i != j and (i + j) mod 3 == 0:
          g.addEdge(i, j)
    let seq_j = johnsons(g)
    let par_j = par.parallelJohnsons(g)
    for src in seq_j.keys:
      for dst in seq_j[src].keys:
        check approxEqual(seq_j[src][dst], par_j[src][dst], 1e-5)

# ============================================================================
# Benchmark helper (not timed in test, just runs to verify no crash)
# ============================================================================

suite "Parallel algorithms on larger graphs":
  test "betweenness on 100-node graph":
    let g = rng.erdosRenyiGraph(100, 0.1)
    let bc = par.parallelBetweennessCentrality(g)
    check bc.len == 100

  test "closeness on 100-node graph":
    let g = rng.erdosRenyiGraph(100, 0.1)
    let cc = par.parallelClosenessCentrality(g)
    check cc.len == 100

  test "clustering on 100-node graph":
    let g = rng.erdosRenyiGraph(100, 0.1)
    let cl = par.parallelClustering(g)
    check cl.len == 100

  test "pagerank on 100-node graph":
    let g = rng.erdosRenyiGraph(100, 0.1)
    let pr = par.parallelPageRank(g)
    check pr.len == 100
    var total = 0.0
    for node, rank in pr:
      total += rank
    check approxEqual(total, 1.0, 0.01)
