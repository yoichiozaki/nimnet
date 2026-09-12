import nimnet/[types, graph, digraph]
import nimnet/algorithms/[community, all_pairs_shortest]
import std/hashes

type UnorderedNode = object
  id: int

func hash(node: UnorderedNode): Hash = hash(node.id mod 2)
func `==`(a, b: UnorderedNode): bool = a.id == b.id

# Instantiate before importing sets, tables, or unittest: callers must not
# supply the algorithm modules' generic implementation dependencies.
block importSmoke:
  var g = newGraph[UnorderedNode]()
  g.addEdge(UnorderedNode(id: 1), UnorderedNode(id: 2))
  let partition = greedyModularityCommunities(g)
  doAssert partition.len == 1
  doAssert modularity(g, partition) == 0.0
  discard johnsons(g)
  discard johnsons(g, includeUnreachable = true)
  discard floydWarshall(g)
  var dg = newDiGraph[UnorderedNode]()
  dg.addEdge(UnorderedNode(id: 1), UnorderedNode(id: 2))
  discard johnsons(dg)
  discard johnsons(dg, includeUnreachable = true)
  discard floydWarshall(dg)

import std/[unittest, tables, sets, random]

const ReferenceTolerance = 1e-12

proc referenceModularity[N](g: Graph[N], partition: seq[HashSet[N]]): float =
  let m = g.numberOfEdges().float
  if m == 0.0:
    return 0.0
  for comm in partition:
    var internalEdges, endpoints: int
    for (u, v) in g.edges:
      if u in comm:
        endpoints.inc
      if v in comm:
        endpoints.inc
      if u in comm and v in comm:
        internalEdges.inc
    let fraction = endpoints.float / (2.0 * m)
    result += internalEdges.float / m - fraction * fraction

proc partitionKey[N](nodes: seq[N], partition: seq[HashSet[N]]): seq[int] =
  for node in nodes:
    var first = -1
    for comm in partition:
      if node in comm:
        for i, candidate in nodes:
          if candidate in comm:
            first = i
            break
        break
    result.add(first)

proc merged(partition: seq[HashSet[int]], i, j: int): seq[HashSet[int]] =
  for k, comm in partition:
    if k == i:
      result.add(comm + partition[j])
    elif k != j:
      result.add(comm)

proc referenceGreedyOutcomes(g: Graph[int]): HashSet[seq[int]] =
  ## Enumerate tied, strictly improving greedy choices using full Q evaluations.
  ## Memoization bounds this small-graph oracle by the number of partitions.
  let nodes = g.nodeSeq()
  var outcomes = initHashSet[seq[int]]()
  var visited = initHashSet[seq[int]]()
  proc visit(partition: seq[HashSet[int]]) =
    let key = partitionKey(nodes, partition)
    if key in visited:
      return
    visited.incl(key)
    let q = referenceModularity(g, partition)
    var best = 0.0
    var choices: seq[(int, int)]
    for i in 0 ..< partition.len:
      for j in i + 1 ..< partition.len:
        let delta = referenceModularity(g, merged(partition, i, j)) - q
        if delta > best + ReferenceTolerance:
          best = delta
          choices = @[(i, j)]
        elif delta > ReferenceTolerance and
            abs(delta - best) <= ReferenceTolerance:
          choices.add((i, j))
    if choices.len == 0:
      outcomes.incl(key)
    else:
      for (i, j) in choices:
        visit(merged(partition, i, j))

  var initial: seq[HashSet[int]]
  for node in nodes:
    initial.add([node].toHashSet())
  visit(initial)
  result = outcomes

proc checkGreedyReference(g: Graph[int]) =
  let partition = greedyModularityCommunities(g)
  check isPartition(g, partition)
  for comm in partition:
    check comm.len > 0
  check partitionKey(g.nodeSeq(), partition) in referenceGreedyOutcomes(g)
  check abs(modularity(g, partition) -
    referenceModularity(g, partition)) <= ReferenceTolerance

template checkAgainstFloyd(g: untyped) =
  block:
    let expected = floydWarshall(g)
    let sparse = johnsons(g)
    let complete = johnsons(g, includeUnreachable = true)
    check sparse.len == g.numberOfNodes()
    check complete.len == g.numberOfNodes()
    for u in g.nodes:
      require sparse.hasKey(u)
      require complete.hasKey(u)
      check complete[u].len == g.numberOfNodes()
      var reachableCount = 0
      for v in g.nodes:
        require complete[u].hasKey(v)
        let want = expected[u][v]
        if want == Inf:
          check not sparse[u].hasKey(v)
          check complete[u][v] == Inf
        else:
          reachableCount.inc
          require sparse[u].hasKey(v)
          check abs(sparse[u][v] - want) <= 1e-10 * max(1.0, abs(want))
          check abs(complete[u][v] - want) <= 1e-10 * max(1.0, abs(want))
      check sparse[u].len == reachableCount

template checkSparseStorage(input: untyped) =
  block:
    let g = input
    let before = getOccupiedMem()
    let distances = johnsons(g)
    let allocated = getOccupiedMem() - before
    check distances.len == g.numberOfNodes()
    for node in g.nodes:
      require distances.hasKey(node)
      check distances[node].len == 1
      check distances[node][node] == 0.0
    # Allow allocator overhead, but reject V-sized storage for singleton rows.
    check allocated < g.numberOfNodes() * 2048

suite "Incremental unweighted greedy modularity":
  test "empty and edgeless graphs retain all nodes":
    var g = newGraph[int]()
    check greedyModularityCommunities(g).len == 0
    check modularity(g, @[]) == 0.0
    checkGreedyReference(g)
    for node in [7, 11, 19, 23]:
      g.addNode(node)
    let partition = greedyModularityCommunities(g)
    check partition.len == 4
    check modularity(g, partition) == 0.0
    checkGreedyReference(g)

  test "self loops count once internally and twice toward degree":
    var g = newGraph[int]()
    g.addEdge(0, 0)
    check modularity(g, @[[0].toHashSet()]) == 0.0
    checkGreedyReference(g)
    g.addEdge(1, 1)
    check modularity(g, @[[0].toHashSet(), [1].toHashSet()]) == 0.5
    check modularity(g, @[[0, 1].toHashSet()]) == 0.0
    checkGreedyReference(g)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check abs(modularity(g, @[[0, 1, 2].toHashSet()])) <= ReferenceTolerance
    checkGreedyReference(g)

  test "disconnected components and isolates are not merged together":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0), (3, 4)])
    g.addNode(5)
    let partition = greedyModularityCommunities(g)
    check partition.len == 3
    check [0, 1, 2].toHashSet() in partition
    check [3, 4].toHashSet() in partition
    check [5].toHashSet() in partition
    checkGreedyReference(g)

  test "edge weights do not change the documented unweighted objective":
    var plain = newGraph[int]()
    plain.addEdgesFrom([(0, 1), (1, 2), (2, 0), (3, 4),
      (4, 5), (5, 3), (2, 3)])
    var weighted = plain.copy()
    for (u, v) in plain.edges:
      weighted.addWeightedEdge(u, v, (u * 13 - v * 17).float)
    weighted.addWeightedEdge(2, 3, 1e100)
    let split = @[[0, 1, 2].toHashSet(), [3, 4, 5].toHashSet()]
    check abs(modularity(weighted, split) - 5.0 / 14.0) <= ReferenceTolerance
    check partitionKey(plain.nodeSeq(), greedyModularityCommunities(plain)) ==
      partitionKey(plain.nodeSeq(), greedyModularityCommunities(weighted))
    checkGreedyReference(weighted)

  test "exactly zero merge gains are not accepted":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 3), (3, 0)])
    let partition = greedyModularityCommunities(g)
    check partition.len == 2
    check abs(modularity(g, partition)) <= ReferenceTolerance
    let nodes = g.nodeSeq()
    var firstPair = [nodes[0]].toHashSet()
    for i in 1 ..< nodes.len:
      if g.hasEdge(nodes[0], nodes[i]):
        firstPair.incl(nodes[i])
        break
    check firstPair in partition
    checkGreedyReference(g)

  test "repeated hub merges invalidate old heap entries":
    var g = newGraph[int]()
    for leaf in 1 .. 80:
      g.addEdge(0, leaf)
    let partition = greedyModularityCommunities(g)
    check partition.len == 1
    check isPartition(g, partition)
    check abs(modularity(g, partition)) <= ReferenceTolerance

  test "all tied greedy outcomes are accepted by an independent small oracle":
    var rng = initRand(168_167)
    for n in 0 .. 6:
      for sample in 0 ..< 18:
        var g = newGraph[int]()
        for u in 0 ..< n:
          g.addNode(u)
        for u in 0 ..< n:
          for v in u ..< n:
            if rng.rand(99) < 20 + (sample mod 3) * 30:
              g.addWeightedEdge(u, v, rng.rand(-20 .. 20).float / 4.0)
        checkGreedyReference(g)

  test "indexed ties are repeatable for non-orderable collision-prone nodes":
    var g = newGraph[UnorderedNode]()
    for i in 0 ..< 8:
      g.addEdge(UnorderedNode(id: i), UnorderedNode(id: (i + 1) mod 8))
    let first = greedyModularityCommunities(g)
    check isPartition(g, first)
    check abs(modularity(g, first) -
      referenceModularity(g, first)) <= ReferenceTolerance
    for repetition in 0 ..< 8:
      check partitionKey(g.nodeSeq(), greedyModularityCommunities(g)) ==
        partitionKey(g.nodeSeq(), first)

suite "Indexed sparse all-pairs shortest paths":
  test "empty graphs return empty tables":
    checkAgainstFloyd(newGraph[int]())
    checkAgainstFloyd(newDiGraph[int]())

  test "edgeless graphs include isolated nodes and unreachable pairs":
    var g = newGraph[string]()
    var dg = newDiGraph[string]()
    for node in ["alpha", "beta", "isolated"]:
      g.addNode(node)
      dg.addNode(node)
    checkAgainstFloyd(g)
    checkAgainstFloyd(dg)

  test "sparse isolated results do not allocate dense rows":
    var g = newGraph[int]()
    var dg = newDiGraph[int]()
    for node in 0 ..< 2048:
      g.addNode(node)
      dg.addNode(node)
    checkSparseStorage(g)
    checkSparseStorage(dg)

  test "undirected defaults, zero weights, self loops and disconnected pairs":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    g.addWeightedEdge(1, 2, 0.0)
    g.addWeightedEdge(0, 2, 8.0)
    g.addWeightedEdge(2, 2, 4.0)
    g.addWeightedEdge(3, 3, 0.0)
    g.addWeightedEdge(4, 5, 2.5)
    g.addNode(6)
    checkAgainstFloyd(g)
    let distances = johnsons(g)
    check distances[0][2] == 1.0
    check distances[2][0] == 1.0
    check not distances[0].hasKey(4)

  test "seeded nonnegative undirected graphs agree with Floyd-Warshall":
    var rng = initRand(167_001)
    for n in 0 .. 14:
      for sample in 0 ..< 10:
        var g = newGraph[int]()
        for u in 0 ..< n:
          g.addNode(u)
        for u in 0 ..< n:
          for v in u ..< n:
            if rng.rand(99) < 30:
              g.addWeightedEdge(u, v, rng.rand(0 .. 40).float / 4.0)
        checkAgainstFloyd(g)

  test "seeded nonnegative directed graphs agree with Floyd-Warshall":
    var rng = initRand(167_002)
    for n in 0 .. 12:
      for sample in 0 ..< 10:
        var g = newDiGraph[int]()
        for u in 0 ..< n:
          g.addNode(u)
        for u in 0 ..< n:
          for v in 0 ..< n:
            if rng.rand(99) < 25:
              g.addWeightedEdge(u, v, rng.rand(0 .. 40).float / 4.0)
        checkAgainstFloyd(g)

  test "directed negative edges without negative cycles":
    var g = newDiGraph[string]()
    g.addWeightedEdge("a", "b", 3.0)
    g.addWeightedEdge("a", "c", 8.0)
    g.addWeightedEdge("b", "c", -4.5)
    g.addWeightedEdge("c", "d", 2.0)
    g.addWeightedEdge("d", "b", 3.0)
    g.addWeightedEdge("x", "y", -7.0)
    g.addNode("isolated")
    checkAgainstFloyd(g)
    let distances = johnsons(g)
    check distances["a"]["c"] == -1.5
    check not distances["a"].hasKey("x")
    check not distances["y"].hasKey("x")

  test "seeded potentials produce cyclic graphs with no negative cycles":
    var rng = initRand(167_003)
    for n in 1 .. 12:
      for sample in 0 ..< 12:
        var g = newDiGraph[int]()
        var potential = newSeq[float](n)
        for u in 0 ..< n:
          g.addNode(u)
          potential[u] = rng.rand(-40 .. 40).float / 4.0
        for u in 0 ..< n:
          for v in 0 ..< n:
            if rng.rand(99) < 30:
              let reducedWeight = rng.rand(0 .. 20).float / 4.0
              g.addWeightedEdge(u, v, reducedWeight + potential[v] - potential[u])
        checkAgainstFloyd(g)

  test "zero-weight directed cycles and decimal reweighting":
    var g = newDiGraph[int]()
    g.addWeightedEdge(0, 1, -3.0)
    g.addWeightedEdge(1, 0, 3.0)
    g.addWeightedEdge(1, 1, 0.0)
    g.addWeightedEdge(1, 2, 0.3)
    g.addWeightedEdge(2, 3, -0.1)
    g.addWeightedEdge(1, 3, 0.25)
    checkAgainstFloyd(g)

  test "undirected negative edges including tiny weights and loops are cycles":
    for weight in [-1.0, -1e-100]:
      var g = newGraph[int]()
      g.addNode(0)
      g.addWeightedEdge(1, 2, weight)
      var loop = newGraph[int]()
      loop.addWeightedEdge(0, 0, weight)
      for includeUnreachable in [false, true]:
        expect NimNetUnfeasible:
          discard johnsons(g, includeUnreachable = includeUnreachable)
        expect NimNetUnfeasible:
          discard johnsons(loop, includeUnreachable = includeUnreachable)

  test "directed negative cycles are rejected even in disconnected components":
    var g = newDiGraph[int]()
    g.addWeightedEdge(0, 1, 2.0)
    g.addWeightedEdge(2, 3, -2.0)
    g.addWeightedEdge(3, 2, 1.0)
    for includeUnreachable in [false, true]:
      expect NimNetUnfeasible:
        discard johnsons(g, includeUnreachable = includeUnreachable)
    for weight in [-1.0, -1e-100]:
      var loop = newDiGraph[int]()
      loop.addWeightedEdge(0, 0, weight)
      var cycle = newDiGraph[int]()
      cycle.addWeightedEdge(0, 1, weight)
      cycle.addWeightedEdge(1, 2, 0.0)
      cycle.addWeightedEdge(2, 0, 0.0)
      for includeUnreachable in [false, true]:
        expect NimNetUnfeasible:
          discard johnsons(loop, includeUnreachable = includeUnreachable)
        expect NimNetUnfeasible:
          discard johnsons(cycle, includeUnreachable = includeUnreachable)

  test "custom non-orderable nodes support tied queue entries and isolates":
    var g = newGraph[UnorderedNode]()
    var dg = newDiGraph[UnorderedNode]()
    for i in 0 ..< 6:
      g.addNode(UnorderedNode(id: i))
      dg.addNode(UnorderedNode(id: i))
    for (u, v) in [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]:
      g.addWeightedEdge(UnorderedNode(id: u), UnorderedNode(id: v), 0.5)
      dg.addWeightedEdge(UnorderedNode(id: u), UnorderedNode(id: v), 0.5)
    dg.addWeightedEdge(UnorderedNode(id: 4), UnorderedNode(id: 2), -0.5)
    checkAgainstFloyd(g)
    checkAgainstFloyd(dg)

  test "nonfinite edge weights are rejected rather than hidden as unreachable":
    for weight in [NaN, Inf, -Inf]:
      var g = newGraph[int]()
      var dg = newDiGraph[int]()
      g.addWeightedEdge(0, 1, weight)
      dg.addWeightedEdge(0, 1, weight)
      for includeUnreachable in [false, true]:
        expect ValueError:
          discard johnsons(g, includeUnreachable = includeUnreachable)
        expect ValueError:
          discard johnsons(dg, includeUnreachable = includeUnreachable)

  test "unrepresentable finite-weight arithmetic raises an algorithm error":
    var g = newDiGraph[int]()
    g.addWeightedEdge(0, 1, -1e308)
    g.addWeightedEdge(1, 2, -1e308)
    for includeUnreachable in [false, true]:
      expect NimNetAlgorithmError:
        discard johnsons(g, includeUnreachable = includeUnreachable)
