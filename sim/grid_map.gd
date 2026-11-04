class_name PRGridMap
extends RefCounted

var width: int
var height: int
var terrain: PackedByteArray  # size w*h
var blocked: PackedByteArray  # 0/1

func _init(w: int = PRConstants.GRID_W, h: int = PRConstants.GRID_H) -> void:
	width = w
	height = h
	terrain = PackedByteArray()
	terrain.resize(w * h)
	blocked = PackedByteArray()
	blocked.resize(w * h)
	for i in w * h:
		terrain[i] = PRConstants.T_PLAINS
		blocked[i] = 0

func idx(x: int, y: int) -> int:
	return y * width + x

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height

func get_terrain(x: int, y: int) -> int:
	return terrain[idx(x, y)]

func set_terrain(x: int, y: int, t: int) -> void:
	terrain[idx(x, y)] = t

func is_blocked(x: int, y: int) -> bool:
	return blocked[idx(x, y)] != 0

func set_blocked(x: int, y: int, b: bool) -> void:
	blocked[idx(x, y)] = 1 if b else 0

func move_cost(x: int, y: int) -> int:
	if not in_bounds(x, y) or is_blocked(x, y):
		return 999999
	return PRConstants.terrain_cost(get_terrain(x, y))

## Build Omaha–Sacramento corridor placeholder geography.
static func build_corridor() -> PRGridMap:
	var m := PRGridMap.new()
	# Base: plains east, desert/west, mountains spine
	for y in m.height:
		for x in m.width:
			var t := PRConstants.T_PLAINS
			# Rough longitude bands (x=0 east Omaha, x=width-1 west Sacramento)
			var nx := float(x) / float(m.width)
			var ny := float(y) / float(m.height)
			# Mountain belt ~ Rockies / Sierra (two ridges)
			var rockies := absf(nx - 0.38) < 0.07 and ny > 0.15 and ny < 0.85
			var sierra := absf(nx - 0.82) < 0.06 and ny > 0.2 and ny < 0.8
			var hills_e := absf(nx - 0.28) < 0.05
			var hills_w := absf(nx - 0.70) < 0.05
			if rockies or sierra:
				t = PRConstants.T_MOUNTAIN
			elif hills_e or hills_w:
				t = PRConstants.T_HILLS
			elif nx > 0.55 and nx < 0.78:
				t = PRConstants.T_DESERT
			# Platte / Humboldt rivers as horizontal soft bands
			if absf(ny - 0.48) < 0.03 and nx < 0.55:
				t = PRConstants.T_RIVER
			if absf(ny - 0.52) < 0.025 and nx > 0.55 and nx < 0.85:
				t = PRConstants.T_RIVER
			m.set_terrain(x, y, t)
	return m
