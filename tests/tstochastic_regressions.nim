import std/hashes
import nimnet/[types, graph, digraph]
import nimnet/algorithms/[centrality, louvain]
import nimnet/algorithms/parallel as par

type UnorderedNode = object
  id: int

func hash(node: UnorderedNode): Hash = hash(node.id mod 3)
func `==`(a, b: UnorderedNode): bool = a.id == b.id

# Instantiate the public APIs before the caller imports tables or sets.
block importSmoke:
  var g = newGraph[UnorderedNode]()
  g.addEdge(UnorderedNode(id: 0), UnorderedNode(id: 1))
  discard pageRank(g)
  discard par.parallelPageRank(g, maxIter = 0)
  discard louvainCommunities(g, seed = 42)
  var dg = newDiGraph[UnorderedNode]()
  dg.addEdge(UnorderedNode(id: 0), UnorderedNode(id: 1))
  discard pageRank(dg)
  discard par.parallelPageRank(dg, maxIter = 0)

import std/[unittest, tables, sets, math, random]

const RankTolerance = 1e-11

proc densePageRankReference[N](adj: Table[N, Table[N, EdgeAttr]],
    alpha: float, maxIter: int, tol: float): Table[N, float] =
  var nodes: seq[N]
  for node in adj.keys:
    nodes.add(node)
  let n = nodes.len
  result = initTable[N, float]()
  if n == 0:
    return
  var transition = newSeq[seq[float]](n)
  for i, source in nodes:
    transition[i] = newSeq[float](n)
    var count = 0
    for target in nodes:
      if adj[source].hasKey(target):
        count.inc
    for j, target in nodes:
      if count == 0:
        transition[i][j] = 1.0 / n.float
      elif adj[source].hasKey(target):
        transition[i][j] = 1.0 / count.float

  var rank = newSeq[float](n)
  for i in 0 ..< n:
    rank[i] = 1.0 / n.float
  for iteration in 0 ..< maxIter:
    var next = newSeq[float](n)
    for target in 0 ..< n:
      next[target] = (1.0 - alpha) / n.float
      for source in 0 ..< n:
        next[target] += alpha * rank[source] * transition[source][target]
    var difference = 0.0
    for i in 0 ..< n:
      difference += abs(next[i] - rank[i])
    rank = next
    if difference < tol:
      break
  for i, node in nodes:
    result[node] = rank[i]

proc rankTableMatches[N](nodes: seq[N], actual, expected: Table[N, float]): bool =
  if actual.len != nodes.len:
    return false
  var total = 0.0
  for node in nodes:
    if not actual.hasKey(node) or
        classify(actual[node]) in {fcNan, fcInf, fcNegInf} or
        actual[node] < 0.0 or abs(actual[node] - expected[node]) > RankTolerance:
      return false
    total += actual[node]
  if nodes.len == 0:
    total == 0.0
  else:
    abs(total - 1.0) <= RankTolerance

template pageRanksMatch(input: untyped, damping: float = 0.85,
    iterations: int = 100, threshold: float = 1e-6): bool =
  block:
    let g = input
    let expected = densePageRankReference(g.adj, damping, iterations, threshold)
    let sequential = pageRank(g, alpha = damping,
      maxIter = iterations, tol = threshold)
    let parallel = par.parallelPageRank(g, alpha = damping,
      maxIter = iterations, tol = threshold)
    let sequentialMatches = rankTableMatches(g.nodeSeq(), sequential, expected)
    let parallelMatches = rankTableMatches(g.nodeSeq(), parallel, expected)
    sequentialMatches and parallelMatches

proc weightedModularityReference[N](g: Graph[N],
    partition: seq[HashSet[N]], resolution: float): float =
  var totalWeight = 0.0
  for (u, v, attr) in g.edgesWithAttr:
    totalWeight += attr.weight
  if totalWeight == 0.0:
    return 0.0
  for comm in partition:
    var internalWeight, degree: float
    for (u, v, attr) in g.edgesWithAttr:
      if u in comm:
        degree += attr.weight
      if v in comm:
        degree += attr.weight
      if u in comm and v in comm:
        internalWeight += attr.weight
    let fraction = degree / (2.0 * totalWeight)
    result += internalWeight / totalWeight - resolution * fraction * fraction

proc validPartition[N](g: Graph[N], partition: seq[HashSet[N]]): bool =
  var seen = initHashSet[N]()
  for comm in partition:
    if comm.len == 0:
      return false
    for node in comm:
      if not g.hasNode(node) or node in seen:
        return false
      seen.incl(node)
  seen.len == g.numberOfNodes()

proc samePartition[N](a, b: seq[HashSet[N]]): bool =
  if a.len != b.len:
    return false
  for comm in a:
    if comm notin b:
      return false
  true

proc optimalModularityReference(g: Graph[int], resolution: float): float =
  let nodes = g.nodeSeq()
  var assignment = newSeq[int](nodes.len)
  var best = -Inf
  proc visit(index, count: int) =
    if index == nodes.len:
      var partition = newSeq[HashSet[int]](count)
      for i, node in nodes:
        partition[assignment[i]].incl(node)
      best = max(best, weightedModularityReference(g, partition, resolution))
      return
    for comm in 0 .. count:
      assignment[index] = comm
      visit(index + 1, max(count, comm + 1))
  visit(0, 0)
  result = best

proc hasOptimalModularity(g: Graph[int], partition: seq[HashSet[int]],
    resolution: float): bool =
  if not validPartition(g, partition):
    return false
  let actual = weightedModularityReference(g, partition, resolution)
  let expected = optimalModularityReference(g, resolution)
  classify(actual) notin {fcNan, fcInf, fcNegInf} and
    abs(actual - expected) <= 1e-10

suite "PageRank transition probability regressions":
  test "a single undirected isolate retains unit probability":
    var g = newGraph[int]()
    g.addNode(0)
    check abs(pageRank(g)[0] - 1.0) <= RankTolerance
    check pageRanksMatch(g)

  test "a lone undirected self loop retains unit probability":
    var g = newGraph[int]()
    g.addEdge(0, 0)
    check abs(pageRank(g)[0] - 1.0) <= RankTolerance
    check pageRanksMatch(g)

  test "all variants use total-L1 stopping rather than maximum coordinate change":
    var g = newGraph[int]()
    var dg = newDiGraph[int]()
    for node in 1 .. 6:
      g.addEdge(0, node)
      dg.addEdge(0, node)
    dg.addEdge(1, 0)
    check pageRanksMatch(g, threshold = 0.02)
    check pageRanksMatch(dg, threshold = 0.02)

  test "empty graphs and all-isolate graphs":
    var g = newGraph[string]()
    var dg = newDiGraph[string]()
    check pageRanksMatch(g)
    check pageRanksMatch(dg)
    for node in ["a", "b", "c", "d", "e"]:
      g.addNode(node)
      dg.addNode(node)
    for damping in [0.0, 0.5, 0.85, 1.0]:
      check pageRanksMatch(g, damping = damping)
      check pageRanksMatch(dg, damping = damping)

  test "loops, ordinary edges, sinks and disconnected components":
    var g = newGraph[int]()
    var dg = newDiGraph[int]()
    for node in 0 .. 7:
      g.addNode(node)
      dg.addNode(node)
    for (u, v) in [(0, 0), (0, 1), (1, 2), (2, 2), (3, 4), (5, 5)]:
      g.addEdge(u, v)
      dg.addEdge(u, v)
    for damping in [0.0, 0.5, 0.85, 1.0]:
      check pageRanksMatch(g, damping = damping)
      check pageRanksMatch(dg, damping = damping)

  test "zero and short iteration caps return the actual last iterate":
    var g = newGraph[int]()
    var dg = newDiGraph[int]()
    g.addEdgesFrom([(0, 1), (0, 2), (0, 3), (0, 4)])
    dg.addEdgesFrom([(0, 1), (1, 2), (2, 0), (0, 3)])
    g.addNode(5)
    dg.addNode(5)
    for damping in [0.0, 0.85, 1.0]:
      for cap in [0, 1, 2, 3, 8]:
        check pageRanksMatch(g, damping = damping, iterations = cap, threshold = 0.0)
        check pageRanksMatch(dg, damping = damping, iterations = cap, threshold = 0.0)
    check pageRanksMatch(g, threshold = 1e100)
    check pageRanksMatch(dg, threshold = 1e100)

  test "edge weights are ignored even for loops and zero or negative attributes":
    var g = newGraph[int]()
    var dg = newDiGraph[int]()
    for (u, v, weight) in [(0, 0, -3.0), (0, 1, 0.0),
        (1, 2, 100.0), (2, 0, -5.0), (2, 2, NaN)]:
      g.addWeightedEdge(u, v, weight)
      dg.addWeightedEdge(u, v, weight)
    g.addNode(3)
    dg.addNode(3)
    check pageRanksMatch(g)
    check pageRanksMatch(dg)

  test "seeded small graphs match dense stochastic transition matrices":
    var prng = initRand(13_014)
    for n in 1 .. 9:
      for sample in 0 ..< 3:
        var g = newGraph[int]()
        var dg = newDiGraph[int]()
        for node in 0 ..< n:
          g.addNode(node)
          dg.addNode(node)
        for u in 0 ..< n:
          for v in 0 ..< n:
            if prng.rand(99) < 25:
              let weight = prng.rand(-8 .. 8).float / 4.0
              dg.addWeightedEdge(u, v, weight)
              if u <= v:
                g.addWeightedEdge(u, v, weight)
        for damping in [0.0, 0.85, 1.0]:
          check pageRanksMatch(g, damping = damping, iterations = 12)
          check pageRanksMatch(dg, damping = damping, iterations = 12)

  test "custom non-orderable nodes with colliding hashes":
    var g = newGraph[UnorderedNode]()
    var dg = newDiGraph[UnorderedNode]()
    for node in 0 .. 8:
      g.addNode(UnorderedNode(id: node))
      dg.addNode(UnorderedNode(id: node))
    for (u, v) in [(0, 0), (0, 1), (1, 2), (2, 0), (3, 4), (5, 5)]:
      g.addEdge(UnorderedNode(id: u), UnorderedNode(id: v))
      dg.addEdge(UnorderedNode(id: u), UnorderedNode(id: v))
    check pageRanksMatch(g)
    check pageRanksMatch(dg)

  test "invalid alpha is rejected by all variants even for empty graphs":
    for populated in [false, true]:
      var g = newGraph[int]()
      var dg = newDiGraph[int]()
      if populated:
        g.addEdge(0, 1)
        dg.addEdge(0, 1)
      for damping in [-1e-100, 1.01, NaN, Inf, -Inf]:
        expect ValueError:
          discard pageRank(g, alpha = damping)
        expect ValueError:
          discard pageRank(dg, alpha = damping)
        expect ValueError:
          discard par.parallelPageRank(g, alpha = damping)
        expect ValueError:
          discard par.parallelPageRank(dg, alpha = damping)

  test "invalid tolerance and iteration cap are not success-shaped returns":
    var g = newGraph[int]()
    var dg = newDiGraph[int]()
    for threshold in [-1e-100, NaN, Inf, -Inf]:
      expect ValueError:
        discard pageRank(g, tol = threshold)
      expect ValueError:
        discard pageRank(dg, tol = threshold)
      expect ValueError:
        discard par.parallelPageRank(g, tol = threshold)
      expect ValueError:
        discard par.parallelPageRank(dg, tol = threshold)
    expect ValueError:
      discard pageRank(g, maxIter = -1)
    expect ValueError:
      discard pageRank(dg, maxIter = -1)
    expect ValueError:
      discard par.parallelPageRank(g, maxIter = -1)
    expect ValueError:
      discard par.parallelPageRank(dg, maxIter = -1)

suite "Louvain resolution and weighted-loop regressions":
  test "low positive resolution merges a clique and high resolution splits it":
    var g = newGraph[int]()
    for u in 0 ..< 4:
      for v in u + 1 ..< 4:
        g.addEdge(u, v)
    let low = louvainCommunities(g, resolution = 0.5, seed = 42)
    let high = louvainCommunities(g, resolution = 3.0, seed = 42)
    check low.len == 1
    check high.len == 4
    check hasOptimalModularity(g, low, 0.5)
    check hasOptimalModularity(g, high, 3.0)

  test "self loops contribute twice to degree but once to internal weight":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 0, 1.0)
    g.addWeightedEdge(1, 1, 1.0)
    g.addWeightedEdge(0, 1, 1.0)
    let low = louvainCommunities(g, resolution = 0.5, seed = 42)
    let high = louvainCommunities(g, resolution = 0.75, seed = 42)
    check low.len == 1
    check high.len == 2
    check hasOptimalModularity(g, low, 0.5)
    check hasOptimalModularity(g, high, 0.75)

  test "uniformly weighted cliques match the objective at multiple resolutions":
    for weight in [1e-300, 0.125, 1.0, 7.5, 1e300]:
      var g = newGraph[int]()
      for u in 0 ..< 4:
        for v in u + 1 ..< 4:
          g.addWeightedEdge(u, v, weight)
      for resolution in [0.0, 0.5, 1.0, 1.2, 1.5, 3.0]:
        let partition = louvainCommunities(g, resolution = resolution, seed = 42)
        check hasOptimalModularity(g, partition, resolution)

  test "weighted loop thresholds agree with exhaustive two-node objectives":
    for (leftLoop, rightLoop, edge) in [(0.0, 4.0, 2.0), (1.0, 1.0, 1.0),
        (2.0, 0.5, 3.0), (2.0, 1.0, 0.0)]:
      var g = newGraph[int]()
      g.addWeightedEdge(0, 0, leftLoop)
      g.addWeightedEdge(1, 1, rightLoop)
      g.addWeightedEdge(0, 1, edge)
      for resolution in [0.0, 0.25, 0.5, 0.75, 1.0, 2.0, 4.0]:
        let partition = louvainCommunities(g, resolution = resolution, seed = 42)
        check hasOptimalModularity(g, partition, resolution)

  test "disconnected weighted pairs, loops and an isolate":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.5)
    g.addWeightedEdge(0, 0, 0.25)
    g.addWeightedEdge(2, 3, 3.0)
    g.addWeightedEdge(3, 3, 1.0)
    g.addNode(4)
    for resolution in [0.0, 0.25, 0.5, 1.0, 2.0, 4.0]:
      let partition = louvainCommunities(g, resolution = resolution, seed = 42)
      check hasOptimalModularity(g, partition, resolution)
      check [4].toHashSet() in partition

  test "coarsening preserves internal weights and resolution":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)])
    g.addWeightedEdge(2, 3, 0.25)
    for (resolution, count) in [(0.05, 1), (1.0, 2), (4.0, 6)]:
      let partition = louvainCommunities(g, resolution = resolution, seed = 42)
      check partition.len == count
      check hasOptimalModularity(g, partition, resolution)

  test "gamma one retains ordinary clique and bridge behavior":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)])
    let partition = louvainCommunities(g, seed = 42)
    check partition.len == 2
    check [0, 1, 2].toHashSet() in partition
    check [3, 4, 5].toHashSet() in partition
    check abs(weightedModularityReference(g, partition, 1.0) - 5.0 / 14.0) < 1e-12

  test "zero-weight edges do not duplicate aggregated community weights":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(2, 3, 1.0)
    for u in 0 .. 1:
      for v in 2 .. 3:
        g.addWeightedEdge(u, v, 0.0)
    for resolution in [0.0, 0.5, 1.0, 3.0]:
      let partition = louvainCommunities(g, resolution = resolution, seed = 42)
      check hasOptimalModularity(g, partition, resolution)

  test "empty, edgeless and zero-total-weight graphs retain singleton nodes":
    var g = newGraph[int]()
    check louvainCommunities(g, seed = 42).len == 0
    for node in 0 .. 4:
      g.addNode(node)
    check louvainCommunities(g, seed = 42).len == 5
    g.addWeightedEdge(0, 1, 0.0)
    g.addWeightedEdge(2, 2, 0.0)
    for resolution in [0.0, 1.0, 10.0]:
      let partition = louvainCommunities(g, resolution = resolution, seed = 42)
      check partition.len == 5
      check validPartition(g, partition)

  test "large finite resolution remains meaningful without nonfinite gains":
    var g = newGraph[int]()
    g.addEdge(0, 1)
    let partition = louvainCommunities(g, resolution = 1e300, seed = 42)
    check partition.len == 2
    check hasOptimalModularity(g, partition, 1e300)

  test "nonzero seeds repeat for arbitrary non-orderable node types":
    var g = newGraph[UnorderedNode]()
    for node in 0 .. 7:
      g.addNode(UnorderedNode(id: node))
    for (u, v, weight) in [(0, 0, 0.5), (0, 1, 2.0), (1, 2, 1.0),
        (2, 0, 3.0), (2, 3, 0.25), (3, 4, 1.5), (4, 5, 1.0), (5, 3, 2.5)]:
      g.addWeightedEdge(UnorderedNode(id: u), UnorderedNode(id: v), weight)
    for resolution in [0.0, 0.5, 1.0, 3.0]:
      let first = louvainCommunities(g, resolution = resolution, seed = 123)
      check validPartition(g, first)
      for repetition in 0 ..< 5:
        let again = louvainCommunities(g, resolution = resolution, seed = 123)
        check samePartition(first, again)

  test "invalid resolution is rejected before empty-graph early returns":
    for populated in [false, true]:
      var g = newGraph[int]()
      if populated:
        g.addEdge(0, 1)
      for resolution in [-1e-100, NaN, Inf, -Inf]:
        expect ValueError:
          discard louvainCommunities(g, resolution = resolution, seed = 42)

  test "negative and nonfinite edge weights are rejected explicitly":
    for weight in [-1e-100, NaN, Inf, -Inf]:
      for selfLoop in [false, true]:
        var g = newGraph[int]()
        g.addWeightedEdge(0, (if selfLoop: 0 else: 1), weight)
        expect ValueError:
          discard louvainCommunities(g, seed = 42)

  test "overflowing weighted-degree arithmetic raises rather than returning a partition":
    for selfLoop in [false, true]:
      var g = newGraph[int]()
      g.addWeightedEdge(0, (if selfLoop: 0 else: 1), 1e308)
      expect NimNetAlgorithmError:
        discard louvainCommunities(g, seed = 42)
