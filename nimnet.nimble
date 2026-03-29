# Package
version       = "0.1.0"
author        = "yoichiozaki"
description   = "A comprehensive network science library for Nim, inspired by NetworkX"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"

task build_tests, "Compile all tests":
  exec "nim c -p:src --nimcache:build/nimcache/ttypes tests/ttypes.nim"
  exec "nim c -p:src --nimcache:build/nimcache/tgraph tests/tgraph.nim"
  exec "nim c -p:src --nimcache:build/nimcache/tdigraph tests/tdigraph.nim"
  exec "nim c -p:src --nimcache:build/nimcache/talgorithms_core tests/talgorithms_core.nim"
  exec "nim c -p:src --nimcache:build/nimcache/talgorithms_io_gen tests/talgorithms_io_gen.nim"
  exec "nim c -p:src --nimcache:build/nimcache/talgorithms_extended tests/talgorithms_extended.nim"
  exec "nim c -p:src --nimcache:build/nimcache/talgorithms_networkx tests/talgorithms_networkx.nim"
  exec "nim c -p:src --nimcache:build/nimcache/tcrossvalidation tests/tcrossvalidation.nim"

task run_tests, "Run compiled tests":
  when defined(windows):
    exec "tests\\ttypes.exe"
    exec "tests\\tgraph.exe"
    exec "tests\\tdigraph.exe"
    exec "tests\\talgorithms_core.exe"
    exec "tests\\talgorithms_io_gen.exe"
    exec "tests\\talgorithms_extended.exe"
    exec "tests\\talgorithms_networkx.exe"
    exec "tests\\tcrossvalidation.exe"
  else:
    exec "./tests/ttypes"
    exec "./tests/tgraph"
    exec "./tests/tdigraph"
    exec "./tests/talgorithms_core"
    exec "./tests/talgorithms_io_gen"
    exec "./tests/talgorithms_extended"
    exec "./tests/talgorithms_networkx"
    exec "./tests/tcrossvalidation"

task test, "Compile and run all tests":
  exec "nim c -r -p:src --nimcache:build/nimcache/ttypes tests/ttypes.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/tgraph tests/tgraph.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/tdigraph tests/tdigraph.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms_core tests/talgorithms_core.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms_io_gen tests/talgorithms_io_gen.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms_extended tests/talgorithms_extended.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms_networkx tests/talgorithms_networkx.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/tcrossvalidation tests/tcrossvalidation.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms_features tests/talgorithms_features.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms_batch2 tests/talgorithms_batch2.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms_batch3 tests/talgorithms_batch3.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/tcoverage tests/tcoverage.nim"
