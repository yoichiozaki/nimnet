import copy
import csv
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "benchmarks"))
sys.path.insert(0, str(ROOT / "tools"))

from compare_results import BENCHMARKS, COLUMNS, MICRO_BENCHMARKS, merge_results, read_results
from build_docs import has_diagnostics
from coverage_badge import coverage_counts, make_badge
from fixtures import benchmark_runs, make_fixture, query_pairs, selected_sizes, validate_fixture, write_metadata


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


if __name__ == "__main__":
    unittest.main()
