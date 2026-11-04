class_name PRCity
extends RefCounted

var id: String
var name: String
var grid_x: int
var grid_y: int
var population: float
var is_major: bool
var served: bool = false
var cargo_supply: float = 1.0  # freight production factor

func _init(p_id: String = "", p_name: String = "", x: int = 0, y: int = 0, pop: float = 1000.0, major: bool = false) -> void:
	id = p_id
	name = p_name
	grid_x = x
	grid_y = y
	population = pop
	is_major = major

func tick_growth(delta_days: float) -> void:
	var rate := PRConstants.GROWTH_SERVED if served else PRConstants.STAGNATE_RATE
	population = clampf(population * (1.0 + rate * delta_days), PRConstants.MIN_POP, PRConstants.MAX_POP)

func passenger_demand_to(other: PRCity) -> float:
	# Gravity model between cities
	var dx := float(grid_x - other.grid_x)
	var dy := float(grid_y - other.grid_y)
	var dist := maxf(1.0, sqrt(dx * dx + dy * dy))
	return (population * other.population) / (dist * dist) * 0.000002

func freight_demand_to(other: PRCity) -> float:
	var dx := float(grid_x - other.grid_x)
	var dy := float(grid_y - other.grid_y)
	var dist := maxf(1.0, sqrt(dx * dx + dy * dy))
	return (population * 0.4 + other.population * 0.6) * cargo_supply / dist * 0.02
