import networkx as nx


def build_fixture(fixture, weighted=False):
    """Construct the shared graph, excluding generation and input parsing."""
    graph = nx.Graph()
    graph.add_nodes_from(range(fixture["nodes"]))
    if weighted:
        graph.add_weighted_edges_from(
            (u, v, weight / 1000.0) for u, v, weight in fixture["edges"]
        )
    else:
        graph.add_edges_from((u, v) for u, v, _ in fixture["edges"])
    return graph
