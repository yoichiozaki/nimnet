"""Render reproducible, dependency-free SVG charts from recorded NimNet evidence."""

import argparse
import csv
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
import json
import math
from pathlib import Path
import re
import xml.etree.ElementTree as ET

from compare_results import COLUMNS

ROOT = Path(__file__).resolve().parent
SVG = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG)

FAMILIES = (
    ("greedy_modularity", "Greedy modularity", "revision",
     "greedy_modularity", "greedy_modularity", "Original", "Incremental"),
    ("bipartite_matching", "Bipartite matching", "revision",
     "bipartite_matching", "bipartite_matching", "DFS augmentation", "Hopcroft-Karp"),
    ("sparse_apsp", "Sparse all-pairs paths", "algorithm",
     "floyd_warshall_sparse", "johnsons_sparse", "Floyd-Warshall", "Johnson"),
    ("sparse_gnp", "Sparse G(n,p) generation", "algorithm",
     "gnp_dense", "gnp_sparse", "Dense sampler", "Fast sampler"),
)
BENCHMARKS = {name for family in FAMILIES for name in family[3:5]}

STYLE = """
text { font-family: "Segoe UI", Arial, sans-serif; font-size: 14px; fill: #334155; }
.title { font-size: 28px; font-weight: 700; fill: #0f172a; }
.heading { font-size: 18px; font-weight: 700; fill: #0f172a; }
.section { font-size: 15px; font-weight: 700; fill: #334155; }
.small { font-size: 13px; fill: #475569; }
.tick { font-size: 12px; fill: #475569; }
.reference { fill: #475569; }
.improved { fill: #087f5b; font-weight: 600; }
.ratio { font-size: 24px; font-weight: 700; fill: #07543e; }
.grid { stroke: #dbe3eb; stroke-width: 1; }
.axis { stroke: #94a3b8; stroke-width: 1; }
.reference-line { stroke: #64748b; stroke-width: 3; fill: none; }
.improved-line { stroke: #087f5b; stroke-width: 3; fill: none; }
""".strip()


@dataclass(frozen=True)
class Sample:
    nodes: int
    edges: int
    milliseconds: Decimal


@dataclass(frozen=True)
class Comparison:
    key: str
    title: str
    category: str
    reference_label: str
    improved_label: str
    pairs: tuple[tuple[Sample, Sample], ...]

    @property
    def speedup(self):
        reference, improved = self.pairs[-1]
        return reference.milliseconds / improved.milliseconds


@dataclass(frozen=True)
class Snapshot:
    measured_date: str
    baseline: str
    candidate: str
    repetitions: int
    warmups: int
    environment: str
    comparisons: tuple[Comparison, ...]


def positive_decimal(value, context):
    try:
        number = Decimal(str(value))
    except InvalidOperation as error:
        raise ValueError(f"Invalid numeric evidence: {context}") from error
    if not number.is_finite() or number <= 0 or not math.isfinite(float(number)):
        raise ValueError(f"Evidence must be finite and positive: {context}")
    return number


def read_samples(path):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or ()) != COLUMNS:
            raise ValueError(f"Invalid evidence CSV header: {path}")
        samples = {}
        for row in reader:
            if set(row) != set(COLUMNS) or any(value is None for value in row.values()):
                raise ValueError(f"Malformed evidence CSV row: {path}")
            if row["library"] != "nimnet" or row["benchmark"] not in BENCHMARKS:
                raise ValueError(f"Unexpected library/workload in evidence: {path}")
            nodes, edges = int(row["nodes"]), int(row["edges"])
            if nodes <= 0 or not 0 <= edges <= nodes * (nodes - 1) // 2:
                raise ValueError(f"Invalid graph dimensions in evidence: {path}")
            if row["size"] != f"n{nodes}":
                raise ValueError(f"Size label does not match node count: {path}")
            key = row["benchmark"], nodes
            if key in samples:
                raise ValueError(f"Duplicate evidence row {key}: {path}")
            milliseconds = positive_decimal(row["time_seconds"], key) * 1000
            if not math.isfinite(float(milliseconds)) or float(milliseconds) <= 0:
                raise ValueError(f"Timing is outside the renderable range: {key}")
            samples[key] = Sample(nodes, edges, milliseconds)
    if not samples:
        raise ValueError(f"Empty evidence CSV: {path}")
    return samples


def required_text(mapping, key):
    if not isinstance(mapping, dict) or not isinstance(mapping.get(key), str) or not mapping[key]:
        raise ValueError(f"Missing/invalid metadata field: {key}")
    return mapping[key]


def first_description(metadata, key, field):
    records = metadata.get(key)
    if not isinstance(records, list) or not records:
        raise ValueError(f"Missing environment evidence: {key}")
    return required_text(records[0], field)


def load_snapshot(directory, recorded_date):
    prefix = recorded_date.isoformat()
    before = read_samples(directory / f"{prefix}-before.csv")
    after = read_samples(directory / f"{prefix}-after.csv")
    metadata = json.loads((directory / f"{prefix}-environment.json").read_text(encoding="utf-8-sig"))
    if not isinstance(metadata, dict):
        raise ValueError("Environment evidence must be a JSON object")
    revisions = []
    for key in ("baseline_revision", "candidate_revision"):
        revision = required_text(metadata, key)
        if not re.fullmatch(r"[0-9a-f]{40}", revision):
            raise ValueError(f"Invalid source revision: {key}")
        revisions.append(revision[:7])
    measured = datetime.fromisoformat(required_text(metadata, "measured_at_utc"))
    if measured.tzinfo is None:
        raise ValueError("Measurement timestamp must include its timezone")
    for key, minimum in (("repetitions", 1), ("warmups_per_workload", 0)):
        if type(metadata.get(key)) is not int or metadata[key] < minimum:
            raise ValueError(f"Invalid measurement configuration: {key}")
    nim = re.search(r"Nim Compiler Version (\S+)", required_text(metadata, "nim_version"))
    if nim is None:
        raise ValueError("Nim compiler version is missing from the evidence")
    system = first_description(metadata, "operating_system", "Caption").removeprefix("Microsoft ")
    processor = first_description(metadata, "processors", "Name")
    processor = processor.replace("(R)", "").replace("(TM)", "")

    recorded = metadata.get("validated_comparisons")
    if not isinstance(recorded, list):
        raise ValueError("Validated comparison metadata is missing")
    checks = {}
    for item in recorded:
        name = required_text(item, "name")
        if name in checks:
            raise ValueError(f"Duplicate comparison metadata: {name}")
        checks[name] = item

    comparisons = []
    expected_checks = set()
    for key, title, category, old_name, new_name, old_label, new_label in FAMILIES:
        source = before if category == "revision" else after
        reference = {nodes: row for (name, nodes), row in source.items() if name == old_name}
        improved = {nodes: row for (name, nodes), row in after.items() if name == new_name}
        if len(reference) < 2 or reference.keys() != improved.keys():
            raise ValueError(f"Missing/unmatched measurement sizes for {key}")
        pairs = tuple((reference[n], improved[n]) for n in sorted(reference))
        if key != "sparse_gnp" and any(a.edges != b.edges for a, b in pairs):
            raise ValueError(f"Different graph inputs in paired evidence: {key}")
        comparison = Comparison(key, title, category, old_label, new_label, pairs)
        check_name = f"{key}_{pairs[-1][0].nodes}"
        expected_checks.add(check_name)
        if check_name not in checks:
            raise ValueError(f"Missing validated comparison: {check_name}")
        check = checks[check_name]
        for field, sample in zip(("before_seconds", "after_seconds"), pairs[-1]):
            if positive_decimal(check.get(field), check_name) * 1000 != sample.milliseconds:
                raise ValueError(f"CSV and metadata disagree: {check_name} / {field}")
        recorded_ratio = positive_decimal(check.get("speedup"), check_name)
        if not math.isclose(float(recorded_ratio), float(comparison.speedup), rel_tol=1e-12):
            raise ValueError(f"CSV and speedup metadata disagree: {check_name}")
        comparisons.append(comparison)
    if set(checks) != expected_checks:
        raise ValueError("Unexpected validated comparison metadata")
    return Snapshot(
        measured.date().isoformat(), *revisions, metadata["repetitions"],
        metadata["warmups_per_workload"], f"Nim {nim[1]} | {system} | {processor}",
        tuple(comparisons),
    )


def coordinate(value):
    if not math.isfinite(value):
        raise ValueError("Nonfinite chart coordinate")
    return f"{value:.3f}".rstrip("0").rstrip(".") if value else "0"


def milliseconds(value):
    return f"{value:,.4f}".rstrip("0").rstrip(".")


def log_domain(values):
    lower = math.floor(math.log10(min(values)))
    upper = math.ceil(math.log10(max(values)))
    if lower == upper:
        upper += 1
    return lower, upper


def log_position(value, bounds, start, end):
    lower, upper = bounds
    if not math.isfinite(value) or value <= 0 or lower >= upper:
        raise ValueError("Invalid logarithmic chart domain")
    return start + (math.log10(value) - lower) / (upper - lower) * (end - start)


def tick_label(exponent):
    value = Decimal(10) ** exponent
    return f"{value:,.0f}" if exponent >= 0 else format(value, "f")


class Drawing:
    def __init__(self, width, height, title, description):
        self.root = ET.Element(f"{{{SVG}}}svg", {
            "width": str(width), "height": str(height), "viewBox": f"0 0 {width} {height}",
            "role": "img", "aria-labelledby": "chart-title chart-description",
        })
        self.add("title", id="chart-title").text = title
        self.add("desc", id="chart-description").text = description
        self.add("style").text = STYLE
        self.add("rect", x=0, y=0, width=width, height=height, fill="#ffffff", rx=16)

    def add(self, tag, parent=None, **attributes):
        encoded = {
            key.replace("_", "-"): coordinate(value) if isinstance(value, float) else str(value)
            for key, value in attributes.items()
        }
        return ET.SubElement(self.root if parent is None else parent, f"{{{SVG}}}{tag}", encoded)

    def text(self, x, y, value, style=None, anchor="start"):
        attributes = {"x": x, "y": y, "text_anchor": anchor}
        if style:
            attributes["class"] = style
        self.add("text", **attributes).text = value

    def mark(self, x, y, improved, label):
        if improved:
            points = " ".join(f"{coordinate(a)},{coordinate(b)}" for a, b in (
                (x, y - 6), (x + 6, y), (x, y + 6), (x - 6, y),
            ))
            marker = self.add("polygon", points=points, fill="#087f5b", stroke="#ffffff",
                              stroke_width=1.5, data_series="improved")
        else:
            marker = self.add("circle", cx=x, cy=y, r=5, fill="#ffffff",
                              stroke="#64748b", stroke_width=2.5, data_series="reference")
        self.add("title", parent=marker).text = label

    def legend(self, y):
        self.mark(790, y, False, "Reference / earlier method")
        self.text(804, y + 5, "Reference / earlier", "small")
        self.mark(992, y, True, "Improved method")
        self.text(1006, y + 5, "Improved", "small")

    def serialize(self):
        ET.indent(self.root, space="  ")
        return ET.tostring(self.root, encoding="unicode") + "\n"


def subtitle(snapshot):
    return (f"{snapshot.measured_date} | Median of {snapshot.repetitions} runs after "
            f"{snapshot.warmups} warmup | NimNet only, not a NetworkX comparison")


def overview(snapshot):
    drawing = Drawing(
        1180, 676, "NimNet improvement snapshot",
        "Paired elapsed times on a logarithmic millisecond axis; lower is better. "
        "The first two workloads compare revisions, the other two compare algorithms "
        "within the candidate revision. The right-hand values are reference/improved time ratios.",
    )
    drawing.text(32, 42, "NimNet improvement snapshot", "title")
    drawing.text(32, 70, subtitle(snapshot), "small")
    drawing.legend(96)
    drawing.text(36, 119, f"REVISION COMPARISON   {snapshot.baseline} -> {snapshot.candidate}", "section")
    drawing.text(36, 367, f"ALGORITHM CHOICE   within {snapshot.candidate}", "section")
    for y, height in ((133, 180), (386, 173)):
        drawing.add("rect", x=24, y=y, width=1132, height=height, rx=12,
                    fill="#f8fafc", stroke="#e2e8f0")
    values = [float(sample.milliseconds) for c in snapshot.comparisons for sample in c.pairs[-1]]
    bounds = log_domain(values)
    left, right = 332, 972
    for exponent in range(bounds[0], bounds[1] + 1):
        x = log_position(10.0 ** exponent, bounds, left, right)
        for y1, y2 in ((143, 303), (396, 549)):
            drawing.add("line", x1=x, y1=y1, x2=x, y2=y2, **{"class": "grid"})
        drawing.text(x, 583, tick_label(exponent), "tick", "middle")
    drawing.text((left + right) / 2, 609, "Elapsed time in milliseconds (log scale) | lower is better",
                 "small", "middle")
    for comparison, y in zip(snapshot.comparisons, (178, 269, 425, 516)):
        reference, improved = comparison.pairs[-1]
        drawing.text(38, y - 16, comparison.title, "heading")
        drawing.text(38, y + 5, f"{comparison.reference_label} -> {comparison.improved_label}", "small")
        detail = (f"{reference.nodes:,} nodes / {reference.edges:,} edges"
                  if comparison.key != "sparse_gnp" else f"{reference.nodes:,} nodes / p = 4 / n")
        drawing.text(38, y + 25, detail, "tick")
        x1 = log_position(float(reference.milliseconds), bounds, left, right)
        x2 = log_position(float(improved.milliseconds), bounds, left, right)
        drawing.add("line", x1=x1, y1=y, x2=x2, y2=y, stroke="#94a3b8", stroke_width=2)
        for sample, x, is_improved, label in (
            (reference, x1, False, comparison.reference_label),
            (improved, x2, True, comparison.improved_label),
        ):
            drawing.mark(x, y, is_improved, f"{label}: {milliseconds(sample.milliseconds)} ms")
            drawing.text(x, y + 25 if is_improved else y - 14,
                         f"{milliseconds(sample.milliseconds)} ms",
                         "improved" if is_improved else "reference", "middle")
        drawing.add("rect", x=997, y=y - 29, width=143, height=59, rx=10, fill="#e4f5ed")
        drawing.text(1068, y - 2, f"{comparison.speedup:,.1f}x", "ratio", "middle")
        drawing.text(1068, y + 18, "reference / improved", "tick", "middle")
    drawing.text(32, 638, snapshot.environment, "small")
    drawing.text(32, 659, "G(n,p): equal n, p and seed; different sampled edges. These are fixture-specific observations.", "small")
    return drawing.serialize()


def scaling(snapshot):
    drawing = Drawing(
        1180, 1012, "NimNet timings across recorded graph sizes",
        "Four panels show every recorded size. Node counts are on linear x axes; "
        "elapsed milliseconds are on logarithmic y axes, with independent ranges per panel. "
        "Hollow circles represent the reference and diamonds the improved method. "
        "Lines join measurements only and are not extrapolations.",
    )
    drawing.text(32, 42, "Timings across recorded graph sizes", "title")
    drawing.text(32, 70, subtitle(snapshot), "small")
    drawing.legend(96)
    for index, comparison in enumerate(snapshot.comparisons):
        x, y = 24 + (index % 2) * 580, 128 + (index // 2) * 422
        drawing.add("rect", x=x, y=y, width=552, height=390, rx=12,
                    fill="#f8fafc", stroke="#e2e8f0")
        drawing.text(x + 20, y + 32, comparison.title, "heading")
        drawing.text(x + 20, y + 56,
                     f"{comparison.reference_label} vs {comparison.improved_label}", "small")
        left, right, top, bottom = x + 83, x + 528, y + 101, y + 310
        bounds = log_domain([float(s.milliseconds) for pair in comparison.pairs for s in pair])
        drawing.text(left, top - 15, "Time (ms, log scale) | lower is better", "small")
        for exponent in range(bounds[0], bounds[1] + 1):
            position = log_position(10.0 ** exponent, bounds, bottom, top)
            drawing.add("line", x1=left, y1=position, x2=right, y2=position, **{"class": "grid"})
            drawing.text(left - 12, position + 4, tick_label(exponent), "tick", "end")
        sizes = [pair[0].nodes for pair in comparison.pairs]
        for nodes in sizes:
            position = left + (nodes - sizes[0]) / (sizes[-1] - sizes[0]) * (right - left)
            drawing.add("line", x1=position, y1=top, x2=position, y2=bottom, **{"class": "grid"})
            drawing.text(position, bottom + 23, f"{nodes:,}", "tick", "middle")
        drawing.text((left + right) / 2, bottom + 48, "Number of nodes (linear scale)", "small", "middle")
        for series, improved in ((0, False), (1, True)):
            points = []
            for pair in comparison.pairs:
                sample = pair[series]
                px = left + (sample.nodes - sizes[0]) / (sizes[-1] - sizes[0]) * (right - left)
                py = log_position(float(sample.milliseconds), bounds, bottom, top)
                points.append((px, py, sample))
            drawing.add("polyline", points=" ".join(f"{coordinate(a)},{coordinate(b)}" for a, b, _ in points),
                        **{"class": "improved-line" if improved else "reference-line"})
            label = comparison.improved_label if improved else comparison.reference_label
            for px, py, sample in points:
                drawing.mark(px, py, improved,
                             f"{label}, {sample.nodes:,} nodes: {milliseconds(sample.milliseconds)} ms")
    drawing.text(32, 972, "Independent y ranges per panel. Lines guide the eye between measured sizes; no extrapolation.", "small")
    drawing.text(32, 994, snapshot.environment, "small")
    return drawing.serialize()


def render(snapshot):
    return {"overview.svg": overview(snapshot), "scaling.svg": scaling(snapshot)}


def write_charts(charts, directory, prefix, check=False):
    if check:
        for name, content in charts.items():
            path = directory / f"{prefix}-{name}"
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                raise ValueError(f"Missing/stale chart: {path}; regenerate without --check")
    else:
        directory.mkdir(parents=True, exist_ok=True)
        for name, content in charts.items():
            (directory / f"{prefix}-{name}").write_text(content, encoding="utf-8", newline="\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--date", type=date.fromisoformat, default=date(2026, 9, 12))
    parser.add_argument("--evidence-dir", type=Path, default=ROOT / "evidence")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "charts")
    parser.add_argument("--check", action="store_true", help="Reject missing/stale images without rewriting them")
    args = parser.parse_args()
    try:
        snapshot = load_snapshot(args.evidence_dir, args.date)
        write_charts(render(snapshot), args.output_dir, args.date.isoformat(), args.check)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"{'Verified' if args.check else 'Generated'} 2 benchmark charts in {args.output_dir}")


if __name__ == "__main__":
    main()
