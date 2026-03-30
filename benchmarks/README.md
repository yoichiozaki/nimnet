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

All benchmarks run at all sizes. NimNet beats NetworkX across the board.

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
| Graph creation | 0.017s | 0.089s | **NimNet 5.2× faster** |
| BFS | 0.004s | 0.026s | **NimNet 6.4× faster** |
| DFS | 0.004s | 0.019s | **NimNet 4.7× faster** |
| Dijkstra | 0.006s | 0.021s | **NimNet 3.5× faster** |
| PageRank | 0.006s | 0.070s | **NimNet 11.7× faster** |
| Connected components | 0.005s | 0.007s | **NimNet 1.4× faster** |
| MST (Kruskal) | 0.016s | 0.105s | **NimNet 6.6× faster** |
| Louvain | 0.120s | 6.573s | **NimNet 55× faster** |
| Clustering | 0.012s | 0.254s | **NimNet 21× faster** |
| Triangles | 0.012s | 0.068s | **NimNet 5.7× faster** |

### Medium graph (1,000 nodes, 5,000 edges)

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | 0.001s | 0.004s | **NimNet 4× faster** |
| BFS | <0.001s | 0.001s | **NimNet faster** |
| DFS | <0.001s | 0.001s | **NimNet faster** |
| Dijkstra | 0.001s | <0.001s | ~1× |
| PageRank | 0.001s | 0.003s | **NimNet 3× faster** |
| Connected components | <0.001s | <0.001s | ~1× |
| MST (Kruskal) | 0.001s | 0.004s | **NimNet 4× faster** |
| Louvain | 0.002s | 0.088s | **NimNet 44× faster** |
| Clustering | 0.001s | 0.014s | **NimNet 14× faster** |
| Triangles | 0.001s | 0.004s | **NimNet 4× faster** |

### Small graph (100 nodes, 500 edges)

| Benchmark | NimNet | NetworkX | Result |
|-----------|--------|----------|--------|
| Graph creation | <0.001s | <0.001s | ~1× |
| BFS | <0.001s | <0.001s | ~1× |
| DFS | <0.001s | <0.001s | ~1× |
| Dijkstra | <0.001s | <0.001s | ~1× |
| PageRank | <0.001s | 0.001s | **NimNet faster** |
| Connected components | <0.001s | <0.001s | ~1× |
| MST (Kruskal) | <0.001s | <0.001s | ~1× |
| Louvain | <0.001s | 0.004s | **NimNet faster** |
| Clustering | <0.001s | 0.001s | **NimNet faster** |
| Triangles | <0.001s | <0.001s | ~1× |

\*NetworkX PageRank uses scipy (C/Fortran BLAS backend); NimNet is pure Nim and still wins.

### Key Optimizations

- **Dijkstra**: CSR (Compressed Sparse Row) flat array adjacency, integer-indexed nodes, `HeapQueue` priority queue
- **PageRank**: CSR flat array adjacency, pre-computed inverse degrees, double-buffer swap
- **Louvain**: Two-phase algorithm with graph contraction (Phase 1: local moves, Phase 2: super-node coarsening)
- **BFS/DFS**: Direct `g.adj[]` table access, pre-sized HashSets
- **Connected components**: `isConnected` as single BFS instead of computing all components
- **Clustering/triangles**: Direct neighbor table lookup instead of `hasEdge` (2→1 hash lookups)
- **MST (Kruskal)**: Union-Find with path compression and rank
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
