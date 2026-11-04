class_name PRLine
extends RefCounted

var id: String
var from_city_id: String
var to_city_id: String
var path: Array[Vector2i] = []
var cost_built: int = 0
var revenue: float = 0.0
var expenses: float = 0.0
var train_ids: Array[String] = []

func profit() -> float:
	return revenue - expenses

func reset_period_stats() -> void:
	revenue = 0.0
	expenses = 0.0
