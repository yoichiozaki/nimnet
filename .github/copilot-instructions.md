# NimNet — Copilot Instructions

## Project Overview
NimNet is a network science library for Nim, inspired by Python's NetworkX.
It provides graph data structures (Graph, DiGraph) with adjacency map internals,
standard graph algorithms, generators, and I/O.

## Architecture
- **ADRs**: Design decisions are in `docs/adr/`. Read them before making architectural changes.
- **Data structure**: Adjacency map (`Table[N, Table[N, EdgeAttr]]`). See ADR-0002.
- **Generic nodes**: `Graph[N]` where `N` must satisfy `hash` + `==`. See ADR-0003.
- **Edge attributes**: `Table[string, string]`. Weight accessor: `weight(g, u, v)`.
- **Module layout**: `src/nimnet.nim` re-exports all; submodules in `src/nimnet/`. See ADR-0005.

## Nim Coding Conventions (NEP-1)
- Types: `PascalCase` — `Graph`, `NodeAttr`, `EdgeAttr`
- Procs/vars: `camelCase` — `addNode`, `shortestPath`, `nodeCount`
- Constructors: `initFoo` (value types), `newFoo` (ref types)
- Export public API with `*` suffix: `proc addNode*[N](...)`
- Use `func` for side-effect-free procs
- Prefer `std/tables`, `std/sets`, `std/deques`, `std/heapqueue` from stdlib
- Iterators: inline by default, `{.closure.}` only when needed

## File Organization
```
src/nimnet.nim           → Main re-export module
src/nimnet/types.nim     → Core types, exceptions
src/nimnet/graph.nim     → Undirected Graph[N]
src/nimnet/digraph.nim   → Directed DiGraph[N]
src/nimnet/algorithms/   → Algorithm submodules
src/nimnet/generators/   → Graph generator submodules
src/nimnet/operators.nim → Graph operations
src/nimnet/io/           → I/O format submodules
src/nimnet/convert.nim   → Type conversions
tests/t*.nim             → Test files (one per source module)
```

## Testing
- Framework: `std/unittest` (see ADR-0004)
- Test files: `tests/t<module>.nim` with `t` prefix
- Run: `nimble test`
- Every public proc MUST have corresponding tests
- Use `suite` and `test` blocks, `check` for assertions, `expect` for exceptions

## Common Patterns

### Adding a new algorithm module
1. Create `src/nimnet/algorithms/<name>.nim`
2. Import `../types`, `../graph`, `../digraph` as needed
3. Export procs with `*`
4. Add `import nimnet/algorithms/<name>` and `export <name>` to `src/nimnet.nim`
5. Create `tests/t<name>.nim` with comprehensive tests
6. Update CHANGELOG.md

### Adding a new graph generator
1. Create `src/nimnet/generators/<name>.nim`
2. Return `Graph[int]` or `Graph[N]` from generator procs
3. Add to `src/nimnet.nim` exports
4. Create tests in `tests/tgenerators.nim` or dedicated file

## Error Handling
- Use the exception hierarchy from `types.nim`:
  - `NimNetError` → base
  - `NodeNotFound` → node lookup failures
  - `EdgeNotFound` → edge lookup failures
  - `NimNetNoPath` → no path between nodes
  - `HasACycle` → unexpected cycle
  - `NimNetUnfeasible` → algorithm infeasible

## CI
- GitHub Actions: `.github/workflows/ci.yml`
- Matrix: ubuntu-latest, macos-latest, windows-latest
- Uses `nim-lang/setup-nimble-action@v1`

## Commit Message Format
- `feat: <description>` — new feature
- `fix: <description>` — bug fix
- `test: <description>` — test additions
- `docs: <description>` — documentation
- `refactor: <description>` — code refactoring
- `chore: <description>` — maintenance
