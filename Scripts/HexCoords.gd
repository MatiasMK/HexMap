class_name HexCoords
extends RefCounted

var q: int
var r: int
var s: int

const DIRECTIONS = [
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

static func from_cubic(q_val: int, r_val: int, s_val: int) -> HexCoords:
	return HexCoords.new(q_val, r_val, s_val)

static func from_axial(q_val: int, r_val: int) -> HexCoords:
	return HexCoords.new(q_val, r_val, -q_val - r_val)

static func from_float(x: float, y: float, z: float) -> HexCoords:
	return cube_round_floats(x, y, z)

# Given three float numbers, makes a new HexCoord whose coords are equal to the numbers.
# Rounding them in the process, and adjusting the value of the biggest number so the sum
# of all three equals 0.
static func cube_round_floats(x: float, y: float, z: float) -> HexCoords:
	var q_val = int(round(x))
	var r_val = int(round(y))
	var s_val = int(round(z))
	
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

func to_axial() -> Dictionary:
	return {"q": q, "r": r}

func to_cubic() -> Dictionary:
	return {"q": q, "r": r, "s": s}

func _add(other: HexCoords) -> HexCoords:
	return HexCoords.new(q + other.q, r + other.r, s + other.s)

func _sub(other: HexCoords) -> HexCoords:
	return HexCoords.new(q - other.q, r - other.r, s - other.s)

func _mul(scalar: int) -> HexCoords:
	return HexCoords.new(q * scalar, r * scalar, s * scalar)

func _div(scalar: int) -> HexCoords:
	@warning_ignore("integer_division")
	return HexCoords.new(q / scalar, r / scalar, s / scalar)

func add(other: HexCoords) -> HexCoords:
	return _add(other)

func sub(other: HexCoords) -> HexCoords:
	return _sub(other)

func mul(scalar: int) -> HexCoords:
	return _mul(scalar)

func div(scalar: int) -> HexCoords:
	return _div(scalar)

# Given a neighbor number, returns its direction.
static func get_neighbor_direction(direction: int) -> Vector3i:
	return DIRECTIONS[direction % 6]

# Given a neighbor number, returns its hex.
static func _neighbor(hex: HexCoords, direction: int) -> HexCoords:
	var dir = DIRECTIONS[direction % 6]
	return HexCoords.new(hex.q + dir.x, hex.r + dir.y, hex.s + dir.z)

# Given a neighbor direction, returns its number.
static func get_neighbor_direction_for(hex: HexCoords, neighbor: HexCoords) -> int:
	var diff = Vector3i(neighbor.q - hex.q, neighbor.r - hex.r, neighbor.s - hex.s)
	for i in range(6):
		if DIRECTIONS[i] == diff:
			return i
	return -1

# Given two diferent hexes, returns the distance between them.
static func distance(a: HexCoords, b: HexCoords) -> int:
	return (abs(a.q - b.q) + abs(a.r - b.r) + abs(a.s - b.s)) / 2

# Returns the points needed to draw a line between two hexes.
static func linear_interpolation(a: HexCoords, b: HexCoords, t: float) -> Dictionary:
	var x = lerp(float(a.q), float(b.q), t)
	var y = lerp(float(a.r), float(b.r), t)
	var z = lerp(float(a.s), float(b.s), t)
	return {"x": x, "y": y, "z": z}

# Returns the hexagons needed to draw a line between two other hexagons.
static func get_line(start: HexCoords, end: HexCoords) -> Array[HexCoords]:
	var results: Array[HexCoords] = []
	var n = distance(start, end)
	results.append(start)
	
	for i in range(1, n + 1):
		var t = float(i) / float(n)
		var interp = linear_interpolation(start, end, t)
		var hex = from_float(interp.x, interp.y, interp.z)
		results.append(hex)
	
	return results

# Returns all hexes within N steps from center.
static func range(center: HexCoords, n: int) -> Array[HexCoords]:
	var results: Array[HexCoords] = []
	
	for _q in range(-n, n + 1):
		var r_min = max(-n, -_q - n)
		var r_max = min(n, -_q + n)
		for _r in range(r_min, r_max + 1):
			var _s = -_q - _r
			results.append(HexCoords.new(center.q + _q, center.r + _r, center.s + _s))
	
	return results

func _eq(other: Variant) -> bool:
	if other is HexCoords:
		return q == other.q and r == other.r and s == other.s
	return false

func _not_eq(other: Variant) -> bool:
	return not _eq(other)

func _to_string() -> String:
	return "(%d, %d, %d)" % [q, r, s]
