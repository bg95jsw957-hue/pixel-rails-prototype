extends Node2D
class_name PRMapView

## Draws the corridor map with cozy pixel tiles, tracks, stations, trains.

var world: PRWorld
var tiles: Dictionary = {}
var camera: Camera2D
var selected_city_id: String = ""
var preview_path: Array[Vector2i] = []
var hover_cell: Vector2i = Vector2i(-1, -1)

signal city_tapped(city_id: String)

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
	# Tracks
	var track_tex: Texture2D = tiles["track"]
	for k in world.network.cells.keys():
		var ki := int(k)
		var tx := ki % m.width
		var ty := int(ki / m.width)
		draw_texture(track_tex, Vector2(tx * PRConstants.TILE_PX, ty * PRConstants.TILE_PX))
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

func handle_tap(local_pos: Vector2) -> void:
	var cell := cell_at(local_pos)
	var city := world.city_at_cell(cell.x, cell.y)
	if city != null:
		city_tapped.emit(city.id)
