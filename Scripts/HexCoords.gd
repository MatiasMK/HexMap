class_name HexCoords
extends RefCounted

var q: int
var r: int
var s: int

const DIRECTIONS := [
	Vector3i(1, -1, 0),
	Vector3i(1, 0, -1),
	Vector3i(0, 1, -1),
	Vector3i(-1, 1, 0),
	Vector3i(-1, 0, 1),
	Vector3i(0, -1, 1)
]


func _init(q_val: int = 0, r_val: int = 0, s_val: int = 0):
	q = q_val
	r = r_val
	s = s_val


# ----- Factory Constructors -----

static func from_cubic(q_val: int, r_val: int, s_val: int) -> HexCoords:
	return HexCoords.new(q_val, r_val, s_val)

static func from_axial(q_val: int, r_val: int) -> HexCoords:
	return HexCoords.new(q_val, r_val, -q_val - r_val)

static func from_float(x: float, y: float, z: float) -> HexCoords:
	return cube_round_floats(x, y, z)


# ----- Rounding -----

static func cube_round_floats(x: float, y: float, z: float) -> HexCoords:
	var q_val = round(x)
	var r_val = round(y)
	var s_val = round(z)

	var q_diff = abs(q_val - x)
	var r_diff = abs(r_val - y)
	var s_diff = abs(s_val - z)

	if q_diff > r_diff and q_diff > s_diff:
		q_val = -r_val - s_val
	elif r_diff > s_diff:
		r_val = -q_val - s_val
	else:
		s_val = -q_val - r_val

	return HexCoords.new(q_val, r_val, s_val)


# ----- Conversion -----

func to_axial() -> Dictionary:
	return {"q": q, "r": r}

func to_cubic() -> Dictionary:
	return {"q": q, "r": r, "s": s}

func to_odd_r_offset() -> Dictionary:
	var col = q
	@warning_ignore("integer_division")
	var row = r + (q - (q & 1)) / 2
	return {"col": col, "row": row}

func to_even_r_offset() -> Dictionary:
	var col = q
	@warning_ignore("integer_division")
	var row = r + (q + (q & 1)) / 2
	return {"col": col, "row": row}

func to_odd_q_offset() -> Dictionary:
	@warning_ignore("integer_division")
	var col = q + (r - (r & 1)) / 2
	var row = r
	return {"col": col, "row": row}

func to_even_q_offset() -> Dictionary:
	@warning_ignore("integer_division")
	var col = q + (r + (r & 1)) / 2
	var row = r
	return {"col": col, "row": row}

static func from_odd_r_offset(col: int, row: int) -> HexCoords:
	var q_val = col
	@warning_ignore("integer_division")
	var r_val = row - (col - (col & 1)) / 2
	return from_axial(q_val, r_val)

static func from_even_r_offset(col: int, row: int) -> HexCoords:
	var q_val = col
	@warning_ignore("integer_division")
	var r_val = row - (col + (col & 1)) / 2
	return from_axial(q_val, r_val)

static func from_odd_q_offset(col: int, row: int) -> HexCoords:
	@warning_ignore("integer_division")
	var q_val = col - (row - (row & 1)) / 2
	var r_val = row
	return from_axial(q_val, r_val)

static func from_even_q_offset(col: int, row: int) -> HexCoords:
	@warning_ignore("integer_division")
	var q_val = col - (row + (row & 1)) / 2
	var r_val = row
	return from_axial(q_val, r_val)


# ----- Arithmetic -----

func add(other: HexCoords) -> HexCoords:
	return HexCoords.new(q + other.q, r + other.r, s + other.s)

func sub(other: HexCoords) -> HexCoords:
	return HexCoords.new(q - other.q, r - other.r, s - other.s)

func mul(scalar: int) -> HexCoords:
	return HexCoords.new(q * scalar, r * scalar, s * scalar)

func div(scalar: int) -> HexCoords:
	@warning_ignore("integer_division")
	return HexCoords.new(q / scalar, r / scalar, s / scalar)


# ----- Length / Distance -----

func length() -> int:
	return (abs(q) + abs(r) + abs(s)) / 2

static func distance(a: HexCoords, b: HexCoords) -> int:
	return (abs(a.q - b.q) + abs(a.r - b.r) + abs(a.s - b.s)) / 2


# ----- Neighbors -----

static func get_neighbor_direction(direction: int) -> Vector3i:
	return DIRECTIONS[direction % 6]

static func get_neighbor_direction_for(hex: HexCoords, _neighbor: HexCoords) -> int:
	var diff = Vector3i(_neighbor.q - hex.q, _neighbor.r - hex.r, _neighbor.s - hex.s)
	for i in range(6):
		if DIRECTIONS[i] == diff:
			return i
	return -1

func neighbor(direction: int) -> HexCoords:
	var dir = DIRECTIONS[direction % 6]
	return HexCoords.new(q + dir.x, r + dir.y, s + dir.z)


# ----- Rotation (60°) -----

func rotate_left() -> HexCoords:
	return HexCoords.new(-s, -q, -r)

func rotate_right() -> HexCoords:
	return HexCoords.new(-r, -s, -q)

func rotate_left_around(center: HexCoords) -> HexCoords:
	return center.add(sub(center).rotate_left())

func rotate_right_around(center: HexCoords) -> HexCoords:
	return center.add(sub(center).rotate_right())


# ----- Reflection -----

func reflect_q() -> HexCoords:
	return HexCoords.new(q, s, r)

func reflect_r() -> HexCoords:
	return HexCoords.new(s, r, q)

func reflect_s() -> HexCoords:
	return HexCoords.new(r, q, s)


# ----- Ring -----

static func ring(center: HexCoords, radius: int) -> Array[HexCoords]:
	if radius <= 0:
		return [center] if radius == 0 else []
	var results: Array[HexCoords] = []
	var dir = DIRECTIONS[4]
	var hex = HexCoords.new(center.q + dir.x * radius, center.r + dir.y * radius, center.s + dir.z * radius)
	for i in range(6):
		for _j in range(radius):
			results.append(hex)
			hex = hex.neighbor(i)
	return results


# ----- Spiral -----

static func spiral(center: HexCoords, radius: int) -> Array[HexCoords]:
	var results: Array[HexCoords] = [center]
	for k in range(1, radius + 1):
		results.append_array(ring(center, k))
	return results


# ----- Line Drawing -----

static func linear_interpolation(a: HexCoords, b: HexCoords, t: float) -> Dictionary:
	var x = lerp(float(a.q), float(b.q), t)
	var y = lerp(float(a.r), float(b.r), t)
	var z = lerp(float(a.s), float(b.s), t)
	return {"x": x, "y": y, "z": z}

static func get_line(start: HexCoords, end: HexCoords) -> Array[HexCoords]:
	var results: Array[HexCoords] = []
	var n = distance(start, end)
	results.append(start)
	for i in range(1, n + 1):
		var t = float(i) / float(n)
		var interp = linear_interpolation(start, end, t)
		results.append(from_float(interp.x, interp.y, interp.z))
	return results


# ----- Range -----

static func range(center: HexCoords, n: int) -> Array[HexCoords]:
	var results: Array[HexCoords] = []
	for _q in range(-n, n + 1):
		var r_min = max(-n, -_q - n)
		var r_max = min(n, -_q + n)
		for _r in range(r_min, r_max + 1):
			results.append(HexCoords.new(center.q + _q, center.r + _r, center.s + -_q - _r))
	return results


# ----- Hex ↔ Pixel (Pointy-Top) -----

static func hex_to_pixel_pointy(hex: HexCoords, size: float) -> Vector2:
	var x = size * (sqrt(3.0) * hex.q + sqrt(3.0) / 2.0 * hex.r)
	var y = size * (1.5 * hex.r)
	return Vector2(x, y)

static func pixel_to_hex_pointy(pixel: Vector2, size: float) -> HexCoords:
	var _q = (sqrt(3.0) / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / size
	var _r = (2.0 / 3.0 * pixel.y) / size
	return from_float(_q, _r, -_q - _r)


# ----- Hex ↔ Pixel (Flat-Top) -----

static func hex_to_pixel_flat(hex: HexCoords, size: float) -> Vector2:
	var x = size * (1.5 * hex.q)
	var y = size * (sqrt(3.0) / 2.0 * hex.q + sqrt(3.0) * hex.r)
	return Vector2(x, y)

static func pixel_to_hex_flat(pixel: Vector2, size: float) -> HexCoords:
	var _q = (2.0 / 3.0 * pixel.x) / size
	var _r = (-1.0 / 3.0 * pixel.x + sqrt(3.0) / 3.0 * pixel.y) / size
	return from_float(_q, _r, -_q - _r)


# ----- Corner Positions for Drawing -----

static func hex_corners_pointy(center: Vector2, size: float) -> PackedVector2Array:
	var corners: PackedVector2Array = []
	corners.resize(6)
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		corners[i] = Vector2(center.x + size * cos(angle), center.y + size * sin(angle))
	return corners

static func hex_corners_flat(center: Vector2, size: float) -> PackedVector2Array:
	var corners: PackedVector2Array = []
	corners.resize(6)
	for i in range(6):
		var angle = deg_to_rad(60.0 * i)
		corners[i] = Vector2(center.x + size * cos(angle), center.y + size * sin(angle))
	return corners


# ----- Operators -----

func _eq(other: Variant) -> bool:
	if other is HexCoords:
		return q == other.q and r == other.r and s == other.s
	return false

func _not_eq(other: Variant) -> bool:
	return not _eq(other)

func _to_string() -> String:
	return "(%d, %d, %d)" % [q, r, s]
