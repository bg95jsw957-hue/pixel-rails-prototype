class_name PRTrain
extends RefCounted

var id: String
var line_id: String
var path_index: float = 0.0  # fractional along path
var direction: int = 1  # +1 toward to_city, -1 toward from
var passengers: int = 0
var freight: int = 0
var waiting: bool = false  # held by signal
var at_station_cooldown: float = 0.0

func _init(p_id: String = "", p_line: String = "") -> void:
	id = p_id
	line_id = p_line
