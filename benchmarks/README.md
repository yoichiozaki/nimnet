# NimNet Benchmark Suite

Comparative benchmarks measuring NimNet performance against Python's [NetworkX](https://networkx.org/) on common graph operations.

## Benchmarks

| Benchmark | Description |
|-----------|-------------|
| `graph_creation` | Create a random graph with `n` nodes and `m` edges |
| `bfs` | Breadth-first search traversal from node 0 |
| `dfs` | Depth-first search preorder traversal from node 0 |
| `dijkstra` | Dijkstra shortest path on a weighted graph |
| `pagerank` | PageRank computation (20 iterations) |
| `connected_components` | Find all connected components |
| `mst_kruskal` | Kruskal minimum spanning tree |
| `louvain` | Louvain community detection |
| `clustering` | Average clustering coefficient |
| `triangles` | Triangle counting for all nodes |

## Graph Sizes

| Size | Nodes | Edges |
|------|-------|-------|
| small | 100 | 500 |
| medium | 1,000 | 5,000 |
| large | 10,000 | 50,000 |

Louvain, clustering, and triangles are skipped for `large` graphs (marked `NA`) to keep benchmark runtime reasonable.

## Running Benchmarks

### Prerequisites

- **Nim** >= 2.0.0 (for NimNet benchmarks)
- **Python** >= 3.10 with `networkx`, `numpy`, `scipy` (for NetworkX benchmarks)

### Quick Run

**Windows (PowerShell):**

```powershell
.\benchmarks\run_benchmarks.ps1
```

**Linux/macOS (Bash):**

```bash
bash benchmarks/run_benchmarks.sh
```

### Manual Run

**NimNet:**

```bash
nim c -d:release -d:danger --opt:speed -p:src -o:build/bench_nimnet benchmarks/bench_nimnet.nim
./build/bench_nimnet > results_nimnet.csv
```

**NetworkX:**

```bash
pip install networkx numpy scipy
python benchmarks/bench_networkx.py > results_networkx.csv
```

## Output Format

Both benchmarks output CSV with identical columns:

```
library,benchmark,size,nodes,edges,time_seconds
```

## Latest Results

Benchmark results comparing NimNet (compiled Nim, pure implementation) vs NetworkX 3.6 (Python + scipy/numpy C backend).
Compiled with `nim c -d:release -d:danger --opt:speed`.

### Large graph (10,000 nodes, 50,000 edges)

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | 0.014s | 0.051s | **NimNet 3.6× faster** |
| BFS | 0.008s | 0.015s | **NimNet 1.9× faster** |
| DFS | 0.006s | 0.010s | **NimNet 1.7× faster** |
| Dijkstra | 0.040s | 0.012s | NetworkX 3.3× faster |
| PageRank | 0.079s | 0.035s | NetworkX 2.3× faster\* |
| Connected components | 0.006s | 0.005s | ~1× |
| MST (Kruskal) | 0.077s | 0.088s | **NimNet 1.1× faster** |
| Louvain | NA | NA | — |
| Clustering | NA | NA | — |
| Triangles | NA | NA | — |

### Medium graph (1,000 nodes, 5,000 edges)

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | 0.001s | 0.005s | **NimNet 5× faster** |
| BFS | 0.001s | 0.002s | **NimNet 2× faster** |
| DFS | 0.001s | 0.001s | ~1× |
| Dijkstra | 0.002s | 0.001s | NetworkX 2× faster |
| PageRank | 0.007s | 0.004s | NetworkX 1.8× faster\* |
| Connected components | 0.001s | 0.000s | — |
| MST (Kruskal) | 0.005s | 0.005s | ~1× |
| Louvain | 0.625s | 0.091s | NetworkX 6.9× faster |
| Clustering | 0.013s | 0.015s | **NimNet 1.2× faster** |
| Triangles | 0.004s | 0.004s | ~1× |

### Small graph (100 nodes, 500 edges)

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | <0.001s | 0.001s | **NimNet faster** |
| BFS | <0.001s | 0.001s | **NimNet faster** |
| DFS | <0.001s | <0.001s | ~1× |
| Dijkstra | <0.001s | <0.001s | ~1× |
| PageRank | <0.001s | 0.205s | **NimNet >200× faster**\*\* |
| Connected components | <0.001s | <0.001s | ~1× |
| MST (Kruskal) | 0.001s | 0.001s | ~1× |
| Louvain | 0.006s | 0.006s | ~1× |
| Clustering | 0.001s | 0.002s | **NimNet 2× faster** |
| Triangles | 0.001s | 0.001s | ~1× |

\*NetworkX PageRank uses scipy (C/Fortran BLAS backend); NimNet is pure Nim.
\*\*Small graph PageRank dominated by scipy startup overhead.

### Key Optimizations

- **Dijkstra/Prim MST**: O(V²) → O((V+E) log V) via binary heap (`std/heapqueue`)
- **PageRank**: Pre-computed degrees, double-buffer swap, direct adjacency access
- **BFS/DFS**: Direct `g.adj[]` table access, pre-sized HashSets
- **Connected components**: `isConnected` as single BFS instead of computing all components
- **Clustering/triangles**: Direct neighbor table lookup instead of `hasEdge` (2→1 hash lookups)
- **Graph construction**: Deferred table allocation, right-sized initial tables

## Notes

- NimNet is a pure Nim implementation with no C/Fortran dependencies.
- NetworkX PageRank uses scipy (C/Fortran backend), making direct comparison less meaningful for that benchmark.
- All graphs use the same random seed (42) for reproducibility.
- Each benchmark is run 5 times after a warmup; the median time is reported.

## Micro-Benchmarks

Fine-grained benchmarks measuring individual graph operation performance.

| Benchmark | Description |
|-----------|-------------|
| `neighbor_iteration` | Iterate over all neighbors of every node |
| `weight_access` | Access edge weight for every edge |
| `has_edge` | Check edge existence for random node pairs |
| `node_iteration` | Iterate over all nodes |
| `edge_iteration` | Iterate over all edges |
| `degree_access` | Query degree for every node |
| `add_edge_bulk` | Build a graph by adding n×5 edges |
| `get_edge_attr` | Retrieve full edge attribute for every edge |

Graph sizes are the same as the main benchmarks (small: 100, medium: 1,000, large: 10,000 nodes). All graphs use random seed 42.

### Running Micro-Benchmarks

**NimNet:**

```bash
nim c -d:release -d:danger --opt:speed -p:src -o:build/bench_micro benchmarks/bench_micro.nim
./build/bench_micro > results_micro_nimnet.csv
```

**NetworkX:**

```bash
pip install networkx
python benchmarks/bench_micro_networkx.py > results_micro_networkx.csv
```
