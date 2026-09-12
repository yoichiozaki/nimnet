import std/[unittest, sets, math]
import std/random as randlib
import nimnet

proc edgeSet(g: Graph[int]): HashSet[(int, int)] =
  for (u, v) in g.edges:
    result.incl((min(u, v), max(u, v)))

proc checkSimpleGraph(g: Graph[int], n: int) =
  check g.numberOfNodes() == n
  var degreeSum = 0
  for node in 0 ..< n:
    check g.hasNode(node)
    check not g.hasEdge(node, node)
    degreeSum += g.degree(node)
  var seen = initHashSet[(int, int)]()
  for (u, v) in g.edges:
    check u >= 0 and u < n
    check v >= 0 and v < n
    check u != v
    check g.hasEdge(v, u)
    let edge = (min(u, v), max(u, v))
    check edge notin seen
    seen.incl(edge)
  check seen.len == g.numberOfEdges()
  check degreeSum == 2 * g.numberOfEdges()

proc checkRegularGraph(g: Graph[int], n, d: int) =
  checkSimpleGraph(g, n)
  check g.numberOfEdges() == n * d div 2
  for node in 0 ..< n:
    check g.degree(node) == d

proc legacyErdosRenyiGraph(n: int, p: float, seed: int64): Graph[int] =
  var rng = randlib.initRand(seed)
  result = newGraph[int](capacity = n)
  for i in 0 ..< n:
    result.addNode(i)
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if rng.rand(1.0) < p:
        result.addEdge(i, j)

suite "Gnp generator regressions":
  test "dense generator preserves the legacy seeded edge sequence":
    for seed in [-17'i64, 1, 42, 987654321]:
      for n in [0, 1, 2, 30]:
        for p in [0.0, 1e-20, 0.1, 0.5, 0.99, 1.0]:
          let actual = erdosRenyiGraph(n, p, seed)
          let expected = legacyErdosRenyiGraph(n, p, seed)
          check actual.nodeSeq == expected.nodeSeq
          check actual.edgeSeq == expected.edgeSeq

  test "both Gnp generators reject negative node counts":
    for n in [-1, low(int)]:
      expect NimNetError:
        discard erdosRenyiGraph(n, 0.5, seed = 42)
      expect NimNetError:
        discard fastGnpRandomGraph(n, 0.5, seed = 42)

  test "both Gnp generators reject invalid probabilities before allocation":
    for p in [-1.0, -1e-300, 1.00001, NaN, Inf, -Inf]:
      for n in [0, 1, 10, high(int)]:
        expect NimNetError:
          discard erdosRenyiGraph(n, p, seed = 42)
        expect NimNetError:
          discard fastGnpRandomGraph(n, p, seed = 42)

  test "fast Gnp supports empty singleton edgeless and complete graphs":
    for n in [0, 1, 2, 12]:
      for p in [0.0, 1.0]:
        let g = fastGnpRandomGraph(n, p, seed = 42)
        checkSimpleGraph(g, n)
        check g.numberOfEdges() == (if p == 0.0: 0 else: n * (n - 1) div 2)
    for n in [0, 1]:
      let g = fastGnpRandomGraph(n, 0.37, seed = 42)
      checkSimpleGraph(g, n)
      check g.numberOfEdges() == 0

  test "fast Gnp is simple and reproducible for nonzero seeds":
    for seed in [-17'i64, 1, 42, 987654321]:
      for p in [0.002, 0.05, 0.5, 0.95]:
        let g = fastGnpRandomGraph(120, p, seed)
        checkSimpleGraph(g, 120)
        check edgeSet(g) == edgeSet(fastGnpRandomGraph(120, p, seed))
    check edgeSet(fastGnpRandomGraph(120, 0.1, seed = 1)) !=
      edgeSet(fastGnpRandomGraph(120, 0.1, seed = 42))

  test "zero seed remains supported":
    checkSimpleGraph(fastGnpRandomGraph(20, 0.25), 20)
    checkSimpleGraph(erdosRenyiGraph(20, 0.25), 20)
    checkSimpleGraph(gnmRandomGraph(20, 25), 20)
    checkRegularGraph(randomRegularGraph(20, 1), 20, 1)

  test "subnormal and sub-epsilon probabilities cannot overflow gaps":
    let smallestPositive = cast[float](1'u64)
    check smallestPositive > 0.0
    for p in [smallestPositive, 1e-320, 1e-300, 1e-100, 1e-20, 1e-17]:
      for seed in [1'i64, 42]:
        let g = fastGnpRandomGraph(256, p, seed)
        checkSimpleGraph(g, 256)
        check g.numberOfEdges() == 0

  test "near-unit probabilities remain finite and produce valid endpoints":
    let p = 1.0 - 1.1102230246251565e-16
    check p < 1.0
    let g = fastGnpRandomGraph(40, p, seed = 42)
    checkSimpleGraph(g, 40)
    check g.numberOfEdges() == 780

  test "large sparse inputs need no integer pair count or unbounded gap":
    let g = fastGnpRandomGraph(70000, 1e-300, seed = 42)
    checkSimpleGraph(g, 70000)
    check g.numberOfEdges() == 0

  test "seeded edge densities agree with binomial expectations":
    const n = 160
    const samples = 16
    const pairs = n * (n - 1) div 2
    for p in [0.002, 0.025, 0.25, 0.8, 0.99]:
      var totalEdges = 0
      for seed in 1 .. samples:
        totalEdges += fastGnpRandomGraph(n, p, int64(seed)).numberOfEdges()
      let expected = float(samples * pairs) * p
      let deviation = sqrt(expected * (1.0 - p))
      check abs(float(totalEdges) - expected) <= 8.0 * deviation + 1.0

  test "row boundaries do not bias individual edge probabilities":
    const n = 8
    const samples = 1000
    const p = 0.3
    var counts: array[n, array[n, int]]
    for seed in 1 .. samples:
      let g = fastGnpRandomGraph(n, p, int64(seed))
      for (u, v) in g.edges:
        inc counts[min(u, v)][max(u, v)]
    let expected = float(samples) * p
    let deviation = sqrt(expected * (1.0 - p))
    for u in 0 ..< n:
      for v in u + 1 ..< n:
        check abs(float(counts[u][v]) - expected) <= 8.0 * deviation + 1.0

suite "Gnm generator regressions":
  test "negative parameters are rejected before arithmetic or allocation":
    for (n, m) in [(-1, 0), (5, -1), (low(int), 0),
                   (high(int), -1), (0, low(int)), (-1, high(int))]:
      expect NimNetError:
        discard gnmRandomGraph(n, m, seed = 42)

  test "edge counts are exact and excess requests saturate":
    for n in [0, 1, 2, 5, 12]:
      let maxEdges = n * (n - 1) div 2
      for m in [0, 1, maxEdges div 2, maxEdges, maxEdges + 1, high(int)]:
        let g = gnmRandomGraph(n, m, seed = 42)
        checkSimpleGraph(g, n)
        check g.numberOfEdges() == min(m, maxEdges)

  test "nonzero seeds reproduce simple graphs with exactly m edges":
    for seed in [-17'i64, 1, 42, 987654321]:
      for m in [1, 30, 150]:
        let g = gnmRandomGraph(20, m, seed)
        checkSimpleGraph(g, 20)
        check g.numberOfEdges() == m
        check edgeSet(g) == edgeSet(gnmRandomGraph(20, m, seed))

  test "large n and small m avoid overflowing the possible edge count":
    let g = gnmRandomGraph(70000, 3, seed = 42)
    checkSimpleGraph(g, 70000)
    check g.numberOfEdges() == 3

suite "Regular generator regressions":
  test "empty zero-degree and complete graphs have exact degrees":
    for (n, d) in [(0, 0), (1, 0), (2, 0), (2, 1), (3, 0),
                   (3, 2), (10, 0), (10, 9), (25, 24)]:
      checkRegularGraph(randomRegularGraph(n, d, seed = 42), n, d)

  test "negative and impossible degree requests are rejected":
    for (n, d) in [(-1, 0), (5, -1), (low(int), 0), (0, low(int)),
                   (0, 1), (1, 1), (4, 4), (4, 7), (3, 1), (5, 3)]:
      expect NimNetError:
        discard randomRegularGraph(n, d, seed = 42)

  test "parity and capacity validation cannot overflow n times d":
    for (n, d) in [(high(int), high(int)), (high(int), 3),
                   (high(int) - 1, 2), (high(int) - 1, high(int) - 2),
                   (high(int), high(int) - 1)]:
      expect NimNetError:
        discard randomRegularGraph(n, d, seed = 42)

  test "sparse and dense seeded graphs always satisfy requested degrees":
    for seed in [-17'i64, 1, 42, 987654321]:
      for (n, d) in [(8, 1), (20, 2), (20, 3), (32, 3),
                     (20, 16), (20, 17), (8, 6), (8, 5), (32, 28)]:
        let g = randomRegularGraph(n, d, seed)
        checkRegularGraph(g, n, d)
        check edgeSet(g) == edgeSet(randomRegularGraph(n, d, seed))
    checkRegularGraph(randomRegularGraph(10, 4, seed = 42), 10, 4)

  test "dense requests are complements of sparse requests":
    for seed in [1'i64, 42, 987654321]:
      let sparse = randomRegularGraph(20, 3, seed)
      let dense = randomRegularGraph(20, 16, seed)
      checkRegularGraph(sparse, 20, 3)
      checkRegularGraph(dense, 20, 16)
      for u in 0 ..< 20:
        for v in u + 1 ..< 20:
          check sparse.hasEdge(u, v) != dense.hasEdge(u, v)

  test "exhausted pairing retries fail explicitly instead of returning empty":
    for d in [11, 12]:
      expect NimNetUnfeasible:
        discard randomRegularGraph(24, d, seed = 42)
