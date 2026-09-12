"""Validate complete, finite benchmark results before merging their CSV files."""

import argparse
import csv
import math
from pathlib import Path

from fixtures import selected_sizes

COLUMNS = ("library", "benchmark", "size", "nodes", "edges", "time_seconds")
BENCHMARKS = (
    "graph_creation", "bfs", "dfs", "dijkstra", "pagerank",
    "connected_components", "mst_kruskal", "louvain", "clustering", "triangles",
)
MICRO_BENCHMARKS = (
    "neighbor_iteration", "weight_access", "has_edge", "node_iteration",
    "edge_iteration", "degree_access", "add_edge_bulk", "get_edge_attr",
)


def read_results(path, sizes, benchmarks=BENCHMARKS):
    expected = {
        (benchmark, name): (n, m)
        for name, n, m in sizes
        for benchmark in benchmarks
    }
    with path.open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or ()) != COLUMNS:
            raise ValueError(f"Invalid CSV header: {path}")
        rows = list(reader)
    library = None
    seen = set()
    for row in rows:
        if set(row) != set(COLUMNS) or any(value is None for value in row.values()):
            raise ValueError(f"Malformed CSV row: {path}")
        if row["library"] not in ("nimnet", "networkx"):
            raise ValueError(f"Unknown benchmark library: {path}")
        if library is None:
            library = row["library"]
        if row["library"] != library:
            raise ValueError(f"Mixed libraries in a single result file: {path}")
        key = row["benchmark"], row["size"]
        if key not in expected or key in seen:
            raise ValueError(f"Unknown/duplicate benchmark row {key}: {path}")
        if (int(row["nodes"]), int(row["edges"])) != expected[key]:
            raise ValueError(f"Incorrect graph dimensions for {key}: {path}")
        elapsed = float(row["time_seconds"])
        if not math.isfinite(elapsed) or elapsed < 0:
            raise ValueError(f"Invalid elapsed time for {key}: {path}")
        seen.add(key)
    if seen != set(expected):
        raise ValueError(f"Incomplete benchmark results: {path}")
    return library, rows


def merge_results(inputs, output, sizes, benchmarks=BENCHMARKS):
    libraries = set()
    rows = []
    for path in inputs:
        library, current = read_results(path, sizes, benchmarks)
        if library in libraries:
            raise ValueError(f"Duplicate result library: {library}")
        libraries.add(library)
        rows.extend(current)
    if "nimnet" not in libraries:
        raise ValueError("NimNet results are required")
    with output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--suite", choices=("main", "micro"), default="main")
    parser.add_argument("inputs", type=Path, nargs="+")
    args = parser.parse_args()
    benchmarks = MICRO_BENCHMARKS if args.suite == "micro" else BENCHMARKS
    merge_results(args.inputs, args.output, selected_sizes(), benchmarks)


if __name__ == "__main__":
    main()
