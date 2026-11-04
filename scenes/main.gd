extends Node2D

@onready var map_view: PRMapView = $MapView
@onready var camera: Camera2D = $Camera2D
@onready var hud: PRHud = $HUD

var world: PRWorld
var pick_from: String = ""
var pending_preview: Dictionary = {}
var drag_active := false
var drag_last := Vector2.ZERO
var pinch_dist := 0.0

func _ready() -> void:
	world = Game.world
	map_view.setup(world)
	map_view.city_tapped.connect(_on_city_tapped)
	hud.speed_changed.connect(_on_speed)
	hud.confirm_build.connect(_on_confirm)
	hud.cancel_build.connect(_on_cancel)
	hud.buy_train_pressed.connect(_on_buy_train)
	world.money_changed.connect(hud.update_money)
	world.message.connect(hud.set_status)
	hud.update_money(world.economy.money)
	hud.update_day(world.day)
	hud.update_goal(world.goal_text, false, 0.0)
	hud.set_status("Tap a station, then another to lay track.")
	hud.show_tooltip("Welcome! Tap two stations to build. Use speed buttons at top.")
	# Center camera on map
	var sz := map_view.world_size()
	camera.position = sz * 0.5
	camera.zoom = Vector2(0.55, 0.55)
	# Soft background color
	RenderingServer.set_default_clear_color(Color("c8e090"))

func _process(delta: float) -> void:
	world.tick(delta)
	hud.update_day(world.day)
	hud.update_goal(world.goal_text, world.omaha_sacramento_connected(), world.period_profit)
	hud.refresh_lines(world.lines_profit_summary())
	map_view.queue_redraw()

func _on_speed(mult: float) -> void:
	world.set_speed(mult)
	var label := "Paused" if mult <= 0.0 else "%dx" % int(mult)
	hud.set_status("Speed: %s" % label)

func _on_city_tapped(city_id: String) -> void:
	if pick_from == "":
		pick_from = city_id
		map_view.selected_city_id = city_id
		hud.set_status("From %s — tap destination." % world.cities[city_id].name)
		hud.hide_preview()
		map_view.preview_path = []
		return
	if city_id == pick_from:
		hud.set_status("Pick a different city.")
		return
	pending_preview = world.preview_route(pick_from, city_id)
	pending_preview["from"] = pick_from
	pending_preview["to"] = city_id
	map_view.preview_path = pending_preview.path
	var cost: int = int(pending_preview.cost)
	hud.show_preview(world.cities[pick_from].name, world.cities[city_id].name, cost, world.economy.can_afford(cost))
	map_view.selected_city_id = city_id

func _on_confirm() -> void:
	if pending_preview.is_empty():
		return
	var res := world.build_line(str(pending_preview.from), str(pending_preview.to))
	_clear_pick()
	if res.ok:
		hud.set_status("Track laid! Select the line and buy a train.")
	else:
		hud.set_status(str(res.error))

func _on_cancel() -> void:
	_clear_pick()
	hud.set_status("Build cancelled.")

func _clear_pick() -> void:
	pick_from = ""
	pending_preview = {}
	map_view.selected_city_id = ""
	map_view.preview_path = []
	hud.hide_preview()

func _on_buy_train() -> void:
	var lid := hud.selected_line_id
	if lid == "":
		if world.network.lines.size() == 1:
			lid = world.network.lines[0].id
			hud.selected_line_id = lid
		else:
			hud.set_status("Select a line first (list on the right).")
			hud.show_tooltip("Tap a line in the side list, then Buy Train.")
			return
	var res := world.buy_train(lid)
	if not res.ok:
		hud.set_status(str(res.error))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var local := map_view.to_local(get_canvas_transform().affine_inverse() * st.position)
			# Convert via camera
			local = camera.get_screen_center_position() + (st.position - get_viewport().get_visible_rect().size * 0.5) / camera.zoom
			# Better: use canvas transform
			local = _screen_to_map(st.position)
			map_view.handle_tap(local)
			drag_active = true
			drag_last = st.position
		else:
			drag_active = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		camera.position -= sd.relative / camera.zoom
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			map_view.handle_tap(_screen_to_map(mb.position))
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			camera.zoom = (camera.zoom * 1.1).clamp(Vector2(0.3, 0.3), Vector2(2.5, 2.5))
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			camera.zoom = (camera.zoom / 1.1).clamp(Vector2(0.3, 0.3), Vector2(2.5, 2.5))
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			camera.position -= mm.relative / camera.zoom

func _screen_to_map(screen_pos: Vector2) -> Vector2:
	var vp := get_viewport()
	var canvas := vp.get_canvas_transform()
	return canvas.affine_inverse() * screen_pos
