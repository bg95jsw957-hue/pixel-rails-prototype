class_name PRTrackNetwork
extends RefCounted

## Cells that have track, and named lines between cities.

var cells: Dictionary = {}  # key int -> true
var lines: Array = []  # Array of PRLine

func has_track(x: int, y: int, width: int) -> bool:
	return cells.has(y * width + x)

func add_path(path: Array[Vector2i], width: int) -> void:
	for p in path:
		cells[p.y * width + p.x] = true

func cell_count() -> int:
	return cells.size()
