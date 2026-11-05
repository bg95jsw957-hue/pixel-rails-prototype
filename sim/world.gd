class_name PRWorld
extends RefCounted

## Pure simulation: map, cities, tracks, trains, economy, time. No rendering.

signal money_changed(amount: float)
signal track_built(line: PRLine)
signal city_changed(city: PRCity)
signal message(text: String)

var map: PRGridMap
var cities: Dictionary = {}  # id -> PRCity
var city_order: Array[String] = []
var network: PRTrackNetwork
var signals: PRSignalSystem
var trains: Dictionary = {}  # id -> PRTrain
var economy: PREconomy
var day: float = 0.0
var speed_mult: float = 1.0  # 0 pause, 1, 2, 4
var _next_train: int = 1
var _next_line: int = 1
var scenario_name: String = "Transcontinental Dawn (1865)"
var goal_text: String = "Connect Omaha to Sacramento and earn $20,000 profit"
var goal_profit_target: float = 20000.0
var period_profit: float = 0.0

func _init() -> void:
	map = PRGridMap.build_corridor()
	network = PRTrackNetwork.new()
	signals = PRSignalSystem.new()
	economy = PREconomy.new()
	_seed_cities()

func _seed_cities() -> void:
	# Rough corridor placement on 96x36 grid (x east→west? we'll use x increasing westward for narrative)
	# Actually x=0 Omaha (east), x=max Sacramento (west) matches map bands.
	var defs := [
		{"id": "omaha", "name": "Omaha", "x": 4, "y": 18, "pop": 12000.0, "major": true},
		{"id": "julesburg", "name": "Julesburg", "x": 14, "y": 16, "pop": 800.0, "major": false},
		{"id": "north_platte", "name": "North Platte", "x": 22, "y": 17, "pop": 2500.0, "major": true},
		{"id": "cheyenne", "name": "Cheyenne", "x": 34, "y": 14, "pop": 4000.0, "major": true},
		{"id": "laramie", "name": "Laramie", "x": 40, "y": 16, "pop": 2200.0, "major": true},
		{"id": "rock_springs", "name": "Rock Springs", "x": 48, "y": 18, "pop": 900.0, "major": false},
		{"id": "ogden", "name": "Ogden", "x": 56, "y": 15, "pop": 5000.0, "major": true},
		{"id": "elko", "name": "Elko", "x": 68, "y": 19, "pop": 1800.0, "major": true},
		{"id": "winnemucca", "name": "Winnemucca", "x": 74, "y": 20, "pop": 700.0, "major": false},
		{"id": "reno", "name": "Reno", "x": 82, "y": 17, "pop": 3500.0, "major": true},
		{"id": "sacramento", "name": "Sacramento", "x": 92, "y": 22, "pop": 15000.0, "major": true},
	]
	for d in defs:
		var c := PRCity.new(d.id, d.name, d.x, d.y, d.pop, d.major)
		cities[c.id] = c
		city_order.append(c.id)
		# Clear mountain under station so pathfinding can reach
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var xx: int = c.grid_x + dx
				var yy: int = c.grid_y + dy
				if map.in_bounds(xx, yy):
					if map.get_terrain(xx, yy) == PRConstants.T_MOUNTAIN:
						map.set_terrain(xx, yy, PRConstants.T_HILLS)

func get_city(id: String) -> PRCity:
	return cities.get(id)

func city_at_cell(x: int, y: int) -> PRCity:
	for id in city_order:
		var c: PRCity = cities[id]
		if absi(c.grid_x - x) <= 1 and absi(c.grid_y - y) <= 1:
			return c
	return null

func preview_route(from_id: String, to_id: String) -> Dictionary:
	var a: PRCity = cities[from_id]
	var b: PRCity = cities[to_id]
	var path := PRPathfinder.find_path(map, Vector2i(a.grid_x, a.grid_y), Vector2i(b.grid_x, b.grid_y))
	var cost := PRPathfinder.path_cost(map, path)
	return {"path": path, "cost": cost, "ok": path.size() > 1}

func build_line(from_id: String, to_id: String) -> Dictionary:
	if from_id == to_id:
		return {"ok": false, "error": "Same city"}
	# Already connected?
	for line in network.lines:
		var L: PRLine = line
		if (L.from_city_id == from_id and L.to_city_id == to_id) or (L.from_city_id == to_id and L.to_city_id == from_id):
			return {"ok": false, "error": "Line already exists"}
	var prev := preview_route(from_id, to_id)
	if not prev.ok:
		return {"ok": false, "error": "No route"}
	var cost: int = int(prev.cost)
	if not economy.can_afford(cost):
		return {"ok": false, "error": "Need $%d" % cost}
	economy.spend(float(cost))
	money_changed.emit(economy.money)
	var line := PRLine.new()
	line.id = "L%d" % _next_line
	_next_line += 1
	line.from_city_id = from_id
	line.to_city_id = to_id
	line.path = prev.path
	line.cost_built = cost
	network.add_path(line.path, map.width)
	network.lines.append(line)
	# Mark cities served
	cities[from_id].served = true
	cities[to_id].served = true
	city_changed.emit(cities[from_id])
	city_changed.emit(cities[to_id])
	track_built.emit(line)
	message.emit("Built %s → %s for $%d" % [cities[from_id].name, cities[to_id].name, cost])
	return {"ok": true, "line": line, "cost": cost}

func buy_train(line_id: String) -> Dictionary:
	var line := _find_line(line_id)
	if line == null:
		return {"ok": false, "error": "No line"}
	if not economy.can_afford(PRConstants.TRAIN_COST):
		return {"ok": false, "error": "Need $%d" % PRConstants.TRAIN_COST}
	economy.spend(float(PRConstants.TRAIN_COST))
	money_changed.emit(economy.money)
	var t := PRTrain.new("T%d" % _next_train, line_id)
	_next_train += 1
	trains[t.id] = t
	line.train_ids.append(t.id)
	# Occupy starting block
	signals.enter(line_id, 0, t.id)
	message.emit("Bought train on %s → %s only" % [cities[line.from_city_id].name, cities[line.to_city_id].name])
	return {"ok": true, "train": t}

func find_line(line_id: String) -> PRLine:
	return _find_line(line_id)

## Line under a map tap. radius is manhattan cells. When several lines tie
## for the closest cell, pass current_id to cycle to the next one.
func pick_line_near(x: int, y: int, radius: int = 0, current_id: String = "") -> PRLine:
	var hits: Array = []
	for line in network.lines:
		var L: PRLine = line
		var best := 1 << 30
		for p in L.path:
			var d := absi(p.x - x) + absi(p.y - y)
			if d < best:
				best = d
				if best == 0:
					break
		if best <= radius:
			hits.append({"line": L, "dist": best})
	if hits.is_empty():
		return null
	hits.sort_custom(func(a, b):
		if int(a.dist) == int(b.dist):
			return str(a.line.id) < str(b.line.id)
		return int(a.dist) < int(b.dist)
	)
	var closest := int(hits[0].dist)
	var tied: Array = []
	for h in hits:
		if int(h.dist) != closest:
			break
		tied.append(h.line)
	if tied.size() == 1:
		return tied[0]
	if current_id != "":
		for i in tied.size():
			var L: PRLine = tied[i]
			if L.id == current_id:
				return tied[(i + 1) % tied.size()]
	return tied[0]

func _find_line(line_id: String) -> PRLine:
	for line in network.lines:
		var L: PRLine = line
		if L.id == line_id:
			return L
	return null

func set_speed(mult: float) -> void:
	speed_mult = mult

func tick(delta_sec: float) -> void:
	if speed_mult <= 0.0:
		return
	var sim_dt := delta_sec * speed_mult
	var delta_days := sim_dt / PRConstants.SECONDS_PER_DAY
	day += delta_days
	_tick_trains(sim_dt)
	_tick_cities(delta_days)
	_tick_maintenance(delta_days)

func _tick_cities(delta_days: float) -> void:
	for id in city_order:
		var c: PRCity = cities[id]
		var before := c.population
		c.tick_growth(delta_days)
		if absf(c.population - before) > 1.0:
			city_changed.emit(c)

func _tick_maintenance(delta_days: float) -> void:
	var cost := 0.0
	cost += trains.size() * PRConstants.MAINTENANCE_PER_TRAIN_PER_DAY * delta_days
	cost += network.cell_count() * PRConstants.MAINTENANCE_PER_TRACK_PER_DAY * delta_days
	if cost > 0.0:
		economy.spend(cost)
		# Attribute to lines roughly
		if network.lines.size() > 0:
			var share := cost / float(network.lines.size())
			for line in network.lines:
				var L: PRLine = line
				L.expenses += share
		money_changed.emit(economy.money)

func _tick_trains(sim_dt: float) -> void:
	var step := PRConstants.TRAIN_SPEED_CELLS_PER_SEC * sim_dt
	for tid in trains.keys():
		var train: PRTrain = trains[tid]
		var line := _find_line(train.line_id)
		if line == null or line.path.is_empty():
			continue
		if train.at_station_cooldown > 0.0:
			train.at_station_cooldown -= sim_dt
			continue
		var path_len := line.path.size()
		var cur_i := int(floor(train.path_index))
		cur_i = clampi(cur_i, 0, path_len - 1)
		var next_i := cur_i + train.direction
		if next_i < 0 or next_i >= path_len:
			# Arrived at terminus — unload/load and reverse
			_serve_station(train, line, train.direction > 0)
			train.direction *= -1
			train.at_station_cooldown = 1.2
			continue
		# Signal check for next block
		if not signals.can_enter(line.id, next_i, train.id):
			train.waiting = true
			continue
		train.waiting = false
		# Leave old block if crossing boundary
		var old_bid := signals.block_id_for(line.id, cur_i)
		var new_bid := signals.block_id_for(line.id, next_i)
		if old_bid != new_bid:
			signals.leave(line.id, cur_i, train.id)
			signals.enter(line.id, next_i, train.id)
		else:
			signals.enter(line.id, next_i, train.id)
		train.path_index = clampf(train.path_index + step * float(train.direction), 0.0, float(path_len - 1))

func _serve_station(train: PRTrain, line: PRLine, at_to_end: bool) -> void:
	var dest_id := line.to_city_id if at_to_end else line.from_city_id
	var origin_id := line.from_city_id if at_to_end else line.to_city_id
	var dest: PRCity = cities[dest_id]
	var origin: PRCity = cities[origin_id]
	# Unload — earn fares
	var pass_earn := train.passengers * PRConstants.FARE_PASS
	var freight_earn := train.freight * PRConstants.FARE_FREIGHT
	var earned := float(pass_earn + freight_earn)
	if earned > 0.0:
		economy.earn(earned)
		line.revenue += earned
		period_profit += earned
		money_changed.emit(economy.money)
	train.passengers = 0
	train.freight = 0
	# Load based on demand
	var pdem := origin.passenger_demand_to(dest)
	var fdem := origin.freight_demand_to(dest)
	train.passengers = mini(PRConstants.TRAIN_CAPACITY_PASS, maxi(1, int(pdem * 8.0)))
	train.freight = mini(PRConstants.TRAIN_CAPACITY_FREIGHT, maxi(1, int(fdem * 3.0)))
	origin.served = true
	dest.served = true

func lines_profit_summary() -> Array:
	var out: Array = []
	for line in network.lines:
		var L: PRLine = line
		out.append({
			"id": L.id,
			"index": out.size(),
			"name": "%s → %s" % [cities[L.from_city_id].name, cities[L.to_city_id].name],
			"profit": L.profit(),
			"revenue": L.revenue,
			"expenses": L.expenses,
			"trains": L.train_ids.size(),
		})
	return out

func omaha_sacramento_connected() -> bool:
	# BFS over lines as edges
	var adj := {}
	for id in city_order:
		adj[id] = []
	for line in network.lines:
		var L: PRLine = line
		adj[L.from_city_id].append(L.to_city_id)
		adj[L.to_city_id].append(L.from_city_id)
	var q: Array = ["omaha"]
	var seen := {"omaha": true}
	while not q.is_empty():
		var cur: String = q.pop_front()
		if cur == "sacramento":
			return true
		for n in adj[cur]:
			if not seen.has(n):
				seen[n] = true
				q.append(n)
	return false
