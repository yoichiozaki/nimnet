"""Shared, versioned benchmark input files; requires only Python's stdlib."""

import argparse
import hashlib
import importlib.metadata
import json
import math
import os
from pathlib import Path
import platform
import random
import subprocess
import sys

SIZES = (("small", 100, 500), ("medium", 1_000, 5_000), ("large", 10_000, 50_000))
DEFAULT_DIR = Path(__file__).resolve().parent / "results" / "fixtures"


def benchmark_runs(default=5):
    runs = int(os.environ.get("BENCH_RUNS", str(default)))
    if runs < 1:
        raise ValueError("BENCH_RUNS must be positive")
    return runs


def selected_sizes():
    names = os.environ.get("BENCH_SIZES", "small,medium,large").split(",")
    names = [name.strip() for name in names]
    unknown = set(names) - {size[0] for size in SIZES}
    if unknown:
        raise ValueError(f"Unknown BENCH_SIZES entries: {sorted(unknown)}")
    return [size for size in SIZES if size[0] in names]


def make_fixture(name, n, m, seed=42):
    if n < 0 or not 0 <= m <= n * (n - 1) // 2:
        raise ValueError("Fixture size must describe a simple undirected graph")
    rng = random.Random(seed)
    pairs = []
    for index in rng.sample(range(n * (n - 1) // 2), m):
        # Invert the triangular edge index without enumerating every node pair.
        v = (1 + math.isqrt(1 + 8 * index)) // 2
        u = index - v * (v - 1) // 2
        pairs.append((u, v))
    edges = [[u, v, rng.randint(1000, 10000)] for u, v in sorted(pairs)]
    return {"format_version": 1, "name": name, "nodes": n, "seed": seed, "edges": edges}


def validate_fixture(data, size):
    name, n, m = size
    if (
        not isinstance(data, dict)
        or type(data.get("format_version")) is not int
        or data.get("format_version") != 1
        or data.get("name") != name
        or type(data.get("nodes")) is not int
        or data.get("nodes") != n
        or not isinstance(data.get("edges"), list)
        or len(data["edges"]) != m
    ):
        raise ValueError(f"Invalid fixture metadata for {name}")
    seen = set()
    for edge in data["edges"]:
        if (
            not isinstance(edge, list)
            or len(edge) != 3
            or any(type(value) is not int for value in edge)
        ):
            raise ValueError(f"Invalid fixture edge for {name}: {edge!r}")
        u, v, weight = edge
        if not 0 <= u < v < n or not 1000 <= weight <= 10000 or (u, v) in seen:
            raise ValueError(f"Invalid/duplicate fixture edge for {name}: {edge!r}")
        seen.add((u, v))
    return data


def fixture_dir():
    return Path(os.environ.get("BENCH_FIXTURES", DEFAULT_DIR))


def query_pairs(n):
    if n <= 0:
        raise ValueError("Query node count must be positive")
    return [(i % n, (i * 17 + 31) % n) for i in range(n * 5)]


def load_fixtures():
    result = []
    for size in selected_sizes():
        path = fixture_dir() / f"{size[0]}.json"
        with path.open(encoding="utf-8") as stream:
            result.append(validate_fixture(json.load(stream), size))
    return result


def write_fixtures(directory):
    directory.mkdir(parents=True, exist_ok=True)
    for name, n, m in selected_sizes():
        data = make_fixture(name, n, m)
        (directory / f"{name}.json").write_text(
            json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8"
        )


def write_metadata(path, include_networkx=False, suite="main"):
    root = Path(__file__).resolve().parent.parent
    metadata = {
        "platform": platform.platform(),
        "python": sys.version,
        "nim": subprocess.check_output(["nim", "--version"], text=True).strip(),
        "compiler_flags": "--threads:on -d:release --opt:speed",
        "revision": subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=root, text=True
        ).strip(),
        "working_tree_dirty": bool(
            subprocess.check_output(["git", "status", "--porcelain"], cwd=root, text=True)
        ),
        "runs": benchmark_runs(),
        "suite": suite,
        "statistic": "median elapsed seconds after one warmup",
        "fixtures": {
            name: hashlib.sha256((fixture_dir() / f"{name}.json").read_bytes()).hexdigest()
            for name, _, _ in selected_sizes()
        },
    }
    if suite == "main":
        metadata["pagerank"] = {
            "alpha": 0.85, "max_iterations": 100,
            "total_l1_tolerance": 1e-6, "weighted": False,
        }
        metadata["louvain"] = {
            "resolution": 1.0, "seed": 42, "max_levels": 20,
            "positive_gain_only": True,
        }
    if include_networkx:
        metadata["packages"] = {
            name: importlib.metadata.version(name) for name in ("networkx", "numpy", "scipy")
        }
    path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=fixture_dir())
    parser.add_argument("--metadata", type=Path)
    parser.add_argument("--suite", choices=("main", "micro"), default="main")
    parser.add_argument("--include-networkx", action="store_true")
    args = parser.parse_args()
    benchmark_runs()
    if args.metadata:
        write_metadata(args.metadata, args.include_networkx, args.suite)
    else:
        write_fixtures(args.output_dir)


if __name__ == "__main__":
    main()
