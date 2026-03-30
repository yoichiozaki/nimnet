# NimNet — Copilot Instructions

## Project Overview
NimNet is a network science library for Nim, inspired by Python's NetworkX.
It provides graph data structures (Graph, DiGraph) with adjacency map internals,
61 algorithm modules, 21 generator modules, 13 I/O formats, a builder DSL,
built-in datasets, and graph operators.

## Architecture
- **ADRs**: Design decisions are in `docs/adr/`. Read them before making architectural changes.
- **Data structure**: Adjacency map (`Table[N, Table[N, EdgeAttr]]`). See ADR-0002.
- **Generic nodes**: `Graph[N]` where `N` must satisfy `hash` + `==`. See ADR-0003.
- **Edge attributes**: `Table[string, string]`. Weight accessor: `getWeight(attr, default=1.0)`.
- **Module layout**: `src/nimnet.nim` re-exports all; submodules in `src/nimnet/`. See ADR-0005.

## Key API Reference

### Attribute Access (common pitfall)
```nim
# Edge attributes — use getEdgeAttr or subscript operator
let attr = g.getEdgeAttr(u, v)   # returns EdgeAttr (Table[string, string])
let attr = g[u, v]               # same thing, subscript sugar

# Node attributes
let attr = g.getNodeAttr(n)      # returns NodeAttr (Table[string, string])

# Weight extraction from EdgeAttr
let w = attr.getWeight()          # default 1.0
let w = attr.getWeight(default=0.0)

# Setting weight
g.addWeightedEdge(u, v, 2.5)     # convenience proc
var attr: EdgeAttr
attr.weight = 3.0                 # setter sugar via weight=

# WRONG — these do NOT exist:
# g.getEdgeData(u, v)   ← does not exist, use getEdgeAttr
# g.getNodeData(n)      ← does not exist, use getNodeAttr
```

### Graph Construction
```nim
var g = newGraph[int]()           # undirected
var dg = newDiGraph[int]()        # directed
g.addNode(1)
g.addEdge(1, 2)                   # auto-adds nodes
g.addWeightedEdge(1, 2, 3.5)
g.addEdgesFrom([(1,2), (2,3)])
```

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
src/nimnet.nim               → Main re-export module
src/nimnet/types.nim         → Core types (EdgeAttr, NodeAttr), exceptions
src/nimnet/graph.nim         → Undirected Graph[N]
src/nimnet/digraph.nim       → Directed DiGraph[N]
src/nimnet/algorithms/       → 61 algorithm submodules
  traversal.nim              → BFS, DFS
  shortest_paths.nim         → Dijkstra, Bellman-Ford, A*
  components.nim             → Connected/strongly connected components
  centrality.nim             → Degree, closeness, PageRank, eigenvector, Katz, HITS
  clustering.nim             → Clustering coefficient, transitivity, triangles
  community.nim              → Greedy modularity community detection
  louvain.nim                → Louvain community detection
  leiden.nim                 → Leiden community detection
  mst.nim                    → Kruskal, Prim MST
  dag.nim                    → Topological sort, DAG operations
  flow.nim                   → Edmonds-Karp max flow, min cut
  all_pairs_shortest.nim     → Floyd-Warshall, Johnson's algorithm
  connectivity.nim           → Node/edge connectivity, resilience
  isomorphism.nim            → VF2 graph isomorphism
  planarity.nim              → Planarity testing (simplified)
  tsp.nim                    → TSP heuristics (nearest neighbor, greedy, 2-opt)
  min_cost_flow.nim          → Minimum cost flow
  tree_decomposition.nim     → Treewidth upper bound
  properties.nim             → isTree, isForest, isRegular, isComplete, girth
  link_prediction.nim        → Common neighbors, Jaccard, Adamic-Adar
  core.nim                   → k-core decomposition
  stats.nim                  → Degree histogram, assortativity
  clique.nim                 → Bron-Kerbosch clique enumeration
  independent_set.nim        → Maximum independent set, vertex cover
  dominating.nim             → Minimum dominating set
  coloring.nim               → Greedy graph coloring
  bipartite.nim              → Bipartiteness, maximum matching
  euler.nim                  → Eulerian circuits/paths, Hamiltonian detection
  bridges.nim                → Bridges, articulation points, biconnected components
  ego.nim                    → Ego graph extraction
  distance_measures.nim      → Diameter, radius, center, periphery, eccentricity
  simple_paths.nim           → All simple paths enumeration
  efficiency.nim             → Global/local efficiency measures
  richclub.nim               → Rich-club coefficient
  wiener.nim                 → Wiener index
  cycles.nim                 → Cycle basis, simple cycles (directed)
  matching.nim               → Maximal/max-weight/min-weight matching
  graph_products.nim         → Cartesian, tensor, strong, lexicographic product
  smallworld.nim             → Small-world sigma (σ) and omega (ω)
  graph_hashing.nim          → Weisfeiler-Lehman graph/subgraph hashes
  similarity.nim             → SimRank, graph edit distance
  spectral.nim               → Laplacian spectrum, algebraic connectivity, Fiedler vector
  triads.nim                 → Triad census, triadic closure
  voronoi.nim                → Voronoi partitions on graphs
  lca.nim                    → Lowest common ancestor in DAGs
  layout.nim                 → Spring, circular, shell, random, spectral layout
  minors.nim                 → Edge contraction, graph minors
  cuts.nim                   → Minimum node/edge cuts, Stoer-Wagner
  parallel.nim               → Parallel PageRank, betweenness, closeness, clustering, Johnson's
  approximation.nim          → Approximate vertex cover, independent set, clique, coloring
  chordal.nim                → Chordality testing, perfect elimination ordering
  communicability.nim         → Communicability, communicability betweenness
  d_separation.nim           → d-separation testing on DAGs
  isolates.nim               → Isolate detection and removal
  misc.nim                   → Graph complement, reciprocity
  network_flow.nim           → Network simplex, min-cost max-flow
  node_classification.nim    → Label propagation node classification
  polynomials.nim            → Chromatic polynomial, Tutte polynomial
  structural_holes.nim       → Constraint, effective size, efficiency
  swaps.nim                  → Edge swaps (degree-preserving)
  tournament.nim             → Tournament testing, Hamiltonian path
src/nimnet/generators/       → 21 generator submodules
  classic.nim                → Complete, cycle, path, star, wheel, grid, barbell, lollipop, ladder, etc.
  random.nim                 → Erdős-Rényi, Barabási-Albert, Watts-Strogatz, regular, SBM
  small.nim                  → Petersen, karate club, Florentine families
  trees.nim                  → Balanced tree, random tree
  line_graph.nim             → Line graph generator
  lattice.nim                → Grid2d, triangular lattice, hypercube
  geometric.nim              → Random geometric, Waxman, soft random geometric
  community.nim              → Caveman, connected caveman, relaxed caveman, planted partition, ring of cliques
  degree_sequence.nim        → Configuration model, Havel-Hakimi, expected degree, degree sequence tree
  directed.nim               → GN, GNR, GNC, random k-out digraphs
  duplication.nim            → Duplication-divergence model
  expanders.nim              → Margulis-Gabber-Galil, chordal cycle expanders
  harary.nim                 → Harary graph, HKN graph
  internet.nim               → Barabási-Albert forest (Internet topology)
  intersection.nim           → Random/uniform intersection graphs
  joint_degree.nim           → Joint degree graph generation
  misc_generators.nim        → Full rary tree, circulant, null graph
  mycielski.nim              → Mycielskian graph, Mycielski graph
  nonisomorphic_trees.nim    → Non-isomorphic tree enumeration
  stochastic.nim             → Stochastic graph generation
  triad_generator.nim        → Triad graph generation
src/nimnet/io/               → 13 I/O format submodules
  edgelist.nim               → Edge list format
  adjlist.nim                → Adjacency list format
  multiline_adjlist.nim      → Multiline adjacency list format
  json_graph.nim             → JSON node-link format
  dot.nim                    → DOT/Graphviz export
  gml.nim                    → GML format read/write
  graphml.nim                → GraphML XML format read/write
  gexf.nim                   → GEXF format read/write (Gephi compatible)
  graph6.nim                 → Graph6/Sparse6 format read/write
  pajek.nim                  → Pajek .net format read/write
  leda.nim                   → LEDA graph format read/write
  network_text.nim           → Network text tree-style display
  svg.nim                    → SVG visualization export
src/nimnet/operators.nim     → Graph operations (complement, union, relabel)
src/nimnet/convert.nim       → Type conversions (adjacency matrix, edge list)
src/nimnet/builder.nim       → Builder DSL (GraphBuilder, buildGraph template)
src/nimnet/datasets.nim      → Built-in dataset loaders (dolphins, les misérables)
src/nimnet/multigraph.nim    → Undirected multigraph (parallel edges)
src/nimnet/views.nim         → Lazy graph views (SubGraph, NodeView, EdgeView)
src/nimnet/compact.nim       → CompactGraph (CSR-based, read-only, cache-friendly)
src/nimnet/static_graph.nim  → StaticGraph (compile-time fixed node set)
tests/                       → Test files
  ttypes.nim                 → 11 tests — types and edge attributes
  tgraph.nim                 → 53 tests — undirected graph operations
  tdigraph.nim               → 40 tests — directed graph operations
  talgorithms_core.nim       → 100 tests — core algorithms (traversal, paths, centrality, etc.)
  talgorithms_io_gen.nim     → 43 tests — advanced algorithms, I/O, generators, builder, datasets
  talgorithms_extended.nim   → 73 tests — extended coverage (DiGraph variants, operators, convert)
  talgorithms_advanced.nim   → 75 tests — advanced algorithms (distance, paths, efficiency, cycles, matching, etc.)
  talgorithms_features.nim   → Feature tests (views, multigraph, compact, static graph)
  talgorithms_batch2.nim     → Batch 2 algorithm coverage
  talgorithms_batch3.nim     → Batch 3 algorithm coverage
  tcoverage.nim              → Coverage gap tests
  tcoverage2.nim             → 198 tests — deeper code path coverage
  tcrossvalidation.nim       → Cross-validation tests
  tparallel.nim              → Parallel algorithm tests (malebolgia threading)
```

## Testing
- Framework: `std/unittest` (see ADR-0004)
- Test files: `tests/t<module>.nim` with `t` prefix
- Run: `nimble test` (runs all 15 test files, 1169+ total tests)
- Every public proc MUST have corresponding tests
- Use `suite` and `test` blocks, `check` for assertions, `expect` for exceptions

## Common Patterns

### Adding a new algorithm module
1. Create `src/nimnet/algorithms/<name>.nim`
2. Import `../types`, `../graph`, `../digraph` as needed
3. Export procs with `*`
4. Add `import nimnet/algorithms/<name>` and `export <name>` to `src/nimnet.nim`
5. Create tests in the appropriate `tests/talgorithms_*.nim` file
6. Update CHANGELOG.md

### Adding a new graph generator
1. Create `src/nimnet/generators/<name>.nim`
2. Return `Graph[int]` or `Graph[N]` from generator procs
3. Add to `src/nimnet.nim` exports
4. Create tests in the appropriate `tests/talgorithms_*.nim` file

### Adding a top-level module (e.g. builder.nim, datasets.nim)
1. Create `src/nimnet/<name>.nim`
2. Import with `./types`, `./graph`, `./digraph` (NOT `../types` — these are peers)
3. Add to `src/nimnet.nim` exports

## Known Pitfalls and Lessons Learned

### Import paths depend on directory level
- Files in `src/nimnet/algorithms/` use `../types`, `../graph`, `../digraph`
- Files in `src/nimnet/` (top-level submodules) use `./types`, `./graph`, `./digraph`
- Getting this wrong causes "cannot open" errors at compile time

### `result` variable cannot be captured in closures
Nim forbids capturing `result` in closure iterators or nested procs.
Use a local variable and assign to `result` afterward:
```nim
# WRONG:
proc foo(): seq[int] =
  let iter = iterator(): int {.closure.} = yield 1
  for x in iter(): result.add(x)  # Error: cannot capture result

# CORRECT:
proc foo(): seq[int] =
  var res: seq[int]
  let iter = iterator(): int {.closure.} = yield 1
  for x in iter(): res.add(x)
  result = res
```

### Disambiguating `reverse` in dag algorithms
`algorithm.reverse()` and `digraph.reverse()` can clash. Qualify:
```nim
import std/algorithm
algorithm.reverse(path)  # for seq reversal, not digraph reversal
```

### Naming collisions across modules
When two modules export the same proc name (e.g. `florentineFamiliesGraph` in
both `generators/small.nim` and `datasets.nim`), prefix with module name:
```nim
let g = small.florentineFamiliesGraph()
```

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
- Uses `jiro4989/setup-nim-action@v2`
- Nim version: stable

## Commit Message Format
- `feat: <description>` — new feature
- `fix: <description>` — bug fix
- `test: <description>` — test additions
- `docs: <description>` — documentation
- `refactor: <description>` — code refactoring
- `chore: <description>` — maintenance
