# nimnet

[![CI](https://github.com/yoichiozaki/nimnet/actions/workflows/ci.yml/badge.svg)](https://github.com/yoichiozaki/nimnet/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive network science library for [Nim](https://nim-lang.org/), inspired by Python's [NetworkX](https://networkx.org/).

## Features

- **Graph types**: Undirected (`Graph`) and directed (`DiGraph`) graphs with generic node types
- **Algorithms**: BFS, DFS, shortest paths (Dijkstra, Bellman-Ford), centrality measures, connected components, clustering, community detection, MST, max flow, topological sort
- **Generators**: Classic graphs, random graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz), famous graphs, trees
- **I/O**: Edge list, adjacency list, JSON graph format, DOT export
- **Operators**: Union, complement, reverse, subgraph, node relabeling

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
