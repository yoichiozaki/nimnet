---
layout: home
title: Home
nav_order: 1
---

# nimnet

A comprehensive network science library for [Nim](https://nim-lang.org/), inspired by Python's [NetworkX](https://networkx.org/).
{: .fs-6 .fw-300 }

[Get started]({{ site.baseurl }}/getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[API Reference]({{ site.baseurl }}/api/nimnet.html){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/yoichiozaki/nimnet){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Why nimnet?

**Performance** — Nim compiles to C with zero-overhead abstractions. nimnet leverages cached edge counts (O(1)), `func`/`{.inline.}` annotations, and pre-sized allocations for serious speed.

**Ergonomics** — Nim-idiomatic API with operator overloading (`in`, `[]`, `+`, `-`), iterators (`for n in g`), and batch operations (`addEdgesFrom`).

**Extensibility** — Generic node types (`Graph[int]`, `Graph[string]`, or any hashable type), typed edge tuples, and a modular architecture.

## Quick example

```nim
import nimnet

var g = newGraph[int]()
g.addEdgesFrom([(1, 2), (2, 3), (3, 1)])

assert 1 in g
assert g.len == 3
echo g  # Graph(nodes=3, edges=3)

for node in g:
  echo node, " has degree ", g.degree(node)
```

## Features at a glance

| Category | Modules |
|:---------|:--------|
| **Core** | `Graph[N]`, `DiGraph[N]`, `MultiGraph[N]`, `MultiDiGraph[N]`, generic node types, cached metrics |
| **Algorithms (48)** | BFS/DFS traversal, Dijkstra, Bellman-Ford, A*, Floyd-Warshall, Johnson's, PageRank, eigenvector/Katz/HITS/betweenness centrality, Tarjan SCC, Kruskal/Prim MST, Edmonds-Karp max flow, min-cost flow, topological sort, Louvain/greedy modularity communities, VF2 isomorphism, planarity testing, TSP heuristics, k-core decomposition, Bron-Kerbosch cliques, graph coloring, bipartite matching, Euler/Hamiltonian paths, link prediction, connectivity, tree decomposition, bridges/articulation points, ego graphs, distance measures, simple paths, efficiency, rich-club coefficient, Wiener index, cycle basis, matching, graph products, small-world metrics, WL graph hashing, SimRank similarity, spectral analysis, triads, Voronoi partitions, LCA, layout (spring, circular, shell), minors, cuts, parallel algorithms |
| **Generators (10)** | Classic (complete, cycle, path, star, wheel, grid, barbell, lollipop, ladder), random (Erdős-Rényi, Barabási-Albert, Watts-Strogatz, regular, SBM), small/famous (Petersen, karate club), trees, line graph, lattice (grid2d, triangular, hypercube), geometric (random geometric, Waxman), community (caveman, planted partition), degree sequence (configuration model, Havel-Hakimi), directed (GN, GNR, GNC, random k-out) |
| **I/O (10)** | Edge list, adjacency list, JSON node-link, DOT/Graphviz, GML, GraphML, GEXF, Graph6/Sparse6, Pajek, SVG export |
| **Operators** | Union, complement, compose, intersection, difference, disjoint union, node relabeling, directed ↔ undirected conversion |
| **Other** | Builder DSL, graph views (lazy subgraph/filter), CompactGraph (CSR), StaticGraph (compile-time), built-in datasets (dolphins, Florentine families, les misérables), adjacency matrix/edge list conversion, parallel algorithms (malebolgia threading) |

## Performance

NimNet is compiled Nim with zero C/Fortran dependencies — yet it outperforms NetworkX (Python + scipy/numpy C backend) on most benchmarks.

**Large graph (10,000 nodes, 50,000 edges) — Erdős-Rényi random graph:**

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | 0.014s | 0.051s | **NimNet 3.6× faster** |
| BFS traversal | 0.008s | 0.015s | **NimNet 1.9× faster** |
| DFS traversal | 0.006s | 0.010s | **NimNet 1.7× faster** |
| Dijkstra | 0.040s | 0.012s | NetworkX 3.3× faster |
| PageRank | 0.079s | 0.035s | NetworkX 2.3× faster\* |
| Connected components | 0.006s | 0.005s | ~1× (tied) |
| MST (Kruskal) | 0.077s | 0.088s | **NimNet 1.1× faster** |

\*NetworkX PageRank uses scipy sparse matrix operations (C/Fortran BLAS); NimNet is pure Nim.
{: .fs-3 }

**Medium graph (1,000 nodes, 5,000 edges):**

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | 0.001s | 0.005s | **NimNet 5× faster** |
| BFS traversal | 0.001s | 0.002s | **NimNet 2× faster** |
| DFS traversal | 0.001s | 0.001s | ~1× (tied) |
| Dijkstra | 0.002s | 0.001s | NetworkX 2× faster |
| PageRank | 0.007s | 0.004s | NetworkX 1.8× faster\* |
| Connected components | 0.001s | 0.000s | — |
| MST (Kruskal) | 0.005s | 0.005s | ~1× (tied) |
| Clustering | 0.013s | 0.015s | **NimNet 1.2× faster** |
| Triangles | 0.004s | 0.004s | ~1× (tied) |

Compiled with `nim c -d:release -d:danger --opt:speed`. See [`benchmarks/`](https://github.com/yoichiozaki/nimnet/tree/main/benchmarks) for reproduction scripts.
{: .fs-3 }
