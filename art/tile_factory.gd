class_name PRTileFactory
extends RefCounted

## Procedural 16x16 chunky pixel tiles — original art, cozy farm-game feel.

static func make_atlas() -> Dictionary:
	var out := {}
	out["plains"] = _plains()
	out["hills"] = _hills()
	out["mountain"] = _mountain()
	out["river"] = _river()
	out["desert"] = _desert()
	out["track"] = _track()
	out["station"] = _station()
	out["station_major"] = _station_major()
	out["train"] = _train()
	return out

static func _img() -> Image:
	return Image.create(16, 16, false, Image.FORMAT_RGBA8)

static func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < 16 and y < 16:
		img.set_pixel(x, y, c)

static func _fill(img: Image, c: Color) -> void:
	img.fill(c)

static func _plains() -> ImageTexture:
	var img := _img()
	_fill(img, PRPalette.GRASS_MID)
	for y in 16:
		for x in 16:
			var n := (x * 3 + y * 7) % 11
			if n == 0:
				_px(img, x, y, PRPalette.GRASS_LIGHT)
			elif n == 5:
				_px(img, x, y, PRPalette.GRASS_DARK)
			# tiny flowers
			if (x + y * 2) % 17 == 3:
				_px(img, x, y, Color("e8c84a"))
	return _tex(img)

static func _hills() -> ImageTexture:
	var img := _img()
	_fill(img, PRPalette.HILL)
	for y in 16:
		for x in 16:
			if y > 10 - (x % 5):
				_px(img, x, y, PRPalette.HILL_DARK)
			if (x + y) % 9 == 0:
				_px(img, x, y, PRPalette.GRASS_MID)
	return _tex(img)

static func _mountain() -> ImageTexture:
	var img := _img()
	_fill(img, PRPalette.MOUNTAIN)
	for y in 16:
		for x in 16:
			var peak := absi(x - 8) + y
			if peak < 10:
				_px(img, x, y, PRPalette.MOUNTAIN_SHADOW)
			if peak < 6:
				_px(img, x, y, PRPalette.MOUNTAIN_SNOW)
			if y > 12:
				_px(img, x, y, PRPalette.HILL_DARK)
	return _tex(img)

static func _river() -> ImageTexture:
	var img := _img()
	_fill(img, PRPalette.RIVER)
	for y in 16:
		for x in 16:
			if (x + y / 2) % 4 == 0:
				_px(img, x, y, PRPalette.RIVER_DEEP)
			if y < 2 or y > 13:
				_px(img, x, y, PRPalette.GRASS_MID)
	return _tex(img)

static func _desert() -> ImageTexture:
	var img := _img()
	_fill(img, PRPalette.DESERT)
	for y in 16:
		for x in 16:
			if (x * 5 + y * 3) % 13 == 0:
				_px(img, x, y, PRPalette.DESERT_DARK)
			if (x + y * 4) % 23 == 0:
				_px(img, x, y, Color("6a8a3a"))  # scrub
	return _tex(img)

static func _track() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	# ballast hint
	for x in 16:
		_px(img, x, 7, PRPalette.TRACK_TIE)
		_px(img, x, 8, PRPalette.TRACK_TIE)
	# ties
	for x in range(1, 16, 3):
		for y in range(5, 11):
			_px(img, x, y, PRPalette.TRACK)
	# rails
	for x in 16:
		_px(img, x, 6, PRPalette.RAIL)
		_px(img, x, 9, PRPalette.RAIL)
	return _tex(img)

static func _station() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	# platform
	for y in range(12, 15):
		for x in range(1, 15):
			_px(img, x, y, Color("9a9a8a"))
	# wooden building
	for y in range(5, 12):
		for x in range(3, 13):
			_px(img, x, y, PRPalette.WOOD if (x + y) % 2 == 0 else PRPalette.WOOD_DARK)
	# roof
	for x in range(2, 14):
		_px(img, x, 4, PRPalette.ROOF)
		_px(img, x, 3, PRPalette.ROOF_DARK)
	_px(img, 8, 2, PRPalette.ROOF)
	# door + window
	for y in range(8, 12):
		_px(img, 7, y, PRPalette.WOOD_LIGHT)
		_px(img, 8, y, PRPalette.WOOD_LIGHT)
	_px(img, 10, 7, Color("d8e8f0"))
	_px(img, 11, 7, Color("d8e8f0"))
	return _tex(img)

static func _station_major() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	for y in range(12, 15):
		for x in range(0, 16):
			_px(img, x, y, Color("9a9a8a"))
	for y in range(4, 12):
		for x in range(1, 15):
			_px(img, x, y, PRPalette.WOOD if (x + y) % 2 == 0 else PRPalette.WOOD_DARK)
	for x in range(0, 16):
		_px(img, x, 3, PRPalette.ROOF)
		_px(img, x, 2, PRPalette.ROOF_DARK)
	for x in range(6, 10):
		_px(img, x, 1, PRPalette.ROOF)
	# clock tower bump
	for y in range(0, 4):
		_px(img, 7, y, PRPalette.WOOD_LIGHT)
		_px(img, 8, y, PRPalette.WOOD_LIGHT)
	_px(img, 7, 0, PRPalette.ROOF_DARK)
	_px(img, 8, 0, PRPalette.ROOF_DARK)
	for y in range(8, 12):
		_px(img, 4, y, PRPalette.WOOD_LIGHT)
		_px(img, 5, y, PRPalette.WOOD_LIGHT)
	_px(img, 11, 6, Color("d8e8f0"))
	_px(img, 12, 6, Color("d8e8f0"))
	return _tex(img)

static func _train() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	# boiler
	for y in range(6, 11):
		for x in range(2, 11):
			_px(img, x, y, PRPalette.TRAIN_BODY)
	# cab
	for y in range(4, 11):
		for x in range(10, 14):
			_px(img, x, y, PRPalette.TRAIN_CAB)
	for y in range(5, 8):
		_px(img, 11, y, Color("6a90b0"))
		_px(img, 12, y, Color("6a90b0"))
	# chimney
	for y in range(2, 6):
		_px(img, 4, y, PRPalette.TRAIN_DARK)
		_px(img, 5, y, PRPalette.TRAIN_DARK)
	_px(img, 4, 1, PRPalette.SMOKE)
	_px(img, 5, 0, PRPalette.SMOKE)
	# wheels
	_px(img, 3, 11, Color("2a2a2a"))
	_px(img, 4, 11, Color("2a2a2a"))
	_px(img, 8, 11, Color("2a2a2a"))
	_px(img, 9, 11, Color("2a2a2a"))
	_px(img, 12, 11, Color("2a2a2a"))
	return _tex(img)
