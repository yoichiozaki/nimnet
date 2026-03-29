"""
Generate reference values from NetworkX for cross-validation with NimNet.

This script computes algorithm outputs on specific graphs and prints them
in a format that can be used to write Nim test assertions.
"""

import networkx as nx
import json
from collections import OrderedDict

# ============================================================
# 1. Karate club graph (well-known, 34 nodes, 78 edges)
# ============================================================
K = nx.karate_club_graph()
print("=== Karate Club Graph ===")
print(f"Nodes: {K.number_of_nodes()}")
print(f"Edges: {K.number_of_edges()}")

# Shortest path
sp = nx.shortest_path(K, 0, 33)
print(f"shortest_path(0, 33) = {sp}")
print(f"shortest_path_length(0, 33) = {nx.shortest_path_length(K, 0, 33)}")

# Diameter / Radius / Center / Eccentricity
print(f"diameter = {nx.diameter(K)}")
print(f"radius = {nx.radius(K)}")
center = sorted(nx.center(K))
print(f"center = {center}")
ecc = nx.eccentricity(K)
print(f"eccentricity[0] = {ecc[0]}")
print(f"eccentricity[33] = {ecc[33]}")
print(f"eccentricity[2] = {ecc[2]}")

# Degree centrality (top 5)
dc = nx.degree_centrality(K)
dc_sorted = sorted(dc.items(), key=lambda x: -x[1])
print("degree_centrality top 5:")
for node, val in dc_sorted[:5]:
    print(f"  node {node}: {val:.10f}")

# Closeness centrality (selected nodes)
cc = nx.closeness_centrality(K)
for n in [0, 2, 33]:
    print(f"closeness_centrality[{n}] = {cc[n]:.10f}")

# Betweenness centrality (selected nodes)
bc = nx.betweenness_centrality(K, normalized=True)
for n in [0, 2, 33]:
    print(f"betweenness_centrality[{n}] = {bc[n]:.10f}")

# PageRank
pr = nx.pagerank(K, alpha=0.85, weight=None)  # NimNet karate club has no edge weights
for n in [0, 2, 33]:
    print(f"pagerank[{n}] = {pr[n]:.10f}")
print(f"pagerank sum = {sum(pr.values()):.10f}")

# Clustering coefficient
for n in [0, 2, 33]:
    print(f"clustering[{n}] = {nx.clustering(K, n):.10f}")
print(f"average_clustering = {nx.average_clustering(K):.10f}")
print(f"transitivity = {nx.transitivity(K):.10f}")

# Triangles
for n in [0, 33]:
    print(f"triangles[{n}] = {nx.triangles(K, n)}")

# Connected components
print(f"number_connected_components = {nx.number_connected_components(K)}")
print(f"is_connected = {nx.is_connected(K)}")

# Wiener index
print(f"wiener_index = {nx.wiener_index(K)}")

# Global efficiency
print(f"global_efficiency = {nx.global_efficiency(K):.10f}")

# Rich club coefficient
rc = nx.rich_club_coefficient(K, normalized=False)
for k in sorted(rc.keys())[:5]:
    print(f"rich_club[{k}] = {rc[k]:.10f}")

# Core number
cn = nx.core_number(K)
for n in [0, 1, 2, 33]:
    print(f"core_number[{n}] = {cn[n]}")

# ============================================================
# 2. Petersen graph (10 nodes, 15 edges, 3-regular)
# ============================================================
P = nx.petersen_graph()
print("\n=== Petersen Graph ===")
print(f"Nodes: {P.number_of_nodes()}")
print(f"Edges: {P.number_of_edges()}")
print(f"diameter = {nx.diameter(P)}")
print(f"radius = {nx.radius(P)}")
print(f"girth = {nx.girth(P)}")
print(f"is_connected = {nx.is_connected(P)}")
print(f"average_clustering = {nx.average_clustering(P):.10f}")
print(f"transitivity = {nx.transitivity(P):.10f}")
print(f"wiener_index = {nx.wiener_index(P)}")

pr_p = nx.pagerank(P, alpha=0.85)
print(f"pagerank[0] = {pr_p[0]:.10f}")
# All nodes equal by symmetry
print(f"pagerank all equal = {all(abs(v - 0.1) < 1e-6 for v in pr_p.values())}")

# Core number (Petersen is 3-regular)
cn_p = nx.core_number(P)
print(f"core_number[0] = {cn_p[0]}")
print(f"all core 3 = {all(v == 3 for v in cn_p.values())}")

# Chromatic number (Petersen = 3)
print(f"greedy_coloring_colors = {max(nx.coloring.greedy_color(P).values()) + 1}")

# ============================================================
# 3. Path graph P_5 (5 nodes, 4 edges)
# ============================================================
P5 = nx.path_graph(5)
print("\n=== Path Graph P5 ===")
print(f"diameter = {nx.diameter(P5)}")
print(f"radius = {nx.radius(P5)}")
print(f"center = {sorted(nx.center(P5))}")
print(f"periphery = {sorted(nx.periphery(P5))}")

bc5 = nx.betweenness_centrality(P5, normalized=True)
for n in range(5):
    print(f"betweenness_centrality[{n}] = {bc5[n]:.10f}")

cc5 = nx.closeness_centrality(P5)
for n in range(5):
    print(f"closeness_centrality[{n}] = {cc5[n]:.10f}")

sp5 = nx.shortest_path(P5, 0, 4)
print(f"shortest_path(0, 4) = {sp5}")

print(f"wiener_index = {nx.wiener_index(P5)}")

# ============================================================
# 4. Complete graph K_5 (5 nodes, 10 edges)
# ============================================================
K5 = nx.complete_graph(5)
print("\n=== Complete Graph K5 ===")
print(f"diameter = {nx.diameter(K5)}")
print(f"radius = {nx.radius(K5)}")
print(f"average_clustering = {nx.average_clustering(K5):.10f}")
print(f"transitivity = {nx.transitivity(K5):.10f}")
print(f"wiener_index = {nx.wiener_index(K5)}")
print(f"global_efficiency = {nx.global_efficiency(K5):.10f}")
print(f"is_connected = {nx.is_connected(K5)}")
for n in range(5):
    print(f"triangles[{n}] = {nx.triangles(K5, n)}")

bc_k5 = nx.betweenness_centrality(K5, normalized=True)
print(f"betweenness_centrality[0] = {bc_k5[0]:.10f}")
# All should be 0 in complete graph
print(f"all betweenness zero = {all(abs(v) < 1e-10 for v in bc_k5.values())}")

# ============================================================
# 5. Cycle graph C_6 (6 nodes, 6 edges)
# ============================================================
C6 = nx.cycle_graph(6)
print("\n=== Cycle Graph C6 ===")
print(f"diameter = {nx.diameter(C6)}")
print(f"radius = {nx.radius(C6)}")
print(f"girth = {nx.girth(C6)}")
print(f"average_clustering = {nx.average_clustering(C6):.10f}")
print(f"transitivity = {nx.transitivity(C6):.10f}")
print(f"wiener_index = {nx.wiener_index(C6)}")
print(f"global_efficiency = {nx.global_efficiency(C6):.10f}")

pr_c6 = nx.pagerank(C6, alpha=0.85)
print(f"pagerank[0] = {pr_c6[0]:.10f}")
print(f"all pagerank equal = {all(abs(v - 1/6) < 1e-6 for v in pr_c6.values())}")

# ============================================================
# 6. Directed graph for PageRank / HITS / SCC
# ============================================================
DG = nx.DiGraph()
DG.add_edges_from([(0,1), (1,2), (2,0), (2,3), (3,4), (4,3)])
print("\n=== Directed Graph ===")
print(f"Nodes: {DG.number_of_nodes()}")
print(f"Edges: {DG.number_of_edges()}")

pr_dg = nx.pagerank(DG, alpha=0.85)
for n in range(5):
    print(f"pagerank[{n}] = {pr_dg[n]:.10f}")

hubs, auths = nx.hits(DG, max_iter=100, tol=1e-8)
for n in range(5):
    print(f"hits_hub[{n}] = {hubs[n]:.10f}")
    print(f"hits_auth[{n}] = {auths[n]:.10f}")

sccs = sorted([sorted(c) for c in nx.strongly_connected_components(DG)])
print(f"strongly_connected_components = {sccs}")
print(f"number_strongly_connected = {nx.number_strongly_connected_components(DG)}")

# ============================================================
# 7. Weighted graph for Dijkstra / MST
# ============================================================
WG = nx.Graph()
WG.add_weighted_edges_from([
    (0, 1, 4.0), (0, 2, 2.0), (1, 2, 1.0),
    (1, 3, 5.0), (2, 3, 8.0), (2, 4, 10.0), (3, 4, 2.0)
])
print("\n=== Weighted Graph ===")
sp_w = nx.dijkstra_path(WG, 0, 4)
print(f"dijkstra_path(0, 4) = {sp_w}")
print(f"dijkstra_path_length(0, 4) = {nx.dijkstra_path_length(WG, 0, 4):.10f}")

sp_w2 = nx.dijkstra_path(WG, 0, 3)
print(f"dijkstra_path(0, 3) = {sp_w2}")
print(f"dijkstra_path_length(0, 3) = {nx.dijkstra_path_length(WG, 0, 3):.10f}")

mst = nx.minimum_spanning_tree(WG)
mst_weight = sum(d['weight'] for u, v, d in mst.edges(data=True))
print(f"mst_weight = {mst_weight:.10f}")
print(f"mst_edges = {sorted([(min(u,v), max(u,v)) for u, v in mst.edges()])}")

# ============================================================
# 8. Max flow directed graph
# ============================================================
FG = nx.DiGraph()
FG.add_edge(0, 1, capacity=10)
FG.add_edge(0, 2, capacity=8)
FG.add_edge(1, 3, capacity=5)
FG.add_edge(1, 2, capacity=2)
FG.add_edge(2, 4, capacity=10)
FG.add_edge(3, 5, capacity=7)
FG.add_edge(4, 3, capacity=8)
FG.add_edge(4, 5, capacity=10)
print("\n=== Flow Graph ===")
flow_val, flow_dict = nx.maximum_flow(FG, 0, 5)
print(f"max_flow_value(0, 5) = {flow_val:.10f}")

# ============================================================
# 9. Bipartite graph
# ============================================================
BG = nx.complete_bipartite_graph(3, 4)
print("\n=== Complete Bipartite K(3,4) ===")
print(f"is_bipartite = {nx.is_bipartite(BG)}")
print(f"is_connected = {nx.is_connected(BG)}")
print(f"diameter = {nx.diameter(BG)}")
print(f"number_of_edges = {BG.number_of_edges()}")

# ============================================================
# 10. Bellman-Ford on weighted directed graph
# ============================================================
BFG = nx.DiGraph()
BFG.add_weighted_edges_from([
    (0, 1, 6.0), (0, 2, 7.0), (1, 2, 8.0),
    (1, 3, 5.0), (1, 4, -4.0), (2, 3, -3.0),
    (2, 4, 9.0), (3, 1, -2.0), (4, 0, 2.0), (4, 3, 7.0)
])
print("\n=== Bellman-Ford Directed Graph ===")
for target in range(5):
    try:
        length = nx.bellman_ford_path_length(BFG, 0, target)
        path = nx.bellman_ford_path(BFG, 0, target)
        print(f"bellman_ford(0, {target}): length={length:.10f}, path={path}")
    except nx.NetworkXNoPath:
        print(f"bellman_ford(0, {target}): no path")

# ============================================================
# 11. All simple paths
# ============================================================
ASP = nx.Graph()
ASP.add_edges_from([(0,1), (0,2), (1,3), (2,3), (1,2)])
print("\n=== All Simple Paths Graph ===")
paths = list(nx.all_simple_paths(ASP, 0, 3))
paths_sorted = sorted([list(p) for p in paths])
print(f"all_simple_paths(0, 3) = {paths_sorted}")
print(f"count = {len(paths_sorted)}")

paths_cutoff = list(nx.all_simple_paths(ASP, 0, 3, cutoff=2))
paths_cutoff_sorted = sorted([list(p) for p in paths_cutoff])
print(f"all_simple_paths(0, 3, cutoff=2) = {paths_cutoff_sorted}")

# ============================================================
# 12. Graph products verification
# ============================================================
G1 = nx.path_graph(3)  # 0-1-2
G2 = nx.path_graph(2)  # 0-1
CP = nx.cartesian_product(G1, G2)
print("\n=== Graph Products ===")
print(f"cartesian_product(P3, P2) nodes = {CP.number_of_nodes()}")
print(f"cartesian_product(P3, P2) edges = {CP.number_of_edges()}")

TP = nx.tensor_product(G1, G2)
print(f"tensor_product(P3, P2) nodes = {TP.number_of_nodes()}")
print(f"tensor_product(P3, P2) edges = {TP.number_of_edges()}")

SP = nx.strong_product(G1, G2)
print(f"strong_product(P3, P2) nodes = {SP.number_of_nodes()}")
print(f"strong_product(P3, P2) edges = {SP.number_of_edges()}")

LP = nx.lexicographic_product(G1, G2)
print(f"lexicographic_product(P3, P2) nodes = {LP.number_of_nodes()}")
print(f"lexicographic_product(P3, P2) edges = {LP.number_of_edges()}")

# ============================================================
# Summary
# ============================================================
print("\n=== DONE ===")
