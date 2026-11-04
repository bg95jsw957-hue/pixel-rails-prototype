class_name PRSignalSystem
extends RefCounted

## Automatic block signaling. Path is split into blocks; a block holds at most one train.
## Player never places signals.

var block_size: int = 4
# block_id -> train_id or ""
var occupancy: Dictionary = {}

func block_id_for(line_id: String, path_index: int) -> String:
	var b := int(path_index / block_size)
	return "%s#%d" % [line_id, b]

func can_enter(line_id: String, path_index: int, train_id: String) -> bool:
	var bid := block_id_for(line_id, path_index)
	var occ: String = str(occupancy.get(bid, ""))
	return occ == "" or occ == train_id

func enter(line_id: String, path_index: int, train_id: String) -> void:
	var bid := block_id_for(line_id, path_index)
	occupancy[bid] = train_id

func leave(line_id: String, path_index: int, train_id: String) -> void:
	var bid := block_id_for(line_id, path_index)
	if str(occupancy.get(bid, "")) == train_id:
		occupancy[bid] = ""

func clear_train(train_id: String) -> void:
	for k in occupancy.keys():
		if str(occupancy[k]) == train_id:
			occupancy[k] = ""
