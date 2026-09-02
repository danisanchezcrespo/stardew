from dataclasses import dataclass
from typing import Optional


@dataclass
class TransportPacket:
    resource_name: str
    amount: float
    progress: float = 0.0


@dataclass
class EdgeInstance:
    from_id: int
    to_id: int
    edge_type_id: str

    packet: Optional[TransportPacket] = None
    return_progress: Optional[float] = None

    canvas_line_id: Optional[int] = None