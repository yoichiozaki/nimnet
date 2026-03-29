# ADR-0005: Module Structure

* Status: accepted
* Date: 2026-03-29

## Context

We need to organize the source code in a way that is:
- Easy to navigate for contributors
- Follows Nim conventions for library packages
- Allows users to import the full API or specific submodules

## Decision

```
src/
├── nimnet.nim              # Main entry point — re-exports all public API
└── nimnet/
    ├── types.nim           # Core types, exceptions
    ├── graph.nim           # Undirected Graph[N]
    ├── digraph.nim         # Directed DiGraph[N]
    ├── algorithms/         # Algorithm submodules
    │   ├── traversal.nim
    │   ├── shortest_paths.nim
    │   ├── centrality.nim
    │   └── ...
    ├── generators/         # Graph generators
    │   ├── classic.nim
    │   ├── random.nim
    │   └── ...
    ├── operators.nim       # Graph operations
    ├── io/                 # I/O formats
    │   ├── edgelist.nim
    │   └── ...
    └── convert.nim         # Type conversions
```

Users can either:
- `import nimnet` — gets everything
- `import nimnet/graph` — gets just the undirected graph
- `import nimnet/algorithms/traversal` — gets just BFS/DFS

## Consequences

- **Positive**: Clean separation of concerns. Users can cherry-pick modules. Standard Nim library layout.
- **Negative**: More files to maintain. Re-export list in `nimnet.nim` must be kept in sync.
