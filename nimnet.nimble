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
  exec "nim c -p:src --nimcache:build/nimcache/talgorithms tests/talgorithms.nim"
  exec "nim c -p:src --nimcache:build/nimcache/talgorithms2 tests/talgorithms2.nim"
  exec "nim c -p:src --nimcache:build/nimcache/talgorithms3 tests/talgorithms3.nim"

task run_tests, "Run compiled tests":
  when defined(windows):
    exec "tests\\ttypes.exe"
    exec "tests\\tgraph.exe"
    exec "tests\\tdigraph.exe"
    exec "tests\\talgorithms.exe"
    exec "tests\\talgorithms2.exe"
    exec "tests\\talgorithms3.exe"
  else:
    exec "./tests/ttypes"
    exec "./tests/tgraph"
    exec "./tests/tdigraph"
    exec "./tests/talgorithms"
    exec "./tests/talgorithms2"
    exec "./tests/talgorithms3"

task test, "Compile and run all tests":
  exec "nim c -r -p:src --nimcache:build/nimcache/ttypes tests/ttypes.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/tgraph tests/tgraph.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/tdigraph tests/tdigraph.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms tests/talgorithms.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms2 tests/talgorithms2.nim"
  exec "nim c -r -p:src --nimcache:build/nimcache/talgorithms3 tests/talgorithms3.nim"
