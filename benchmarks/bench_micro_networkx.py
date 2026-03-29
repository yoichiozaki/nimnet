"""
NetworkX micro-benchmark suite for comparison with nimnet.

Measures fundamental graph data structure operations independently,
enabling identification of bottlenecks in iterator and attribute access overhead.

Outputs CSV matching nimnet format:
  library,benchmark,size,nodes,edges,time_seconds

Usage:
  pip install networkx
  python benchmarks/bench_micro_networkx.py
"""

import time
import random
import networkx as nx


def bench(func, *args, **kwargs):
    """Run function and return elapsed wall-clock time in seconds."""
    t0 = time.perf_counter()
    result = func(*args, **kwargs)
    elapsed = time.perf_counter() - t0
    return elapsed, result


def build_erdos_renyi(n, m, seed=42):
    """Build random graph with n nodes, m edges."""
    return nx.gnm_random_graph(n, m, seed=seed)


def build_weighted_erdos_renyi(n, m, seed=42):
    """Build weighted random graph with n nodes, m edges."""
    g = nx.gnm_random_graph(n, m, seed=seed)
    rng = random.Random(seed)
    for u, v in g.edges():
        g[u][v]["weight"] = rng.random() * 10.0
    return g


def bench_neighbor_iteration(g):
    """How fast can we iterate g.neighbors(v) for all v?"""
    def run():
        count = 0
        for node in g.nodes():
            for _ in g.neighbors(node):
                count += 1
        assert count > 0
    t, _ = bench(run)
    return t


def bench_weight_access(g):
    """How fast can we access edge weight for all edges?"""
    def run():
        total = 0.0
        for u, v, d in g.edges(data=True):
            total += d.get("weight", 1.0)
        assert total > 0
    t, _ = bench(run)
    return t


def bench_has_edge(g, n):
    """How fast is g.has_edge(u, v) for random (u, v) pairs?"""
    rng = random.Random(42)
    pairs = [(rng.randint(0, n - 1), rng.randint(0, n - 1)) for _ in range(100_000)]

    def run():
        count = sum(1 for u, v in pairs if g.has_edge(u, v))
        return count
    t, _ = bench(run)
    return t


def bench_node_iteration(g):
    """How fast can we iterate for n in g.nodes()?"""
    def run():
        count = sum(1 for _ in g.nodes())
        assert count > 0
    t, _ = bench(run)
    return t


def bench_edge_iteration(g):
    """How fast can we iterate for (u, v) in g.edges()?"""
    def run():
        count = sum(1 for _ in g.edges())
        assert count > 0
    t, _ = bench(run)
    return t


def bench_degree_access(g):
    """How fast is g.degree() for all nodes?"""
    def run():
        total = sum(d for _, d in g.degree())
        assert total > 0
    t, _ = bench(run)
    return t


def bench_add_edge_bulk(n, m):
    """How fast can we build a graph by adding edges?"""
    rng = random.Random(42)
    pairs = [(rng.randint(0, n - 1), rng.randint(0, n - 1)) for _ in range(m)]

    def run():
        g = nx.Graph()
        for u, v in pairs:
            g.add_edge(u, v)
        assert g.number_of_nodes() > 0
    t, _ = bench(run)
    return t


def bench_get_edge_attr(g):
    """How fast can we access the edge attribute dict for all edges?"""
    def run():
        count = 0
        for u, v, d in g.edges(data=True):
            if d.get("weight", 1.0) > 0.0:
                count += 1
        assert count > 0
    t, _ = bench(run)
    return t


def main():
    print("library,benchmark,size,nodes,edges,time_seconds")
    sizes = [(10_000, 50_000, "large"), (1_000, 5_000, "medium"), (100, 500, "small")]

    for n, m, size_name in sizes:
        g = build_erdos_renyi(n, m)
        gw = build_weighted_erdos_renyi(n, m)

        t = bench_neighbor_iteration(g)
        print(f"networkx_micro,neighbor_iteration,{size_name},{n},{m},{t:.6f}")

        t = bench_weight_access(gw)
        print(f"networkx_micro,weight_access,{size_name},{n},{m},{t:.6f}")

        t = bench_has_edge(g, n)
        print(f"networkx_micro,has_edge,{size_name},{n},{m},{t:.6f}")

        t = bench_node_iteration(g)
        print(f"networkx_micro,node_iteration,{size_name},{n},{m},{t:.6f}")

        t = bench_edge_iteration(g)
        print(f"networkx_micro,edge_iteration,{size_name},{n},{m},{t:.6f}")

        t = bench_degree_access(g)
        print(f"networkx_micro,degree_access,{size_name},{n},{m},{t:.6f}")

        t = bench_add_edge_bulk(n, m)
        print(f"networkx_micro,add_edge_bulk,{size_name},{n},{m},{t:.6f}")

        t = bench_get_edge_attr(gw)
        print(f"networkx_micro,get_edge_attr,{size_name},{n},{m},{t:.6f}")


if __name__ == "__main__":
    main()
