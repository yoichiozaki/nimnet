<p align="center">
  <img src="docs/assets/images/nimnet-logo.png" alt="NimNet Logo" width="300">
</p>

# nimnet

[![CI](https://github.com/yoichiozaki/nimnet/actions/workflows/ci.yml/badge.svg)](https://github.com/yoichiozaki/nimnet/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/yoichiozaki/nimnet/badges/docs/badges/coverage.json)](https://github.com/yoichiozaki/nimnet/actions/workflows/coverage.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive network science library for [Nim](https://nim-lang.org/), inspired by Python's [NetworkX](https://networkx.org/).

## Features

- **Graph types**: Undirected (`Graph`), directed (`DiGraph`), multigraphs (`MultiGraph`, `MultiDiGraph`) with generic node types
- **Graph views**: Lazy subgraph views (`GraphView`, `DiGraphView`) — zero-copy, read-only
- **CompactGraph**: Cache-friendly CSR (Compressed Sparse Row) representation
- **StaticGraph**: Compile-time graph construction templates
- **61 Algorithm modules**: BFS/DFS traversal, shortest paths (Dijkstra, Bellman-Ford, A*, Floyd-Warshall, Johnson's), centrality (degree, closeness, PageRank, eigenvector, Katz, HITS), connected/strongly connected components, clustering coefficients, community detection (greedy modularity, Louvain, Leiden), MST (Kruskal, Prim), max flow (Edmonds-Karp), topological sort, transitive closure/reduction, graph isomorphism (VF2), planarity testing, TSP heuristics, min-cost flow, tree decomposition, k-core decomposition, clique enumeration, graph coloring, bipartite matching, Eulerian/Hamiltonian paths, link prediction, bridges & articulation points, ego graphs, distance measures, simple paths, efficiency, rich-club coefficient, Wiener index, cycle basis, matching, graph products, small-world metrics, graph hashing (WL), similarity (SimRank, graph edit distance), spectral analysis, triads, voronoi, LCA, layout (spring, circular, shell), minors, cuts, parallel algorithms, approximation, chordal graph analysis, communicability, d-separation, isolates, network flow, node classification, polynomials, structural holes, tournaments, edge swaps
- **21 Generator modules**: Classic graphs (complete, cycle, path, star, wheel, grid, barbell, lollipop, ladder, etc.), random graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz, random regular, stochastic block model), small/famous graphs (Petersen, karate club), tree generators, line graph, lattice (grid2d, triangular, hypercube), geometric graphs (random geometric, Waxman), community generators (caveman, planted partition), degree sequence generators (configuration model, Havel-Hakimi), directed graph generators (GN, GNR, GNC, random k-out), duplication-divergence, internet topology (Barabási-Albert forest), intersection graphs, joint degree graphs, Mycielski graphs, Harary graphs, stochastic graphs, non-isomorphic trees, triad generators, expander graphs, miscellaneous generators
- **13 I/O formats**: Edge list, adjacency list, multiline adjacency list, JSON graph, DOT/Graphviz, GML, GraphML, GEXF, Graph6, Pajek, LEDA, network text (tree display), SVG export
- **Operators**: Union, complement, intersection, difference, node relabeling, directed ↔ undirected conversion
- **Builder DSL**: Fluent graph construction with method chaining and `buildGraph` template
- **Built-in datasets**: Dolphins social network, Florentine families, les misérables

Version **1.1.0** includes exact cardinality matching, Hopcroft-Karp, sparse random graphs,
undirected sparse all-pairs paths, directed loaders, PageRank probability
conservation and meaningful Louvain resolution. The
[improvement backlog](docs/backlog.md) records the implementation and acceptance evidence.

## Installation

```bash
nimble install "https://github.com/yoichiozaki/nimnet@1.1.0"
```

NimNet is not yet listed in the official Nimble package index. Install directly
from its GitHub repository, or add the repository URL to your `.nimble` file:

```nim
requires "https://github.com/yoichiozaki/nimnet >= 1.1.0"
```

## Quick Start

```nim
import nimnet

# Create an undirected graph
var g = newGraph[int]()
g.addNode(1)
g.addNode(2)
g.addNode(3)
g.addEdge(1, 2)
g.addEdge(2, 3)
g.addEdge(1, 3)

echo "Nodes: ", g.numberOfNodes()  # 3
echo "Edges: ", g.numberOfEdges()  # 3

# Iterate neighbors
for neighbor in g.neighbors(1):
  echo neighbor  # 2, 3

# Shortest path
echo shortestPath(g, 1, 3)  # @[1, 3]

# Create a directed graph
var dg = newDiGraph[string]()
dg.addEdge("A", "B")
dg.addEdge("B", "C")
echo dg.hasPath("A", "C")  # true

# Graph generators
let complete = completeGraph[int](5)
let er = erdosRenyiGraph[int](100, 0.05)

# Builder DSL
let h = buildGraph[int]:
  nodes [1, 2, 3, 4, 5]
  edges [(1,2), (2,3), (3,4), (4,5)]

# Centrality analysis
let pr = pageRank(complete)
let communities = louvainCommunities(er)

# All-pairs shortest paths
let dist = floydWarshall(g)

# Graph properties
echo isTree(g)      # false (has a cycle)
echo isComplete(g)  # true (K3)

# I/O
writeGml(g, "my_graph.gml")
let loaded = readGml("my_graph.gml")
```

## Algorithm Modules

| Category | Module | Algorithms |
|----------|--------|-----------|
| Traversal | `traversal` | BFS, DFS (edges, tree, layers, preorder, postorder) |
| Shortest Paths | `shortest_paths` | Dijkstra, Bellman-Ford, A*, unweighted BFS |
| All-Pairs Shortest | `all_pairs_shortest` | Floyd-Warshall, sparse Johnson/Dijkstra distances for Graph and DiGraph |
| Components | `components` | Connected, strongly connected (Tarjan), weakly connected, condensation |
| Centrality | `centrality` | Degree, closeness, PageRank, eigenvector, Katz, HITS |
| Clustering | `clustering` | Clustering coefficient, transitivity, triangles |
| Community | `community`, `louvain` | Incremental greedy modularity, Louvain method |
| MST | `mst` | Kruskal, Prim |
| DAG | `dag` | Topological sort, cycle detection, ancestors, descendants, transitive closure/reduction |
| Flow | `flow` | Edmonds-Karp max flow, minimum cut |
| Min-Cost Flow | `min_cost_flow` | Successive shortest path |
| Connectivity | `connectivity` | Node/edge connectivity, resilience |
| Isomorphism | `isomorphism` | VF2 graph isomorphism |
| Planarity | `planarity` | Euler's formula + K5/K3,3 subgraph detection |
| TSP | `tsp` | Nearest neighbor, greedy, 2-opt |
| Tree Decomposition | `tree_decomposition` | Treewidth upper bound |
| Properties | `properties` | isTree, isForest, isRegular, isComplete, girth |
| Link Prediction | `link_prediction` | Common neighbors, Jaccard, Adamic-Adar |
| k-Core | `core` | Core decomposition, k-core, k-shell |
| Statistics | `stats` | Degree histogram, assortativity |
| Cliques | `clique` | Bron-Kerbosch, clique number |
| Independent Set | `independent_set` | Maximum independent set, vertex cover |
| Dominating Set | `dominating` | Minimum dominating set |
| Coloring | `coloring` | Greedy coloring (largest-first, DSATUR) |
| Bipartite | `bipartite` | Bipartiteness, Hopcroft-Karp matching, explicit partitions, minimum vertex cover |
| Euler | `euler` | Eulerian circuits/paths, Hamiltonian detection |
| Bridges | `bridges` | Bridges (cut edges), articulation points, biconnected components |
| Ego Graph | `ego` | Ego graph extraction (k-hop neighborhood subgraph) |
| Distance Measures | `distance_measures` | Diameter, radius, center, periphery, eccentricity, barycenter |
| Simple Paths | `simple_paths` | All simple paths enumeration |
| Efficiency | `efficiency` | Global efficiency, local efficiency |
| Rich Club | `richclub` | Rich-club coefficient |
| Wiener Index | `wiener` | Wiener index |
| Cycles | `cycles` | Cycle basis, simple cycles (directed) |
| Matching | `matching` | Exact maximum-cardinality matching and minimum edge cover; greedy weighted matching |
| Graph Products | `graph_products` | Cartesian, tensor, strong, lexicographic product |
| Small-World | `smallworld` | Small-world sigma (σ) and omega (ω) coefficients |
| Graph Hashing | `graph_hashing` | Weisfeiler-Lehman graph/subgraph hashes |
| Similarity | `similarity` | SimRank, graph edit distance |
| Spectral | `spectral` | Laplacian spectrum, algebraic connectivity, spectral radius, Fiedler vector |
| Triads | `triads` | Triad census, triadic closure |
| Voronoi | `voronoi` | Voronoi partitions on graphs |
| LCA | `lca` | Lowest common ancestor in DAGs |
| Layout | `layout` | Spring (Fruchterman-Reingold), circular, shell, random, spectral layout |
| Minors | `minors` | Edge contraction, graph minors |
| Cuts | `cuts` | Cut size, conductance, normalized cut, edge expansion, node boundary |
| Parallel | `parallel` | Parallel PageRank, betweenness, closeness, clustering, Johnson's (malebolgia) |
| Approximation | `approximation` | Approximate vertex cover, independent set, clique, dominating set, TSP, coloring, min-cut |
| Chordal | `chordal` | Chordality testing, perfect elimination ordering, chordal completion |
| Communicability | `communicability` | Communicability, communicability betweenness |
| d-Separation | `d_separation` | d-separation testing on DAGs, Markov blanket |
| Isolates | `isolates` | Isolate detection and removal |
| Leiden | `leiden` | Leiden community detection algorithm |
| Misc | `misc` | Graph complement, reciprocity, max weight clique |
| Network Flow | `network_flow` | Network simplex, min-cost max-flow |
| Node Classification | `node_classification` | Label propagation node classification |
| Polynomials | `polynomials` | Chromatic polynomial, Tutte polynomial |
| Structural Holes | `structural_holes` | Constraint, effective size, efficiency |
| Swaps | `swaps` | Edge swaps, double edge swaps (degree-preserving) |
| Tournament | `tournament` | Tournament testing, Hamiltonian path in tournaments |

## Additional Data Structures

| Type | Description |
|------|-------------|
| `MultiGraph[N]` | Undirected multigraph supporting parallel edges |
| `MultiDiGraph[N]` | Directed multigraph supporting parallel edges |
| `GraphView` / `DiGraphView` | Lazy, zero-copy read-only graph views |
| `CompactGraph` / `CompactDiGraph` | Cache-friendly CSR (Compressed Sparse Row) representation |
| `StaticGraph` | Compile-time graph construction via templates |

## Performance

NimNet uses indexed adjacency, CSR traversal and incremental algorithm state
where they improve performance without replacing the flexible graph API.
`fastGnpRandomGraph` provides expected O(V+E) sparse generation alongside the
existing O(V²) `erdosRenyiGraph`.

The [benchmark suite](benchmarks/README.md) measures both targeted improvements
and comparisons with NetworkX. Both libraries read identical graph/weight
fixtures, perform equivalent operations, and run sequentially using median
elapsed times after warmup. Compiler/package versions and fixture hashes are
recorded with the results; assertions remain enabled.

Performance depends on graph structure, size, algorithm and hardware. There is
no blanket claim that one library wins every workload. NetworkX also uses
NumPy/SciPy native backends for some algorithms; NimNet's algorithms are
implemented in Nim without those dependencies.

## Attributes and algorithm guarantees

Greedy modularity uses the unweighted objective (attributes are ignored), with
self-loops counted consistently. Louvain uses weighted modularity and applies
resolution only to the null-model term. Both community methods are heuristics.

`EdgeAttr` stores a numeric `weight` and an `extra: Table[string, string]`.
`newEdgeAttr()` starts with weight `1.0`; `getWeight()` returns the stored value.
The legacy `default` argument does not override that value. `NodeAttr` is a
`JsonNode`, so node attributes can contain typed or nested values.

`maximumCardinalityMatching` is exact for general graphs, including odd cycles.
The existing `maxWeightMatching` and `minWeightMatching` are **greedy
approximations**, also exposed as `approxMaxWeightMatching` and
`approxMinWeightMatching`. Only the maximum-weight greedy routine has a 1/2
weight guarantee, and only for finite nonnegative weights; the minimum-weight
routine has no general approximation guarantee.

See the [API guide](docs/getting-started.md) for new APIs and migration notes.

## Examples

See the [`examples/`](examples/) directory for complete, runnable programs:

- **Social network analysis** — centrality, clustering, community detection on the karate club graph
- **Shortest path demo** — Dijkstra, Bellman-Ford, A* on a weighted city network
- **Graph I/O roundtrip** — reading, writing and round-trip examples for supported formats
- **Network resilience** — bridges, articulation points, connectivity analysis

```bash
nim c -r -p:src examples/social_network_analysis.nim
```

## Development

### Using DevContainer (Recommended)

1. Install [Docker](https://www.docker.com/) and [VS Code Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open the project in VS Code
3. Click "Reopen in Container" when prompted
4. Run `nimble test`

### Manual Setup

1. Install [Nim](https://nim-lang.org/install.html) >= 2.0.0
2. Clone the repository
3. Run `nimble test`

## Architecture

Design decisions are documented as [Architecture Decision Records](docs/adr/) (ADRs).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT — see [LICENSE](LICENSE).
