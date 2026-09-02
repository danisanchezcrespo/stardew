class_name SimulationTransportPacket
extends RefCounted

var resource_name: String = ""
var amount: float = 0.0
var progress: float = 0.0


func _init(name: String = "", packet_amount: float = 0.0, travel_progress: float = 0.0) -> void:
	resource_name = name
	amount = packet_amount
	progress = travel_progress
