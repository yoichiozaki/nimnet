# Contributing to NimNet

Thank you for your interest in contributing to NimNet!

## Getting Started

1. Fork and clone the repository
2. Install Nim >= 2.0.0: https://nim-lang.org/install.html
3. Set up git hooks: `git config core.hooksPath .githooks`
4. Run `nimble test` to verify your setup
5. After testing, clean up compiled files: `nimble cleanup`

## Development Workflow

1. Check existing [Issues](https://github.com/yoichiozaki/nimnet/issues) or create a new one
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Write code and tests
4. Run `nimble test` to ensure all tests pass
5. Submit a Pull Request referencing the issue

## Code Style

Follow [NEP-1](https://nim-lang.org/docs/nep1.html) naming conventions:

- **Types**: `PascalCase` — `Graph`, `DiGraph`, `EdgeAttr`
- **Procs/funcs**: `camelCase` — `addNode`, `shortestPath`, `numberOfEdges`
- **Constructors**: `newFoo` (ref types), `initFoo` (value types)
- **Export**: Public API uses `*` suffix — `proc addNode*[N](...)`
- Use `func` for side-effect-free procedures
- Prefer stdlib: `std/tables`, `std/sets`, `std/deques`, `std/heapqueue`

## Adding a New Algorithm

1. Create `src/nimnet/algorithms/<name>.nim`
2. Import types: `import ../types`, `import ../graph`, `import ../digraph`
3. Export all public procs with `*`
4. Register in `src/nimnet.nim`: `import nimnet/algorithms/<name>; export <name>`
5. Add tests to the appropriate `tests/talgorithms_*.nim` file
6. Update `CHANGELOG.md`

### Import path rules
- Files in `src/nimnet/algorithms/` → `../types`, `../graph`, `../digraph`
- Files in `src/nimnet/` (top-level) → `./types`, `./graph`, `./digraph`

## Error Handling

Use the exception hierarchy from `types.nim`:
- `NimNetError` → base
- `NodeNotFound` → node lookup failures
- `EdgeNotFound` → edge lookup failures
- `NimNetNoPath` → no path between nodes
- `HasACycle` → unexpected cycle
- `NimNetUnfeasible` → algorithm infeasible

## Testing

```bash
nimble test
```

- **Framework**: `std/unittest`
- **Test files**: `tests/t<name>.nim`
- **Every public proc must have corresponding tests**
- Use `suite` + `test` blocks with `check` assertions, `expect` for exceptions

All `tests/t*.nim` files are discovered in sorted order by the same runner.
`nimble list_tests` shows the inventory; `nimble build_tests` and
`nimble run_tests` split compilation and execution without changing that list.
Executables are written to `build/tests`, not beside their source files.

For a focused run in PowerShell:

```powershell
$env:NIMNET_TESTS = "tgraph,tdigraph"
nimble test
Remove-Item Env:NIMNET_TESTS
```

On Linux/macOS, use `NIMNET_TESTS=tgraph,tdigraph nimble test`. Unknown test
names fail explicitly. Run benchmark/coverage helper tests with
`python -m unittest discover -s tests -p test_tooling.py`.
`nimble coverage_tests` uses the same inventory with GCC coverage and Nim source
line mapping. CI covers stable Nim on three platforms and Nim 2.0.0 on Linux.
`nimble docs` generates API documentation in `build/docs` and rejects markup
diagnostics even on Nim versions that report them with a zero exit code.
Documentation and tooling commands require Python; library use does not.

Performance changes should include an identical-input baseline, release-mode
elapsed-time measurements with warmup and repeated samples, and correctness
checks. Do not run competing benchmarks concurrently or disable assertions.
See [the benchmark methodology](benchmarks/README.md) and
[the current improvement backlog](docs/backlog.md).

## Architecture Decisions

Significant design decisions are recorded as ADRs in `docs/adr/`. If your change involves an architectural decision, please create a new ADR using the template at `docs/adr/0000-template.md`.

## Commit Messages

Use [conventional commits](https://www.conventionalcommits.org/):
- `feat: add Dijkstra's shortest path algorithm`
- `fix: correct edge removal in undirected graph`
- `test: add tests for BFS traversal`
- `docs: update API documentation`
- `refactor: simplify adjacency map iteration`
- `chore: update CI configuration`

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
