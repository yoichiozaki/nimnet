## Tests for previously untested modules
## Covers: d_separation, node_classification, network_flow, structural_holes,
## joint_degree, misc_generators, nonisomorphic_trees, triad_generator,
## multiline_adjlist, network_text

import std/[unittest, tables, sets, strutils, math]
import nimnet

# ============================================================================
# d-separation (DAG queries)
# ============================================================================

suite "d_separation":
  test "isDSeparator — basic chain A→B→C":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let x = toHashSet([1])
    let y = toHashSet([3])
    let z = toHashSet([2])
    check isDSeparator(g, x, y, z) == true

  test "isDSeparator — not separated without blocker":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let x = toHashSet([1])
    let y = toHashSet([3])
    let z: HashSet[int] = initHashSet[int]()
    check isDSeparator(g, x, y, z) == false

  test "isDSeparator — fork structure":
    # A←B→C: B d-separates A and C
    var g = newDiGraph[int]()
    g.addEdge(2, 1)
    g.addEdge(2, 3)
    let x = toHashSet([1])
    let y = toHashSet([3])
    let z = toHashSet([2])
    check isDSeparator(g, x, y, z) == true

  test "findMinimalDSeparator":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let x = toHashSet([1])
    let y = toHashSet([3])
    let sep = findMinimalDSeparator(g, x, y)
    check 2 in sep

  test "isMinimalDSeparator":
    var g = newDiGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let x = toHashSet([1])
    let y = toHashSet([3])
    let z = toHashSet([2])
    check isMinimalDSeparator(g, x, y, z) == true

  test "immediateDominators":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let idom = immediateDominators(g, 0)
    check idom[1] == 0
    check idom[2] == 0
    check idom[3] == 0

  test "dominanceFrontiers":
    var g = newDiGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let df = dominanceFrontiers(g, 0)
    check 3 in df[1]
    check 3 in df[2]

# ============================================================================
# node_classification
# ============================================================================

suite "node_classification":
  test "harmonicFunction — simple propagation":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    let labels = {1: 0, 4: 1}.toTable
    let result = harmonicFunction(g, labels)
    check result[1] == 0
    check result[4] == 1
    # Middle nodes should get classified
    check 2 in result
    check 3 in result

  test "localAndGlobalConsistency":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    let labels = {1: 0, 4: 1}.toTable
    let result = localAndGlobalConsistency(g, labels)
    check result[1] == 0
    check result[4] == 1
    check 2 in result
    check 3 in result

  test "sMetric":
    # Path graph: 1-2-3
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    # Degrees: 1→1, 2→2, 3→1
    # s = deg(1)*deg(2) + deg(2)*deg(3) = 1*2 + 2*1 = 4
    let s = sMetric(g)
    check abs(s - 4.0) < 1e-9

  test "sMetric — complete graph K3":
    var g = newGraph[int]()
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(1, 3)
    # All degrees = 2, 3 edges → s = 3 * (2*2) = 12
    let s = sMetric(g)
    check abs(s - 12.0) < 1e-9

# ============================================================================
# network_flow
# ============================================================================

suite "network_flow":
  test "stoerWagnerMinCut":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 2.0)
    g.addWeightedEdge(0, 2, 3.0)
    g.addWeightedEdge(1, 2, 3.0)
    g.addWeightedEdge(1, 3, 2.0)
    g.addWeightedEdge(2, 3, 2.0)
    let (cutWeight, s1, s2) = stoerWagnerMinCut(g)
    check cutWeight > 0.0
    check s1.len + s2.len == 4
    check s1.len > 0
    check s2.len > 0

  test "dinitz max flow":
    var g = newDiGraph[int]()
    g.addWeightedEdge(0, 1, 10.0)
    g.addWeightedEdge(0, 2, 10.0)
    g.addWeightedEdge(1, 3, 5.0)
    g.addWeightedEdge(2, 3, 10.0)
    g.addWeightedEdge(1, 2, 2.0)
    let (flowValue, _) = dinitz(g, 0, 3)
    check flowValue >= 15.0 - 1e-9

  test "spanner":
    var g = newGraph[int]()
    for i in 0 ..< 5:
      for j in i+1 ..< 5:
        g.addEdge(i, j)
    let sp = spanner(g, 3)
    check sp.numberOfNodes() == 5
    check sp.numberOfEdges() <= g.numberOfEdges()
    check sp.numberOfEdges() >= 4  # at least a spanning tree

  test "gomoryHuTree":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(0, 2, 7.0)
    g.addWeightedEdge(1, 2, 1.0)
    g.addWeightedEdge(1, 3, 3.0)
    g.addWeightedEdge(2, 3, 2.0)
    let tree = gomoryHuTree(g)
    check tree.numberOfNodes() == 4
    check tree.numberOfEdges() == 3  # tree has n-1 edges

# ============================================================================
# structural_holes
# ============================================================================

suite "structural_holes":
  test "constraint — star graph":
    # Star: center 0, leaves 1,2,3 — center has constraint 1/3 per leaf
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    let c = constraint(g)
    check 0 in c
    check c[0] > 0.0

  test "effectiveSize — star graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    let es = effectiveSize(g)
    check 0 in es
    # Star center: no redundancy among leaves → effective size = degree
    check abs(es[0] - 3.0) < 1e-6

  test "localConstraint":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    let lc = localConstraint(g, 0, 1)
    check lc > 0.0

  test "effectiveSize — complete graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    let es = effectiveSize(g)
    # Complete K3: maximum redundancy → effective size = 1
    check es[0] <= 2.0 + 1e-6

# ============================================================================
# generators/joint_degree
# ============================================================================

suite "joint_degree":
  test "isValidJointDegree — valid":
    let jd = {(1, 2): 2, (2, 2): 1}.toTable
    check isValidJointDegree(jd) == true

  test "isValidJointDegree — invalid asymmetric":
    # (1,2): 2 means 2 edges between deg-1 and deg-2 nodes, but (2,1) missing
    let jd = {(1, 3): 1}.toTable  # degree-3 node needs 3 stubs, but only 1 edge provided
    check isValidJointDegree(jd) == false

  test "jointDegreeGraph":
    let jd = {(1, 2): 2, (2, 2): 2}.toTable
    let g = jointDegreeGraph(jd, seed = 42)
    check g.numberOfNodes() > 0
    check g.numberOfEdges() > 0

# ============================================================================
# generators/misc_generators
# ============================================================================

suite "misc_generators":
  test "intervalGraph":
    let g = intervalGraph([(0.0, 1.5), (1.0, 2.0), (3.0, 4.0)])
    check g.numberOfNodes() == 3
    check g.hasEdge(0, 1)  # overlapping intervals
    check not g.hasEdge(0, 2)  # non-overlapping
    check not g.hasEdge(1, 2)

  test "sudokuGraph — n=2":
    let g = sudokuGraph(2)
    check g.numberOfNodes() == 16  # 4×4
    # Every node in same row/col/box is connected
    check g.numberOfEdges() > 0

  test "visibilityGraph":
    let g = visibilityGraph([1.0, 0.5, 2.0])
    check g.numberOfNodes() == 3
    # Node 0 sees node 1 (adjacent), node 1 sees node 2 (adjacent)
    check g.hasEdge(0, 1)
    check g.hasEdge(1, 2)

  test "randomCograph":
    let g = randomCograph(6, seed = 42)
    check g.numberOfNodes() == 6

# ============================================================================
# generators/nonisomorphic_trees
# ============================================================================

suite "nonisomorphic_trees":
  test "nonisomorphicTrees — order 1":
    let trees = nonisomorphicTrees(1)
    check trees.len == 1
    check trees[0].numberOfNodes() == 1

  test "nonisomorphicTrees — order 4":
    let trees = nonisomorphicTrees(4)
    check trees.len == 2  # star and path

  test "nonisomorphicTrees — order 5":
    let trees = nonisomorphicTrees(5)
    check trees.len == 3

  test "numberOfNonisomorphicTrees":
    check numberOfNonisomorphicTrees(1) == 1
    check numberOfNonisomorphicTrees(4) == 2
    check numberOfNonisomorphicTrees(5) == 3
    check numberOfNonisomorphicTrees(6) == 6

# ============================================================================
# generators/triad_generator
# ============================================================================

suite "triad_generator":
  test "triadGraph — 003 (empty)":
    let g = triadGraph("003")
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 0

  test "triadGraph — 012 (single edge)":
    let g = triadGraph("012")
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 1

  test "triadGraph — 300 (complete)":
    let g = triadGraph("300")
    check g.numberOfNodes() == 3
    check g.numberOfEdges() == 6  # all 6 directed edges

  test "triadGraph — all 16 types":
    let triadTypes = @["003", "012", "102", "021D", "021U", "021C",
                       "111D", "111U", "030T", "030C", "201",
                       "120D", "120U", "120C", "210", "300"]
    for tt in triadTypes:
      let g = triadGraph(tt)
      check g.numberOfNodes() == 3

# ============================================================================
# io/multiline_adjlist
# ============================================================================

suite "multiline_adjlist":
  test "writeMultilineAdjlist and readMultilineAdjlist round-trip":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)
    let data = writeMultilineAdjlist(g)
    check data.len > 0
    let g2 = readMultilineAdjlist(data)
    check g2.numberOfNodes() == 3
    check g2.numberOfEdges() == 3

  test "parseMultilineAdjlist":
    let data = writeMultilineAdjlist(newGraph[int]())
    let g = readMultilineAdjlist(data)
    check g.numberOfNodes() == 0

  test "generateMultilineAdjlist":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let lines = generateMultilineAdjlist(g)
    check lines.len > 0

# ============================================================================
# io/network_text
# ============================================================================

suite "network_text":
  test "writeNetworkText — undirected graph":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    let text = writeNetworkText(g)
    check text.len > 0
    check "0" in text
    check "1" in text
    check "2" in text

  test "writeNetworkText — directed graph":
    var dg = newDiGraph[int]()
    dg.addEdge(0, 1)
    dg.addEdge(0, 2)
    let text = writeNetworkText(dg)
    check text.len > 0
    check "0" in text

  test "writeNetworkText — empty graph":
    var g = newGraph[int]()
    let text = writeNetworkText(g)
    check text.len == 0 or text == ""

  test "generateNetworkText":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    var lines: seq[string]
    for line in generateNetworkText(g):
      lines.add(line)
    check lines.len > 0
