import copy
import csv
from datetime import date
from decimal import Decimal
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "benchmarks"))
sys.path.insert(0, str(ROOT / "tools"))

from compare_results import BENCHMARKS, COLUMNS, MICRO_BENCHMARKS, merge_results, read_results
from build_docs import has_diagnostics
from coverage_badge import coverage_counts, make_badge
from fixtures import benchmark_runs, make_fixture, query_pairs, selected_sizes, validate_fixture, write_metadata
from render_charts import SVG, load_snapshot, log_position, read_samples, render, write_charts


class FixtureTests(unittest.TestCase):
    def test_repeatability_and_simple_graph_invariants(self):
        fixture = make_fixture("tiny", 20, 80)
        self.assertEqual(fixture, make_fixture("tiny", 20, 80))
        self.assertNotEqual(fixture, make_fixture("tiny", 20, 80, seed=43))
        self.assertEqual(validate_fixture(fixture, ("tiny", 20, 80)), fixture)
        self.assertEqual(len({tuple(edge[:2]) for edge in fixture["edges"]}), 80)
        self.assertTrue(all(0 <= u < v < 20 for u, v, _ in fixture["edges"]))
        self.assertEqual(json.loads(json.dumps(fixture)), fixture)

    def test_boundary_and_invalid_sizes(self):
        for n in (0, 1, 5):
            for m in (0, n * (n - 1) // 2):
                fixture = make_fixture("tiny", n, m)
                validate_fixture(fixture, ("tiny", n, m))
        for n, m in ((-1, 0), (1, 1), (5, -1), (5, 11)):
            with self.subTest(n=n, m=m), self.assertRaises(ValueError):
                make_fixture("tiny", n, m)

    def test_invalid_fixture_records(self):
        fixture = make_fixture("tiny", 5, 3)
        for edge in ([0, 0, 1000], [0, 5, 1000], [1, 0, 1000],
                     [0, 1, 1], [0, 1, 1000.0], [0, 1], None):
            invalid = copy.deepcopy(fixture)
            invalid["edges"][0] = edge
            with self.subTest(edge=edge), self.assertRaises(ValueError):
                validate_fixture(invalid, ("tiny", 5, 3))
        invalid = copy.deepcopy(fixture)
        invalid["edges"][1] = invalid["edges"][0]
        with self.assertRaises(ValueError):
            validate_fixture(invalid, ("tiny", 5, 3))
        with self.assertRaises(ValueError):
            validate_fixture(fixture, ("different", 5, 3))
        for key, value in (("format_version", True), ("format_version", 1.0), ("nodes", 5.0)):
            invalid = copy.deepcopy(fixture)
            invalid[key] = value
            with self.assertRaises(ValueError):
                validate_fixture(invalid, ("tiny", 5, 3))

    def test_configuration(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(benchmark_runs(), 5)
            self.assertEqual(len(selected_sizes()), 3)
        for value in ("0", "-1", "NaN", ""):
            with patch.dict(os.environ, {"BENCH_RUNS": value}), self.assertRaises(ValueError):
                benchmark_runs()
        with patch.dict(os.environ, {"BENCH_SIZES": " medium,small,small"}):
            self.assertEqual([size[0] for size in selected_sizes()], ["small", "medium"])
        for value in ("tiny", "small,", ""):
            with patch.dict(os.environ, {"BENCH_SIZES": value}), self.assertRaises(ValueError):
                selected_sizes()

    def test_identical_deterministic_query_sequence(self):
        self.assertEqual(query_pairs(5), [(0, 1), (1, 3), (2, 0), (3, 2), (4, 4)] * 5)
        for n in (0, -1):
            with self.assertRaises(ValueError):
                query_pairs(n)


class ResultTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nimnet-results-")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.sizes = [("small", 100, 500)]

    def write_result(self, library="nimnet", mutate=None, benchmarks=BENCHMARKS):
        rows = [
            dict(zip(COLUMNS, (library, benchmark, "small", "100", "500", "0.001")))
            for benchmark in benchmarks
        ]
        if mutate:
            mutate(rows)
        path = self.directory / f"{library}.csv"
        with path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=COLUMNS)
            writer.writeheader()
            writer.writerows(rows)
        return path

    def test_complete_pair_and_explicit_nim_only(self):
        nimnet = self.write_result()
        networkx = self.write_result("networkx")
        output = self.directory / "combined.csv"
        merge_results([nimnet, networkx], output, self.sizes)
        with output.open(newline="", encoding="utf-8") as stream:
            self.assertEqual(len(list(csv.DictReader(stream))), 20)
        merge_results([nimnet], output, self.sizes)
        with output.open(newline="", encoding="utf-8") as stream:
            self.assertEqual(len(list(csv.DictReader(stream))), 10)
        with self.assertRaises(ValueError):
            merge_results([nimnet, nimnet], output, self.sizes)

    def test_micro_inventory_is_validated_separately(self):
        path = self.write_result(benchmarks=MICRO_BENCHMARKS)
        _, rows = read_results(path, self.sizes, MICRO_BENCHMARKS)
        self.assertEqual(len(rows), 8)
        with self.assertRaises(ValueError):
            read_results(path, self.sizes)

    def test_missing_duplicate_or_nonfinite_results_fail(self):
        mutations = [
            lambda rows: rows.pop(),
            lambda rows: rows.append(rows[0].copy()),
            lambda rows: rows[0].update(nodes="101"),
            lambda rows: rows[0].update(time_seconds="NaN"),
            lambda rows: rows[0].update(time_seconds="inf"),
            lambda rows: rows[0].update(time_seconds="-1"),
            lambda rows: rows[0].update(time_seconds="NA"),
        ]
        for mutate in mutations:
            path = self.write_result(mutate=mutate)
            with self.assertRaises(ValueError):
                read_results(path, self.sizes)


class CoverageTests(unittest.TestCase):
    def test_valid_counts_and_thresholds(self):
        content = "SF:src/a.nim\nLF:10\nLH:7\nend_of_record\n"
        content += "SF:src/b.nim\nLF:10\nLH:9\nend_of_record\n"
        self.assertEqual(coverage_counts(content), (16, 20))
        self.assertEqual(make_badge(content)["message"], "80.00%")
        self.assertEqual(make_badge(content)["color"], "brightgreen")
        for hits, color in ((0, "red"), (2, "orange"), (4, "yellowgreen"), (6, "green")):
            content = f"SF:src/a.nim\nLF:10\nLH:{hits}\nend_of_record\n"
            self.assertEqual(make_badge(content)["color"], color)

    def test_missing_or_inconsistent_coverage_is_not_zero_percent_success(self):
        for content in (
            "", "SF:src/a.nim\nLF:0\nLH:0\nend_of_record\n",
            "SF:src/a.nim\nLF:1\nLH:2\nend_of_record\n",
            "SF:src/a.nim\nLF:1\nend_of_record\n",
            "SF:src/a.nim\nLF:1\nLH:1\n",
            "SF:src/a.nim\nLF:-1\nLH:0\nend_of_record\n",
            "LF:2\nLH:1\nend_of_record\n",
            "SF:src/a.nim\nLF:2\nLF:2\nLH:1\nend_of_record\n",
        ):
            with self.subTest(content=content), self.assertRaises(ValueError):
                make_badge(content)


class DocumentationTests(unittest.TestCase):
    def test_false_green_doc_diagnostics_are_detected(self):
        for output in (
            "src/module.nim(12, 3) Error: '*' expected\n",
            "C:\\repo\\module.nim(1, 20) Warning: broken link 'N' [BrokenLink]\n",
            "Error: cannot open file\n",
            "Hint: processing source\nWarning: bad documentation\n",
        ):
            with self.subTest(output=output):
                self.assertTrue(has_diagnostics(output))

    def test_normal_output_is_not_a_diagnostic(self):
        self.assertFalse(has_diagnostics("Hint: processing source\nSuccess: generated docs\n"))
        self.assertFalse(has_diagnostics("A sentence mentioning Error: as ordinary text\n"))


class MetadataTests(unittest.TestCase):
    def test_main_configuration_and_exact_fixture_hash_are_recorded(self):
        with tempfile.TemporaryDirectory(prefix="nimnet-metadata-") as directory:
            root = Path(directory)
            fixture = root / "small.json"
            fixture.write_text(json.dumps(make_fixture("small", 100, 500)), encoding="utf-8")
            environment = {
                "BENCH_FIXTURES": directory, "BENCH_SIZES": "small", "BENCH_RUNS": "3",
            }
            with patch.dict(os.environ, environment), patch(
                "fixtures.platform.platform", return_value="test-platform",
            ), patch(
                "fixtures.subprocess.check_output",
                side_effect=["Nim test compiler\n", "test-revision\n", ""],
            ), patch("fixtures.importlib.metadata.version", return_value="test-version"):
                output = root / "metadata.json"
                write_metadata(output, include_networkx=True)
            data = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(data["runs"], 3)
            self.assertEqual(data["suite"], "main")
            self.assertEqual(data["revision"], "test-revision")
            self.assertFalse(data["working_tree_dirty"])
            self.assertEqual(data["fixtures"]["small"], hashlib.sha256(fixture.read_bytes()).hexdigest())
            self.assertEqual(data["pagerank"]["total_l1_tolerance"], 1e-6)
            self.assertFalse(data["pagerank"]["weighted"])
            self.assertEqual(data["louvain"]["seed"], 42)
            self.assertEqual(data["louvain"]["max_levels"], 20)
            self.assertEqual(set(data["packages"]), {"networkx", "numpy", "scipy"})

    def test_micro_metadata_does_not_claim_untimed_algorithm_parameters(self):
        with tempfile.TemporaryDirectory(prefix="nimnet-metadata-") as directory:
            root = Path(directory)
            (root / "small.json").write_text(
                json.dumps(make_fixture("small", 100, 500)), encoding="utf-8",
            )
            with patch.dict(os.environ, {
                "BENCH_FIXTURES": directory, "BENCH_SIZES": "small", "BENCH_RUNS": "1",
            }), patch("fixtures.platform.platform", return_value="test-platform"), patch(
                "fixtures.subprocess.check_output",
                side_effect=["Nim test compiler\n", "test-revision\n", " M file\n"],
            ):
                output = root / "metadata.json"
                write_metadata(output, suite="micro")
            data = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(data["suite"], "micro")
            self.assertTrue(data["working_tree_dirty"])
            self.assertNotIn("pagerank", data)
            self.assertNotIn("louvain", data)
            self.assertNotIn("packages", data)


class ChartTests(unittest.TestCase):
    recorded_date = date(2026, 9, 12)
    prefix = "2026-09-12"

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nimnet-charts-")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        for suffix in ("before.csv", "after.csv", "environment.json"):
            name = f"{self.prefix}-{suffix}"
            (self.directory / name).write_bytes((ROOT / "benchmarks" / "evidence" / name).read_bytes())

    def rows(self, suffix):
        with (self.directory / f"{self.prefix}-{suffix}.csv").open(
            encoding="utf-8-sig", newline=""
        ) as stream:
            return list(csv.DictReader(stream))

    def write_rows(self, suffix, rows):
        with (self.directory / f"{self.prefix}-{suffix}.csv").open(
            "w", encoding="utf-8", newline=""
        ) as stream:
            writer = csv.DictWriter(stream, fieldnames=COLUMNS)
            writer.writeheader()
            writer.writerows(rows)

    def test_chart_pairs_preserve_comparison_scope_and_exact_values(self):
        snapshot = load_snapshot(self.directory, self.recorded_date)
        self.assertEqual((snapshot.baseline, snapshot.candidate), ("2ece49c", "6e47786"))
        self.assertEqual([c.category for c in snapshot.comparisons],
                         ["revision", "revision", "algorithm", "algorithm"])
        self.assertEqual([len(c.pairs) for c in snapshot.comparisons], [3, 3, 3, 3])
        greedy, matching, apsp, gnp = snapshot.comparisons
        self.assertEqual(greedy.pairs[-1][0].milliseconds, Decimal("726.8526"))
        self.assertEqual(matching.pairs[-1][1].milliseconds, Decimal("13.0493"))
        self.assertEqual(apsp.pairs[-1][0].milliseconds, Decimal("1286.4617"))
        self.assertNotEqual(apsp.pairs[-1][0].milliseconds, Decimal("1297.6046"))
        self.assertEqual((gnp.pairs[-1][0].edges, gnp.pairs[-1][1].edges), (19951, 20052))

    def test_rendering_is_deterministic_and_independent_of_csv_order(self):
        expected = render(load_snapshot(self.directory, self.recorded_date))
        for suffix in ("before", "after"):
            self.write_rows(suffix, list(reversed(self.rows(suffix))))
        self.assertEqual(render(load_snapshot(self.directory, self.recorded_date)), expected)

    def test_images_are_accessible_and_include_all_measured_points(self):
        charts = render(load_snapshot(self.directory, self.recorded_date))
        for name, content in charts.items():
            root = ET.fromstring(content)
            self.assertEqual(root.attrib["role"], "img")
            self.assertEqual(root.attrib["aria-labelledby"], "chart-title chart-description")
            self.assertTrue(root.find(f"{{{SVG}}}title").text)
            self.assertTrue(root.find(f"{{{SVG}}}desc").text)
            self.assertFalse(root.findall(f".//{{{SVG}}}script"))
            self.assertIn("log scale", content)
            self.assertIn("not a NetworkX comparison", content)
            text = " ".join(root.itertext())
            for label in ("Floyd-Warshall", "Johnson", "Dense sampler", "Fast sampler"):
                self.assertIn(label, text)
            expected = 5 if name == "overview.svg" else 13
            for series in ("reference", "improved"):
                self.assertEqual(sum(e.get("data-series") == series for e in root.iter()), expected)
            width, height = float(root.get("width")), float(root.get("height"))
            for element in root.iter():
                for axis, maximum in (("x", width), ("cx", width), ("y", height), ("cy", height)):
                    if axis in element.attrib:
                        self.assertGreaterEqual(float(element.get(axis)), 0)
                        self.assertLessEqual(float(element.get(axis)), maximum)

    def test_log_axis_uses_equal_spacing_for_decades(self):
        positions = [log_position(v, (-1, 3), 0, 400) for v in (0.1, 1, 10, 100, 1000)]
        self.assertEqual(positions, [0, 100, 200, 300, 400])
        for invalid in (0, -1, float("nan"), float("inf")):
            with self.assertRaises(ValueError):
                log_position(invalid, (-1, 3), 0, 400)

    def test_nonpositive_or_nonfinite_measurements_are_rejected(self):
        original = self.rows("after")
        for value in ("0", "-1", "NaN", "Infinity", "invalid"):
            rows = copy.deepcopy(original)
            rows[0]["time_seconds"] = value
            self.write_rows("after", rows)
            with self.subTest(value=value), self.assertRaises(ValueError):
                read_samples(self.directory / f"{self.prefix}-after.csv")

    def test_missing_duplicate_or_changed_inputs_are_rejected(self):
        original = self.rows("after")
        mutations = [
            lambda rows: rows.pop(),
            lambda rows: rows.append(rows[0].copy()),
            lambda rows: rows[0].update(edges=str(int(rows[0]["edges"]) + 1)),
            lambda rows: rows[0].update(library="networkx"),
            lambda rows: rows[0].update(size="n0"),
        ]
        for mutation in mutations:
            rows = copy.deepcopy(original)
            mutation(rows)
            self.write_rows("after", rows)
            with self.assertRaises(ValueError):
                load_snapshot(self.directory, self.recorded_date)

    def test_stale_metadata_and_unsafe_numeric_configuration_are_rejected(self):
        path = self.directory / f"{self.prefix}-environment.json"
        original = json.loads(path.read_text(encoding="utf-8-sig"))
        for mutation in (
            lambda data: data["validated_comparisons"][0].update(speedup=2),
            lambda data: data["validated_comparisons"][0].update(before_seconds=1),
            lambda data: data.update(repetitions=True),
            lambda data: data.update(warmups_per_workload=-1),
            lambda data: data.update(candidate_revision="not-a-revision"),
        ):
            data = copy.deepcopy(original)
            mutation(data)
            path.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(ValueError):
                load_snapshot(self.directory, self.recorded_date)

    def test_metadata_text_is_xml_escaped(self):
        path = self.directory / f"{self.prefix}-environment.json"
        metadata = json.loads(path.read_text(encoding="utf-8-sig"))
        metadata["processors"][0]["Name"] = 'CPU <script> & "quoted"'
        path.write_text(json.dumps(metadata), encoding="utf-8")
        for content in render(load_snapshot(self.directory, self.recorded_date)).values():
            root = ET.fromstring(content)
            self.assertFalse(root.findall(f".//{{{SVG}}}script"))
            self.assertIn("&lt;script&gt; &amp;", content)

    def test_check_detects_stale_or_missing_assets_without_rewriting(self):
        charts = render(load_snapshot(self.directory, self.recorded_date))
        output = self.directory / "charts"
        with self.assertRaises(ValueError):
            write_charts(charts, output, self.prefix, check=True)
        self.assertFalse(output.exists())
        write_charts(charts, output, self.prefix)
        write_charts(charts, output, self.prefix, check=True)
        path = output / f"{self.prefix}-overview.svg"
        path.write_text("stale", encoding="utf-8")
        with self.assertRaises(ValueError):
            write_charts(charts, output, self.prefix, check=True)
        self.assertEqual(path.read_text(encoding="utf-8"), "stale")


if __name__ == "__main__":
    unittest.main()
