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
| **Algorithms (61 modules)** | Traversal, shortest paths, centrality, communities, connectivity, flow, matching, spectral analysis, layouts, approximation and network analysis. Includes exact cardinality matching, Hopcroft-Karp and sparse undirected all-pairs paths introduced in 1.1.0. |
| **Generators (21 modules)** | Classic, random, sparse G(n,p), small/famous, tree, lattice, geometric, community, degree-sequence, directed, duplication, expander, Harary, internet, intersection, joint-degree, Mycielski, non-isomorphic tree, stochastic, triad and miscellaneous generators. |
| **I/O (13 modules)** | Edge list, adjacency list, multiline adjacency list, JSON graph, DOT, GML, GraphML, GEXF, Graph6/Sparse6, Pajek, LEDA, network text and SVG. Some formats are export-only. |
| **Operators** | Union, complement, compose, intersection, difference, disjoint union, node relabeling, directed ↔ undirected conversion |
| **Other** | Builder DSL, graph views (lazy subgraph/filter), CompactGraph (CSR), StaticGraph (compile-time), built-in datasets (dolphins, Florentine families, les misérables), adjacency matrix/edge list conversion, parallel algorithms (malebolgia threading) |

## Performance

Performance varies by algorithm, graph and hardware. The
[benchmark suite](https://github.com/yoichiozaki/nimnet/tree/main/benchmarks)
uses shared graph/weight fixtures, equivalent operations, monotonic elapsed
timing, sequential runs and recorded environments. Historical tables using
different random graphs and timing methods have been retired.

The [improvement backlog]({{ site.baseurl }}/backlog) records the changes
introduced in 1.1.0 and their delivery evidence.
