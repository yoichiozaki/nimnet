# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Exact general-graph `maximumCardinalityMatching`, including odd cycles, and
  explicitly named `approxMaxWeightMatching` / `approxMinWeightMatching` aliases.
- Known-partition overloads for bipartite matching and minimum vertex cover.
- Sparse weighted undirected `johnsons(Graph)` all-pairs distances, with
  `includeUnreachable=true` for explicit complete `Inf` rows on either graph
  kind; existing reachable-only directed defaults remain intact.
- Expected O(V+E) `fastGnpRandomGraph` with seeded repeatability and robust
  probability boundary handling.
- Directed edge-list string/file dataset loaders, `readEdgelistDirected`, and
  `toGraph(CompactDiGraph)` conversion.
- Exhaustive small-graph matching oracles, targeted invariant/scalability
  regressions, shared benchmark fixture checks and Python tooling tests.

### Changed
- Bipartite matching now uses indexed, iterative Hopcroft-Karp rather than
  repeated unconstrained DFS augmentation.
- Greedy modularity merges maintain incremental community gains instead of
  repeatedly copying partitions and evaluating full modularity.
- All Nimble test/coverage tasks discover the same sorted `tests/t*.nim`
  inventory; `NIMNET_TESTS` supports validated selections and executables live
  under `build`.
- CI covers the minimum supported Nim compiler as well as stable, keys compiled
  caches by compiler version, and uses one non-masking coverage workflow.
- Benchmarks use identical serialized graph/weight fixtures, equivalent work,
  monotonic elapsed clocks, sequential timing, validated complete CSV results
  and recorded environments. The Python comparison environment is pinned.
- Reviewed GitHub Actions upgrades and automatic grouped benchmark dependency
  updates; current API, attribute and performance documentation reconciled.

### Fixed
- Minimum edge covers now use maximum-cardinality matching; graphs with
  uncovered isolated nodes raise `NimNetUnfeasible`.
- Compact undirected self-loop edge counts, degrees and graph round-trips.
- Directed GEXF node labels survive read/write round-trips.
- PageRank preserves probability mass for isolates and self-loops, including
  serial/parallel consistency, without changing unweighted semantics.
- Louvain resolution applies to the null-model term instead of scaling the
  entire gain; nondefault values now have their documented effect.
- Previously ignored directed dataset modes and unsupported edge-list
  `createUsing` selectors now fail explicitly with migration guidance.
- Invalid random-generator parameters and exhausted regular-graph retries no
  longer produce success-shaped malformed graphs. G(n,m) complete-graph
  saturation remains supported.
- Test files omitted by hand-maintained runners are now included; failed tests,
  malformed benchmark output and absent source coverage no longer pass silently.
- API documentation markup is rendered as literals where appropriate; strict
  doc generation rejects diagnostics even when the compiler returns zero.

## [1.0.0] - 2026-03-30

### Changed
- **Version bump to 1.0.0** — library is now considered production-ready
- **Updated README benchmarks** — reflects optimized Dijkstra, PageRank, Louvain results (NimNet now outperforms NetworkX across all benchmarks at scale)

### Fixed
- **GEXF I/O**: Edge weight attributes are now correctly preserved when reading GEXF files (both undirected and directed)

### Added
- **CI coverage reporting** — code coverage collection via lcov with Codecov integration on Linux

## [0.1.0] - 2025-07-16

### Added

#### Batch 3: Advanced Modules
- **Spectral analysis**: Algebraic connectivity, Fiedler vector, spectral gap, Laplacian spectrum
- **Graph layouts**: Spring (Fruchterman-Reingold), circular, random, shell, spectral layout
- **SVG export**: Render graphs to SVG with configurable styles and layouts
- **Graph views**: Lazy subgraph, reverse, and generic filtered views (no copy)
- **MultiGraph / MultiDiGraph**: Parallel-edge graph types
- **Compact CSR graph**: Cache-friendly compressed sparse row representation
- **Static graph**: Immutable, compile-time-friendly graph type
- **Parallel algorithms**: Parallel BFS, PageRank, connected components, betweenness centrality
- **Nodeable concept**: Type-constraint for node types (`hash` + `==` + `$`)
- **Enhanced datasets**: Dolphins, Florentine families, les misérables, Zachary karate club

#### Batch 2: Additional Algorithm Modules
- **Triads**: Triad census for directed graphs
- **Graph minors**: Node/edge contraction, quotient graphs
- **Cut algorithms**: Minimum node/edge cuts, Stoer-Wagner
- **Small-world**: Sigma and omega coefficients
- **LCA**: Lowest common ancestor for DAGs
- **Graph hashing**: Weisfeiler-Lehman graph hash
- **Voronoi**: Voronoi partition on graphs
- **Geometric generators**: Random geometric, Waxman, soft random geometric
- **Community generators**: Caveman, connected caveman, relaxed caveman, planted partition, LFR benchmark

### Changed
- **BREAKING**: `EdgeAttr` and `NodeAttr` migrated from `Table[string, string]` to `JsonNode` — enables storing typed values (float, int, bool, nested objects) in attributes
- New attribute helpers: `attrStr`, `attrFloat`, `getAttrFloat`
- `getWeight()` now handles JFloat, JInt, and JString value types
- `newEdgeAttr()` returns `newJObject()` instead of `initTable`

#### Performance Optimizations
- **Dijkstra**: O(V²) linear-scan → O((V+E) log V) binary heap (HeapQueue) — **35× faster**
- **PageRank**: Pre-computed degrees, `swap` instead of allocation per iteration, direct adjacency access — **14× faster**
- **A\***: Linear-scan → HeapQueue-based priority queue
- **Prim MST**: O(V²) → O(E log V) HeapQueue-based
- **BFS/DFS traversal**: Direct `g.adj[node].keys` access, pre-sized HashSets — **8–10× faster**
- **Connected components**: Direct adjacency access; `isConnected` rewritten as single BFS — **10× faster**
- **Clustering/triangles**: Direct `Table.contains` instead of `hasEdge` (2→1 hash lookup) — eliminated per-node HashSet allocation
- **Graph creation**: Deferred EdgeAttr allocation (zero-init empty tables) — **10× faster**
- **Table sizing**: Small initial sizes for neighbor tables (8) and EdgeAttr (2) — reduced memory 4–32× and improved cache locality
- **getWeight**: Eliminated try/except overhead, single hash lookup via `getOrDefault`
- **Betweenness, closeness, eigenvector, Katz, HITS centrality**: Direct adjacency access, pre-allocated swap buffers
- Exposed `adj` and `pred` fields as public for direct algorithm access

#### Core & Infrastructure
- Initial project scaffolding
- DevContainer configuration
- GitHub Actions CI pipeline (ubuntu, macos, windows × Nim 2.2.8)
- Issue and PR templates
- ADR framework with initial design decisions
- Builder DSL (`GraphBuilder`, `buildGraph` template) for fluent graph construction
- Built-in dataset loaders (dolphins social network, Florentine families, les misérables)

#### Algorithm Modules (27 total)
- **Traversal**: BFS (edges, tree, layers, predecessors), DFS (edges, tree, preorder, postorder)
- **Shortest Paths**: Dijkstra, Bellman-Ford, A* search, unweighted BFS
- **Components**: Connected components, strongly connected (Tarjan), weakly connected, condensation
- **Centrality**: Degree, closeness, PageRank, eigenvector, Katz, HITS
- **Clustering**: Clustering coefficient, average clustering, transitivity, triangle counting
- **Community**: Greedy modularity optimization
- **Louvain**: Louvain community detection with resolution parameter
- **MST**: Kruskal, Prim minimum spanning tree
- **DAG**: Topological sort, cycle detection, ancestors, descendants, longest path
- **Flow**: Edmonds-Karp max flow, minimum cut
- **All-Pairs Shortest**: Floyd-Warshall, Johnson's algorithm
- **Connectivity**: Node/edge connectivity, resilience measures
- **Isomorphism**: VF2 graph isomorphism
- **Planarity**: Planarity testing (edge bounds + K5/K3,3 subgraph detection)
- **TSP**: Nearest neighbor, greedy, 2-opt heuristics
- **Min-Cost Flow**: Successive shortest path algorithm
- **Tree Decomposition**: Treewidth upper bound (greedy heuristic)
- **Properties**: isTree, isForest, isRegular, isComplete, girth
- **Link Prediction**: Common neighbors, Jaccard, Adamic-Adar, preferential attachment, resource allocation
- **k-Core**: Core number decomposition, k-core/k-shell subgraph extraction
- **Statistics**: Degree histogram, average degree, assortativity, graph info summary
- **Cliques**: Bron-Kerbosch maximal clique enumeration, clique number
- **Independent Set**: Maximum independent set, minimum vertex cover
- **Dominating Set**: Minimum dominating set, domination number
- **Coloring**: Greedy coloring (largest-first, smallest-last, DSATUR), chromatic number
- **Bipartite**: Bipartiteness testing, bipartite sets, maximum matching
- **Euler**: Eulerian circuit/path (Hierholzer), semi-Eulerian detection, Hamiltonian detection
- **Bridges**: Bridge detection, articulation points, biconnected components
- **Ego**: Ego graph extraction (BFS with distance tracking)
- **Distance Measures**: Eccentricity, diameter, radius, center, periphery, barycenter
- **Simple Paths**: All simple paths enumeration, isSimplePath, allSimplePathsSeq
- **Efficiency**: Global efficiency, local efficiency, average local efficiency
- **Rich Club**: Rich-club coefficient per degree
- **Wiener Index**: Wiener index (sum of all shortest path distances)
- **Cycles**: Cycle basis (fundamental cycles), simple cycles for directed graphs (Johnson's)
- **Matching**: Maximal matching, max-weight matching, min-weight matching, isMatching, isPerfectMatching
- **Graph Products**: Cartesian product, tensor product, strong product, lexicographic product

#### Graph Generators (6 modules)
- **Classic**: Complete, cycle, path, star, wheel, grid, complete bipartite, barbell, lollipop, ladder, circular ladder, tadpole, Turán, book, friendship (windmill), null, trivial
- **Random**: Erdős-Rényi (G(n,p) and G(n,m)), Barabási-Albert, Watts-Strogatz, Newman-Watts-Strogatz, random regular, stochastic block model, power-law cluster
- **Small**: Petersen graph, Zachary karate club, Florentine families
- **Trees**: Balanced tree, random tree
- **Line Graph**: Line graph generator
- **Lattice**: Grid2d (with periodic/torus option), triangular lattice, hypercube

#### I/O Formats (7 modules)
- Edge list format read/write
- Adjacency list format read/write
- JSON node-link format read/write
- DOT/Graphviz export
- GML format read/write
- GraphML XML format read/write
- GEXF format read/write (Gephi compatible)

#### Operators & Conversions
- Graph complement, union, intersection, difference
- Node relabeling
- Directed ↔ undirected conversion
- Adjacency matrix, edge list, degree sequence conversions

### Testing
- 695 tests across 11 test files
- Cross-validation against NetworkX reference values
- Coverage measurement via lcov + Codecov integration
- Coverage badge on README
