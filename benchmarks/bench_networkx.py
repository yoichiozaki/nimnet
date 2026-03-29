"""
NetworkX benchmark suite for comparison with nimnet.

Outputs CSV matching nimnet format:
  library,benchmark,size,nodes,edges,time_seconds

Usage:
  pip install networkx
  python bench_networkx.py
"""

import time
import random
import networkx as nx

random.seed(42)


def bench(func, *args, **kwargs):
    """Run function and return elapsed CPU time in seconds."""
    t0 = time.perf_counter()
    result = func(*args, **kwargs)
    elapsed = time.perf_counter() - t0
    return elapsed, result


def build_erdos_renyi(n, m):
    """Build random graph with n nodes, m edges (same seed as Nim version)."""
    return nx.gnm_random_graph(n, m, seed=42)


def build_weighted_erdos_renyi(n, m):
    """Build weighted random graph."""
    g = nx.gnm_random_graph(n, m, seed=42)
    rng = random.Random(42)
    for u, v in g.edges():
        g[u][v]["weight"] = rng.uniform(1.0, 10.0)
    return g


def bench_graph_creation(n, m):
    t, g = bench(nx.gnm_random_graph, n, m, seed=42)
    return t


def bench_bfs(g):
    t, _ = bench(lambda: list(nx.bfs_tree(g, 0).nodes()))
    return t


def bench_dfs(g):
    t, _ = bench(lambda: list(nx.dfs_preorder_nodes(g, 0)))
    return t


def bench_dijkstra(g, target):
    t, _ = bench(nx.dijkstra_path, g, 0, target)
    return t


def bench_pagerank(g):
    t, _ = bench(nx.pagerank, g)
    return t


def bench_connected_components(g):
    t, _ = bench(lambda: list(nx.connected_components(g)))
    return t


def bench_mst_kruskal(g):
    t, _ = bench(lambda: list(nx.minimum_spanning_edges(g, algorithm="kruskal")))
    return t


def bench_louvain(g):
    t, _ = bench(nx.community.louvain_communities, g, seed=42)
    return t


def bench_clustering(g):
    t, _ = bench(nx.average_clustering, g)
    return t


def bench_triangles(g):
    t, _ = bench(nx.triangles, g)
    return t


SIZES = [
    ("small", 100, 500),
    ("medium", 1_000, 5_000),
    ("large", 10_000, 50_000),
]


def main():
    print("library,benchmark,size,nodes,edges,time_seconds")

    for size_name, n, m in SIZES:
        # Graph creation
        t = bench_graph_creation(n, m)
        print(f"networkx,graph_creation,{size_name},{n},{m},{t:.6f}")

        g = build_erdos_renyi(n, m)
        gw = build_weighted_erdos_renyi(n, m)

        # BFS
        t = bench_bfs(g)
        print(f"networkx,bfs,{size_name},{n},{m},{t:.6f}")

        # DFS
        t = bench_dfs(g)
        print(f"networkx,dfs,{size_name},{n},{m},{t:.6f}")

        # Dijkstra
        target = n // 2
        try:
            t = bench_dijkstra(gw, target)
            print(f"networkx,dijkstra,{size_name},{n},{m},{t:.6f}")
        except Exception:
            print(f"networkx,dijkstra,{size_name},{n},{m},NA")

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
        if n <= 1_000:
            t = bench_louvain(g)
            print(f"networkx,louvain,{size_name},{n},{m},{t:.6f}")
        else:
            print(f"networkx,louvain,{size_name},{n},{m},NA")

        # Clustering
        if n <= 1_000:
            t = bench_clustering(g)
            print(f"networkx,clustering,{size_name},{n},{m},{t:.6f}")
        else:
            print(f"networkx,clustering,{size_name},{n},{m},NA")

        # Triangles
        if n <= 1_000:
            t = bench_triangles(g)
            print(f"networkx,triangles,{size_name},{n},{m},{t:.6f}")
        else:
            print(f"networkx,triangles,{size_name},{n},{m},NA")


if __name__ == "__main__":
    main()
