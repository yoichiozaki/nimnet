# NimNet Agents

## Explore
Use the `Explore` agent for codebase navigation and understanding:
- Finding where a type is defined
- Understanding how algorithms use graph types
- Checking test coverage for a module
- Tracing import dependencies across modules

## DataAnalysisExpert
Use for analyzing benchmark results and performance data.

## Common Tasks by Agent

### Adding a new algorithm
Use **default agent** — it handles creating the module, wiring exports, writing tests, and committing.

### Investigating compilation errors
Use **Explore** to trace import chains and find where types/procs are defined.
Common errors:
- `undeclared identifier` — wrong import path or using nonexistent API (e.g. `getEdgeData` vs `getEdgeAttr`)
- `cannot open` — import path mismatch between `../types` (algorithms/) vs `./types` (top-level)
- `ambiguous call` — naming collision between modules, qualify with module prefix
