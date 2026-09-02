#!/usr/bin/env python3
"""Run deterministic, headless scenarios against the legacy simulator."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
LEGACY_ROOT = REPOSITORY_ROOT / "legacy_simcity"
SNAPSHOT_FORMAT_VERSION = 1
FLOAT_DIGITS = 12


@contextmanager
def _working_directory(path: Path) -> Iterator[None]:
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)


def _load_legacy_types():
    legacy_path = str(LEGACY_ROOT)
    if legacy_path not in sys.path:
        sys.path.insert(0, legacy_path)

    from editor.app_controller import AppController
    from persistence.savegame_io import load_game_from_path

    return AppController, load_game_from_path


def _number(value: float | int) -> float | int:
    if isinstance(value, bool) or isinstance(value, int):
        return value
    rounded = round(float(value), FLOAT_DIGITS)
    return 0.0 if rounded == 0.0 else rounded


def _numeric_map(values: dict[str, Any]) -> dict[str, float | int]:
    return {key: _number(values[key]) for key in sorted(values)}


def _state_name(value: Any) -> str:
    return str(value.value if hasattr(value, "value") else value)


class LegacySession:
    def __init__(self) -> None:
        AppController, load_game_from_path = _load_legacy_types()
        with _working_directory(LEGACY_ROOT):
            self.controller = AppController()
        self._load_game_from_path = load_game_from_path
        self.aliases: dict[str, int] = {}
        self.steps = 0
        self.simulated_seconds = 0.0

    def resolve_node(self, value: str | int) -> int:
        if isinstance(value, int):
            return value
        if value not in self.aliases:
            raise ValueError(f"Unknown node alias: {value}")
        return self.aliases[value]

    def apply(self, action: dict[str, Any]) -> None:
        operation = action.get("op")
        if operation == "load_save":
            path = _repository_path(action["path"])
            self._load_game_from_path(
                self.controller.project,
                self.controller.state,
                path,
            )
            self.aliases.clear()
            return

        if operation == "create_node":
            node = self.controller.project.graph.create_node(
                str(action["entity_type"]),
                float(action.get("x", 0.0)),
                float(action.get("y", 0.0)),
            )
            alias = action.get("as")
            if alias:
                if alias in self.aliases:
                    raise ValueError(f"Duplicate node alias: {alias}")
                self.aliases[str(alias)] = node.id
            return

        if operation == "connect":
            from_id = self.resolve_node(action["from"])
            to_id = self.resolve_node(action["to"])
            self.controller.state.selected_edge_type = str(action["edge_type"])
            if not self.controller.connect_nodes(from_id, to_id):
                raise ValueError(
                    f"Legacy simulator rejected connection {from_id} -> {to_id}"
                )
            return

        if operation == "set_inventory":
            node_id = self.resolve_node(action["node"])
            node = self.controller.project.graph.get_node(node_id)
            if node is None:
                raise ValueError(f"Unknown node ID: {node_id}")
            inventory = {
                str(key): float(value)
                for key, value in action.get("inventory", {}).items()
            }
            if action.get("merge", False):
                node.inventory.update(inventory)
            else:
                node.inventory = inventory
            return

        if operation == "set_workers":
            self.controller.state.workers_current = float(action["amount"])
            return

        if operation == "step":
            dt = float(action["dt"])
            count = int(action.get("count", 1))
            if dt < 0.0:
                raise ValueError("step dt must be non-negative")
            if count < 0:
                raise ValueError("step count must be non-negative")
            for _ in range(count):
                self.controller.simulation_step(dt)
            self.steps += count
            self.simulated_seconds += dt * count
            return

        if operation == "delete_node":
            self.controller.state.selected_node_id = self.resolve_node(action["node"])
            self.controller.state.selected_edge_index = None
            self.controller.delete_selected()
            return

        if operation == "delete_edge":
            self.controller.state.selected_node_id = None
            self.controller.state.selected_edge_index = int(action["index"])
            self.controller.delete_selected()
            return

        raise ValueError(f"Unsupported parity operation: {operation!r}")

    def snapshot(self, scenario_name: str) -> dict[str, Any]:
        graph = self.controller.project.graph
        state = self.controller.state

        nodes = []
        for node in sorted(graph.nodes.values(), key=lambda item: item.id):
            nodes.append(
                {
                    "id": node.id,
                    "entity_type": node.entity_type,
                    "position": [_number(node.world_x), _number(node.world_y)],
                    "state": _state_name(node.state),
                    "inventory": _numeric_map(node.inventory),
                    "construction_progress": _numeric_map(node.construction_progress),
                    "process": {
                        "total_sec": _number(node.active_process_total_sec),
                        "remaining_sec": _number(node.active_process_remaining_sec),
                        "output_name": node.active_process_output_name,
                    },
                    "workers_assigned": _number(node.workers_assigned),
                    "worker_efficiency": _number(node.worker_efficiency),
                }
            )

        edges = []
        for index, edge in enumerate(graph.edges):
            packet = None
            if edge.packet is not None:
                packet = {
                    "resource_name": edge.packet.resource_name,
                    "amount": _number(edge.packet.amount),
                    "progress": _number(edge.packet.progress),
                }
            edges.append(
                {
                    "index": index,
                    "from_id": edge.from_id,
                    "to_id": edge.to_id,
                    "edge_type_id": edge.edge_type_id,
                    "packet": packet,
                    "return_progress": (
                        None
                        if edge.return_progress is None
                        else _number(edge.return_progress)
                    ),
                }
            )

        simulation = {
            "next_node_id": graph.next_node_id,
            "nodes": nodes,
            "edges": edges,
            "transport_inventory": _numeric_map(state.transport_inventory),
            "settlement": {
                "workers_current": _number(state.workers_current),
                "workers_max": _number(state.workers_max),
                "food_available": _number(state.food_available),
                "food_consumed_last_tick": _number(state.food_consumed_last_tick),
                "food_support_ratio": _number(state.food_support_ratio),
                "attractiveness": _number(state.attractiveness),
                "worker_trend": state.worker_trend,
            },
        }
        canonical = json.dumps(
            simulation,
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=True,
        ).encode("utf-8")

        return {
            "snapshot_format_version": SNAPSHOT_FORMAT_VERSION,
            "scenario": scenario_name,
            "runner": "legacy_python",
            "steps": self.steps,
            "simulated_seconds": _number(self.simulated_seconds),
            "simulation_sha256": hashlib.sha256(canonical).hexdigest(),
            "simulation": simulation,
        }


def _repository_path(value: str) -> Path:
    path = Path(value)
    if not path.is_absolute():
        path = REPOSITORY_ROOT / path
    return path.resolve()


def run_scenario(scenario_path: Path) -> dict[str, Any]:
    scenario = json.loads(scenario_path.read_text(encoding="utf-8"))
    session = LegacySession()
    for index, action in enumerate(scenario.get("actions", [])):
        try:
            session.apply(action)
        except Exception as error:
            raise RuntimeError(
                f"Action {index} ({action.get('op', '<missing>')}) failed: {error}"
            ) from error
    return session.snapshot(str(scenario.get("name", scenario_path.stem)))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scenario", type=Path, help="Parity scenario JSON file")
    parser.add_argument("--output", type=Path, help="Optional snapshot output path")
    args = parser.parse_args()

    result = run_scenario(args.scenario.resolve())
    rendered = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    else:
        sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
