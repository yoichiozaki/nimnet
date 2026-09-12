import std/[algorithm, os, strutils]

# Package
version       = "1.0.0"
author        = "yoichiozaki"
description   = "A comprehensive network science library for Nim, inspired by NetworkX"
license       = "MIT"
srcDir        = "src"
# homepage: https://github.com/yoichiozaki/nimnet
skipDirs      = @["benchmarks", "docs", "build", "examples", ".github", "tests", "tools"]

# Dependencies
requires "nim >= 2.0.0"
requires "malebolgia >= 1.3.0"

let projectRoot = thisDir()

proc selectedTests(): seq[string] =
  var available: seq[string]
  for path in listFiles(projectRoot / "tests"):
    let name = extractFilename(path)
    if name.startsWith("t") and name.endsWith(".nim"):
      available.add(path)
  available.sort()
  if available.len == 0:
    raise newException(ValueError, "No tests/t*.nim files found")

  let selection = getEnv("NIMNET_TESTS")
  if selection.len == 0:
    return available
  let names = selection.split(',')
  for name in names:
    var found = false
    for path in available:
      if splitFile(path).name == name.strip():
        found = true
    if not found:
      raise newException(ValueError, "Unknown test in NIMNET_TESTS: " & name)
  for path in available:
    for name in names:
      if splitFile(path).name == name.strip():
        result.add(path)
        break

proc testExecutable(path: string, coverage = false): string =
  let dir = if coverage: "coverage_tests" else: "tests"
  result = projectRoot / "build" / dir / splitFile(path).name
  when defined(windows):
    result.add(".exe")

proc compileTests(run = false, coverage = false) =
  for path in selectedTests():
    let output = testExecutable(path, coverage)
    mkDir(parentDir(output))
    let cacheDir = if coverage: "nimcache_cov" else: "nimcache"
    let cache = projectRoot / "build" / cacheDir / splitFile(path).name
    var command = "nim c --threads:on --hints:off"
    if run:
      command.add(" -r")
    if coverage:
      command.add(" --lineDir:on --passC:--coverage --passL:--coverage")
    command.add(" " & quoteShell("-p:" & (projectRoot / "src")))
    command.add(" " & quoteShell("--nimcache:" & cache))
    command.add(" " & quoteShell("-o:" & output))
    command.add(" " & quoteShell(path))
    exec command

task list_tests, "List the sorted test inventory (NIMNET_TESTS optionally filters names)":
  for path in selectedTests():
    echo relativePath(path, projectRoot)

task build_tests, "Compile every discovered test":
  compileTests()

task run_tests, "Run every discovered, previously compiled test":
  for path in selectedTests():
    let executable = testExecutable(path)
    if not fileExists(executable):
      raise newException(ValueError, "Missing test executable; run nimble build_tests: " & executable)
    exec quoteShell(executable)

task test, "Compile and run every discovered test":
  compileTests(run = true)

task coverage_tests, "Compile and run every test with GCC coverage and Nim source line mapping":
  compileTests(run = true, coverage = true)

task docs, "Build API documentation, rejecting compiler and markup diagnostics":
  let script = quoteShell(projectRoot / "tools" / "build_docs.py")
  when defined(windows):
    # Python may be a batch-file shim rather than a directly executable binary.
    let command = quoteShell(getEnv("COMSPEC", "cmd.exe")) & " /d /c python " & script
    exec command
  else:
    exec "python3 " & script

task cleanup, "Remove compiled executables":
  exec "nim e --hints:off " & quoteShell(projectRoot / "tools" / "clean.nims")
