extends Node2D
class_name PRMapView

## Draws the corridor map with cozy pixel tiles, tracks, stations, trains.

var world: PRWorld
var tiles: Dictionary = {}
var camera: Camera2D
var selected_city_id: String = ""
var selected_line_id: String = ""
var preview_path: Array[Vector2i] = []
var hover_cell: Vector2i = Vector2i(-1, -1)

signal city_tapped(city_id: String)
signal line_tapped(line_id: String)

## Manhattan cells. A couple of tiles of slop so a fingertip can hit a rail.
const LINE_TAP_RADIUS := 2

func setup(w: PRWorld) -> void:
	world = w
	tiles = PRTileFactory.make_atlas()
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var m := world.map
	for y in m.height:
		for x in m.width:
			var t := m.get_terrain(x, y)
			var key := "plains"
			match t:
				PRConstants.T_HILLS: key = "hills"
				PRConstants.T_MOUNTAIN: key = "mountain"
				PRConstants.T_RIVER: key = "river"
				PRConstants.T_DESERT: key = "desert"
				_: key = "plains"
			var tex: Texture2D = tiles[key]
			draw_texture(tex, Vector2(x * PRConstants.TILE_PX, y * PRConstants.TILE_PX))
	# Tracks, then each line's color so rails stay distinct. Selected line is drawn last.
	var track_tex: Texture2D = tiles["track"]
	for k in world.network.cells.keys():
		var ki := int(k)
		var tx := ki % m.width
		var ty := int(ki / m.width)
		draw_texture(track_tex, Vector2(tx * PRConstants.TILE_PX, ty * PRConstants.TILE_PX))
	var line_i := 0
	var selected: PRLine = null
	for line in world.network.lines:
		var L: PRLine = line
		if L.id == selected_line_id:
			selected = L
		else:
			_draw_line_tint(L, PRPalette.line_color(line_i), false)
		line_i += 1
	if selected != null:
		var sel_index := 0
		for line in world.network.lines:
			if line.id == selected.id:
				break
			sel_index += 1
		_draw_line_tint(selected, PRPalette.line_color(sel_index), true)
	# Preview path
	if preview_path.size() > 1:
		for i in range(1, preview_path.size()):
			var p: Vector2i = preview_path[i]
			var r := Rect2(p.x * PRConstants.TILE_PX + 2, p.y * PRConstants.TILE_PX + 2, PRConstants.TILE_PX - 4, PRConstants.TILE_PX - 4)
			draw_rect(r, PRPalette.PREVIEW, true)
	# Stations
	for id in world.city_order:
		var c: PRCity = world.cities[id]
		var tex_key := "station_major" if c.is_major else "station"
		var pos := Vector2(c.grid_x * PRConstants.TILE_PX, c.grid_y * PRConstants.TILE_PX)
		draw_texture(tiles[tex_key], pos)
		if selected_city_id == id:
			draw_rect(Rect2(pos.x - 2, pos.y - 2, PRConstants.TILE_PX + 4, PRConstants.TILE_PX + 4), PRPalette.SELECT, false, 2.0)
		# Name tag
		var font := ThemeDB.fallback_font
		var label := c.name
		var pop_k := int(c.population / 100.0) / 10.0
		var sub := "%.1fk" % pop_k
		draw_string(font, pos + Vector2(-4, -2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PRPalette.UI_TEXT)
		draw_string(font, pos + Vector2(-4, PRConstants.TILE_PX + 10), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, PRPalette.UI_PANEL_EDGE)
	# Trains
	var train_tex: Texture2D = tiles["train"]
	for tid in world.trains.keys():
		var train: PRTrain = world.trains[tid]
		var line := _line(train.line_id)
		if line == null or line.path.is_empty():
			continue
		var idx := clampi(int(floor(train.path_index)), 0, line.path.size() - 1)
		var cell: Vector2i = line.path[idx]
		var tp := Vector2(cell.x * PRConstants.TILE_PX, cell.y * PRConstants.TILE_PX - 4)
		draw_texture(train_tex, tp)
		if train.waiting:
			draw_circle(tp + Vector2(8, 0), 3.0, PRPalette.UI_BAD)

func _line(line_id: String) -> PRLine:
	for line in world.network.lines:
		var L: PRLine = line
		if L.id == line_id:
			return L
	return null

func world_size() -> Vector2:
	return Vector2(world.map.width * PRConstants.TILE_PX, world.map.height * PRConstants.TILE_PX)

func cell_at(local_pos: Vector2) -> Vector2i:
	return Vector2i(int(local_pos.x / PRConstants.TILE_PX), int(local_pos.y / PRConstants.TILE_PX))

func _draw_line_tint(line: PRLine, col: Color, selected: bool) -> void:
	var tile := float(PRConstants.TILE_PX)
	for p in line.path:
		var origin := Vector2(p.x * tile, p.y * tile)
		if selected:
			draw_rect(Rect2(origin, Vector2(tile, tile)), PRPalette.SELECT_FILL, true)
			draw_rect(Rect2(origin, Vector2(tile, tile)), PRPalette.SELECT_EDGE, false, 2.0)
		else:
			var stripe := Rect2(origin.x + 2, origin.y + tile * 0.35, tile - 4, tile * 0.3)
			draw_rect(stripe, Color(col.r, col.g, col.b, 0.85), true)

func handle_tap(local_pos: Vector2) -> void:
	var cell := cell_at(local_pos)
	var city := world.city_at_cell(cell.x, cell.y)
	if city != null:
		city_tapped.emit(city.id)
		return
	if world == null:
		return
	var line := world.pick_line_near(cell.x, cell.y, LINE_TAP_RADIUS, selected_line_id)
	if line != null:
		line_tapped.emit(line.id)
