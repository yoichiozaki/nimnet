## Shared input validation and elapsed-time measurement for benchmarks.

import std/[algorithm, json, monotimes, os, sets, strutils, times]

type
  BenchSize* = tuple[name: string, nodes, edges: int]
  FixtureEdge* = tuple[u, v, weightMillis: int]
  Fixture* = object
    size*: BenchSize
    edges*: seq[FixtureEdge]

const benchmarkSizes* = [
  ("small", 100, 500),
  ("medium", 1_000, 5_000),
  ("large", 10_000, 50_000)
]

proc benchmarkRuns*(default = 5): int =
  result = parseInt(getEnv("BENCH_RUNS", $default))
  if result < 1:
    raise newException(ValueError, "BENCH_RUNS must be positive")

proc selectedSizes*(): seq[BenchSize] =
  var names: seq[string]
  for name in getEnv("BENCH_SIZES", "small,medium,large").split(','):
    names.add(name.strip())
  for name in names:
    var found = false
    for size in benchmarkSizes:
      if name == size[0]:
        found = true
    if not found:
      raise newException(ValueError, "Unknown BENCH_SIZES entry: " & name)
  for size in benchmarkSizes:
    if size[0] in names:
      result.add(size)

proc loadFixture*(path: string, size: BenchSize): Fixture =
  let data = parseJson(readFile(path))
  if data.kind != JObject or
      not data.hasKey("format_version") or data["format_version"].kind != JInt or
      data["format_version"].getInt() != 1 or
      not data.hasKey("name") or data["name"].kind != JString or
      data["name"].getStr() != size.name or
      not data.hasKey("nodes") or data["nodes"].kind != JInt or
      data["nodes"].getInt() != size.nodes or
      not data.hasKey("edges") or data["edges"].kind != JArray or
      data["edges"].len != size.edges:
    raise newException(ValueError, "Invalid fixture metadata: " & path)
  result.size = size
  var seen = initHashSet[(int, int)]()
  for edge in data["edges"]:
    if edge.kind != JArray or edge.len != 3 or
        edge[0].kind != JInt or edge[1].kind != JInt or edge[2].kind != JInt:
      raise newException(ValueError, "Invalid fixture edge: " & path)
    let u = edge[0].getInt()
    let v = edge[1].getInt()
    let weight = edge[2].getInt()
    if u < 0 or u >= v or v >= size.nodes or weight < 1000 or weight > 10000 or
        (u, v) in seen:
      raise newException(ValueError, "Invalid/duplicate fixture edge: " & path)
    seen.incl((u, v))
    result.edges.add((u, v, weight))

proc loadFixtures*(): seq[Fixture] =
  let directory = getEnv("BENCH_FIXTURES",
    currentSourcePath().parentDir / "results" / "fixtures")
  for size in selectedSizes():
    result.add(loadFixture(directory / (size.name & ".json"), size))

proc queryPairs*(n: int): seq[(int, int)] =
  if n <= 0:
    raise newException(ValueError, "Query node count must be positive")
  for i in 0 ..< n * 5:
    result.add((i mod n, (i * 17 + 31) mod n))

template medianTime*(runs: int, body: untyped): float =
  block:
    let count = runs
    if count < 1:
      raise newException(ValueError, "Benchmark run count must be positive")
    body
    var samples: seq[float]
    for run in 0 ..< count:
      let start = getMonoTime()
      body
      samples.add((getMonoTime() - start).inNanoseconds.float / 1e9)
    samples.sort()
    if samples.len mod 2 == 0:
      (samples[samples.len div 2 - 1] + samples[samples.len div 2]) / 2.0
    else:
      samples[samples.len div 2]
