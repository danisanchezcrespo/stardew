from dataclasses import dataclass
from model.entity_defs import EntityRegistry
from model.graph import GraphModel


@dataclass
class ProjectModel:
    registry: EntityRegistry

    def __post_init__(self) -> None:
        self.graph = GraphModel(registry=self.registry)