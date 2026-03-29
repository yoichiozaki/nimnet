# Package
version       = "0.1.0"
author        = "yoichiozaki"
description   = "A comprehensive network science library for Nim, inspired by NetworkX"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"

task test, "Run all tests":
  exec "nim c -r -p:src tests/ttypes.nim"
  exec "nim c -r -p:src tests/tgraph.nim"
  exec "nim c -r -p:src tests/tdigraph.nim"
