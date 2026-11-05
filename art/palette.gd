class_name PRPalette
extends RefCounted

## Original cozy warm palette inspired by farm-life pixel games (not copied assets).

const GRASS_LIGHT := Color("8fbf5a")
const GRASS_MID := Color("6fa344")
const GRASS_DARK := Color("4f7a32")
const GRASS_SHADOW := Color("3d5e28")

const HILL := Color("a3925a")
const HILL_DARK := Color("7a6b42")

const MOUNTAIN := Color("8a8074")
const MOUNTAIN_SNOW := Color("e8e4d8")
const MOUNTAIN_SHADOW := Color("5c564c")

const DESERT := Color("d6c07a")
const DESERT_DARK := Color("c4a85e")

const RIVER := Color("5aa0c8")
const RIVER_DEEP := Color("3a78a0")

const TRACK := Color("5a3c22")
const TRACK_TIE := Color("7a5530")
const RAIL := Color("b0b0b0")

const WOOD := Color("a0663a")
const WOOD_DARK := Color("704428")
const WOOD_LIGHT := Color("c48850")
const ROOF := Color("c45c3a")
const ROOF_DARK := Color("8a3a28")

const TRAIN_BODY := Color("c4783a")
const TRAIN_DARK := Color("8a4a22")
const TRAIN_CAB := Color("d8d0c0")
const SMOKE := Color("d0d0d0")

const UI_PANEL := Color("f2e6c8")
const UI_PANEL_EDGE := Color("8a6a40")
const UI_TEXT := Color("3a2a18")
const UI_ACCENT := Color("d4783a")
const UI_GOOD := Color("4a8a3a")
const UI_BAD := Color("a03828")
const PREVIEW := Color(0.95, 0.85, 0.35, 0.7)
const SELECT := Color(1.0, 0.95, 0.4, 0.9)
const SELECT_FILL := Color(0.98, 0.78, 0.22, 0.62)
const SELECT_EDGE := Color(0.42, 0.24, 0.05, 1.0)

## Stable colors so a row in the Lines list matches that rail on the map.
static func line_color(index: int) -> Color:
	var colors: Array[Color] = [
		Color("c4783a"),
		Color("2f6fad"),
		Color("5d8a32"),
		Color("8a3d78"),
		Color("2f7a74"),
		Color("a84a28"),
	]
	var n := colors.size()
	var i := index % n
	if i < 0:
		i += n
	return colors[i]
