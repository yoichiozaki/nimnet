<p align="center">
  <img src="docs/assets/images/nimnet-logo.png" alt="NimNet Logo" width="300">
</p>

# nimnet

[![CI](https://github.com/yoichiozaki/nimnet/actions/workflows/ci.yml/badge.svg)](https://github.com/yoichiozaki/nimnet/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/endpoint?url=https://yoichiozaki.github.io/nimnet/badges/coverage.json)](https://github.com/yoichiozaki/nimnet/actions/workflows/coverage.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive network science library for [Nim](https://nim-lang.org/), inspired by Python's [NetworkX](https://networkx.org/).

## Features

- **Graph types**: Undirected (`Graph`) and directed (`DiGraph`) graphs with generic node types
- **27 Algorithm modules**: BFS/DFS traversal, shortest paths (Dijkstra, Bellman-Ford, A*, Floyd-Warshall, Johnson's), centrality (degree, closeness, PageRank, eigenvector, Katz, HITS), connected/strongly connected components, clustering coefficients, community detection (greedy modularity, Louvain), MST (Kruskal, Prim), max flow (Edmonds-Karp), topological sort, graph isomorphism (VF2), planarity testing, TSP heuristics, min-cost flow, tree decomposition, k-core decomposition, clique enumeration, graph coloring, bipartite matching, Eulerian/Hamiltonian paths, link prediction, and more
- **4 Generator modules**: Classic graphs (complete, cycle, path, star, wheel, grid), random graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz, random regular, stochastic block model), small/famous graphs (Petersen, karate club), tree generators
- **6 I/O formats**: Edge list, adjacency list, JSON graph, DOT/Graphviz, GML, GraphML
- **Operators**: Union, complement, intersection, difference, node relabeling, directed ↔ undirected conversion
- **Builder DSL**: Fluent graph construction with method chaining and `buildGraph` template
- **Built-in datasets**: Dolphins social network, Florentine families, les misérables
- **347 tests** across 6 test files

## Installation

```bash
nimble install nimnet
```

Or add to your `.nimble` file:

```nim
requires "nimnet >= 0.1.0"
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
| All-Pairs Shortest | `all_pairs_shortest` | Floyd-Warshall, Johnson's algorithm |
| Components | `components` | Connected, strongly connected (Tarjan), weakly connected, condensation |
| Centrality | `centrality` | Degree, closeness, PageRank, eigenvector, Katz, HITS |
| Clustering | `clustering` | Clustering coefficient, transitivity, triangles |
| Community | `community`, `louvain` | Greedy modularity, Louvain method |
| MST | `mst` | Kruskal, Prim |
| DAG | `dag` | Topological sort, cycle detection, ancestors, descendants |
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
| Bipartite | `bipartite` | Bipartiteness, maximum matching |
| Euler | `euler` | Eulerian circuits/paths, Hamiltonian detection |

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
