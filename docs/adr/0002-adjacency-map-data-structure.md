# ADR-0002: Adjacency Map Data Structure

* Status: accepted
* Date: 2026-03-29

## Context

We need to choose the internal data structure for representing graphs. The main candidates are:

1. **Adjacency map** (`Table[N, Table[N, EdgeAttr]]`) — used by Python's NetworkX
2. **Adjacency list with integer indices** (`seq[seq[int]]` or linked-list in edge array) — used by Rust's petgraph and Nim's patgraph
3. **Labeled property graph** with string-based node/edge IDs — used by Nim's grim

The library aims to be a general-purpose network science tool, prioritizing usability and flexibility over raw performance.

## Decision

We will use an **adjacency map** based on `std/tables`:

- `Graph[N]` stores `adj: Table[N, Table[N, EdgeAttr]]` for undirected graphs
- `DiGraph[N]` stores both `adj` (successors) and `pred: Table[N, Table[N, EdgeAttr]]` (predecessors)

This mirrors NetworkX's internal structure and provides:
- O(1) average node/edge lookup
- Natural support for arbitrary node types (any `N` with `hash` + `==`)
- Easy attribute access on edges
- Familiar API for NetworkX users

## Consequences

- **Positive**: Flexible, intuitive API. Supports any hashable node type. Easy to add/remove nodes and edges dynamically.
- **Negative**: Higher memory overhead than array-based approaches. Hash table operations have worse cache locality. Not optimal for algorithms on very large graphs (millions of edges).
- **Mitigation**: For performance-critical use cases, we can later add a compact backend or integrate with array-based representations.
