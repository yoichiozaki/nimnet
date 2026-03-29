"""
NetworkX micro-benchmark suite for comparison with NimNet.

Measures fine-grained graph operation performance across small (100),
medium (1,000), and large (10,000) node graphs.

Outputs CSV matching nimnet format:
  library,benchmark,size,nodes,edges,time_seconds

Usage:
  pip install networkx
  python bench_micro_networkx.py
"""

import time
import random
import statistics
import networkx as nx

random.seed(42)

BENCH_RUNS = 5  # Number of timed runs per benchmark


def bench(fn):
    """Run fn multiple times and return the median elapsed time."""
    # Warmup run (not timed)
    fn()
    times = []
    for _ in range(BENCH_RUNS):
        t0 = time.perf_counter()
        fn()
        times.append(time.perf_counter() - t0)
    return statistics.median(times)


def build_graph(n, seed=42):
    """Build an Erdős-Rényi-like graph: n nodes, ~n*5 edges."""
    rng = random.Random(seed)
    g = nx.Graph()
    g.add_nodes_from(range(n))
    added = 0
    m = n * 5
    while added < m:
        u = rng.randint(0, n - 1)
        v = rng.randint(0, n - 1)
        if u != v and not g.has_edge(u, v):
            g.add_edge(u, v, weight=rng.uniform(1.0, 10.0))
            added += 1
    return g


def bench_neighbor_iteration(g):
    def fn():
        total = 0
        for node in g.nodes():
            for _ in g.neighbors(node):
                total += 1
        assert total > 0
    return bench(fn)


def bench_weight_access(g):
    def fn():
        total = 0.0
        for u, v, data in g.edges(data=True):
            total += data.get("weight", 1.0)
        assert total > 0
    return bench(fn)


def bench_has_edge(g, n):
    rng = random.Random(42)
    pairs = [(rng.randint(0, n - 1), rng.randint(0, n - 1)) for _ in range(n * 5)]

    def fn():
        count = 0
        for u, v in pairs:
            if g.has_edge(u, v):
                count += 1
        assert count >= 0
    return bench(fn)


def bench_node_iteration(g):
    def fn():
        total = 0
        for _ in g.nodes():
            total += 1
        assert total > 0
    return bench(fn)


def bench_edge_iteration(g):
    def fn():
        total = 0
        for _ in g.edges():
            total += 1
        assert total > 0
    return bench(fn)


def bench_degree_access(g):
    def fn():
        total = 0
        for node in g.nodes():
            total += g.degree(node)
        assert total > 0
    return bench(fn)


def bench_add_edge_bulk(n):
    rng = random.Random(42)
    pairs = [(rng.randint(0, n - 1), rng.randint(0, n - 1)) for _ in range(n * 5)]

    def fn():
        g = nx.Graph()
        g.add_nodes_from(range(n))
        for u, v in pairs:
            if u != v:
                g.add_edge(u, v)
        assert g.number_of_nodes() == n
    return bench(fn)


def bench_get_edge_attr(g):
    edges = list(g.edges())

    def fn():
        total = 0.0
        for u, v in edges:
            total += g[u][v].get("weight", 1.0)
        assert total > 0
    return bench(fn)


def run_benchmarks():
    print("library,benchmark,size,nodes,edges,time_seconds")

    sizes = [
        ("small",  100,    500),
        ("medium", 1_000,  5_000),
        ("large",  10_000, 50_000),
    ]

    for size_name, n, _ in sizes:
        g = build_graph(n)
        m = g.number_of_edges()

        t = bench_neighbor_iteration(g)
        print(f"networkx,neighbor_iteration,{size_name},{n},{m},{t:.6f}")

        t = bench_weight_access(g)
        print(f"networkx,weight_access,{size_name},{n},{m},{t:.6f}")

        t = bench_has_edge(g, n)
        print(f"networkx,has_edge,{size_name},{n},{m},{t:.6f}")

        t = bench_node_iteration(g)
        print(f"networkx,node_iteration,{size_name},{n},{m},{t:.6f}")

        t = bench_edge_iteration(g)
        print(f"networkx,edge_iteration,{size_name},{n},{m},{t:.6f}")

        t = bench_degree_access(g)
        print(f"networkx,degree_access,{size_name},{n},{m},{t:.6f}")

        t = bench_add_edge_bulk(n)
        print(f"networkx,add_edge_bulk,{size_name},{n},{m},{t:.6f}")

        t = bench_get_edge_attr(g)
        print(f"networkx,get_edge_attr,{size_name},{n},{m},{t:.6f}")


if __name__ == "__main__":
    run_benchmarks()
