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
import statistics
from fixtures import benchmark_runs, load_fixtures, query_pairs
from bench_graphs import build_fixture

BENCH_RUNS = benchmark_runs()


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
    pairs = query_pairs(n)

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


def bench_add_edge_bulk(fixture):
    def fn():
        g = build_fixture(fixture)
        assert len(g) == fixture["nodes"] and g.number_of_edges() == len(fixture["edges"])
    return bench(fn)


def bench_get_edge_attr(g, fixture):
    edges = [(u, v) for u, v, _ in fixture["edges"]]

    def fn():
        total = 0.0
        for u, v in edges:
            total += g[u][v].get("weight", 1.0)
        assert total > 0
    return bench(fn)


def run_benchmarks():
    fixtures = load_fixtures()
    print("library,benchmark,size,nodes,edges,time_seconds")

    for fixture in fixtures:
        size_name, n, m = fixture["name"], fixture["nodes"], len(fixture["edges"])
        g = build_fixture(fixture, weighted=True)
        assert len(g) == n and g.number_of_edges() == m

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

        t = bench_add_edge_bulk(fixture)
        print(f"networkx,add_edge_bulk,{size_name},{n},{m},{t:.6f}")

        t = bench_get_edge_attr(g, fixture)
        print(f"networkx,get_edge_attr,{size_name},{n},{m},{t:.6f}")


if __name__ == "__main__":
    run_benchmarks()
