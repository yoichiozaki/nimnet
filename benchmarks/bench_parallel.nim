## Benchmarks: Sequential vs Parallel Algorithm Performance
##
## Compares wall-clock time of sequential and parallel implementations
## across various graph sizes.
##
## Compile: nim c -d:release --threads:on benchmarks/bench_parallel.nim
## Run: benchmarks/bench_parallel

import std/[times, tables, math, strformat, strutils, cpuinfo, monotimes]
import nimnet
import nimnet/algorithms/parallel as par
import nimnet/generators/random as rng

# ---------------------------------------------------------------------------
# Timing helpers
# ---------------------------------------------------------------------------

type BenchResult = object
  name: string
  nodes: int
  edges: int
  seqMs: float
  parMs: float
  speedup: float

proc fmtMs(ms: float): string =
  if ms < 1.0:
    &"{ms * 1000.0:.1f} µs"
  elif ms < 1000.0:
    &"{ms:.2f} ms"
  else:
    &"{ms / 1000.0:.2f} s"

proc timeIt(body: proc()): float =
  ## Returns elapsed milliseconds using monotonic clock.
  let t0 = getMonoTime()
  body()
  let elapsed = getMonoTime() - t0
  result = elapsed.inNanoseconds.float / 1_000_000.0

# ---------------------------------------------------------------------------
# Graph builders
# ---------------------------------------------------------------------------

proc makeUndirected(n: int, p: float): Graph[int] =
  result = rng.erdosRenyiGraph(n, p, seed = 42)

proc makeDirected(n: int, p: float): DiGraph[int] =
  let ug = rng.erdosRenyiGraph(n, p, seed = 42)
  result = newDiGraph[int]()
  for u in ug.nodes():
    result.addNode(u)
  for (u, v) in ug.edges():
    result.addEdge(u, v)
    result.addEdge(v, u)

# ---------------------------------------------------------------------------
# Individual benchmarks
# ---------------------------------------------------------------------------

proc benchBetweenness(g: Graph[int]): BenchResult =
  result.name = "Betweenness Centrality"
  result.nodes = g.numberOfNodes
  result.edges = g.numberOfEdges
  result.seqMs = timeIt(proc() = discard betweennessCentrality(g))
  result.parMs = timeIt(proc() = discard par.parallelBetweennessCentrality(g))
  result.speedup = result.seqMs / result.parMs

proc benchCloseness(g: Graph[int]): BenchResult =
  result.name = "Closeness Centrality"
  result.nodes = g.numberOfNodes
  result.edges = g.numberOfEdges
  result.seqMs = timeIt(proc() = discard closenessCentrality(g))
  result.parMs = timeIt(proc() = discard par.parallelClosenessCentrality(g))
  result.speedup = result.seqMs / result.parMs

proc benchClustering(g: Graph[int]): BenchResult =
  result.name = "Clustering Coefficient"
  result.nodes = g.numberOfNodes
  result.edges = g.numberOfEdges
  result.seqMs = timeIt(proc() = discard clustering(g))
  result.parMs = timeIt(proc() = discard par.parallelClustering(g))
  result.speedup = result.seqMs / result.parMs

proc benchPageRankUndirected(g: Graph[int]): BenchResult =
  result.name = "PageRank (undirected)"
  result.nodes = g.numberOfNodes
  result.edges = g.numberOfEdges
  result.seqMs = timeIt(proc() = discard pageRank(g))
  result.parMs = timeIt(proc() = discard par.parallelPageRank(g))
  result.speedup = result.seqMs / result.parMs

proc benchPageRankDirected(dg: DiGraph[int]): BenchResult =
  result.name = "PageRank (directed)"
  result.nodes = dg.numberOfNodes
  result.edges = dg.numberOfEdges
  result.seqMs = timeIt(proc() = discard pageRank(dg))
  result.parMs = timeIt(proc() = discard par.parallelPageRank(dg))
  result.speedup = result.seqMs / result.parMs

proc benchJohnsons(dg: DiGraph[int]): BenchResult =
  result.name = "Johnson's APSP"
  result.nodes = dg.numberOfNodes
  result.edges = dg.numberOfEdges
  result.seqMs = timeIt(proc() = discard johnsons(dg))
  result.parMs = timeIt(proc() = discard par.parallelJohnsons(dg))
  result.speedup = result.seqMs / result.parMs

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

proc printHeader() =
  echo "=" .repeat(80)
  echo "  NimNet Benchmark: Sequential vs Parallel"
  echo "  Compiled with: --threads:on -d:release"
  echo &"  CPUs available: {countProcessors()}"
  echo "=" .repeat(80)
  echo ""

proc printResult(r: BenchResult) =
  let arrow = if r.speedup >= 1.0: "↑" else: "↓"
  echo &"  {r.name:<28} | N={r.nodes:<5} E={r.edges:<6} | seq={fmtMs(r.seqMs):>10} | par={fmtMs(r.parMs):>10} | {r.speedup:.2f}x {arrow}"

proc printSectionHeader(title: string) =
  echo ""
  echo &"--- {title} " & "-".repeat(max(0, 74 - title.len))

proc main() =
  printHeader()

  var allResults: seq[BenchResult]

  # Test multiple graph sizes
  let sizes = @[
    (50, 0.3),    # small: ~375 edges
    (100, 0.2),   # medium: ~990 edges
    (200, 0.15),  # larger: ~2985 edges
    (400, 0.08),  # large: ~6384 edges
  ]

  for (n, p) in sizes:
    let g = makeUndirected(n, p)
    let dg = makeDirected(n, p)

    printSectionHeader(&"Graph size: N={n}, p={p:.2f} (E≈{g.numberOfEdges})")

    var r: BenchResult

    r = benchBetweenness(g)
    printResult(r)
    allResults.add(r)

    r = benchCloseness(g)
    printResult(r)
    allResults.add(r)

    r = benchClustering(g)
    printResult(r)
    allResults.add(r)

    r = benchPageRankUndirected(g)
    printResult(r)
    allResults.add(r)

    r = benchPageRankDirected(dg)
    printResult(r)
    allResults.add(r)

    # Johnson's is O(V²·logV + V·E), skip for large graphs
    if n <= 200:
      r = benchJohnsons(dg)
      printResult(r)
      allResults.add(r)

  # Summary
  echo ""
  echo "=" .repeat(80)
  echo "  Summary"
  echo "=" .repeat(80)

  var totalSpeedup = 0.0
  var count = 0
  var cntFaster = 0
  var cntSlower = 0
  for r in allResults:
    totalSpeedup += r.speedup
    count += 1
    if r.speedup >= 1.0:
      cntFaster += 1
    else:
      cntSlower += 1

  let avgSpeedup = totalSpeedup / count.float
  echo &"  Benchmarks run: {count}"
  echo &"  Parallel faster: {cntFaster} / {count}"
  echo &"  Average speedup: {avgSpeedup:.2f}x"

  # Find best and worst
  var best = allResults[0]
  var worst = allResults[0]
  for r in allResults:
    if r.speedup > best.speedup:
      best = r
    if r.speedup < worst.speedup:
      worst = r

  echo &"  Best speedup:  {best.speedup:.2f}x — {best.name} (N={best.nodes})"
  echo &"  Worst speedup: {worst.speedup:.2f}x — {worst.name} (N={worst.nodes})"
  echo ""

main()
