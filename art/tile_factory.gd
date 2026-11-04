class_name PRTileFactory
extends RefCounted

## Procedural 16x16 chunky pixel tiles — original cozy farm-game feel (warm, soft, readable).

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
	var t := ImageTexture.create_from_image(img)
	return t

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < 16 and y < 16:
		img.set_pixel(x, y, c)

static func _fill(img: Image, c: Color) -> void:
	img.fill(c)

static func _plains() -> ImageTexture:
	var img := _img()
	# Warm soft grass base
	_fill(img, Color("7fbe4e"))
	for y in 16:
		for x in 16:
			var n := (x * 3 + y * 7 + x * y) % 13
			if n == 0 or n == 1:
				_px(img, x, y, Color("98d466"))  # light warm
			elif n == 5:
				_px(img, x, y, Color("5f9a38"))  # soft shadow
			elif n == 9:
				_px(img, x, y, Color("6fad42"))
			# tiny wildflowers
			if (x * 11 + y * 5) % 29 == 0:
				_px(img, x, y, Color("f0c85a"))
			if (x * 7 + y * 13) % 37 == 0:
				_px(img, x, y, Color("e888b0"))
	return _tex(img)

static func _hills() -> ImageTexture:
	var img := _img()
	_fill(img, Color("b8a46a"))
	for y in 16:
		for x in 16:
			# soft rolling shade
			if y > 9 - ((x + 3) % 6):
				_px(img, x, y, Color("8f7c48"))
			if (x + y * 2) % 11 == 0:
				_px(img, x, y, Color("8fbe4e"))  # grass tuft
			if y < 3 and (x + y) % 4 == 0:
				_px(img, x, y, Color("c8b87a"))
	return _tex(img)

static func _mountain() -> ImageTexture:
	var img := _img()
	_fill(img, Color("8e8478"))
	for y in 16:
		for x in 16:
			var peak := absi(x - 8) + int(y * 0.85)
			if peak < 11:
				_px(img, x, y, Color("6e665c"))
			if peak < 7:
				_px(img, x, y, Color("efe8d8"))  # soft snow cap
			if peak < 4:
				_px(img, x, y, Color("ffffff"))
			if y > 12:
				_px(img, x, y, Color("7a6b42"))
			# warm cliff edge
			if peak == 11:
				_px(img, x, y, Color("a09070"))
	return _tex(img)

static func _river() -> ImageTexture:
	var img := _img()
	_fill(img, Color("6ab0d0"))
	for y in 16:
		for x in 16:
			if (x + int(y / 2)) % 5 == 0:
				_px(img, x, y, Color("4a90b8"))
			if (x * 2 + y) % 7 == 0:
				_px(img, x, y, Color("8ec8e0"))  # sparkle
			# grassy banks
			if y < 2 or y > 13:
				_px(img, x, y, Color("7fbe4e"))
			if y == 2 or y == 13:
				_px(img, x, y, Color("5f9a38"))
	return _tex(img)

static func _desert() -> ImageTexture:
	var img := _img()
	_fill(img, Color("e0c878"))
	for y in 16:
		for x in 16:
			if (x * 5 + y * 3) % 13 == 0:
				_px(img, x, y, Color("c8a858"))
			if (x + y * 4) % 19 == 0:
				_px(img, x, y, Color("7a9a48"))  # scrub
			if (x * 3 + y) % 23 == 0:
				_px(img, x, y, Color("d8b868"))
	return _tex(img)

static func _track() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	# warm gravel bed
	for y in range(5, 11):
		for x in 16:
			_px(img, x, y, Color("c4a878") if (x + y) % 2 == 0 else Color("b09060"))
	# wooden ties
	for x in range(0, 16, 3):
		for y in range(5, 11):
			_px(img, x, y, Color("6a4428"))
			_px(img, mini(15, x + 1), y, Color("8a5a34"))
	# steel rails
	for x in 16:
		_px(img, x, 6, Color("d0d4d8"))
		_px(img, x, 9, Color("d0d4d8"))
		_px(img, x, 5, Color("909498"))
		_px(img, x, 10, Color("909498"))
	return _tex(img)

static func _station() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	# soft ground shadow
	for y in range(13, 16):
		for x in range(1, 15):
			_px(img, x, y, Color(0.35, 0.28, 0.15, 0.35))
	# platform
	for y in range(12, 15):
		for x in range(1, 15):
			_px(img, x, y, Color("b0a890"))
	# wooden body — chunky boards
	for y in range(5, 12):
		for x in range(3, 13):
			var board := Color("c48850") if (y % 2 == 0) else Color("a86e3a")
			_px(img, x, y, board)
	# warm roof
	for x in range(2, 14):
		_px(img, x, 4, Color("d46848"))
		_px(img, x, 3, Color("a84830"))
	_px(img, 7, 2, Color("d46848"))
	_px(img, 8, 2, Color("d46848"))
	# door
	for y in range(8, 12):
		_px(img, 7, y, Color("6a3a1e"))
		_px(img, 8, y, Color("6a3a1e"))
	# window glow
	_px(img, 10, 7, Color("ffe8a0"))
	_px(img, 11, 7, Color("ffe8a0"))
	_px(img, 10, 8, Color("f0d080"))
	_px(img, 11, 8, Color("f0d080"))
	return _tex(img)

static func _station_major() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	for y in range(13, 16):
		for x in range(0, 16):
			_px(img, x, y, Color(0.35, 0.28, 0.15, 0.4))
	for y in range(12, 15):
		for x in range(0, 16):
			_px(img, x, y, Color("b0a890"))
	for y in range(4, 12):
		for x in range(1, 15):
			_px(img, x, y, Color("c48850") if (y % 2 == 0) else Color("a86e3a"))
	for x in range(0, 16):
		_px(img, x, 3, Color("d46848"))
		_px(img, x, 2, Color("a84830"))
	for x in range(5, 11):
		_px(img, x, 1, Color("d46848"))
	# clock tower
	for y in range(0, 5):
		_px(img, 7, y, Color("e0d0b0"))
		_px(img, 8, y, Color("e0d0b0"))
	_px(img, 7, 0, Color("a84830"))
	_px(img, 8, 0, Color("a84830"))
	_px(img, 7, 2, Color("2a2a2a"))
	_px(img, 8, 2, Color("2a2a2a"))
	# big door
	for y in range(8, 12):
		_px(img, 4, y, Color("6a3a1e"))
		_px(img, 5, y, Color("6a3a1e"))
	# windows
	for wx in [10, 12]:
		_px(img, wx, 6, Color("ffe8a0"))
		_px(img, wx + 1, 6, Color("ffe8a0"))
		_px(img, wx, 7, Color("f0d080"))
		_px(img, wx + 1, 7, Color("f0d080"))
	return _tex(img)

static func _train() -> ImageTexture:
	var img := _img()
	img.fill(Color(0, 0, 0, 0))
	# shadow
	for x in range(2, 14):
		_px(img, x, 12, Color(0.2, 0.15, 0.1, 0.35))
	# boiler — warm copper/red
	for y in range(6, 11):
		for x in range(2, 11):
			_px(img, x, y, Color("d87840") if y < 9 else Color("b85828"))
	# cab
	for y in range(4, 11):
		for x in range(10, 14):
			_px(img, x, y, Color("f0e8d8"))
	for y in range(5, 8):
		_px(img, 11, y, Color("5a88b0"))
		_px(img, 12, y, Color("5a88b0"))
	# chimney + puff
	for y in range(2, 6):
		_px(img, 4, y, Color("4a3020"))
		_px(img, 5, y, Color("4a3020"))
	_px(img, 4, 1, Color("e8e8e8"))
	_px(img, 5, 0, Color("d0d0d0"))
	_px(img, 6, 1, Color("e8e8e8"))
	# cowcatcher hint
	_px(img, 1, 10, Color("c0c0c0"))
	_px(img, 2, 11, Color("a0a0a0"))
	# wheels
	for wx in [3, 8, 12]:
		_px(img, wx, 11, Color("2a2a2a"))
		_px(img, wx + 1, 11, Color("2a2a2a"))
	return _tex(img)
