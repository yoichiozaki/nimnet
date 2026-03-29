# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

#### Graph Generators (4 modules)
- **Classic**: Complete, cycle, path, star, wheel, grid, complete bipartite
- **Random**: Erdős-Rényi (G(n,p) and G(n,m)), Barabási-Albert, Watts-Strogatz, Newman-Watts-Strogatz, random regular, stochastic block model, power-law cluster
- **Small**: Petersen graph, Zachary karate club, Florentine families
- **Trees**: Balanced tree, random tree

#### I/O Formats (6 modules)
- Edge list format read/write
- Adjacency list format read/write
- JSON node-link format read/write
- DOT/Graphviz export
- GML format read/write
- GraphML XML format read/write

#### Operators & Conversions
- Graph complement, union, intersection, difference
- Node relabeling
- Directed ↔ undirected conversion
- Adjacency matrix, edge list, degree sequence conversions

### Testing
- 347 tests across 6 test files (ttypes, tgraph, tdigraph, talgorithms, talgorithms2, talgorithms3)
- Coverage measurement via lcov + Codecov integration
- Coverage badge on README
