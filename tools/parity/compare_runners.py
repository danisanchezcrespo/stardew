#!/usr/bin/env python3
"""Execute parity scenarios in Python and Godot and compare their snapshots."""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from legacy_runner import REPOSITORY_ROOT, run_scenario


DEFAULT_ABSOLUTE_TOLERANCE = 1e-9


def find_godot() -> Path:
    configured = os.environ.get("GODOT_BIN")
    candidates = [
        configured,
        shutil.which("godot"),
        shutil.which("godot4"),
        r"D:\Godot\Godot_v4.7.1-stable_win64_console.exe",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return Path(candidate)
    raise FileNotFoundError("Godot not found. Set GODOT_BIN to its console executable.")


def run_godot_scenario(godot: Path, scenario: Path) -> dict[str, Any]:
    log_path = REPOSITORY_ROOT / "godot" / ".godot" / "parity-runner.log"
    with tempfile.TemporaryDirectory() as directory:
        output_path = Path(directory) / "snapshot.json"
        command = [
            str(godot),
            "--headless",
            "--path",
            str(REPOSITORY_ROOT / "godot"),
            "--log-file",
            str(log_path),
            "--script",
            "res://tools/parity_runner.gd",
            "--",
            "--scenario",
            str(scenario),
            "--output",
            str(output_path),
        ]
        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
        if completed.returncode != 0 or not output_path.is_file():
            details = "\n".join(
                part.strip()
                for part in (completed.stdout, completed.stderr)
                if part.strip()
            )
            raise RuntimeError(
                f"Godot runner failed for {scenario.name} "
                f"with exit code {completed.returncode}:\n{details}"
            )
        return json.loads(output_path.read_text(encoding="utf-8"))


def first_difference(
    expected: Any,
    actual: Any,
    path: str = "$",
    tolerance: float = DEFAULT_ABSOLUTE_TOLERANCE,
) -> str | None:
    if (
        isinstance(expected, (int, float))
        and not isinstance(expected, bool)
        and isinstance(actual, (int, float))
        and not isinstance(actual, bool)
    ):
        if math.isclose(float(expected), float(actual), rel_tol=0.0, abs_tol=tolerance):
            return None
        return f"{path}: expected {expected!r}, got {actual!r}"

    if type(expected) is not type(actual):
        return f"{path}: expected type {type(expected).__name__}, got {type(actual).__name__}"
    if isinstance(expected, dict):
        expected_keys = set(expected)
        actual_keys = set(actual)
        if expected_keys != actual_keys:
            missing = sorted(expected_keys - actual_keys)
            extra = sorted(actual_keys - expected_keys)
            return f"{path}: key mismatch; missing={missing}, extra={extra}"
        for key in sorted(expected):
            difference = first_difference(expected[key], actual[key], f"{path}.{key}", tolerance)
            if difference:
                return difference
        return None
    if isinstance(expected, list):
        if len(expected) != len(actual):
            return f"{path}: expected length {len(expected)}, got {len(actual)}"
        for index, (expected_item, actual_item) in enumerate(zip(expected, actual)):
            difference = first_difference(
                expected_item,
                actual_item,
                f"{path}[{index}]",
                tolerance,
            )
            if difference:
                return difference
        return None
    if expected != actual:
        return f"{path}: expected {expected!r}, got {actual!r}"
    return None


def compare_scenario(godot: Path, scenario: Path, tolerance: float) -> str | None:
    legacy = run_scenario(scenario)
    godot_result = run_godot_scenario(godot, scenario)
    legacy_comparable = {
        "snapshot_format_version": legacy["snapshot_format_version"],
        "scenario": legacy["scenario"],
        "steps": legacy["steps"],
        "simulated_seconds": legacy["simulated_seconds"],
        "simulation": legacy["simulation"],
    }
    godot_comparable = {
        "snapshot_format_version": godot_result["snapshot_format_version"],
        "scenario": godot_result["scenario"],
        "steps": godot_result["steps"],
        "simulated_seconds": godot_result["simulated_seconds"],
        "simulation": godot_result["simulation"],
    }
    return first_difference(legacy_comparable, godot_comparable, tolerance=tolerance)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scenarios", nargs="*", help="Scenario paths; defaults to all golden scenarios")
    parser.add_argument("--godot", type=Path, help="Godot console executable")
    parser.add_argument("--tolerance", type=float, default=DEFAULT_ABSOLUTE_TOLERANCE)
    args = parser.parse_args()

    godot = args.godot.resolve() if args.godot else find_godot()
    scenario_root = Path(__file__).resolve().parent / "scenarios"
    scenarios = [Path(value).resolve() for value in args.scenarios]
    if not scenarios:
        scenarios = sorted(scenario_root.glob("*.json"))

    failed = False
    for scenario in scenarios:
        difference = compare_scenario(godot, scenario, args.tolerance)
        if difference:
            failed = True
            print(f"FAIL {scenario.name}: {difference}")
        else:
            print(f"PASS {scenario.name}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
