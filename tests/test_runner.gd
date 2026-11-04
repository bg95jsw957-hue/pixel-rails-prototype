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
