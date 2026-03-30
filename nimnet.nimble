# Package
version       = "1.0.0"
author        = "yoichiozaki"
description   = "A comprehensive network science library for Nim, inspired by NetworkX"
license       = "MIT"
srcDir        = "src"
# homepage: https://github.com/yoichiozaki/nimnet
skipDirs      = @["benchmarks", "docs", "build", "examples", ".github"]

# Dependencies
requires "nim >= 2.0.0"
requires "malebolgia >= 1.3.0"

task build_tests, "Compile all tests":
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/ttypes tests/ttypes.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/tgraph tests/tgraph.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/tdigraph tests/tdigraph.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/talgorithms_core tests/talgorithms_core.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/talgorithms_io_gen tests/talgorithms_io_gen.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/talgorithms_extended tests/talgorithms_extended.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/talgorithms_advanced tests/talgorithms_advanced.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/tcrossvalidation tests/tcrossvalidation.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/talgorithms_features tests/talgorithms_features.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/talgorithms_batch2 tests/talgorithms_batch2.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/talgorithms_batch3 tests/talgorithms_batch3.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/tcoverage tests/tcoverage.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/tcoverage2 tests/tcoverage2.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/tparallel tests/tparallel.nim"
  exec "nim c --threads:on -p:src --nimcache:build/nimcache/tcoverage3 tests/tcoverage3.nim"

task run_tests, "Run compiled tests":
  when defined(windows):
    exec "tests\\ttypes.exe"
    exec "tests\\tgraph.exe"
    exec "tests\\tdigraph.exe"
    exec "tests\\talgorithms_core.exe"
    exec "tests\\talgorithms_io_gen.exe"
    exec "tests\\talgorithms_extended.exe"
    exec "tests\\talgorithms_advanced.exe"
    exec "tests\\tcrossvalidation.exe"
    exec "tests\\talgorithms_features.exe"
    exec "tests\\talgorithms_batch2.exe"
    exec "tests\\talgorithms_batch3.exe"
    exec "tests\\tcoverage.exe"
    exec "tests\\tcoverage2.exe"
    exec "tests\\tparallel.exe"
    exec "tests\\tcoverage3.exe"
  else:
    exec "./tests/ttypes"
    exec "./tests/tgraph"
    exec "./tests/tdigraph"
    exec "./tests/talgorithms_core"
    exec "./tests/talgorithms_io_gen"
    exec "./tests/talgorithms_extended"
    exec "./tests/talgorithms_advanced"
    exec "./tests/tcrossvalidation"
    exec "./tests/talgorithms_features"
    exec "./tests/talgorithms_batch2"
    exec "./tests/talgorithms_batch3"
    exec "./tests/tcoverage"
    exec "./tests/tcoverage2"
    exec "./tests/tparallel"
    exec "./tests/tcoverage3"

task test, "Compile and run all tests":
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/ttypes tests/ttypes.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tgraph tests/tgraph.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tdigraph tests/tdigraph.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/talgorithms_core tests/talgorithms_core.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/talgorithms_io_gen tests/talgorithms_io_gen.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/talgorithms_extended tests/talgorithms_extended.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/talgorithms_advanced tests/talgorithms_advanced.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tcrossvalidation tests/tcrossvalidation.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/talgorithms_features tests/talgorithms_features.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/talgorithms_batch2 tests/talgorithms_batch2.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/talgorithms_batch3 tests/talgorithms_batch3.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tcoverage tests/tcoverage.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tcoverage2 tests/tcoverage2.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tparallel tests/tparallel.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tcoverage3 tests/tcoverage3.nim"
  exec "nim c -r --threads:on -p:src --nimcache:build/nimcache/tnewfeatures3 tests/tnewfeatures3.nim"

task cleanup, "Remove compiled exe files and build artifacts":
  let root = thisDir()
  for dir in ["tests", "examples", "build", "src"]:
    let full = root & "/" & dir
    if dirExists(full):
      for f in listFiles(full):
        if f[^4 .. ^1] == ".exe":
          rmFile(f)
  for f in listFiles(root):
    if f.len > 4 and f[^4 .. ^1] == ".exe":
      rmFile(f)
