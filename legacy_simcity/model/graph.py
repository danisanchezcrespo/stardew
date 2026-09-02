from dataclasses import dataclass, field
from typing import Dict, List, Optional

from core.enums import NodeState
from model.edge import EdgeInstance
from model.entity_defs import EntityRegistry
from model.node import NodeInstance


@dataclass
class GraphModel:
    registry: EntityRegistry
    nodes: Dict[int, NodeInstance] = field(default_factory=dict)
    edges: List[EdgeInstance] = field(default_factory=list)
    next_node_id: int = 1

    def create_node(self, entity_type: str, world_x: float, world_y: float) -> NodeInstance:
        entity_def = self.registry.get(entity_type)

        has_construction_cost = len(entity_def.construction_cost) > 0
        is_source = len(entity_def.recipe_outputs) > 0 and len(entity_def.recipe_inputs) == 0

        if has_construction_cost:
            state = NodeState.UNDER_CONSTRUCTION
            construction_progress = {
                resource_name: 0.0
                for resource_name in entity_def.construction_cost.keys()
            }
            inventory = {}
        else:
            state = NodeState.RUNNING if is_source else NodeState.READY
            construction_progress = {}
            inventory = dict(entity_def.initial_amounts)

        node = NodeInstance(
            id=self.next_node_id,
            entity_type=entity_type,
            world_x=world_x,
            world_y=world_y,
            state=state,
            inventory=inventory,
            construction_progress=construction_progress,
            active_process_total_sec=0.0,
            active_process_remaining_sec=0.0,
            active_process_output_name=None,
        )
        self.nodes[node.id] = node
        self.next_node_id += 1
        return node

    def get_node(self, node_id: int) -> Optional[NodeInstance]:
        return self.nodes.get(node_id)

    def create_edge(self, from_id: int, to_id: int, edge_type_id: str) -> Optional[EdgeInstance]:
        if from_id == to_id:
            return None

        for edge in self.edges:
            if edge.from_id == from_id and edge.to_id == to_id:
                return None

        edge = EdgeInstance(from_id=from_id, to_id=to_id, edge_type_id=edge_type_id)
        self.edges.append(edge)
        return edge

    def remove_edge_by_index(self, edge_index: int) -> None:
        if 0 <= edge_index < len(self.edges):
            del self.edges[edge_index]

    def remove_node(self, node_id: int) -> None:
        if node_id not in self.nodes:
            return

        del self.nodes[node_id]
        self.edges = [
            edge for edge in self.edges
            if edge.from_id != node_id and edge.to_id != node_id
        ]