"""
NetworkX benchmark suite for comparison with nimnet.

Outputs CSV matching nimnet format:
  library,benchmark,size,nodes,edges,time_seconds

Usage:
  pip install networkx
  python bench_networkx.py
"""

import time
import statistics
import networkx as nx

from fixtures import benchmark_runs, load_fixtures
from bench_graphs import build_fixture

BENCH_RUNS = benchmark_runs()


def bench(func, *args, **kwargs):
    """Run function multiple times and return median elapsed time."""
    # Warmup run (not timed)
    result = func(*args, **kwargs)
    times = []
    for _ in range(BENCH_RUNS):
        t0 = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - t0
        times.append(elapsed)
    return statistics.median(times), result


def bench_graph_creation(fixture):
    t, g = bench(build_fixture, fixture)
    assert len(g) == fixture["nodes"] and g.number_of_edges() == len(fixture["edges"])
    return t


def bench_bfs(g):
    t, count = bench(lambda: sum(1 for _ in nx.bfs_edges(g, 0)))
    assert count > 0
    return t


def bench_dfs(g):
    t, _ = bench(lambda: list(nx.dfs_preorder_nodes(g, 0)))
    return t


def bench_dijkstra(g, target):
    t, _ = bench(nx.dijkstra_path, g, 0, target)
    return t


def bench_pagerank(g):
    def run():
        ranks = nx.pagerank(g, alpha=0.85, max_iter=100, tol=1e-6 / len(g), weight=None)
        assert len(ranks) == len(g)
        total = 0.0
        for value in ranks.values():
            assert value >= 0.0
            total += value
        assert abs(total - 1.0) < 1e-8
        return ranks
    t, _ = bench(run)
    return t


def bench_connected_components(g):
    t, _ = bench(lambda: list(nx.connected_components(g)))
    return t


def bench_mst_kruskal(g):
    t, _ = bench(lambda: list(nx.minimum_spanning_edges(g, algorithm="kruskal")))
    return t


def bench_louvain(g):
    t, _ = bench(
        nx.community.louvain_communities, g, weight=None, resolution=1.0,
        seed=42, threshold=0.0, max_level=20,
    )
    return t


def bench_clustering(g):
    t, _ = bench(nx.average_clustering, g)
    return t


def bench_triangles(g):
    t, _ = bench(nx.triangles, g)
    return t


def main():
    fixtures = load_fixtures()
    print("library,benchmark,size,nodes,edges,time_seconds")

    for fixture in fixtures:
        size_name, n, m = fixture["name"], fixture["nodes"], len(fixture["edges"])
        # Graph creation
        t = bench_graph_creation(fixture)
        print(f"networkx,graph_creation,{size_name},{n},{m},{t:.6f}")

        g = build_fixture(fixture)
        gw = build_fixture(fixture, weighted=True)
        assert len(gw) == n and gw.number_of_edges() == m
        assert all(gw[u][v]["weight"] == w / 1000.0 for u, v, w in fixture["edges"])

        # BFS
        t = bench_bfs(g)
        print(f"networkx,bfs,{size_name},{n},{m},{t:.6f}")

        # DFS
        t = bench_dfs(g)
        print(f"networkx,dfs,{size_name},{n},{m},{t:.6f}")

        # Dijkstra
        target = n // 2
        t = bench_dijkstra(gw, target)
        print(f"networkx,dijkstra,{size_name},{n},{m},{t:.6f}")

        # PageRank
        t = bench_pagerank(g)
        print(f"networkx,pagerank,{size_name},{n},{m},{t:.6f}")

        # Connected components
        t = bench_connected_components(g)
        print(f"networkx,connected_components,{size_name},{n},{m},{t:.6f}")

        # MST (Kruskal)
        t = bench_mst_kruskal(gw)
        print(f"networkx,mst_kruskal,{size_name},{n},{m},{t:.6f}")

        # Louvain
        t = bench_louvain(g)
        print(f"networkx,louvain,{size_name},{n},{m},{t:.6f}")

        # Clustering
        t = bench_clustering(g)
        print(f"networkx,clustering,{size_name},{n},{m},{t:.6f}")

        # Triangles
        t = bench_triangles(g)
        print(f"networkx,triangles,{size_name},{n},{m},{t:.6f}")


if __name__ == "__main__":
    main()
