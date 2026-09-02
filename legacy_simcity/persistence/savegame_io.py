import json
from pathlib import Path
from typing import Any

from core.enums import NodeState, SimulationMode
from editor.editor_state import EditorState
from model.edge import EdgeInstance, TransportPacket
from model.node import NodeInstance
from model.project import ProjectModel


SAVEGAME_VERSION = 1


def build_savegame_data(project: ProjectModel, state: EditorState) -> dict[str, Any]:
    return {
        "version": SAVEGAME_VERSION,
        "nodes": [_serialize_node(node) for node in project.graph.nodes.values()],
        "edges": [_serialize_edge(edge) for edge in project.graph.edges],
        "state": _serialize_state(state),
    }


def save_game_to_path(project: ProjectModel, state: EditorState, path: str | Path) -> None:
    save_data = build_savegame_data(project, state)
    Path(path).write_text(
        json.dumps(save_data, indent=4, ensure_ascii=False),
        encoding="utf-8",
    )


def load_game_from_path(project: ProjectModel, state: EditorState, path: str | Path) -> None:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    load_savegame_data(project, state, data)


def load_savegame_data(project: ProjectModel, state: EditorState, data: dict[str, Any]) -> None:
    version = int(data.get("version", 0))
    if version != SAVEGAME_VERSION:
        raise ValueError(f"Unsupported savegame version: {version}")

    graph = project.graph
    graph.nodes.clear()
    graph.edges.clear()
    graph.next_node_id = 1

    for node_data in data.get("nodes", []):
        node = _deserialize_node(node_data)
        graph.nodes[node.id] = node
        graph.next_node_id = max(graph.next_node_id, node.id + 1)

    for edge_data in data.get("edges", []):
        graph.edges.append(_deserialize_edge(edge_data))

    _deserialize_state_into(state, data.get("state", {}))


# -----------------------------------------------------------------------------
# Node serialization
# -----------------------------------------------------------------------------


def _serialize_node(node: NodeInstance) -> dict[str, Any]:
    return {
        "id": node.id,
        "entity_type": node.entity_type,
        "world_x": node.world_x,
        "world_y": node.world_y,
        "state": node.state.value if hasattr(node.state, "value") else str(node.state),
        "inventory": dict(node.inventory),
        "construction_progress": dict(node.construction_progress),
        "active_process_total_sec": node.active_process_total_sec,
        "active_process_remaining_sec": node.active_process_remaining_sec,
        "active_process_output_name": node.active_process_output_name,
        "workers_assigned": getattr(node, "workers_assigned", 0.0),
        "worker_efficiency": getattr(node, "worker_efficiency", 1.0),
    }


def _deserialize_node(data: dict[str, Any]) -> NodeInstance:
    return NodeInstance(
        id=int(data["id"]),
        entity_type=str(data["entity_type"]),
        world_x=float(data["world_x"]),
        world_y=float(data["world_y"]),
        state=NodeState(data["state"]),
        inventory={k: float(v) for k, v in data.get("inventory", {}).items()},
        construction_progress={
            k: float(v) for k, v in data.get("construction_progress", {}).items()
        },
        active_process_total_sec=float(data.get("active_process_total_sec", 0.0)),
        active_process_remaining_sec=float(data.get("active_process_remaining_sec", 0.0)),
        active_process_output_name=data.get("active_process_output_name"),
        workers_assigned=float(data.get("workers_assigned", 0.0)),
        worker_efficiency=float(data.get("worker_efficiency", 1.0)),
    )


# -----------------------------------------------------------------------------
# Edge serialization
# -----------------------------------------------------------------------------


def _serialize_edge(edge: EdgeInstance) -> dict[str, Any]:
    return {
        "from_id": edge.from_id,
        "to_id": edge.to_id,
        "edge_type_id": edge.edge_type_id,
        "packet": _serialize_packet(edge.packet),
        "return_progress": edge.return_progress,
    }


def _deserialize_edge(data: dict[str, Any]) -> EdgeInstance:
    return EdgeInstance(
        from_id=int(data["from_id"]),
        to_id=int(data["to_id"]),
        edge_type_id=str(data["edge_type_id"]),
        packet=_deserialize_packet(data.get("packet")),
        return_progress=(
            None if data.get("return_progress") is None else float(data.get("return_progress"))
        ),
    )


def _serialize_packet(packet: TransportPacket | None) -> dict[str, Any] | None:
    if packet is None:
        return None

    return {
        "resource_name": packet.resource_name,
        "amount": packet.amount,
        "progress": packet.progress,
    }


def _deserialize_packet(data: dict[str, Any] | None) -> TransportPacket | None:
    if data is None:
        return None

    return TransportPacket(
        resource_name=str(data["resource_name"]),
        amount=float(data["amount"]),
        progress=float(data.get("progress", 0.0)),
    )


# -----------------------------------------------------------------------------
# EditorState serialization
# -----------------------------------------------------------------------------


def _serialize_state(state: EditorState) -> dict[str, Any]:
    return {
        # Simulation
        "simulation_mode": (
            state.simulation_mode.value
            if hasattr(state.simulation_mode, "value")
            else str(state.simulation_mode)
        ),

        # UI / selection
        "selected_palette_entity": state.selected_palette_entity,
        "selected_edge_type": state.selected_edge_type,
        "selected_node_id": state.selected_node_id,
        "selected_edge_index": state.selected_edge_index,

        # Camera
        "pan_x": state.pan_x,
        "pan_y": state.pan_y,
        "scale": state.scale,

        # Notifications
        "notification_text": state.notification_text,
        "notification_timer": state.notification_timer,

        # Transport pool
        "transport_inventory": dict(state.transport_inventory),

        # Settlement simulation
        "workers_current": getattr(state, "workers_current", 0.0),
        "workers_max": getattr(state, "workers_max", 0.0),
        "food_available": getattr(state, "food_available", 0.0),
        "food_consumed_last_tick": getattr(state, "food_consumed_last_tick", 0.0),
        "food_support_ratio": getattr(state, "food_support_ratio", 1.0),
        "attractiveness": getattr(state, "attractiveness", 0.0),
        "worker_trend": getattr(state, "worker_trend", "stable"),
    }


def _deserialize_state_into(state: EditorState, data: dict[str, Any]) -> None:
    state.simulation_mode = SimulationMode(data.get("simulation_mode", SimulationMode.PAUSED.value))

    state.selected_palette_entity = data.get("selected_palette_entity")
    state.selected_edge_type = data.get("selected_edge_type")
    state.selected_node_id = data.get("selected_node_id")
    state.selected_edge_index = data.get("selected_edge_index")

    state.pan_x = float(data.get("pan_x", 0.0))
    state.pan_y = float(data.get("pan_y", 0.0))
    state.scale = float(data.get("scale", 1.0))

    state.notification_text = str(data.get("notification_text", ""))
    state.notification_timer = float(data.get("notification_timer", 0.0))

    state.transport_inventory = {
        k: float(v) for k, v in data.get("transport_inventory", {}).items()
    }

    state.workers_current = float(data.get("workers_current", 0.0))
    state.workers_max = float(data.get("workers_max", 0.0))
    state.food_available = float(data.get("food_available", 0.0))
    state.food_consumed_last_tick = float(data.get("food_consumed_last_tick", 0.0))
    state.food_support_ratio = float(data.get("food_support_ratio", 1.0))
    state.attractiveness = float(data.get("attractiveness", 0.0))
    state.worker_trend = str(data.get("worker_trend", "stable"))

    # Dragging / panning transient input state should not be restored from save
    state.is_panning = False
    state.last_pan_mouse_x = None
    state.last_pan_mouse_y = None
    state.dragging_node_id = None
    state.drag_node_mouse_start_x = None
    state.drag_node_mouse_start_y = None
    state.drag_node_world_start_x = None
    state.drag_node_world_start_y = None