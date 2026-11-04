class_name PRPathfinder
extends RefCounted

## A* on 4-connected grid. Returns array of Vector2i cells inclusive, or empty on failure.

static func find_path(map: PRGridMap, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not map.in_bounds(start.x, start.y) or not map.in_bounds(goal.x, goal.y):
		return empty
	if map.is_blocked(start.x, start.y) or map.is_blocked(goal.x, goal.y):
		return empty

	var open := {}
	var came := {}
	var gscore := {}
	var fscore := {}
	var key := func(p: Vector2i) -> int: return p.y * map.width + p.x

	var start_k: int = key.call(start)
	open[start_k] = start
	gscore[start_k] = 0
	fscore[start_k] = _heuristic(start, goal)

	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]

	while not open.is_empty():
		var current_k := _lowest_f(open, fscore)
		var current: Vector2i = open[current_k]
		if current == goal:
			return _reconstruct(came, current, map.width)
		open.erase(current_k)
		for d in dirs:
			var n := current + d
			if not map.in_bounds(n.x, n.y) or map.is_blocked(n.x, n.y):
				continue
			var nk: int = key.call(n)
			var tent: int = int(gscore[current_k]) + map.move_cost(n.x, n.y)
			if not gscore.has(nk) or tent < int(gscore[nk]):
				came[nk] = current_k
				gscore[nk] = tent
				fscore[nk] = tent + _heuristic(n, goal)
				open[nk] = n
	return empty

static func path_cost(map: PRGridMap, path: Array[Vector2i]) -> int:
	if path.is_empty():
		return 0
	var total := 0
	for i in range(1, path.size()):
		var p: Vector2i = path[i]
		total += map.move_cost(p.x, p.y)
	return total * PRConstants.TRACK_COST_MULT

static func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return (absi(a.x - b.x) + absi(a.y - b.y)) * 10

static func _lowest_f(open: Dictionary, fscore: Dictionary) -> int:
	var best_k := -1
	var best_f := 1 << 30
	for k in open.keys():
		var f: int = int(fscore.get(k, 1 << 30))
		if f < best_f:
			best_f = f
			best_k = int(k)
	return best_k

static func _reconstruct(came: Dictionary, current: Vector2i, width: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	var ck: int = current.y * width + current.x
	while came.has(ck):
		var pk: int = int(came[ck])
		var px := pk % width
		var py := int(pk / width)
		path.push_front(Vector2i(px, py))
		ck = pk
	return path
