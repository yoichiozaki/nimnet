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

## Notes

- NimNet is a pure Nim implementation with no C/Fortran dependencies.
- NetworkX PageRank uses scipy (C/Fortran backend), making direct comparison less meaningful for that benchmark.
- All graphs use the same random seed (42) for reproducibility.
- Each benchmark is run 5 times after a warmup; the median time is reported.
