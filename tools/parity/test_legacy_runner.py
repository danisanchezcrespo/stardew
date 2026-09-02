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
            "d37b1490e94fb3696cadb7d95cbde2c81dab617549b65f8af74f84bbc010865d",
        )

    def test_bundled_save_scenarios_are_stable(self) -> None:
        cases = {
            "egypt_10_ticks.json": (
                29,
                4,
                "be728a0fc33c9a10c36219590f5d4a47cc90d120ed93f31c01e8777df152a798",
            ),
            "eg2_10_ticks.json": (
                56,
                19,
                "99384dfa2d74b5740370a078b57e72aab3689e59b58c076c794c103159ce5738",
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
