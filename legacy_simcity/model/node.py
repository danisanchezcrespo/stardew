from dataclasses import dataclass, field
from typing import Optional

from core.enums import NodeState


@dataclass
class NodeInstance:
    id: int
    entity_type: str
    world_x: float
    world_y: float

    state: NodeState
    inventory: dict[str, float] = field(default_factory=dict)
    construction_progress: dict[str, float] = field(default_factory=dict)

    active_process_total_sec: float = 0.0
    active_process_remaining_sec: float = 0.0
    active_process_output_name: Optional[str] = None

    # -------------------------------------------------------------------------
    # Worker staffing runtime state
    # -------------------------------------------------------------------------

    workers_assigned: float = 0.0
    worker_efficiency: float = 1.0

    canvas_item_id: Optional[int] = None
    label_item_id: Optional[int] = None