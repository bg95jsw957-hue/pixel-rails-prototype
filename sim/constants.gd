class_name PRConstants
extends RefCounted

const GRID_W := 96
const GRID_H := 36
const TILE_PX := 16

# Terrain kinds
const T_PLAINS := 0
const T_HILLS := 1
const T_MOUNTAIN := 2
const T_RIVER := 3
const T_DESERT := 4

static func terrain_cost(t: int) -> int:
	match t:
		T_PLAINS: return 10
		T_HILLS: return 25
		T_MOUNTAIN: return 60
		T_RIVER: return 40
		T_DESERT: return 15
		_: return 10

static func terrain_name(t: int) -> String:
	match t:
		T_PLAINS: return "plains"
		T_HILLS: return "hills"
		T_MOUNTAIN: return "mountain"
		T_RIVER: return "river"
		T_DESERT: return "desert"
		_: return "unknown"

# Economy
const STARTING_MONEY := 50000
const TRACK_COST_MULT := 1
const TRAIN_COST := 8000
const TRAIN_CAPACITY_PASS := 40
const TRAIN_CAPACITY_FREIGHT := 60
const FARE_PASS := 12
const FARE_FREIGHT := 8
const TRAIN_SPEED_CELLS_PER_SEC := 2.5
const MAINTENANCE_PER_TRAIN_PER_DAY := 15
const MAINTENANCE_PER_TRACK_PER_DAY := 0.05

# Sim time: 1 game-day = 20 real seconds at 1x
const SECONDS_PER_DAY := 20.0

# City growth
const GROWTH_SERVED := 0.015
const STAGNATE_RATE := -0.004
const MIN_POP := 200
const MAX_POP := 80000
