---
layout: default
title: Getting Started
nav_order: 2
---

# Getting Started

## Installation

```bash
nimble install "https://github.com/yoichiozaki/nimnet@1.1.0"
```

NimNet is not yet listed in the official Nimble package index. Use the GitHub
URL directly, or add it to your `.nimble` file:

```nim
requires "https://github.com/yoichiozaki/nimnet >= 1.1.0"
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
let florentine = datasets.florentineFamiliesGraph()
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
echo v.numberOfNodes()  # 4
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

## New in 1.1.0

The following APIs are available from NimNet 1.1.0.
See the [backlog]({{ site.baseurl }}/backlog) and changelog for implementation
and compatibility details.
A runnable version is in
[`examples/library_improvements.nim`](https://github.com/yoichiozaki/nimnet/blob/main/examples/library_improvements.nim).

### Exact matching and explicit bipartitions

```nim
import std/sets
import nimnet

var g = newGraph[string]()
g.addEdgesFrom([("A", "X"), ("A", "Y"), ("B", "X")])
let left = toHashSet(["A", "B"])
assert maximumMatching(g, left).len == 2
assert minimumVertexCover(g, left).len == 2

var triangle = newGraph[int]()
triangle.addEdgesFrom([(0, 1), (1, 2), (2, 0)])
assert maximumCardinalityMatching(triangle).len == 1
assert minEdgeCover(triangle).len == 2
```

`maximumCardinalityMatching` is an exact O(V³) general-graph solver using
blossom contraction. Bipartite matching uses iterative Hopcroft-Karp in
O((V+E)√V); supplying the left side skips partition inference, but validates
unknown nodes and edges within either side. An isolate without a self-loop
makes an edge cover infeasible and raises `NimNetUnfeasible`.
Here minimum means the number of edges, not their total weight.

`maxWeightMatching` / `approxMaxWeightMatching` and
`minWeightMatching` / `approxMinWeightMatching` remain greedy, not exact
weighted solvers. The maximum-weight variant has a 1/2 guarantee for finite
nonnegative weights; the minimum-weight variant has no general guarantee.

### Sparse graphs and shortest paths

```nim
import std/[math, tables]
import nimnet

let sparse = fastGnpRandomGraph(1000, 0.004, seed = 42)
assert sparse.numberOfNodes() == 1000

var weighted = newGraph[string]()
weighted.addWeightedEdge("A", "B", 2.5)
weighted.addWeightedEdge("B", "C", 1.0)
let distances = johnsons(weighted)
assert distances["A"]["C"] == 3.5
weighted.addNode("isolated")
assert not johnsons(weighted)["A"].hasKey("isolated")
let completeDistances = johnsons(weighted, includeUnreachable = true)
assert completeDistances["A"]["isolated"] == Inf
```

`fastGnpRandomGraph` uses geometric skipping in expected O(V+E). The original
`erdosRenyiGraph` and its valid seeded output are unchanged. A nonzero seed is
repeatable within each generator; zero uses a system-derived seed. Different
generator algorithms do not promise identical edges for the same seed.
Invalid sizes/probabilities raise `NimNetError`; probabilities must be finite
and in `[0, 1]`.

`gnmRandomGraph` retains complete-graph saturation when `m` exceeds the maximum.
`randomRegularGraph` always returns the requested degrees or raises:
invalid parameters produce `NimNetError`, and exhausted bounded pairing
attempts produce `NimNetUnfeasible`. It never silently substitutes an empty
graph. `johnsons` now accepts weighted undirected graphs as well as digraphs;
its result is a nested `Table[N, Table[N, float]]` of source/destination
distances. The default keeps the original directed API's reachable-only
destination keys; each isolate still has a self-distance of zero.
`includeUnreachable=true` explicitly requests complete rows with `Inf` for
unreachable destinations. Negative undirected edges represent negative cycles
and are rejected. `parallelJohnsons` produces complete rows in both threaded
and non-threaded builds.

### PageRank and community resolution

```nim
import std/tables
import nimnet

var isolate = newGraph[int]()
isolate.addNode(0)
assert pageRank(isolate)[0] == 1.0

let clique = completeGraph[int](4)
assert louvainCommunities(clique, resolution = 0.5, seed = 42).len == 1
assert louvainCommunities(clique, resolution = 3.0, seed = 42).len == 4
```

PageRank is unweighted: edge weight attributes do not affect its transitions.
Dangling mass is redistributed uniformly and a self-loop contributes one
transition, so nonempty results remain normalized. The stopping condition is
total L1 change `< tol`; reaching `maxIter` still returns the last iterate.
Zero iterations return the uniform initialization. Invalid settings raise
`ValueError`: `alpha` must be finite in `[0, 1]`, `tol` finite/nonnegative,
and iteration counts nonnegative.

Louvain optimizes weighted modularity; `resolution` scales the null-model term,
not the entire gain. Higher values favor smaller communities. Use a nonzero
seed for repeatability; community quality and partitions can still differ from
other implementations.
Resolution and edge weights must be finite and nonnegative (`ValueError`
otherwise); unrepresentable arithmetic raises `NimNetAlgorithmError`.
The method remains a heuristic with 100 passes per level and 20 levels.

### Attributes, compact loops and directed loaders

```nim
import std/json
import nimnet

var edge = newEdgeAttr([("kind", "road")])
edge.weight = 2.5
assert edge.getWeight() == 2.5

let node = newNodeAttr([("label", "Alpha")])
node["active"] = %true

let directed = loadFromEdgeListStringDirected[int]("1 2 3.5\n2 3 1.0")
assert directed.hasEdge(1, 2)
assert not directed.hasEdge(2, 1)
```

`EdgeAttr` has a numeric weight and string-valued `extra` attributes;
`NodeAttr` is JSON-valued. `newEdgeAttr()` supplies weight `1.0`;
the legacy `getWeight(default=...)` argument does not replace stored weights.

Use `loadFromEdgeListFileDirected` for integer-node files and
`readEdgelistDirected(filename, delimiter)` for string-node edge lists.
The old `loadFromEdgeListString(..., directed=true)` cannot return a digraph
with its declared `Graph` return type: it now raises an actionable error
instead of silently ignoring the flag. `readEdgelist` accepts `createUsing =
"graph"`; unsupported selectors fail rather than pretending to change graph
kind. Malformed rows/weights raise `ValueError`.

Compact graphs correctly count self-loops and their contribution of two to
undirected degree. `toGraph` supports both compact graph kinds, retaining
direction, topology and weights. Directed GEXF round-trips preserve node labels
as well as edge weights.

## Performance

Use the [benchmark suite](https://github.com/yoichiozaki/nimnet/tree/main/benchmarks)
for shared inputs, repeatable elapsed-time measurements and recorded
environment details. Results depend on graph shape, size, algorithm and
hardware; historical tables using different random graphs are not comparable
with the current fixture-based measurements.
