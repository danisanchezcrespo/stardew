import json
import math
from typing import Optional, Tuple

from core.constants import (
    ATTRACTIVENESS_DECLINE_REDUCTION_PER_POINT,
    ATTRACTIVENESS_GROWTH_BONUS_PER_POINT,
    ENTITY_RADIUS,
    FOOD_PER_WORKER_PER_SEC,
    GRID_SPACING,
    MAX_SCALE,
    MIN_DECLINE_MULTIPLIER,
    MIN_SCALE,
    WORKER_DECLINE_RATE_PER_SEC,
    WORKER_GROWTH_RATE_PER_SEC,
    ZOOM_FACTOR,
)

from core.enums import NodeState, SimulationMode
from editor.editor_state import EditorState
from model.edge import TransportPacket
from model.entity_defs import EntityRegistry
from model.project import ProjectModel


class AppController:
    def __init__(self) -> None:
        self.registry_path = "data/entities.json"
        self.registry = EntityRegistry(self.registry_path)
        self.project = ProjectModel(registry=self.registry)
        self.state = EditorState()
        self.state.selected_edge_type = self.registry.get_default_edge_type_id()
        self.state.transport_inventory = self._build_initial_transport_inventory()

    # -------------------------------------------------------------------------
    # JSON editor bridge
    # -------------------------------------------------------------------------

    def get_current_json_data(self):
        with open(self.registry_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def set_current_json_data(self, data) -> None:
        with open(self.registry_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)

    def reload_from_json(self) -> None:
        self.registry.reload()
        self.project = ProjectModel(registry=self.registry)
        self.state = EditorState()
        self.state.selected_edge_type = self.registry.get_default_edge_type_id()
        self.state.transport_inventory = self._build_initial_transport_inventory()

    # -------------------------------------------------------------------------
    # Transport pool
    # -------------------------------------------------------------------------

    def _build_initial_transport_inventory(self) -> dict[str, float]:
        pool: dict[str, float] = {}
        for edge_type_id in self.registry.get_all_edge_type_ids():
            edge_def = self.registry.get_edge_type(edge_type_id)
            if not edge_def.transport_resource:
                continue
            pool[edge_def.transport_resource] = (
                pool.get(edge_def.transport_resource, 0.0) + edge_def.initial_pool_units
            )
        return pool

    def _get_transport_resource_to_edge_type(self) -> dict[str, str]:
        result: dict[str, str] = {}
        for edge_type_id in self.registry.get_all_edge_type_ids():
            edge_def = self.registry.get_edge_type(edge_type_id)
            if edge_def.transport_resource:
                result[edge_def.transport_resource] = edge_type_id
        return result

    def _is_transport_resource(self, resource_name: str) -> bool:
        return resource_name in self._get_transport_resource_to_edge_type()

    def _add_to_transport_pool(self, resource_name: str, amount: float) -> None:
        if amount <= 0:
            return
        self.state.transport_inventory[resource_name] = (
            self.state.transport_inventory.get(resource_name, 0.0) + amount
        )

    def _spend_transport_for_edge(self, edge_type_id: str) -> bool:
        edge_def = self.registry.get_edge_type(edge_type_id)
        resource_name = edge_def.transport_resource
        if not resource_name:
            return True

        available = self.state.transport_inventory.get(resource_name, 0.0)
        if available + 0.0001 < edge_def.units_per_edge:
            return False

        self.state.transport_inventory[resource_name] = max(
            0.0,
            available - edge_def.units_per_edge,
        )
        return True

    def _refund_edge_transport(self, edge) -> None:
        edge_def = self.registry.get_edge_type(edge.edge_type_id)
        resource_name = edge_def.transport_resource
        if not resource_name:
            return

        self.state.transport_inventory[resource_name] = (
            self.state.transport_inventory.get(resource_name, 0.0) + edge_def.units_per_edge
        )

    def get_available_transport_units(self, edge_type_id: str) -> int:
        edge_def = self.registry.get_edge_type(edge_type_id)
        if not edge_def.transport_resource:
            return 999999

        current = self.state.transport_inventory.get(edge_def.transport_resource, 0.0)
        return int(current // edge_def.units_per_edge)

    def get_transport_inventory_counts(self) -> dict[str, int]:
        result: dict[str, int] = {}
        for edge_type_id in self.registry.get_all_edge_type_ids():
            result[edge_type_id] = self.get_available_transport_units(edge_type_id)
        return result

    # -------------------------------------------------------------------------
    # Notifications
    # -------------------------------------------------------------------------

    def set_notification(self, text: str, duration: float = 2.0) -> None:
        self.state.notification_text = text
        self.state.notification_timer = duration

    def update_notifications(self, dt: float) -> None:
        if self.state.notification_timer <= 0:
            return

        self.state.notification_timer -= dt
        if self.state.notification_timer <= 0:
            self.state.notification_timer = 0.0
            self.state.notification_text = ""

    # -------------------------------------------------------------------------
    # Selection / deletion
    # -------------------------------------------------------------------------

    def clear_selection(self) -> None:
        self.state.selected_node_id = None
        self.state.selected_edge_index = None

    def delete_selected(self) -> None:
        if self.state.selected_node_id is not None:
            node_id = self.state.selected_node_id
            for edge in list(self.project.graph.edges):
                if edge.from_id == node_id or edge.to_id == node_id:
                    self._refund_edge_transport(edge)

            self.project.graph.remove_node(node_id)
            self.clear_selection()
            return

        if self.state.selected_edge_index is not None:
            if 0 <= self.state.selected_edge_index < len(self.project.graph.edges):
                edge = self.project.graph.edges[self.state.selected_edge_index]
                self._refund_edge_transport(edge)

            self.project.graph.remove_edge_by_index(self.state.selected_edge_index)
            self.clear_selection()

    # -------------------------------------------------------------------------
    # Simulation controls
    # -------------------------------------------------------------------------
    def _has_output_capacity_for_batch(self, node, entity_def) -> bool:
        if not entity_def.recipe_outputs:
            return True

        for resource_name, produced_amount in entity_def.recipe_outputs.items():
            if self._is_transport_resource(resource_name):
                continue

            current_amount = node.inventory.get(resource_name, 0.0)
            maximum_amount = entity_def.max_amounts.get(resource_name, float("inf"))

            if current_amount + produced_amount > maximum_amount + 0.0001:
                return False
        return True

    def _release_blocked_production_edges(self, node) -> None:
        if node.state == NodeState.UNDER_CONSTRUCTION:
            return

        entity_def = self.registry.get(node.entity_type)

        if not entity_def.recipe_inputs:
            return

        if self._has_output_capacity_for_batch(node, entity_def):
            return

        for i in range(len(self.project.graph.edges) - 1, -1, -1):
            edge = self.project.graph.edges[i]

            if edge.to_id != node.id:
                continue

            if edge.packet is not None:
                continue

            from_node = self.project.graph.get_node(edge.from_id)
            if from_node is None:
                continue

            output_resources = set(self._get_output_resources(from_node))
            matched_input = None

            for resource_name in entity_def.recipe_inputs.keys():
                if resource_name not in output_resources:
                    continue

                current_amount = node.inventory.get(resource_name, 0.0)
                maximum_amount = entity_def.max_amounts.get(resource_name, float("inf"))

                if current_amount + 0.0001 >= maximum_amount:
                    matched_input = resource_name
                    break

            if matched_input is None:
                continue

            self._refund_edge_transport(edge)
            self.project.graph.remove_edge_by_index(i)


    def toggle_simulation_mode(self) -> None:
        if self.state.simulation_mode == SimulationMode.PAUSED:
            self.state.simulation_mode = SimulationMode.RUNNING
        else:
            self.state.simulation_mode = SimulationMode.PAUSED

    def pause_simulation(self) -> None:
        self.state.simulation_mode = SimulationMode.PAUSED

    def is_running(self) -> bool:
        return self.state.simulation_mode == SimulationMode.RUNNING

    def simulation_step(self, dt: float) -> None:
        self._rebuild_shared_city_stats()
        self._consume_food_and_update_workers(dt)
        self._assign_workers_to_nodes()
        self._process_running_entities(dt)
        self._advance_transporters(dt)
        self._launch_packets()
        self._promote_finished_entities()
        self.update_notifications(dt)


    def get_world_status(self) -> dict:
        building_count = len(self.project.graph.nodes)
        resident_count = int(self.state.workers_current)

        workers_assigned = 0.0
        for node in self.project.graph.nodes.values():
            workers_assigned += getattr(node, "workers_assigned", 0.0)

        unemployed = max(0.0, self.state.workers_current - workers_assigned)
        unemployment_percent = (
            (unemployed / self.state.workers_current) * 100.0
            if self.state.workers_current > 0.0
            else 0.0
        )

        food_reserves = int(self._get_total_resource_across_nodes("food"))

        trend = str(self.state.worker_trend).lower()
        if trend == "growing":
            growth_text = "Growing"
        elif trend == "shrinking":
            growth_text = "Shrinking"
        else:
            growth_text = "Stable"

        return {
            "building_count": building_count,
            "resident_count": resident_count,
            "unemployment_percent": unemployment_percent,
            "food_reserves": food_reserves,
            "growth_text": growth_text,
        }

    def get_selected_node_info(self) -> dict | None:
        if self.state.selected_node_id is None:
            return None

        node = self.project.graph.get_node(self.state.selected_node_id)
        if node is None:
            return None

        entity_def = self.registry.get(node.entity_type)

        construction_materials = []
        construction_progress_map = dict(getattr(node, "construction_progress", {}) or {})
        construction_cost = dict(getattr(entity_def, "construction_cost", {}) or {})

        if node.state == NodeState.UNDER_CONSTRUCTION:
            recipe_name = "Under construction"

            for resource_name, required_amount in construction_cost.items():
                have_amount = construction_progress_map.get(resource_name, 0.0)
                construction_materials.append({
                    "resource": resource_name,
                    "have": have_amount,
                    "need": required_amount,
                })

            contents = {
                key: value
                for key, value in construction_progress_map.items()
                if abs(value) > 0.0001
            }

            required_total = sum(construction_cost.values())
            delivered_total = 0.0
            for resource_name, required_amount in construction_cost.items():
                delivered_total += min(construction_progress_map.get(resource_name, 0.0), required_amount)

            construction_progress = 1.0 if required_total <= 0 else max(
                0.0,
                min(1.0, delivered_total / required_total),
            )

        else:
            if entity_def.recipe_outputs:
                if entity_def.recipe_inputs:
                    inputs_text = self._format_resource_map_for_message(entity_def.recipe_inputs)
                    outputs_text = self._format_resource_map_for_message(entity_def.recipe_outputs)
                    recipe_name = f"{inputs_text} -> {outputs_text}"
                else:
                    outputs_text = self._format_resource_map_for_message(entity_def.recipe_outputs)
                    recipe_name = f"Source -> {outputs_text}"
            else:
                recipe_name = "-"

            contents = {
                key: value
                for key, value in node.inventory.items()
                if abs(value) > 0.0001
            }
            construction_progress = None

        workers_assigned = int(getattr(node, "workers_assigned", 0.0))
        workers_total = int(getattr(entity_def, "workers_required", 0.0))

        return {
            "node_id": node.id,
            "node_name": entity_def.label,
            "recipe_name": recipe_name,
            "contents": contents,
            "workers_assigned": workers_assigned,
            "workers_total": workers_total,
            "is_source": self._is_source_node(node),
            "state": node.state,
            "construction_materials": construction_materials,
            "construction_progress": construction_progress,
        }

    # -------------------------------------------------------------------------
    # Shared worker / food / attractiveness simulation
    # -------------------------------------------------------------------------

    def _rebuild_shared_city_stats(self) -> None:
        workers_max = 0.0
        attractiveness = 0.0

        for node in self.project.graph.nodes.values():
            if node.state == NodeState.UNDER_CONSTRUCTION:
                continue

            entity_def = self.registry.get(node.entity_type)
            workers_max += entity_def.shared_resource_modifiers.get("workers_max", 0.0)
            attractiveness += entity_def.shared_resource_modifiers.get("attractiveness", 0.0)

        self.state.workers_max = workers_max
        self.state.attractiveness = attractiveness
        self.state.workers_current = max(0.0, min(self.state.workers_current, self.state.workers_max))

    def _get_total_resource_across_nodes(self, resource_name: str) -> float:
        total = 0.0
        for node in self.project.graph.nodes.values():
            if node.state == NodeState.UNDER_CONSTRUCTION:
                continue
            total += node.inventory.get(resource_name, 0.0)
        return total

    def _consume_global_resource(self, resource_name: str, amount: float) -> float:
        if amount <= 0.0:
            return 0.0

        remaining = amount
        consumed = 0.0

        for node in self.project.graph.nodes.values():
            if remaining <= 0.0:
                break

            if node.state == NodeState.UNDER_CONSTRUCTION:
                continue

            available = node.inventory.get(resource_name, 0.0)
            if available <= 0.0:
                continue

            taken = min(available, remaining)
            node.inventory[resource_name] = available - taken
            if node.inventory[resource_name] < 0.0001:
                node.inventory[resource_name] = 0.0

            consumed += taken
            remaining -= taken

        return consumed

    def _consume_food_and_update_workers(self, dt: float) -> None:
        self.state.food_available = self._get_total_resource_across_nodes("food")

        food_needed = self.state.workers_current * FOOD_PER_WORKER_PER_SEC * dt
        food_consumed = self._consume_global_resource("food", food_needed)

        self.state.food_consumed_last_tick = food_consumed

        if food_needed <= 0.000001:
            food_support_ratio = 1.0
        else:
            food_support_ratio = max(0.0, min(1.0, food_consumed / food_needed))

        self.state.food_support_ratio = food_support_ratio

        if self.state.workers_max <= 0.0:
            self.state.workers_current = 0.0
            self.state.worker_trend = "stable"
            return

        current = self.state.workers_current
        max_workers = self.state.workers_max
        attractiveness = self.state.attractiveness

        growth_multiplier = 1.0 + attractiveness * ATTRACTIVENESS_GROWTH_BONUS_PER_POINT
        decline_multiplier = max(
            MIN_DECLINE_MULTIPLIER,
            1.0 - attractiveness * ATTRACTIVENESS_DECLINE_REDUCTION_PER_POINT,
        )

        if food_support_ratio >= 0.9999:
            room = max(0.0, max_workers - current)
            delta = WORKER_GROWTH_RATE_PER_SEC * growth_multiplier * room * dt
            new_workers = min(max_workers, current + delta)

            if new_workers > current + 0.0001:
                self.state.worker_trend = "growing"
            else:
                self.state.worker_trend = "stable"
        else:
            shortage = 1.0 - food_support_ratio
            delta = WORKER_DECLINE_RATE_PER_SEC * decline_multiplier * shortage * current * dt
            new_workers = max(0.0, current - delta)

            if new_workers + 0.0001 < current:
                self.state.worker_trend = "shrinking"
            else:
                self.state.worker_trend = "stable"

        self.state.workers_current = max(0.0, min(new_workers, max_workers))

    def _assign_workers_to_nodes(self) -> None:
        candidates = []

        for node in self.project.graph.nodes.values():
            node.workers_assigned = 0.0
            node.worker_efficiency = 1.0

            if node.state == NodeState.UNDER_CONSTRUCTION:
                node.workers_assigned = 0.0
                node.worker_efficiency = 0.0
                continue

            entity_def = self.registry.get(node.entity_type)
            if entity_def.workers_required > 0.0:
                candidates.append((entity_def.worker_priority, node.id, node, entity_def))

        candidates.sort(key=lambda item: (-item[0], item[1]))

        remaining_workers = self.state.workers_current

        for _priority, _node_id, node, entity_def in candidates:
            required = entity_def.workers_required
            assigned = min(required, remaining_workers)
            node.workers_assigned = assigned
            node.worker_efficiency = 0.0 if required <= 0.0 else max(0.0, min(1.0, assigned / required))
            remaining_workers -= assigned

    # -------------------------------------------------------------------------
    # Node / transport selection
    # -------------------------------------------------------------------------

    def select_palette_entity(self, entity_type: str) -> None:

        missing = self.get_missing_requirements_for_entity(entity_type)
        if missing:
            self.state.selected_palette_entity = None
            self.set_notification(f"NEEDS {', '.join(missing)}", duration=999.0)
            return

        self.state.selected_palette_entity = entity_type
        self._show_entity_info_message(entity_type)

    def select_edge_type(self, edge_type_id: str) -> None:

        if self.get_available_transport_units(edge_type_id) <= 0:
            label = self.registry.get_edge_type(edge_type_id).label.upper()
            self.set_notification(f"NO {label} AVAILABLE", duration=999.0)
            return

        self.state.selected_edge_type = edge_type_id
        self.state.selected_palette_entity = None
        self._show_edge_type_info_message(edge_type_id)

    def _get_entity_required_resources(self, entity_type: str) -> set[str]:
        entity_def = self.registry.get(entity_type)
        required = set(entity_def.construction_cost.keys())
        required.update(entity_def.recipe_inputs.keys())
        return required

    def _get_entity_output_resources(self, entity_type: str) -> set[str]:
        entity_def = self.registry.get(entity_type)
        return set(entity_def.recipe_outputs.keys())

    def _get_canvas_entity_types(self) -> list[str]:
        return [node.entity_type for node in self.project.graph.nodes.values()]

    def compute_reachable_resources(self) -> set[str]:
        placed_entity_types = self._get_canvas_entity_types()
        reachable: set[str] = set()

        changed = True
        while changed:
            changed = False

            for entity_type in placed_entity_types:
                required = self._get_entity_required_resources(entity_type)
                outputs = self._get_entity_output_resources(entity_type)

                if not required or required.issubset(reachable):
                    before = len(reachable)
                    reachable.update(outputs)
                    if len(reachable) != before:
                        changed = True

        return reachable

    def is_entity_unlocked(self, entity_type: str) -> bool:
        required = self._get_entity_required_resources(entity_type)
        reachable = self.compute_reachable_resources()
        return required.issubset(reachable)

    def get_missing_requirements_for_entity(self, entity_type: str) -> list[str]:
        required = self._get_entity_required_resources(entity_type)
        reachable = self.compute_reachable_resources()
        return sorted(required - reachable)

    def get_entity_unlock_states(self) -> dict[str, tuple[bool, list[str]]]:
        reachable = self.compute_reachable_resources()
        result: dict[str, tuple[bool, list[str]]] = {}

        for entity_id in self.registry.get_all_ids():
            required = self._get_entity_required_resources(entity_id)
            missing = sorted(required - reachable)
            result[entity_id] = (len(missing) == 0, missing)

        return result

    # -------------------------------------------------------------------------
    # Node type helpers
    # -------------------------------------------------------------------------

    def _is_source_entity_type(self, entity_type: str) -> bool:
        entity_def = self.registry.get(entity_type)
        return len(entity_def.recipe_outputs) > 0 and len(entity_def.recipe_inputs) == 0

    def _is_source_node(self, node) -> bool:
        return self._is_source_entity_type(node.entity_type)

    def _node_staffing_efficiency(self, node) -> float:
        entity_def = self.registry.get(node.entity_type)

        if entity_def.workers_required <= 0.0:
            return 1.0

        efficiency = max(0.0, min(1.0, node.worker_efficiency))

        # Apply minimum efficiency floor from entity definition
        if entity_def.min_worker_efficiency > 0.0:
            efficiency = max(entity_def.min_worker_efficiency, efficiency)

        return efficiency

    def get_node_construction_progress(self, node_id: int) -> float:
        node = self.project.graph.get_node(node_id)
        if node is None:
            return 0.0

        entity_def = self.registry.get(node.entity_type)
        cost = entity_def.construction_cost or {}

        if not cost:
            return 1.0

        delivered = getattr(node, "construction_progress", {}) or {}

        required_total = sum(cost.values())
        delivered_total = 0.0

        for resource_name, required_amount in cost.items():
            delivered_total += min(delivered.get(resource_name, 0), required_amount)

        if required_total <= 0:
            return 1.0

        return max(0.0, min(1.0, delivered_total / required_total))
       

    # -------------------------------------------------------------------------
    # Production
    # -------------------------------------------------------------------------

    def _add_produced_output(self, node, resource_name: str, amount: float) -> None:
        if self._is_transport_resource(resource_name):
            self._add_to_transport_pool(resource_name, amount)
            return

        current = node.inventory.get(resource_name, 0.0)
        maximum = self.registry.get(node.entity_type).max_amounts.get(resource_name, float("inf"))
        node.inventory[resource_name] = min(maximum, current + amount)


    def _process_running_entities(self, dt: float) -> None:
        for node in self.project.graph.nodes.values():
            if node.state == NodeState.UNDER_CONSTRUCTION:
                continue

            entity_def = self.registry.get(node.entity_type)

            if not entity_def.recipe_outputs:
                node.state = NodeState.READY
                continue

            is_source = self._is_source_node(node)

            # ---------------------------------------------------------
            # SOURCE NODES
            # ---------------------------------------------------------
            if is_source:
                rate = entity_def.source_rate_per_sec
                if rate <= 0:
                    node.state = NodeState.READY
                    continue

                has_capacity = False
                for resource_name in entity_def.recipe_outputs.keys():
                    if self._is_transport_resource(resource_name):
                        has_capacity = True
                        break

                    current = node.inventory.get(resource_name, 0.0)
                    maximum = entity_def.max_amounts.get(resource_name, float("inf"))

                    if current + 0.0001 < maximum:
                        has_capacity = True
                        break

                if not has_capacity:
                    node.state = NodeState.READY
                    self._release_blocked_production_edges(node)
                    continue

                node.state = NodeState.RUNNING

                for resource_name, produced_amount in entity_def.recipe_outputs.items():
                    self._add_produced_output(node, resource_name, produced_amount * rate * dt)

                self._release_blocked_production_edges(node)
                continue

            # ---------------------------------------------------------
            # NORMAL MACHINES
            # ---------------------------------------------------------

            staffing_efficiency = self._node_staffing_efficiency(node)
            if staffing_efficiency <= 0.0:
                node.state = NodeState.READY
                continue

            # ❗ OUTPUT BLOCK → STOPPED
            if not self._has_output_capacity_for_batch(node, entity_def):
                node.state = NodeState.READY
                self._release_blocked_production_edges(node)
                continue

            # If mid-process → continue working
            if node.active_process_remaining_sec > 0.0:
                node.state = NodeState.RUNNING

                effective_dt = dt * staffing_efficiency
                node.active_process_remaining_sec = max(
                    0.0,
                    node.active_process_remaining_sec - effective_dt,
                )

                if node.active_process_remaining_sec <= 0.0:
                    for resource_name, produced_amount in entity_def.recipe_outputs.items():
                        self._add_produced_output(node, resource_name, produced_amount)

                    node.active_process_total_sec = 0.0
                    node.active_process_output_name = None

                self._release_blocked_production_edges(node)
                continue

            # Check inputs
            for resource_name, required_amount in entity_def.recipe_inputs.items():
                available = node.inventory.get(resource_name, 0.0)
                if available + 0.0001 < required_amount:
                    node.state = NodeState.READY
                    self._release_blocked_production_edges(node)
                    break
            else:
                # We CAN run → consume + start process
                node.state = NodeState.RUNNING

                for resource_name, required_amount in entity_def.recipe_inputs.items():
                    node.inventory[resource_name] = max(
                        0.0,
                        node.inventory.get(resource_name, 0.0) - required_amount,
                    )

                node.active_process_total_sec = max(0.0, entity_def.process_time_sec)
                node.active_process_remaining_sec = max(0.0, entity_def.process_time_sec)
                node.active_process_output_name = next(
                    iter(entity_def.recipe_outputs.keys()),
                    None,
                )

                if node.active_process_remaining_sec <= 0.0:
                    for resource_name, produced_amount in entity_def.recipe_outputs.items():
                        self._add_produced_output(node, resource_name, produced_amount)

                    node.active_process_total_sec = 0.0
                    node.active_process_output_name = None

                self._release_blocked_production_edges(node)

    # -------------------------------------------------------------------------
    # Transport layer
    # -------------------------------------------------------------------------

    def _edge_distance(self, edge) -> float:
        from_node = self.project.graph.get_node(edge.from_id)
        to_node = self.project.graph.get_node(edge.to_id)
        if from_node is None or to_node is None:
            return 1.0

        dx = to_node.world_x - from_node.world_x
        dy = to_node.world_y - from_node.world_y
        return max(1.0, math.hypot(dx, dy))

    def _advance_transporters(self, dt: float) -> None:
        for edge in self.project.graph.edges:
            from_node = self.project.graph.get_node(edge.from_id)
            to_node = self.project.graph.get_node(edge.to_id)
            if from_node is None or to_node is None:
                continue

            edge_type = self.registry.get_edge_type(edge.edge_type_id)
            distance = self._edge_distance(edge)
            progress_per_sec = edge_type.speed / distance

            if edge.packet is not None:
                edge.packet.progress += dt * progress_per_sec
                if edge.packet.progress >= 1.0:
                    self._deliver_packet(to_node, edge.packet.resource_name, edge.packet.amount)
                    edge.packet = None

                    if edge_type.mode == "ping_pong":
                        edge.return_progress = 0.0

            elif edge.return_progress is not None:
                edge.return_progress += dt * progress_per_sec
                if edge.return_progress >= 1.0:
                    edge.return_progress = None

    def _deliver_packet(self, to_node, resource_name: str, amount: float) -> None:
        if to_node.state == NodeState.UNDER_CONSTRUCTION:
            entity_def = self.registry.get(to_node.entity_type)
            required_amount = entity_def.construction_cost.get(resource_name, 0.0)

            if required_amount <= 0.0:
                return

            current_amount = to_node.construction_progress.get(resource_name, 0.0)
            missing_amount = max(0.0, required_amount - current_amount)
            delivered_amount = min(amount, missing_amount)

            if delivered_amount > 0.0:
                to_node.construction_progress[resource_name] = current_amount + delivered_amount

            # After every construction delivery, free any now-useless construction edges
            self._release_satisfied_construction_edges(to_node)
            return

        current_amount = to_node.inventory.get(resource_name, 0.0)
        maximum_amount = self.registry.get(to_node.entity_type).max_amounts.get(
            resource_name,
            float("inf"),
        )
        to_node.inventory[resource_name] = min(maximum_amount, current_amount + amount)
        
        
    def _edge_is_busy(self, edge) -> bool:
        return edge.packet is not None or edge.return_progress is not None

    def _launch_packets(self) -> None:
        for edge in self.project.graph.edges:
            if self._edge_is_busy(edge):
                continue

            from_node = self.project.graph.get_node(edge.from_id)
            to_node = self.project.graph.get_node(edge.to_id)
            if from_node is None or to_node is None:
                continue

            edge_type = self.registry.get_edge_type(edge.edge_type_id)
            acceptable_resources = self._get_acceptable_target_resources(to_node)

            for resource_name in acceptable_resources:
                available = from_node.inventory.get(resource_name, 0.0)
                if available <= 0:
                    continue

                receivable = self._get_receivable_amount_with_reservations(to_node, resource_name)
                if receivable <= 0:
                    continue

                moved = min(available, receivable, edge_type.capacity_per_trip)
                if moved <= 0:
                    continue

                from_node.inventory[resource_name] = available - moved
                if from_node.inventory[resource_name] < 0.0001:
                    from_node.inventory[resource_name] = 0.0

                edge.packet = TransportPacket(
                    resource_name=resource_name,
                    amount=moved,
                    progress=0.0,
                )
                break

    def _incoming_reserved_amount(self, to_node, resource_name: str) -> float:
        total = 0.0
        for edge in self.project.graph.edges:
            if edge.to_id != to_node.id:
                continue
            if edge.packet is not None and edge.packet.resource_name == resource_name:
                total += edge.packet.amount
        return total

    # -------------------------------------------------------------------------
    # Construction and capacities
    # -------------------------------------------------------------------------

    def _release_satisfied_construction_edges(self, node) -> None:
        if node.state != NodeState.UNDER_CONSTRUCTION:
            return

        acceptable_resources = set(self._get_acceptable_target_resources(node))

        for i in range(len(self.project.graph.edges) - 1, -1, -1):
            edge = self.project.graph.edges[i]

            if edge.to_id != node.id:
                continue

            # Do not delete an edge that is currently carrying a packet
            if edge.packet is not None:
                continue

            from_node = self.project.graph.get_node(edge.from_id)
            if from_node is None:
                continue

            output_resources = set(self._get_output_resources(from_node))

            # If this edge can no longer provide any still-needed construction resource,
            # it is now useless and should be freed.
            if len(output_resources & acceptable_resources) == 0:
                self._refund_edge_transport(edge)
                self.project.graph.remove_edge_by_index(i)

    def _promote_finished_entities(self) -> None:
        for node in self.project.graph.nodes.values():
            if node.state != NodeState.UNDER_CONSTRUCTION:
                continue

            entity_def = self.registry.get(node.entity_type)

            finished = True
            for resource_name, required_amount in entity_def.construction_cost.items():
                current_amount = node.construction_progress.get(resource_name, 0.0)
                if current_amount + 0.0001 < required_amount:
                    finished = False
                    break

            if not finished:
                continue

            # Built nodes should end in READY / paused state
            node.state = NodeState.READY

            for resource_name, initial_amount in entity_def.initial_amounts.items():
                node.inventory[resource_name] = initial_amount

            # Free all incoming construction transporters for this node
            for i in range(len(self.project.graph.edges) - 1, -1, -1):
                edge = self.project.graph.edges[i]
                if edge.to_id != node.id:
                    continue

                # Only delete once no packet is still flying toward the node
                if edge.packet is not None:
                    continue

                self._refund_edge_transport(edge)
                self.project.graph.remove_edge_by_index(i)
    # -------------------------------------------------------------------------
    # Compatibility helpers
    # -------------------------------------------------------------------------

    def _get_output_resources(self, node) -> list[str]:
        entity_def = self.registry.get(node.entity_type)
        if node.state == NodeState.UNDER_CONSTRUCTION:
            return []

        outputs: list[str] = []
        for resource_name in entity_def.recipe_outputs.keys():
            if not self._is_transport_resource(resource_name):
                outputs.append(resource_name)
        return outputs

    def _get_acceptable_target_resources(self, node) -> list[str]:
        entity_def = self.registry.get(node.entity_type)

        if node.state == NodeState.UNDER_CONSTRUCTION:
            wanted: list[str] = []

            for resource_name, required_amount in entity_def.construction_cost.items():
                current_amount = node.construction_progress.get(resource_name, 0.0)

                if current_amount + 0.0001 < required_amount:
                    wanted.append(resource_name)

            return wanted

        return list(entity_def.recipe_inputs.keys())

    def _get_receivable_amount(self, node, resource_name: str) -> float:
        entity_def = self.registry.get(node.entity_type)

        if node.state == NodeState.UNDER_CONSTRUCTION:
            required_amount = entity_def.construction_cost.get(resource_name, 0.0)
            current_amount = min(
                node.construction_progress.get(resource_name, 0.0),
                required_amount,
            )
            return max(0.0, required_amount - current_amount)

        current_amount = node.inventory.get(resource_name, 0.0)
        maximum_amount = entity_def.max_amounts.get(resource_name, float("inf"))
        return max(0.0, maximum_amount - current_amount)

    def _get_receivable_amount_with_reservations(self, node, resource_name: str) -> float:
        base = self._get_receivable_amount(node, resource_name)
        reserved = self._incoming_reserved_amount(node, resource_name)
        return max(0.0, base - reserved)

    def can_connect_nodes(self, from_id: int, to_id: int) -> bool:
        from_node = self.project.graph.get_node(from_id)
        to_node = self.project.graph.get_node(to_id)

        if from_node is None or to_node is None:
            return False

        output_resources = set(self._get_output_resources(from_node))
        acceptable_resources = set(self._get_acceptable_target_resources(to_node))
        return len(output_resources & acceptable_resources) > 0

    def connect_nodes(self, from_id: int, to_id: int) -> bool:
        if from_id == to_id:
            self.set_notification("Cannot connect node to itself")
            return False

        if not self.can_connect_nodes(from_id, to_id):
            self.set_notification("Incompatible nodes")
            return False

        edge_type_id = self.state.selected_edge_type or self.registry.get_default_edge_type_id()
        if edge_type_id is None:
            self.set_notification("No transport type selected")
            return False

        if self.get_available_transport_units(edge_type_id) <= 0:
            label = self.registry.get_edge_type(edge_type_id).label.upper()
            self.set_notification(f"NO {label} AVAILABLE")
            return False

        created = self.project.graph.create_edge(from_id, to_id, edge_type_id)
        if created is None:
            self.set_notification("Edge already exists")
            return False

        if not self._spend_transport_for_edge(edge_type_id):
            self.project.graph.remove_edge_by_index(len(self.project.graph.edges) - 1)
            label = self.registry.get_edge_type(edge_type_id).label.upper()
            self.set_notification(f"NO {label} AVAILABLE")
            return False

        return True

    # -------------------------------------------------------------------------
    # Coordinates
    # -------------------------------------------------------------------------
    def _snap_world_to_grid_center(self, wx: float, wy: float) -> Tuple[float, float]:
        spacing = GRID_SPACING
        half = spacing * 0.5

        snapped_x = round((wx - half) / spacing) * spacing + half
        snapped_y = round((wy - half) / spacing) * spacing + half
        return snapped_x, snapped_y


    def world_to_screen(self, wx: float, wy: float) -> Tuple[float, float]:
        return wx * self.state.scale + self.state.pan_x, wy * self.state.scale + self.state.pan_y

    def screen_to_world(self, sx: float, sy: float) -> Tuple[float, float]:
        return (sx - self.state.pan_x) / self.state.scale, (sy - self.state.pan_y) / self.state.scale

    def create_node_at_screen(self, sx: float, sy: float) -> None:
        if self.state.selected_palette_entity is None:
            return

        missing = self.get_missing_requirements_for_entity(self.state.selected_palette_entity)
        if missing:
            self.set_notification(f"NEEDS {', '.join(missing)}", duration=999.0)
            self.state.selected_palette_entity = None
            return

        wx, wy = self.screen_to_world(sx, sy)
        wx, wy = self._snap_world_to_grid_center(wx, wy)
        self.project.graph.create_node(self.state.selected_palette_entity, wx, wy)

    # -------------------------------------------------------------------------
    # Picking
    # -------------------------------------------------------------------------

    def find_node_at_screen(self, sx: int, sy: int) -> Optional[int]:
        hit_radius = max(14, ENTITY_RADIUS * self.state.scale)
        for node in reversed(list(self.project.graph.nodes.values())):
            nx, ny = self.world_to_screen(node.world_x, node.world_y)
            dx = sx - nx
            dy = sy - ny
            if dx * dx + dy * dy <= hit_radius * hit_radius:
                return node.id
        return None

    def find_edge_index_at_screen(self, sx: int, sy: int) -> Optional[int]:
        hit_distance = max(8.0, 10.0 * self.state.scale)

        for i in range(len(self.project.graph.edges) - 1, -1, -1):
            edge = self.project.graph.edges[i]
            from_node = self.project.graph.get_node(edge.from_id)
            to_node = self.project.graph.get_node(edge.to_id)
            if from_node is None or to_node is None:
                continue

            ax, ay = self.world_to_screen(from_node.world_x, from_node.world_y)
            bx, by = self.world_to_screen(to_node.world_x, to_node.world_y)

            if self._point_to_segment_distance(float(sx), float(sy), ax, ay, bx, by) <= hit_distance:
                return i

        return None

    def _point_to_segment_distance(self, px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
        abx = bx - ax
        aby = by - ay
        apx = px - ax
        apy = py - ay

        ab_len_sq = abx * abx + aby * aby
        if ab_len_sq <= 0.000001:
            dx = px - ax
            dy = py - ay
            return (dx * dx + dy * dy) ** 0.5

        t = (apx * abx + apy * aby) / ab_len_sq
        t = max(0.0, min(1.0, t))
        closest_x = ax + t * abx
        closest_y = ay + t * aby
        dx = px - closest_x
        dy = py - closest_y
        return (dx * dx + dy * dy) ** 0.5

    # -------------------------------------------------------------------------
    # Mouse interaction
    # -------------------------------------------------------------------------

    def begin_left_press(self, sx: int, sy: int) -> None:
        node_id = self.find_node_at_screen(sx, sy)
        if node_id is not None:
            node = self.project.graph.get_node(node_id)
            if node is None:
                return

            self.state.selected_node_id = node_id
            self.state.selected_edge_index = None

            self._show_entity_info_message(node.entity_type)
            self.state.dragging_node_id = node_id
            self.state.drag_node_mouse_start_x = sx
            self.state.drag_node_mouse_start_y = sy
            self.state.drag_node_world_start_x = node.world_x
            self.state.drag_node_world_start_y = node.world_y
            return

        self.state.is_panning = True
        self.state.last_pan_mouse_x = sx
        self.state.last_pan_mouse_y = sy

    def update_left_drag(self, sx: int, sy: int) -> None:
        if self.state.dragging_node_id is not None:
            self._drag_node(sx, sy)
            return

        if self.state.is_panning and self.state.last_pan_mouse_x is not None and self.state.last_pan_mouse_y is not None:
            self.state.pan_x += sx - self.state.last_pan_mouse_x
            self.state.pan_y += sy - self.state.last_pan_mouse_y
            self.state.last_pan_mouse_x = sx
            self.state.last_pan_mouse_y = sy

    def end_left_release(self, sx: int, sy: int) -> None:
        if self.state.dragging_node_id is not None:
            self._end_node_drag()
            return

        if self.state.is_panning:
            node_id = self.find_node_at_screen(sx, sy)
            if node_id is None and self.state.selected_palette_entity is not None:
                self.create_node_at_screen(sx, sy)

        self.state.is_panning = False
        self.state.last_pan_mouse_x = None
        self.state.last_pan_mouse_y = None

    def handle_right_click(self, sx: int, sy: int) -> None:
        clicked_node_id = self.find_node_at_screen(sx, sy)
        if clicked_node_id is not None:
            if self.state.selected_node_id is None:
                self.state.selected_node_id = clicked_node_id
                self.state.selected_edge_index = None
                return

            if self.state.selected_node_id != clicked_node_id:
                self.connect_nodes(self.state.selected_node_id, clicked_node_id)

            self.state.selected_node_id = None
            self.state.selected_edge_index = None
            return

        clicked_edge_index = self.find_edge_index_at_screen(sx, sy)
        if clicked_edge_index is not None:
            self.state.selected_edge_index = clicked_edge_index
            self.state.selected_node_id = None
            return

        self.clear_selection()

    def zoom_at_screen_point(self, sx: float, sy: float, zoom_in: bool) -> None:
        factor = ZOOM_FACTOR if zoom_in else (1 / ZOOM_FACTOR)
        new_scale = max(MIN_SCALE, min(MAX_SCALE, self.state.scale * factor))
        wx_before, wy_before = self.screen_to_world(sx, sy)
        self.state.scale = new_scale
        sx_after, sy_after = self.world_to_screen(wx_before, wy_before)
        self.state.pan_x += sx - sx_after
        self.state.pan_y += sy - sy_after

    def _format_resource_map_for_message(self, value: dict[str, float]) -> str:
        if not value:
            return "-"
        return ", ".join(f"{k}:{v:g}" for k, v in value.items())

    def _show_entity_info_message(self, entity_type: str) -> None:
        entity_def = self.registry.get(entity_type)
        is_source = len(entity_def.recipe_outputs) > 0 and len(entity_def.recipe_inputs) == 0
        kind = "Source" if is_source else "Machine"

        if is_source:
            speed_text = f"Rate {entity_def.source_rate_per_sec:g}/s"
        else:
            speed_text = f"Time {entity_def.process_time_sec:g}s"

        shared_mods = entity_def.shared_resource_modifiers or {}

        modifier_text = ""
        if shared_mods:
            parts = []
            for key, value in shared_mods.items():
                sign = "+" if value >= 0 else ""
                parts.append(f"{key} {sign}{value:g}")
            modifier_text = " | Modifier: " + ", ".join(parts)
        workers_text = f"{entity_def.workers_required:g}"

        text = (
            f"{entity_def.label} | {kind} | "
            f"Build [{self._format_resource_map_for_message(entity_def.construction_cost)}] | "
            f"In [{self._format_resource_map_for_message(entity_def.recipe_inputs)}] | "
            f"Out [{self._format_resource_map_for_message(entity_def.recipe_outputs)}] | "
            f"{speed_text} | "
            f"Workers {workers_text} | "
            f"{modifier_text}"
        )
        self.set_notification(text, duration=999.0)

    def _show_edge_type_info_message(self, edge_type_id: str) -> None:
        edge_def = self.registry.get_edge_type(edge_type_id)
        mode_text = "ping_pong" if edge_def.mode == "ping_pong" else "one_way"
        count = self.get_available_transport_units(edge_type_id)

        text = (
            f"{edge_def.label} | speed {edge_def.speed:g} | "
            f"capacity {edge_def.capacity_per_trip:g} | mode {mode_text} | "
            f"available {count}"
        )
        self.set_notification(text, duration=999.0)

    def _drag_node(self, sx: int, sy: int) -> None:
        if self.state.dragging_node_id is None:
            return

        node = self.project.graph.get_node(self.state.dragging_node_id)
        if node is None:
            return

        if (
            self.state.drag_node_mouse_start_x is None
            or self.state.drag_node_mouse_start_y is None
            or self.state.drag_node_world_start_x is None
            or self.state.drag_node_world_start_y is None
        ):
            return

        dx_world = (sx - self.state.drag_node_mouse_start_x) / self.state.scale
        dy_world = (sy - self.state.drag_node_mouse_start_y) / self.state.scale
        node.world_x = self.state.drag_node_world_start_x + dx_world
        node.world_y = self.state.drag_node_world_start_y + dy_world

    def _end_node_drag(self) -> None:
        if self.state.dragging_node_id is not None:
            node = self.project.graph.get_node(self.state.dragging_node_id)
            if node is not None:
                node.world_x, node.world_y = self._snap_world_to_grid_center(
                    node.world_x,
                    node.world_y,
                )

        self.state.dragging_node_id = None
        self.state.drag_node_mouse_start_x = None
        self.state.drag_node_mouse_start_y = None
        self.state.drag_node_world_start_x = None
        self.state.drag_node_world_start_y = None