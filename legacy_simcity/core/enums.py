from enum import Enum


class SimulationMode(str, Enum):
    PAUSED = "PAUSED"
    RUNNING = "RUNNING"


class NodeState(str, Enum):
    UNDER_CONSTRUCTION = "UNDER_CONSTRUCTION"
    READY = "READY"
    RUNNING = "RUNNING"