# NimNet Benchmark Suite

Reproducible comparisons with Python's [NetworkX](https://networkx.org/), plus
targeted before/after workloads for the library improvement backlog.

## Benchmarks

| Benchmark | Description |
|-----------|-------------|
| `graph_creation` | Build the supplied graph, excluding random generation and file I/O |
| `bfs` | Count yielded BFS tree edges from node 0 in both libraries |
| `dfs` | Materialize DFS preorder nodes |
| `dijkstra` | Materialize a weighted shortest path |
| `pagerank` | PageRank on the same unweighted graph |
| `connected_components` | Materialize connected-component sets |
| `mst_kruskal` | Materialize Kruskal minimum spanning tree edges |
| `louvain` | Louvain community detection |
| `clustering` | Average clustering coefficient |
| `triangles` | Triangle counts for all nodes |

| Size | Nodes | Edges |
|------|-------|-------|
| small | 100 | 500 |
| medium | 1,000 | 5,000 |
| large | 10,000 | 50,000 |

All workloads run at all sizes by default. Results are workload- and
hardware-dependent; neither implementation is claimed to win universally.

## Running benchmarks

Prerequisites: Nim >= 2.0.0, installed Nimble dependencies, and Python >= 3.12.
Install the pinned comparison environment from `requirements.txt`. Fixture
generation, result validation and metadata collection use only the stdlib.

**Windows (PowerShell):**

```powershell
python -m pip install -r benchmarks\requirements.txt
.\benchmarks\run_benchmarks.ps1
.\benchmarks\run_benchmarks.ps1 -Micro
```

**Linux/macOS (Bash):**

```bash
python -m pip install -r benchmarks/requirements.txt
bash benchmarks/run_benchmarks.sh
bash benchmarks/run_benchmarks.sh --micro
```

Use `-SkipNetworkX` / `--nim-only` to explicitly run without NetworkX.
An unavailable requested dependency, failed compiler/executable, invalid
configuration or malformed/incomplete CSV makes the runner fail. Previous
results are not silently reused.

### Configuration

| Variable | Meaning |
|----------|---------|
| `BENCH_RUNS` | Positive timed repetition count; default 5, CI 3 |
| `BENCH_SIZES` | Comma-separated subset of `small,medium,large`; unknown/empty entries fail |
| `BENCH_FIXTURES` | Optional fixture directory; default `benchmarks/results/fixtures` |

For a quick smoke run in PowerShell:

```powershell
$env:BENCH_SIZES = "small"
$env:BENCH_RUNS = "1"
.\benchmarks\run_benchmarks.ps1
Remove-Item Env:BENCH_SIZES, Env:BENCH_RUNS
```

One-run smoke output is not performance evidence.

## Output

Both implementations output the same CSV schema:

```text
library,benchmark,size,nodes,edges,time_seconds
```

Results are written to `benchmarks/results`: `nimnet.csv`, `networkx.csv`,
`combined.csv` and `metadata.json`. Micro results use a `micro_` prefix.
Metadata records the platform, compiler/package versions, Git revision, dirty
state, repetition count and SHA-256 fixture hashes. CI uploads the input fixtures
alongside the results so the exact graphs can be reused.

## Methodology

`fixtures.py` generates a versioned JSON G(n,m) fixture once per size, including
all node IDs and canonical undirected edges. Weights are integer thousandths
between 1 and 10. Both libraries load and validate the same bytes; they do not
independently regenerate supposedly identical graphs from different RNGs.
Weighted and unweighted workloads share topology. Parsing and generation are
outside timed sections, including the graph-construction workload.

All timing uses monotonic elapsed clocks, one untimed warmup and the median of
the requested repetitions (the mean of the two middle samples for even counts).
Runners execute libraries sequentially, not as competing background processes.
Builds use `--threads:on -d:release --opt:speed`, **not `-d:danger`**; assertions
and runtime checks remain enabled. Do not run other builds/benchmarks
concurrently when collecting evidence.

BFS counts edges in both implementations rather than comparing iteration with
NetworkX tree construction. DFS, shortest paths, component lists, MST edge
lists, PageRank maps and triangle maps are materialized consistently.
Heuristic algorithms can produce different partitions because iteration orders
and implementations differ; timings do not establish equal community quality.
NetworkX PageRank uses a SciPy
backend; the comparison is between user-facing implementations, not identical
machine-code kernels.

PageRank uses unit transitions, `alpha=0.85`, at most 100 iterations, and a total
L1 convergence tolerance of `1e-6` in both implementations. NetworkX therefore
receives `tol=1e-6/n` and `weight=None`. Both runners check nonnegative ranks
and conserved probability mass. Louvain uses `resolution=1.0`, nonzero seed
`42` and at most 20 levels; NetworkX receives `threshold=0.0` to match strictly
positive accepted gains. NimNet additionally caps each level at 100 passes,
which is not a public NetworkX parameter.

Historical tables generated with different random graphs, CPU-versus-elapsed
clocks or concurrent runners have been retired. They cannot substantiate
claims about the current code.

## Targeted improvement workloads

`bench_regressions.nim` covers clique-ring greedy modularity, triangular
bipartite matching, sparse weighted all-pairs paths, and sparse G(n,p)
generation. Its default is three repetitions after one warmup.

```powershell
nim c --threads:on -d:release --opt:speed -p:src `
  --nimcache:build\nimcache\regressions -o:build\bench_regressions.exe `
  benchmarks\bench_regressions.nim
.\build\bench_regressions.exe
```

For a before/after comparison, extract only `src` from the baseline commit
`2ece49c` into a separate build directory with `git archive`, and compile the
**same current benchmark driver** with `-p:` pointing to that source tree.
Compile both binaries before timing; never switch or overwrite the working
source tree just to benchmark it.

Community/matching timings compare identical deterministic graphs across
revisions. Floyd-Warshall versus the new undirected Johnson overload uses the
same weighted graph. Dense versus fast G(n,p) compares equal `(n, p, seed)`
parameters, **not identical output edges**; actual edge counts are recorded.
The new sparse generator intentionally does not reproduce the dense
generator's random stream.

## Micro-benchmarks

| Benchmark | Description |
|-----------|-------------|
| `neighbor_iteration` | Iterate all neighbors of every node |
| `weight_access` | Read the weight of every edge |
| `has_edge` | Execute the same deterministic node-pair query sequence |
| `node_iteration` | Iterate all nodes |
| `edge_iteration` | Iterate all edges |
| `degree_access` | Query the degree of every node |
| `add_edge_bulk` | Build the supplied graph by adding its edges |
| `get_edge_attr` | Retrieve edge attributes in fixture order |

Micro-benchmarks reuse the main suite's fixtures, graph constructors, timing
configuration and result validation. Lookup queries use
`(i mod n, (17*i+31) mod n)` for `i=0..5n-1` in both languages; attribute lookups
use fixture edge order. Use the `-Micro` / `--micro` runner options above.

`bench_parallel.nim` separately compares serial and parallel Nim algorithms on
the same graph, also using repeated median elapsed timing. Its text report is
diagnostic and is not part of the cross-library CSV comparison.
