import json
from dataclasses import dataclass, field
from pathlib import Path


@dataclass(frozen=True)
class EntityDef:
    entity_id: str
    label: str
    color: str

    construction_cost: dict[str, float] = field(default_factory=dict)
    initial_amounts: dict[str, float] = field(default_factory=dict)
    max_amounts: dict[str, float] = field(default_factory=dict)

    recipe_inputs: dict[str, float] = field(default_factory=dict)
    recipe_outputs: dict[str, float] = field(default_factory=dict)

    source_rate_per_sec: float = 0.0
    process_time_sec: float = 0.0

    # -------------------------------------------------------------------------
    # Workforce / shared modifiers
    # -------------------------------------------------------------------------

    # Buildings can contribute to shared city stats
    shared_resource_modifiers: dict[str, float] = field(default_factory=dict)

    # Workforce required to operate this building
    workers_required: float = 0.0

    # Higher priority buildings receive workers first
    worker_priority: int = 0

    # Minimum operating efficiency floor (0.0–1.0)
    # Allows primitive buildings to still function even if understaffed
    min_worker_efficiency: float = 0.0


@dataclass(frozen=True)
class EdgeTypeDef:
    edge_type_id: str
    label: str
    color: str
    speed: float
    capacity_per_trip: float
    mode: str  # "one_way" | "ping_pong"

    transport_resource: str = ""
    units_per_edge: float = 1.0
    initial_pool_units: float = 0.0


class EntityRegistry:
    def __init__(self, json_path: str = "data/entities.json") -> None:
        self.json_path = Path(json_path)

        self.entities_by_id: dict[str, EntityDef] = {}
        self.palette_order: list[str] = []

        self.edge_types_by_id: dict[str, EdgeTypeDef] = {}
        self.edge_palette_order: list[str] = []

        self.reload()

    def reload(self) -> None:
        raw = json.loads(self.json_path.read_text(encoding="utf-8"))
        entities = raw.get("entities", [])
        edge_types = raw.get("edges", raw.get("edge_types", []))

        self.entities_by_id = {}
        self.palette_order = []

        for item in entities:
            entity_def = EntityDef(
                entity_id=item["id"],
                label=item.get("label", item["id"]),
                color=item.get("color", "#888888"),
                construction_cost={k: float(v) for k, v in item.get("construction_cost", {}).items()},
                initial_amounts={k: float(v) for k, v in item.get("initial_amounts", {}).items()},
                max_amounts={k: float(v) for k, v in item.get("max_amounts", {}).items()},
                recipe_inputs={k: float(v) for k, v in item.get("recipe_inputs", {}).items()},
                recipe_outputs={k: float(v) for k, v in item.get("recipe_outputs", {}).items()},
                source_rate_per_sec=float(item.get("source_rate_per_sec", 0.0)),
                process_time_sec=float(item.get("process_time_sec", 0.0)),

                # Workforce / modifiers
                shared_resource_modifiers={
                    k: float(v) for k, v in item.get("shared_resource_modifiers", {}).items()
                },
                workers_required=float(item.get("workers_required", 0.0)),
                worker_priority=int(item.get("worker_priority", 0)),
                min_worker_efficiency=float(item.get("min_worker_efficiency", 0.0)),
            )

            self.entities_by_id[entity_def.entity_id] = entity_def
            self.palette_order.append(entity_def.entity_id)

        self.edge_types_by_id = {}
        self.edge_palette_order = []

        for item in edge_types:
            mode = item.get("mode", "one_way")
            if mode not in ("one_way", "ping_pong"):
                raise ValueError(
                    f"Invalid edge mode '{mode}' for edge type '{item.get('id', '?')}'."
                )

            units_per_edge = float(item.get("units_per_edge", 1.0))
            if units_per_edge <= 0:
                raise ValueError(
                    f"units_per_edge must be > 0 for edge type '{item.get('id', '?')}'."
                )

            edge_def = EdgeTypeDef(
                edge_type_id=item["id"],
                label=item.get("label", item["id"]),
                color=item.get("color", "#FFD966"),
                speed=float(item.get("speed", 50.0)),
                capacity_per_trip=float(item.get("capacity_per_trip", 10.0)),
                mode=mode,
                transport_resource=str(item.get("transport_resource", "")),
                units_per_edge=units_per_edge,
                initial_pool_units=float(item.get("initial_pool_units", 0.0)),
            )

            self.edge_types_by_id[edge_def.edge_type_id] = edge_def
            self.edge_palette_order.append(edge_def.edge_type_id)

    def get(self, entity_id: str) -> EntityDef:
        return self.entities_by_id[entity_id]

    def get_all_ids(self) -> list[str]:
        return list(self.palette_order)

    def get_edge_type(self, edge_type_id: str) -> EdgeTypeDef:
        return self.edge_types_by_id[edge_type_id]

    def get_all_edge_type_ids(self) -> list[str]:
        return list(self.edge_palette_order)

    def get_default_edge_type_id(self) -> str | None:
        return self.edge_palette_order[0] if self.edge_palette_order else None

    def read_json_text(self) -> str:
        return self.json_path.read_text(encoding="utf-8")

    def write_json_text(self, text: str) -> None:
        parsed = json.loads(text)

        if "entities" not in parsed or not isinstance(parsed["entities"], list):
            raise ValueError("El JSON debe contener una lista 'entities'.")

        if "edges" in parsed and not isinstance(parsed["edges"], list):
            raise ValueError("La clave 'edges' debe ser una lista.")

        for item in parsed.get("edges", []):
            mode = item.get("mode", "one_way")
            if mode not in ("one_way", "ping_pong"):
                raise ValueError(
                    f"El campo 'mode' de cada edge debe ser 'one_way' o 'ping_pong'. Error en '{item.get('id', '?')}'."
                )

            units_per_edge = float(item.get("units_per_edge", 1.0))
            if units_per_edge <= 0:
                raise ValueError(
                    f"El campo 'units_per_edge' debe ser > 0. Error en '{item.get('id', '?')}'."
                )

        self.json_path.write_text(text, encoding="utf-8")
        self.reload()