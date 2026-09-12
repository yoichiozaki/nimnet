import std/[unittest, sets, tables, hashes, random, bitops]
import nimnet/[graph, types]
import nimnet/algorithms/matching as mat
import nimnet/algorithms/bipartite as bip

type OpaqueNode = object
  id: int

func hash(node: OpaqueNode): Hash = Hash(node.id)
func `==`(a, b: OpaqueNode): bool = a.id == b.id
func `$`(node: OpaqueNode): string = "opaque"

type HashOnlyNode = object
  id: int

func hash(node: HashOnlyNode): Hash = Hash(node.id)
func `==`(a, b: HashOnlyNode): bool = a.id == b.id
proc `$`(node: HashOnlyNode): string {.error: "This node has no string conversion".}

static:
  doAssert not compiles(OpaqueNode(id: 0) < OpaqueNode(id: 1))
  doAssert not compiles($HashOnlyNode(id: 0))

proc graphFromMask(n, mask: int, selfLoops = false): Graph[int] =
  result = newGraph[int]()
  for u in 0 ..< n:
    result.addNode(u)
  var bit = 0
  for u in 0 ..< n:
    let first = if selfLoops: u else: u + 1
    for v in first ..< n:
      if mask != 0 and (mask and (1 shl bit)) != 0:
        result.addEdge(u, v)
      bit.inc

proc searchMatching(adjacency: seq[int], available: int): int =
  if available == 0:
    return 0
  var u = 0
  while (available and (1 shl u)) == 0:
    u.inc
  let remaining = available xor (1 shl u)
  result = searchMatching(adjacency, remaining)
  for v in u + 1 ..< adjacency.len:
    if (remaining and adjacency[u] and (1 shl v)) != 0:
      result = max(result,
        1 + searchMatching(adjacency, remaining xor (1 shl v)))

proc bruteCardinality(g: Graph[int], n: int): int =
  var adjacency = newSeq[int](n)
  for u in 0 ..< n:
    for v in u + 1 ..< n:
      if g.hasEdge(u, v):
        adjacency[u] = adjacency[u] or (1 shl v)
        adjacency[v] = adjacency[v] or (1 shl u)
  searchMatching(adjacency, (1 shl n) - 1)

proc edgeMasks(g: Graph[int]): seq[int] =
  for (u, v) in g.edges:
    result.add((1 shl u) or (1 shl v))

proc bruteEdgeCoverSize(g: Graph[int], n: int): int =
  let edges = edgeMasks(g)
  result = high(int)
  for subset in 0 ..< (1 shl edges.len):
    let size = countSetBits(subset)
    if size >= result:
      continue
    var covered = 0
    for i, endpoints in edges:
      if (subset and (1 shl i)) != 0:
        covered = covered or endpoints
    if covered == (1 shl n) - 1:
      result = size
  if result == high(int):
    result = -1

proc bruteVertexCoverSize(g: Graph[int], n: int): int =
  let edges = edgeMasks(g)
  result = n
  for subset in 0 ..< (1 shl n):
    let size = countSetBits(subset)
    if size >= result:
      continue
    var valid = true
    for endpoints in edges:
      if (subset and endpoints) == 0:
        valid = false
        break
    if valid:
      result = size

proc brutePartition(g: Graph[int], n: int):
    tuple[valid: bool, top: HashSet[int]] =
  result.top = initHashSet[int]()
  var edges: seq[(int, int)]
  for edge in g.edges:
    edges.add(edge)
  for subset in 0 ..< (1 shl n):
    var valid = true
    for (u, v) in edges:
      if ((subset shr u) and 1) == ((subset shr v) and 1):
        valid = false
        break
    if valid:
      result.valid = true
      for u in 0 ..< n:
        if (subset and (1 shl u)) != 0:
          result.top.incl(u)
      return

proc checkBipartiteResults[N](g: Graph[N], top: HashSet[N], expected: int) =
  let inferred = bip.maximumMatching(g)
  let supplied = bip.maximumMatching(g, top)
  for matching in [inferred, supplied]:
    check matching.len == expected
    check mat.isMatching(g, matching)
    check mat.isMaximalMatching(g, matching)
    var mates = initTable[N, N]()
    for (u, v) in matching:
      mates[u] = v
      mates[v] = u
    check mates.len == 2 * expected
    for u, v in mates:
      check mates[v] == u
  for (u, v) in supplied:
    check u in top
    check v notin top
  for cover in [bip.minimumVertexCover(g), bip.minimumVertexCover(g, top)]:
    check cover.len == expected
    for node in cover:
      check g.hasNode(node)
      check g.degree(node) > 0
    for (u, v) in g.edges:
      check u in cover or v in cover

proc checkAgainstOracles(g: Graph[int], n: int, exactEdgeCover = false) =
  let expected = bruteCardinality(g, n)
  let matching = mat.maximumCardinalityMatching(g)
  check matching.len == expected
  check mat.isMatching(g, matching)
  check mat.isMaximalMatching(g, matching)
  var feasible = true
  for node in g.nodes:
    if g.degree(node) == 0:
      feasible = false
  if feasible:
    let cover = mat.minEdgeCover(g)
    check mat.isEdgeCover(g, cover)
    check cover.len == n - expected
    if exactEdgeCover:
      check cover.len == bruteEdgeCoverSize(g, n)
  else:
    expect NimNetUnfeasible:
      discard mat.minEdgeCover(g)
    if exactEdgeCover:
      check bruteEdgeCoverSize(g, n) == -1
  let partition = brutePartition(g, n)
  check bip.isBipartite(g) == partition.valid
  if partition.valid:
    checkBipartiteResults(g, partition.top, expected)
    check bruteVertexCoverSize(g, n) == expected
  else:
    expect NimNetError:
      discard bip.maximumMatching(g)
    expect NimNetError:
      discard bip.minimumVertexCover(g)
    expect NimNetError:
      discard bip.maximumMatching(g, partition.top)
    expect NimNetError:
      discard bip.minimumVertexCover(g, partition.top)

proc matchingWeight[N](g: Graph[N], matching: seq[(N, N)]): float =
  for (u, v) in matching:
    result += g.getEdgeAttr(u, v).getWeight()

proc bruteMaximumWeight(g: Graph[int], available: int): float =
  if available == 0:
    return 0.0
  var u = 0
  while (available and (1 shl u)) == 0:
    u.inc
  let remaining = available xor (1 shl u)
  result = bruteMaximumWeight(g, remaining)
  for v in u + 1 ..< g.numberOfNodes():
    if (remaining and (1 shl v)) != 0 and g.hasEdge(u, v):
      result = max(result, g.getEdgeAttr(u, v).getWeight() +
        bruteMaximumWeight(g, remaining xor (1 shl v)))

suite "Exact matching and cover oracles":
  test "all 1100 simple graphs through five vertices":
    var count = 0
    for n in 0 .. 5:
      let edgeCount = n * (n - 1) div 2
      for mask in 0 ..< (1 shl edgeCount):
        checkAgainstOracles(graphFromMask(n, mask), n, exactEdgeCover = true)
        count.inc
    check count == 1100

  test "all graphs with optional self-loops through four vertices":
    for n in 0 .. 4:
      let edgeCount = n * (n + 1) div 2
      for mask in 0 ..< (1 shl edgeCount):
        checkAgainstOracles(graphFromMask(n, mask, selfLoops = true), n,
          exactEdgeCover = true)

  test "seeded general graphs on six through nine vertices":
    var rng = initRand(169177)
    for n in 6 .. 9:
      for trial in 0 ..< 140:
        var g = graphFromMask(n, 0)
        let density = [0, 10, 25, 50, 75, 90, 100][trial mod 7]
        for u in 0 ..< n:
          for v in u + 1 ..< n:
            if rng.rand(99) < density:
              g.addEdge(u, v)
        checkAgainstOracles(g, n)

  test "seeded bipartite graphs and explicit partitions on six to nine nodes":
    var rng = initRand(177169)
    for n in 6 .. 9:
      for trial in 0 ..< 100:
        var g = graphFromMask(n, 0)
        var top = initHashSet[int]()
        for node in 0 ..< n:
          if rng.rand(1) == 1:
            top.incl(node)
        let density = [0, 20, 50, 80, 100][trial mod 5]
        for u in 0 ..< n:
          for v in u + 1 ..< n:
            if (u in top) != (v in top) and rng.rand(99) < density:
              g.addEdge(u, v)
        let expected = bruteCardinality(g, n)
        checkBipartiteResults(g, top, expected)
        check bruteVertexCoverSize(g, n) == expected
        check mat.maximumCardinalityMatching(g).len == expected

suite "General blossom matching regressions":
  test "augment past a non-maximum greedy matching to get a minimum edge cover":
    var g = newGraph[OpaqueNode]()
    let a = OpaqueNode(id: 0)
    let b = OpaqueNode(id: 1)
    let c = OpaqueNode(id: 2)
    let d = OpaqueNode(id: 3)
    g.addEdgesFrom([(a, b), (a, c), (b, d)])
    check mat.maximalMatching(g).len == 1
    let matching = mat.maximumCardinalityMatching(g)
    check matching.len == 2
    check mat.isPerfectMatching(g, matching)
    let cover = mat.minEdgeCover(g)
    check cover.len == 2
    check mat.isEdgeCover(g, cover)

  test "blossoms with stems and nested overlapping odd cycles":
    let cases = @[
      (n: 4, size: 2, edges: @[(0, 1), (1, 2), (2, 0), (2, 3)]),
      (n: 6, size: 3, edges: @[(0, 1), (1, 2), (2, 0),
        (0, 3), (3, 4), (0, 5)]),
      (n: 10, size: 5, edges: @[(0, 1), (1, 2), (2, 0),
        (1, 3), (3, 4), (4, 2), (3, 5), (5, 6), (6, 4),
        (5, 7), (7, 8), (8, 6), (8, 9)]),
      (n: 14, size: 7, edges: @[(0, 1), (1, 2), (2, 0),
        (3, 4), (4, 5), (5, 3), (6, 7), (7, 8), (8, 9),
        (9, 10), (10, 6), (2, 3), (5, 6), (10, 11), (11, 12),
        (12, 13)])
    ]
    var rng = initRand(169)
    for fixture in cases:
      var labels = newSeq[int](fixture.n)
      for i in 0 ..< labels.len:
        labels[i] = i
      for trial in 0 ..< 24:
        rng.shuffle(labels)
        var g = graphFromMask(fixture.n, 0)
        for (u, v) in fixture.edges:
          g.addEdge(labels[u], labels[v])
        let matching = mat.maximumCardinalityMatching(g)
        check matching.len == fixture.size
        check mat.isPerfectMatching(g, matching)
        check matching.len == bruteCardinality(g, fixture.n)
        let cover = mat.minEdgeCover(g)
        check cover.len == fixture.n - fixture.size
        check mat.isEdgeCover(g, cover)

  test "large odd complete graph and disconnected blossoms":
    var g = graphFromMask(105, 0)
    for u in 0 ..< 101:
      for v in u + 1 ..< 101:
        g.addEdge(u, v)
    g.addEdgesFrom([(101, 102), (102, 103), (103, 101)])
    let matching = mat.maximumCardinalityMatching(g)
    check matching.len == 51
    check mat.isMatching(g, matching)
    check mat.isMaximalMatching(g, matching)
    expect NimNetUnfeasible:
      discard mat.minEdgeCover(g)
    g.addEdge(104, 104)
    let cover = mat.minEdgeCover(g)
    check cover.len == 105 - 51
    check mat.isEdgeCover(g, cover)

  test "empty graph, isolates, loops, and invalid matching validation":
    var g = newGraph[int]()
    check mat.maximumCardinalityMatching(g).len == 0
    check mat.minEdgeCover(g).len == 0
    check mat.isPerfectMatching(g, @[])
    g.addNode(0)
    check mat.maximumCardinalityMatching(g).len == 0
    expect NimNetUnfeasible:
      discard mat.minEdgeCover(g)
    g.addEdge(0, 0)
    check mat.maximumCardinalityMatching(g).len == 0
    check mat.maximalMatching(g).len == 0
    check mat.isMaximalMatching(g, @[])
    check not mat.isMatching(g, @[(0, 0)])
    check not mat.isPerfectMatching(g, @[(0, 0)])
    check not mat.isMaximalMatching(g, @[(0, 0)])
    check mat.minEdgeCover(g) == @[(0, 0)]
    g.addEdge(1, 2)
    check not mat.isMatching(g, @[(1, 2), (2, 1)])
    check not mat.isMatching(g, @[(0, 1)])
    check mat.maximumCardinalityMatching(g).len == 1
    check mat.minEdgeCover(g).len == 2
    check mat.isEdgeCover(g, mat.minEdgeCover(g))

  test "cardinality matching ignores edge weights and does not mutate attributes":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1_000_000.0)
    g.addWeightedEdge(0, 2, -20.0)
    g.addWeightedEdge(1, 3, -30.0)
    let matching = mat.maximumCardinalityMatching(g)
    check matching.len == 2
    check mat.isPerfectMatching(g, matching)
    check matchingWeight(g, matching) == -50.0
    check g.numberOfNodes() == 4
    check g.numberOfEdges() == 3
    check g.getEdgeAttr(0, 1).getWeight() == 1_000_000.0

  test "matching and covers need only hashing and equality, not string conversion":
    let a = HashOnlyNode(id: 0)
    let b = HashOnlyNode(id: 1)
    let c = HashOnlyNode(id: 2)
    let d = HashOnlyNode(id: 3)
    var g = newGraph[HashOnlyNode]()
    g.addEdgesFrom([(a, b), (b, c), (c, a), (c, d)])
    let matching = mat.maximumCardinalityMatching(g)
    check matching.len == 2
    let perfect = mat.isPerfectMatching(g, matching)
    check perfect
    let cover = mat.minEdgeCover(g)
    check cover.len == 2
    let covered = mat.isEdgeCover(g, cover)
    check covered
    for greedy in [mat.maximalMatching(g), mat.approxMaxWeightMatching(g),
        mat.approxMinWeightMatching(g)]:
      let valid = mat.isMaximalMatching(g, greedy)
      check valid
    var bg = newGraph[HashOnlyNode]()
    bg.addEdgesFrom([(a, b), (b, c), (c, d)])
    let top = toHashSet([a, c])
    for m in [bip.maximumMatching(bg), bip.maximumMatching(bg, top)]:
      check m.len == 2
      let valid = mat.isMatching(bg, m)
      check valid
    for vc in [bip.minimumVertexCover(bg), bip.minimumVertexCover(bg, top)]:
      check vc.len == 2
      for (u, v) in bg.edges:
        let covered = u in vc or v in vc
        check covered
    expect NodeNotFound:
      discard bip.maximumMatching(bg, toHashSet([HashOnlyNode(id: 99)]))
    var isolated = newGraph[HashOnlyNode]()
    isolated.addNode(a)
    expect NimNetUnfeasible:
      discard mat.minEdgeCover(isolated)

suite "Explicit greedy weighted matching contracts":
  test "maximum-weight name remains greedy and its alias is identical":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.1)
    g.addWeightedEdge(0, 2, 1.0)
    g.addWeightedEdge(1, 3, 1.0)
    let matching = mat.maxWeightMatching(g)
    check matching == mat.approxMaxWeightMatching(g)
    check matching.len == 1
    check mat.isMaximalMatching(g, matching)
    check mat.maximumCardinalityMatching(g).len == 2
    check matchingWeight(g, matching) < bruteMaximumWeight(g, 15)
    check matchingWeight(g, matching) >= 0.5 * bruteMaximumWeight(g, 15)

  test "ascending-weight heuristic is not a minimum-weight exact solver":
    var g = newGraph[int]()
    g.addWeightedEdge(0, 1, 1.0)
    g.addWeightedEdge(2, 3, 1000.0)
    g.addWeightedEdge(0, 2, 2.0)
    g.addWeightedEdge(1, 3, 2.0)
    let matching = mat.minWeightMatching(g)
    check matching == mat.approxMinWeightMatching(g)
    check mat.isPerfectMatching(g, matching)
    check matchingWeight(g, matching) == 1001.0
    check matchingWeight(g, @[(0, 2), (1, 3)]) == 4.0
    g.removeEdge(2, 3)
    check mat.minWeightMatching(g).len == 1
    check mat.maximumCardinalityMatching(g).len == 2

  test "negative edge handling is preserved and loops are not matched":
    var g = newGraph[int]()
    for matching in [mat.maxWeightMatching(g), mat.minWeightMatching(g),
        mat.approxMaxWeightMatching(g), mat.approxMinWeightMatching(g)]:
      check matching.len == 0
    g.addWeightedEdge(0, 1, -5.0)
    g.addWeightedEdge(0, 0, 100.0)
    g.addWeightedEdge(2, 2, -100.0)
    for matching in [mat.maxWeightMatching(g), mat.minWeightMatching(g),
        mat.approxMaxWeightMatching(g), mat.approxMinWeightMatching(g)]:
      check matching.len == 1
      check mat.isMaximalMatching(g, matching)
      check matchingWeight(g, matching) == -5.0

  test "generic nodes with identical string representations retain distinct edges":
    var g = newGraph[OpaqueNode]()
    g.addWeightedEdge(OpaqueNode(id: 0), OpaqueNode(id: 1), 3.0)
    g.addWeightedEdge(OpaqueNode(id: 2), OpaqueNode(id: 3), 2.0)
    g.addWeightedEdge(OpaqueNode(id: 4), OpaqueNode(id: 4), 100.0)
    for matching in [mat.maxWeightMatching(g), mat.minWeightMatching(g),
        mat.approxMaxWeightMatching(g), mat.approxMinWeightMatching(g)]:
      check matching.len == 2
      check mat.isMaximalMatching(g, matching)
      check matchingWeight(g, matching) == 5.0

  test "one-half maximum-weight bound against seeded brute-force optima":
    var rng = initRand(16901)
    for trial in 0 ..< 100:
      var g = graphFromMask(7, 0)
      for u in 0 ..< 7:
        for v in u + 1 ..< 7:
          if rng.rand(1) == 1:
            g.addWeightedEdge(u, v, float(rng.rand(20)))
      let matching = mat.approxMaxWeightMatching(g)
      check mat.isMaximalMatching(g, matching)
      check matchingWeight(g, matching) >=
        0.5 * bruteMaximumWeight(g, (1 shl 7) - 1)
      check matching == mat.maxWeightMatching(g)
      let ascending = mat.approxMinWeightMatching(g)
      check mat.isMaximalMatching(g, ascending)
      check ascending == mat.minWeightMatching(g)

suite "Hopcroft-Karp partition and stack regressions":
  test "generic supplied partitions orient disconnected components and isolates":
    var g = newGraph[OpaqueNode]()
    var nodes = newSeq[OpaqueNode](7)
    for i in 0 ..< nodes.len:
      nodes[i] = OpaqueNode(id: i)
      g.addNode(nodes[i])
    g.addEdgesFrom([(nodes[0], nodes[2]), (nodes[1], nodes[2]),
      (nodes[3], nodes[4])])
    let top = toHashSet([nodes[2], nodes[4], nodes[5]])
    checkBipartiteResults(g, top, 2)
    var other = initHashSet[OpaqueNode]()
    for node in nodes:
      if node notin top:
        other.incl(node)
    checkBipartiteResults(g, other, 2)
    expect NodeNotFound:
      discard bip.maximumMatching(g, top + toHashSet([OpaqueNode(id: 99)]))
    expect NodeNotFound:
      discard bip.minimumVertexCover(g, top + toHashSet([OpaqueNode(id: 99)]))

  test "empty and edgeless graphs allow either placement of isolates":
    var g = newGraph[int]()
    checkBipartiteResults(g, initHashSet[int](), 0)
    for node in 0 ..< 5:
      g.addNode(node)
    for top in [initHashSet[int](), toHashSet([0, 2, 4]),
        toHashSet([0, 1, 2, 3, 4])]:
      checkBipartiteResults(g, top, 0)

  test "unknown nodes and either kind of intra-part edge are rejected":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (2, 3)])
    expect NodeNotFound:
      discard bip.maximumMatching(g, toHashSet([0, 2, 99]))
    expect NodeNotFound:
      discard bip.minimumVertexCover(g, toHashSet([0, 2, 99]))
    for top in [toHashSet([0, 1, 2]), toHashSet([0]),
        initHashSet[int](), toHashSet([0, 1, 2, 3])]:
      expect NimNetError:
        discard bip.maximumMatching(g, top)
      expect NimNetError:
        discard bip.minimumVertexCover(g, top)
    let empty = newGraph[int]()
    expect NodeNotFound:
      discard bip.maximumMatching(empty, toHashSet([0]))
    expect NodeNotFound:
      discard bip.minimumVertexCover(empty, toHashSet([0]))

  test "odd cycles and self-loops reject inferred and explicit partitions":
    var g = newGraph[int]()
    g.addEdgesFrom([(0, 1), (1, 2), (2, 0), (3, 4)])
    for top in [toHashSet([0, 3]), toHashSet([0, 1, 3])]:
      expect NimNetError:
        discard bip.maximumMatching(g, top)
      expect NimNetError:
        discard bip.minimumVertexCover(g, top)
    expect NimNetError:
      discard bip.maximumMatching(g)
    expect NimNetError:
      discard bip.minimumVertexCover(g)
    g = newGraph[int]()
    g.addEdge(0, 0)
    for top in [initHashSet[int](), toHashSet([0])]:
      expect NimNetError:
        discard bip.maximumMatching(g, top)
      expect NimNetError:
        discard bip.minimumVertexCover(g, top)
    expect NimNetError:
      discard bip.maximumMatching(g)
    expect NimNetError:
      discard bip.minimumVertexCover(g)

  test "a 11999-edge alternating augmenting path uses no recursive stack":
    const side = 6000
    var g = newGraph[OpaqueNode](capacity = side * 2)
    var top = initHashSet[OpaqueNode]()
    var right = newSeq[OpaqueNode](side)
    for i in 0 ..< side:
      let left = OpaqueNode(id: (i shl 5) + 2)
      right[i] = OpaqueNode(id: (i shl 5) + 1)
      top.incl(left)
      g.addNode(left)
      g.addNode(right[i])
    var left: seq[OpaqueNode]
    for node in g.nodes:
      if node in top:
        left.add(node)
    # Equal low hash bits keep each two-neighbor table in insertion order.
    # Phase one matches left[i] to right[i], leaving only left[^1] free.
    for i in 0 ..< side - 1:
      g.addEdge(left[i], right[i])
      g.addEdge(left[i], right[i + 1])
      for first in g.neighbors(left[i]):
        check first == right[i]
        break
    g.addEdge(left[^1], right[0])
    let matching = bip.maximumMatching(g, top)
    check matching.len == side
    check mat.isPerfectMatching(g, matching)
    for (u, v) in matching:
      check u in top
      check v notin top
    let cover = bip.minimumVertexCover(g, top)
    check cover.len == side
    for (u, v) in g.edges:
      check u in cover or v in cover
