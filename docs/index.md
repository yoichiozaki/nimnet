---
layout: home
title: Home
nav_order: 1
---

# nimnet

A comprehensive network science library for [Nim](https://nim-lang.org/), inspired by Python's [NetworkX](https://networkx.org/).
{: .fs-6 .fw-300 }

[Get started]({{ site.baseurl }}/getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
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
| **Core** | `Graph[N]`, `DiGraph[N]`, generic node types, cached metrics |
| **Algorithms** | BFS, DFS, Dijkstra, Bellman-Ford, PageRank, betweenness, Tarjan SCC, Kruskal/Prim MST, Edmonds-Karp max flow, topological sort |
| **Generators** | Complete, cycle, path, star, grid, Erdős-Rényi, Barabási-Albert, Watts-Strogatz, Petersen, Zachary karate club |
| **I/O** | Edge list, adjacency list, JSON node-link, DOT (Graphviz) |
| **Operators** | Union, complement, compose, intersection, node relabeling |
