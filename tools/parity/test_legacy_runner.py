from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from legacy_runner import REPOSITORY_ROOT, run_scenario


SCENARIOS = Path(__file__).resolve().parent / "scenarios"


class LegacyRunnerTests(unittest.TestCase):
    def test_empty_sources_are_deterministic(self) -> None:
        path = SCENARIOS / "empty_sources_20_ticks.json"
        first = run_scenario(path)
        second = run_scenario(path)

        self.assertEqual(first, second)
        self.assertEqual(first["steps"], 20)
        self.assertEqual(first["simulated_seconds"], 2.0)
        self.assertEqual(len(first["simulation"]["nodes"]), 2)
        self.assertEqual(
            first["simulation_sha256"],
            "b3a63ff16e88bebee6b836a048b20e6d6047a15204d18f37fe4e57b8ad67c696",
        )

    def test_bundled_save_scenarios_are_stable(self) -> None:
        cases = {
            "egypt_10_ticks.json": (
                29,
                4,
                "fd4c08401874c40524808da85f5245f1d3c69cb49c4bf7542a38cd3e9479252e",
            ),
            "eg2_10_ticks.json": (
                56,
                19,
                "781400234fc95dbf23e00a8e0ed4e8a1ad65aa75aa5ada5fb100ea7424ed570e",
            ),
        }
        for filename, (node_count, edge_count, expected_digest) in cases.items():
            with self.subTest(filename=filename):
                result = run_scenario(SCENARIOS / filename)
                self.assertEqual(len(result["simulation"]["nodes"]), node_count)
                self.assertEqual(len(result["simulation"]["edges"]), edge_count)
                self.assertEqual(result["simulation_sha256"], expected_digest)

    def test_snapshot_is_json_serializable(self) -> None:
        result = run_scenario(SCENARIOS / "egypt_10_ticks.json")
        encoded = json.dumps(result, allow_nan=False, sort_keys=True)
        self.assertIn('"snapshot_format_version": 1', encoded)

    def test_scenario_paths_are_repository_relative(self) -> None:
        scenario = {
            "name": "load_fixture",
            "actions": [
                {
                    "op": "load_save",
                    "path": "legacy_simcity/data/egypt.json",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "scenario.json"
            path.write_text(json.dumps(scenario), encoding="utf-8")
            result = run_scenario(path)
        self.assertEqual(len(result["simulation"]["nodes"]), 29)
        self.assertTrue((REPOSITORY_ROOT / "legacy_simcity").is_dir())


if __name__ == "__main__":
    unittest.main()
