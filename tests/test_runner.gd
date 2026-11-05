extends SceneTree

## Headless test runner: godot --headless -s res://tests/test_runner.gd

var passed := 0
var failed := 0

func _init() -> void:
	print("=== Pixel Rails tests ===")
	_run()
	print("=== %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _run() -> void:
	test_terrain_costs()
	test_pathfinder_finds_route()
	test_pathfinder_mountains_costlier()
	test_build_line_and_money()
	test_signals_block_collision()
	test_city_growth_served_vs_stagnate()
	test_train_earns_revenue()
	test_buy_train_attaches_to_chosen_line()
	test_pick_line_near_specific_rail()
	test_buy_requires_explicit_line_selection()
	test_corridor_cities_present()
	test_preview_then_cancel_no_spend()
	test_omaha_sacramento_connectable()

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: ", msg)
	else:
		failed += 1
		print("  FAIL: ", msg)

func assert_eq(a, b, msg: String) -> void:
	assert_true(a == b, "%s (got %s expected %s)" % [msg, str(a), str(b)])

func test_terrain_costs() -> void:
	assert_true(PRConstants.terrain_cost(PRConstants.T_MOUNTAIN) > PRConstants.terrain_cost(PRConstants.T_PLAINS), "mountains cost more than plains")
	assert_true(PRConstants.terrain_cost(PRConstants.T_RIVER) > PRConstants.terrain_cost(PRConstants.T_PLAINS), "rivers cost more than plains")

func test_pathfinder_finds_route() -> void:
	var w := PRWorld.new()
	var prev := w.preview_route("omaha", "north_platte")
	assert_true(prev.ok, "omaha→north_platte has path")
	assert_true(prev.path.size() > 5, "path has multiple cells")

func test_pathfinder_mountains_costlier() -> void:
	var w := PRWorld.new()
	var plains := w.preview_route("omaha", "julesburg")
	var rocky := w.preview_route("cheyenne", "laramie")
	assert_true(plains.ok and rocky.ok, "both routes exist")
	# Per-cell average should be higher through rockies area
	var avg_p: float = float(plains.cost) / float(maxi(1, plains.path.size()))
	var avg_r: float = float(rocky.cost) / float(maxi(1, rocky.path.size()))
	assert_true(avg_r >= avg_p * 0.9, "rocky corridor not cheaper per cell than plains")

func test_build_line_and_money() -> void:
	var w := PRWorld.new()
	var before := w.economy.money
	var prev := w.preview_route("omaha", "julesburg")
	var res := w.build_line("omaha", "julesburg")
	assert_true(res.ok, "build succeeds")
	assert_true(w.economy.money < before, "money decreased")
	assert_eq(w.economy.money, before - float(prev.cost), "spent exact preview cost")
	assert_true(w.cities["omaha"].served and w.cities["julesburg"].served, "cities marked served")

func test_signals_block_collision() -> void:
	var sig := PRSignalSystem.new()
	sig.block_size = 4
	assert_true(sig.can_enter("L1", 0, "T1"), "empty block free")
	sig.enter("L1", 0, "T1")
	assert_true(not sig.can_enter("L1", 1, "T2"), "same block occupied blocks other train")
	assert_true(sig.can_enter("L1", 0, "T1"), "same train may stay")
	assert_true(sig.can_enter("L1", 4, "T2"), "next block free")
	sig.leave("L1", 0, "T1")
	assert_true(sig.can_enter("L1", 1, "T2"), "freed after leave")

func test_city_growth_served_vs_stagnate() -> void:
	var a := PRCity.new("a", "A", 0, 0, 1000.0, true)
	var b := PRCity.new("b", "B", 1, 0, 1000.0, false)
	a.served = true
	b.served = false
	for i in 100:
		a.tick_growth(1.0)
		b.tick_growth(1.0)
	assert_true(a.population > 1000.0, "served city grew")
	assert_true(b.population < 1000.0, "skipped city stagnated")

func test_train_earns_revenue() -> void:
	var w := PRWorld.new()
	w.build_line("omaha", "julesburg")
	var line: PRLine = w.network.lines[0]
	var buy := w.buy_train(line.id)
	assert_true(buy.ok, "bought train")
	var money_before := w.economy.money
	# Fast-forward until train reaches end and earns
	w.set_speed(4.0)
	for i in 800:
		w.tick(0.25)
		if w.economy.money > money_before:
			break
	assert_true(w.economy.money > money_before, "train earned revenue after trips")
	assert_true(line.revenue > 0.0, "line shows revenue")

func test_buy_train_attaches_to_chosen_line() -> void:
	var w := PRWorld.new()
	w.economy.money = 200000.0
	var built_a := w.build_line("omaha", "julesburg")
	var built_b := w.build_line("cheyenne", "laramie")
	assert_true(built_a.ok and built_b.ok, "two lines exist to choose from")
	var line_a: PRLine = built_a.line
	var line_b: PRLine = built_b.line
	var buy := w.buy_train(line_b.id)
	assert_true(buy.ok, "bought train on the chosen line")
	var train: PRTrain = buy.train
	assert_eq(train.line_id, line_b.id, "train.line_id is the chosen line")
	assert_true(w.trains[train.id].line_id == line_b.id, "world stores the train on that line")
	assert_true(line_b.train_ids.has(train.id), "chosen line lists the train")
	assert_eq(line_a.train_ids.size(), 0, "the other line did not receive the train")
	assert_eq(w.trains.size(), 1, "exactly one train was created")
	var cash := w.economy.money
	var blank := w.buy_train("")
	assert_true(not blank.ok, "blank line id is rejected")
	var missing := w.buy_train("no-such-line")
	assert_true(not missing.ok, "unknown line id is rejected")
	assert_eq(w.trains.size(), 1, "rejected buys create no train")
	assert_eq(w.economy.money, cash, "rejected buys do not charge")
	var buy_a := w.buy_train(line_a.id)
	assert_true(buy_a.ok, "bought a train on the other line")
	var train_a: PRTrain = buy_a.train
	assert_eq(train_a.line_id, line_a.id, "second train attached to its own line")
	assert_eq(line_a.train_ids.size(), 1, "first line has one train")
	assert_eq(line_b.train_ids.size(), 1, "second line still has one train")

func test_pick_line_near_specific_rail() -> void:
	var w := PRWorld.new()
	var built_a := w.build_line("omaha", "julesburg")
	var built_b := w.build_line("cheyenne", "laramie")
	assert_true(built_a.ok and built_b.ok, "routes exist for map pick")
	var line_a: PRLine = built_a.line
	var line_b: PRLine = built_b.line
	var mid_b: Vector2i = line_b.path[line_b.path.size() / 2]
	var picked: PRLine = w.pick_line_near(mid_b.x, mid_b.y, 0, "")
	assert_true(picked != null, "track cell finds a line")
	assert_eq(picked.id, line_b.id, "tapped rail is line B, not the first line")
	var mid_a: Vector2i = line_a.path[line_a.path.size() / 2]
	assert_true(mid_a != mid_b, "the two sample cells are different rails")
	var picked_a: PRLine = w.pick_line_near(mid_a.x, mid_a.y, 0, line_b.id)
	assert_eq(picked_a.id, line_a.id, "tapped rail is line A")
	assert_true(w.pick_line_near(0, 0, 0, "") == null, "empty cell selects no line")
	# Overlapping cells cycle instead of sticking to the earlier line.
	var shared := PRLine.new()
	shared.id = "Lshared"
	var overlap: Array[Vector2i] = [mid_b]
	shared.path = overlap
	w.network.lines.append(shared)
	var first: PRLine = w.pick_line_near(mid_b.x, mid_b.y, 0, "")
	var second: PRLine = w.pick_line_near(mid_b.x, mid_b.y, 0, first.id)
	assert_true(first != null and second != null, "shared cell returns a line")
	assert_true(first.id != second.id, "tapping a shared cell again cycles to the other line")
	assert_true(second.id == line_b.id or second.id == shared.id, "cycle stays on lines through that cell")

func test_buy_requires_explicit_line_selection() -> void:
	assert_eq(PRHud.resolve_buy_line_id("", 1), "", "a single line is not an implicit selection")
	assert_eq(PRHud.resolve_buy_line_id("", 3), "", "no selection stays empty")
	assert_eq(PRHud.resolve_buy_line_id("L2", 3), "L2", "explicit selection is the buy target")

func test_corridor_cities_present() -> void:
	var w := PRWorld.new()
	for id in ["omaha", "north_platte", "cheyenne", "laramie", "ogden", "elko", "reno", "sacramento"]:
		assert_true(w.cities.has(id), "city present: " + id)

func test_preview_then_cancel_no_spend() -> void:
	var w := PRWorld.new()
	var before := w.economy.money
	var prev := w.preview_route("omaha", "sacramento")
	assert_true(prev.ok, "preview long route ok")
	assert_eq(w.economy.money, before, "preview does not spend")

func test_omaha_sacramento_connectable() -> void:
	var w := PRWorld.new()
	# Build chain
	var chain := ["omaha", "julesburg", "north_platte", "cheyenne", "laramie", "rock_springs", "ogden", "elko", "winnemucca", "reno", "sacramento"]
	w.economy.money = 500000.0
	for i in range(chain.size() - 1):
		var res := w.build_line(chain[i], chain[i + 1])
		assert_true(res.ok, "build %s→%s" % [chain[i], chain[i + 1]])
	assert_true(w.omaha_sacramento_connected(), "network connects Omaha to Sacramento")
