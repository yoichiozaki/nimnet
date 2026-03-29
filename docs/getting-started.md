---
layout: default
title: Getting Started
nav_order: 2
---

# Getting Started

## Installation

```bash
nimble install nimnet
```

Or add to your `.nimble` file:

```nim
requires "nimnet >= 0.1.0"
```

## Requirements

- Nim >= 2.0.0

## Your first graph

### Undirected graph

```nim
import nimnet

# Create an empty undirected graph with int nodes
var g = newGraph[int]()

# Add nodes individually or in batch
g.addNode(1)
g.addNodesFrom([2, 3, 4, 5])

# Add edges
g.addEdge(1, 2)
g.addEdgesFrom([(2, 3), (3, 4), (4, 5), (5, 1)])

# Nim-idiomatic access
assert 1 in g           # contains operator
assert g.len == 5       # number of nodes
assert g[1].len == 2    # neighbors of node 1

echo g  # Graph(nodes=5, edges=5)
```

### Directed graph

```nim
import nimnet

var dg = newDiGraph[string]()
dg.addEdge("A", "B")
dg.addEdge("B", "C")
dg.addEdge("C", "A")

assert dg.hasEdge("A", "B")
assert not dg.hasEdge("B", "A")  # directed!

echo dg.outDegree("A")  # 1
echo dg.inDegree("A")   # 1
```

### Weighted edges

```nim
import nimnet

var g = newGraph[int]()
g.addWeightedEdge(1, 2, 3.5)
g.addWeightedEdgesFrom([(2, 3, 1.0), (3, 4, 2.5)])

echo g.weight(1, 2)  # 3.5
```

### Using string nodes

```nim
import nimnet

var social = newGraph[string]()
social.addEdgesFrom([
  ("Alice", "Bob"),
  ("Bob", "Charlie"),
  ("Charlie", "Alice")
])

for friend in social.neighbors("Alice"):
  echo friend  # Bob, Charlie
```

## Graph algorithms

```nim
import nimnet

var g = newGraph[int]()
g.addEdgesFrom([(1,2), (2,3), (3,4), (4,5)])

# Shortest path (BFS)
let path = shortestPath(g, 1, 5)
echo path  # @[1, 2, 3, 4, 5]

# Connected components
for comp in connectedComponents(g):
  echo comp

# Degree centrality
let dc = degreeCentrality(g)
for node, centrality in dc:
  echo node, ": ", centrality
```

## Graph generators

```nim
import nimnet

# Classic graphs
let k5 = completeGraph[int](5)
let cycle = cycleGraph[int](10)
let petersen = petersenGraph()

# Random graphs
let er = erdosRenyiGraph[int](100, 0.05)
let ba = barabasiAlbertGraph[int](100, 3)

# Famous graphs
let karate = karateClubGraph()
```

## I/O

```nim
import nimnet

var g = newGraph[int]()
g.addEdgesFrom([(1,2), (2,3)])

# DOT format (Graphviz)
writeDot(g, "my_graph.dot")

# Edge list
writeEdgelist(g, "my_graph.edgelist")

# Adjacency list
writeAdjlist(g, "my_graph.adjlist")

# JSON node-link format
writeJsonGraph(g, "my_graph.json")

# GML format
writeGml(g, "my_graph.gml")

# GraphML format
writeGraphml(g, "my_graph.graphml")

# GEXF format (Gephi compatible)
writeGexf(g, "my_graph.gexf")

# Pajek format
writePajek(g, "my_graph.net")

# Graph6 format (compact, for simple graphs)
let g6str = writeGraph6(g)

# SVG visualization (requires a layout)
let pos = circularLayout(g)
writeSvg(g, pos, "my_graph.svg")
```

## Builder DSL

```nim
import nimnet

let g = buildGraph[int]:
  nodes [1, 2, 3, 4, 5]
  edges [(1,2), (2,3), (3,4), (4,5), (5,1)]

echo g  # Graph(nodes=5, edges=5)
```

## Built-in datasets

```nim
import nimnet

let karate = karateClubGraph()
let dolphins = dolphinsGraph()
let florentine = florentineFamiliesGraph()
let lesmis = lesMiserablesGraph()
```

## MultiGraph (parallel edges)

```nim
import nimnet

var mg = newMultiGraph[int]()
let k1 = mg.addEdge(1, 2)  # returns edge key 0
let k2 = mg.addEdge(1, 2)  # returns edge key 1 (parallel edge)
echo mg.numberOfEdges()     # 2
```

## Graph views (lazy, zero-copy)

```nim
import nimnet

var g = newGraph[int]()
g.addEdgesFrom([(1,2), (2,3), (3,4)])

# Create a read-only view (no graph copy)
let v = view(g)
echo v.numberOfNodes()  # 3
for n in v.nodes:
  echo n
```

## CompactGraph (CSR, cache-friendly)

```nim
import nimnet

var g = newGraph[int]()
g.addEdgesFrom([(0,1), (1,2), (2,0)])

# Convert to compressed sparse row (immutable, fast iteration)
let cg = toCompact(g)
echo cg.numberOfNodes()  # 3

# Convert back
let g2 = toGraph(cg)
```

## Static graph (compile-time construction)

```nim
import nimnet

let g = staticGraph[int]([(1,2), (2,3), (3,1)])
let dg = staticDiGraph[int]([(1,2), (2,3)])
let wg = staticWeightedGraph[int]([(1,2, 1.5), (2,3, 2.5)])
```

## Parallel algorithms

NimNet provides parallel versions of heavy algorithms using [malebolgia](https://github.com/Araq/malebolgia) threading:

```nim
import nimnet

let g = erdosRenyiGraph(1000, 0.01)

# These run on multiple threads automatically
let pr = parallelPageRank(g)
let bc = parallelBetweennessCentrality(g)
let cc = parallelClosenessCentrality(g)
```

## Next steps

- [API Reference]({{ site.baseurl }}/api/nimnet.html) — Full module documentation (auto-generated from source)
- [ADR Documents](https://github.com/yoichiozaki/nimnet/tree/main/docs/adr) — Architecture Decision Records

## Performance

nimnet is a pure Nim implementation with no C/Fortran dependencies — yet it outperforms Python's NetworkX (which uses scipy/numpy C backends) on most benchmarks.

**Large graph (10,000 nodes, 50,000 edges):**

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | 0.014s | 0.051s | **NimNet 3.6× faster** |
| BFS traversal | 0.008s | 0.015s | **NimNet 1.9× faster** |
| DFS traversal | 0.006s | 0.010s | **NimNet 1.7× faster** |
| Dijkstra | 0.040s | 0.012s | NetworkX 3.3× faster |
| PageRank | 0.079s | 0.035s | NetworkX 2.3× faster\* |
| Connected components | 0.006s | 0.005s | ~1× |
| MST (Kruskal) | 0.077s | 0.088s | **NimNet 1.1× faster** |

\*NetworkX PageRank uses scipy sparse matrix operations (C/Fortran); NimNet is pure Nim.

To reproduce benchmarks, see the [`benchmarks/`](https://github.com/yoichiozaki/nimnet/tree/main/benchmarks) directory.
