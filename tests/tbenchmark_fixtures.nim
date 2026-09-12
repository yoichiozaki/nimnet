import std/[json, os, tempfiles, unittest]
import ../benchmarks/bench_common

suite "Shared benchmark fixtures":
  test "loads exactly the declared nodes, edges and integer weights":
    let (file, path) = createTempFile("nimnet-benchmark-", ".json")
    file.close()
    defer: removeFile(path)
    writeFile(path, """{"format_version":1,"name":"tiny","nodes":4,
      "edges":[[0,1,1000],[1,2,2750]]}""")
    let fixture = loadFixture(path, ("tiny", 4, 2))
    check fixture.size.nodes == 4
    check fixture.edges == @[(0, 1, 1000), (1, 2, 2750)]

  test "rejects malformed metadata, edges, duplicates and graph kinds":
    let (file, path) = createTempFile("nimnet-benchmark-invalid-", ".json")
    file.close()
    defer: removeFile(path)
    let valid = parseJson("""{"format_version":1,"name":"tiny","nodes":3,
      "edges":[[0,1,1000],[1,2,2000]]}""")
    for invalid in [
      """{"format_version":2,"name":"tiny","nodes":3,"edges":[]}""",
      """{"format_version":1,"name":"tiny","nodes":3,"edges":[[0,1,1000],[0,1,1000]]}""",
      """{"format_version":1,"name":"tiny","nodes":3,"edges":[[0,0,1000],[1,2,2000]]}""",
      """{"format_version":1,"name":"tiny","nodes":3,"edges":[[0,3,1000],[1,2,2000]]}""",
      """{"format_version":1,"name":"tiny","nodes":3,"edges":[[0,1,1],[1,2,2000]]}""",
      """{"format_version":1,"name":"tiny","nodes":3,"edges":[[0,1,1.5],[1,2,2000]]}""",
      """{"format_version":1,"name":"tiny","nodes":3,"edges":[[0,1],[1,2,2000]]}""",
      """[]"""
    ]:
      writeFile(path, invalid)
      expect ValueError:
        discard loadFixture(path, ("tiny", 3, 2))
    writeFile(path, $valid)
    expect ValueError:
      discard loadFixture(path, ("different", 3, 2))

  test "timing performs one warmup plus exactly the requested runs":
    var calls = 0
    let elapsed = medianTime(2):
      inc calls
    check calls == 3
    check elapsed >= 0.0
    expect ValueError:
      discard medianTime(0):
        inc calls

  test "lookup queries have the same deterministic sequence as Python":
    let pairs = queryPairs(5)
    check pairs.len == 25
    let expected = @[(0, 1), (1, 3), (2, 0), (3, 2), (4, 4)]
    for i, pair in pairs:
      check pair == expected[i mod 5]
    expect ValueError:
      discard queryPairs(0)
    expect ValueError:
      discard queryPairs(-1)

  test "repeated measurements isolate declarations in their bodies":
    var total = 0
    let first = medianTime(1):
      let distances = @[1, 2]
      total += distances.len
    let second = medianTime(1):
      let distances = @[3, 4, 5]
      total += distances.len
    check total == 10
    check first >= 0.0 and second >= 0.0
