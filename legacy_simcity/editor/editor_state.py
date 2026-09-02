from dataclasses import dataclass, field
from typing import Optional

from core.enums import SimulationMode


@dataclass
class EditorState:
    selected_palette_entity: Optional[str] = None
    selected_edge_type: Optional[str] = None

    selected_node_id: Optional[int] = None
    selected_edge_index: Optional[int] = None

    simulation_mode: SimulationMode = SimulationMode.RUNNING

    pan_x: float = 0.0
    pan_y: float = 0.0
    scale: float = 1.0

    is_panning: bool = False
    last_pan_mouse_x: Optional[int] = None
    last_pan_mouse_y: Optional[int] = None

    dragging_node_id: Optional[int] = None
    drag_node_mouse_start_x: Optional[int] = None
    drag_node_mouse_start_y: Optional[int] = None
    drag_node_world_start_x: Optional[float] = None
    drag_node_world_start_y: Optional[float] = None

    notification_text: str = ""
    notification_timer: float = 0.0

    transport_inventory: dict[str, float] = field(default_factory=dict)

    # -------------------------------------------------------------------------
    # Shared settlement simulation state
    # -------------------------------------------------------------------------

    workers_current: float = 0.0
    workers_max: float = 0.0

    food_available: float = 0.0
    food_consumed_last_tick: float = 0.0
    food_support_ratio: float = 1.0

    attractiveness: float = 0.0

    # "growing" | "shrinking" | "stable"
    worker_trend: str = "stable"