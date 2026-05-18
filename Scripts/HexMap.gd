class_name HexMap
extends Node2D

class BiomeDef extends Resource:
	@export var label: String = "Biome"
	@export var elevation_min: float = -1.0
	@export var elevation_max: float = 1.0
	@export var temperature_min: float = -1.0
	@export var temperature_max: float = 1.0
	@export var moisture_min: float = -1.0
	@export var moisture_max: float = 1.0
	@export var tile_type: HexTile.Type = HexTile.Type.GRASS

@export var hex_size: float = 32.0
@export var map_radius: int = 10:
	set(value):
		map_radius = value
		if is_node_ready():
			generate_map()
@export var pointy_top: bool = true
@export var default_tile_type: HexTile.Type = HexTile.Type.GRASS
@export var noise_seed: int = 0:
	set(value):
		noise_seed = value
		if is_inside_tree():
			_update_noise_seeds()
			generate_map()
@export var continent_scale: float = 0.01
@export var elevation_scale: float = 0.05
@export var temperature_scale: float = 0.015
@export var moisture_scale: float = 0.04
@export var biome_rules: Array[BiomeDef] = []

var noise_continent: FastNoiseLite
var noise_elevation: FastNoiseLite
var noise_temperature: FastNoiseLite
var noise_moisture: FastNoiseLite
var noise_offset: Vector2

var tiles: Dictionary = {}  # key: Vector2i(q, r), value: HexTile

signal tile_changed(coords: HexCoords, new_type: HexTile.Type)


func _ready():
	noise_continent = FastNoiseLite.new()
	noise_continent.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_continent.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_continent.fractal_octaves = 3
	noise_continent.fractal_lacunarity = 2.0
	noise_continent.fractal_gain = 0.5

	noise_elevation = FastNoiseLite.new()
	noise_elevation.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_elevation.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise_elevation.fractal_octaves = 4
	noise_elevation.fractal_lacunarity = 2.0
	noise_elevation.fractal_gain = 0.5

	noise_temperature = FastNoiseLite.new()
	noise_temperature.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_temperature.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_temperature.fractal_octaves = 2

	noise_moisture = FastNoiseLite.new()
	noise_moisture.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_moisture.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_moisture.fractal_octaves = 3

	_update_noise_seeds()
	if biome_rules.is_empty():
		_setup_default_biomes()
	generate_map()


func _setup_default_biomes():
	biome_rules = [
		_rule("Beach",         0.0, 0.1,  -1.0, 1.0, -1.0, 1.0, HexTile.Type.GRASS),
		_rule("Desert",        0.1, 0.5,   0.5, 1.0, -1.0, 0.0, HexTile.Type.DESERT),
		_rule("Savanna",       0.1, 0.3,   0.6, 1.0,  0.0, 1.0, HexTile.Type.GRASS),
		_rule("Forest",        0.1, 0.5,   0.3, 0.6,  0.0, 1.0, HexTile.Type.FOREST),
		_rule("Plains",        0.1, 0.5,   0.3, 0.6, -1.0, 0.0, HexTile.Type.GRASS),
		_rule("Taiga",         0.1, 0.5,  -1.0, 0.3,  0.0, 1.0, HexTile.Type.FOREST),
		_rule("Tundra",        0.1, 0.5,  -1.0, 0.3, -1.0, 0.0, HexTile.Type.SNOW),
		_rule("Mountain",      0.5, 0.7,  -1.0, 1.0, -1.0, 1.0, HexTile.Type.MOUNTAIN),
		_rule("Peak",          0.7, 1.0,  -1.0, 1.0, -1.0, 1.0, HexTile.Type.SNOW),
	]


static func _rule(label: String, e_min: float, e_max: float, t_min: float, t_max: float, m_min: float, m_max: float, type: HexTile.Type) -> BiomeDef:
	var r = BiomeDef.new()
	r.label = label
	r.elevation_min = e_min
	r.elevation_max = e_max
	r.temperature_min = t_min
	r.temperature_max = t_max
	r.moisture_min = m_min
	r.moisture_max = m_max
	r.tile_type = type
	return r


func _update_noise_seeds():
	noise_continent.seed = noise_seed
	noise_elevation.seed = noise_seed + 1
	noise_temperature.seed = noise_seed + 2
	noise_moisture.seed = noise_seed + 3
	var rng = RandomNumberGenerator.new()
	rng.seed = noise_seed
	noise_offset = Vector2(rng.randf_range(-5000.0, 5000.0), rng.randf_range(-5000.0, 5000.0))


func generate_map():
	tiles.clear()
	for hex in HexCoords.range(HexCoords.new(), map_radius):
		var pos = hex_to_pixel(hex) + noise_offset

		var continent = noise_continent.get_noise_2d(pos.x * continent_scale, pos.y * continent_scale)
		var elevation = noise_elevation.get_noise_2d(pos.x * elevation_scale, pos.y * elevation_scale)
		var temp_noise = noise_temperature.get_noise_2d(pos.x * temperature_scale, pos.y * temperature_scale)
		var moisture = noise_moisture.get_noise_2d(pos.x * moisture_scale, pos.y * moisture_scale)

		var latitude = remap(pos.y, -1000.0, 1000.0, -1.0, 1.0)
		var height = elevation
		var temperature = temp_noise * 0.3 + latitude * 0.5 + 0.5
		var tile_type = _biome_from_rules(continent, height, temperature, moisture)
		var key = Vector2i(hex.q, hex.r)
		tiles[key] = HexTile.new(hex, tile_type)
	queue_redraw()


func _biome_from_rules(continent: float, height: float, temperature: float, moisture: float) -> HexTile.Type:
	if continent + 0.3 < 0.0:
		return HexTile.Type.WATER

	for rule in biome_rules:
		if height >= rule.elevation_min and height <= rule.elevation_max \
		and temperature >= rule.temperature_min and temperature < rule.temperature_max \
		and moisture >= rule.moisture_min and moisture < rule.moisture_max:
			return rule.tile_type
	return HexTile.Type.WATER


func get_tile(hex: HexCoords) -> HexTile:
	return tiles.get(Vector2i(hex.q, hex.r))


func set_tile_type(hex: HexCoords, new_type: HexTile.Type):
	var tile = get_tile(hex)
	if tile and tile.type != new_type:
		tile.type = new_type
		tile_changed.emit(hex, new_type)
		queue_redraw()


func hex_to_pixel(hex: HexCoords) -> Vector2:
	if pointy_top:
		return HexCoords.hex_to_pixel_pointy(hex, hex_size)
	return HexCoords.hex_to_pixel_flat(hex, hex_size)


func pixel_to_hex(point: Vector2) -> HexCoords:
	if pointy_top:
		return HexCoords.pixel_to_hex_pointy(point, hex_size)
	return HexCoords.pixel_to_hex_flat(point, hex_size)


func hex_corners(hex: HexCoords) -> PackedVector2Array:
	var center = hex_to_pixel(hex)
	if pointy_top:
		return HexCoords.hex_corners_pointy(center, hex_size)
	return HexCoords.hex_corners_flat(center, hex_size)


static func tile_color(type: HexTile.Type) -> Color:
	match type:
		HexTile.Type.GRASS:   return Color("#5a8f4c")
		HexTile.Type.FOREST:  return Color("#2d5a1e")
		HexTile.Type.DESERT:  return Color("#d4b872")
		HexTile.Type.WATER:   return Color("#3b7eb0")
		HexTile.Type.MOUNTAIN:return Color("#8a7f6e")
		HexTile.Type.SNOW:    return Color("#e8e8f0")
	return Color.WHITE


func _draw():
	for key in tiles:
		var tile = tiles[key] as HexTile
		var corners = hex_corners(tile.coords)
		draw_colored_polygon(corners, tile_color(tile.type))
		draw_polyline(corners, Color(0, 0, 0, 0.3), 1.5, true)


func _input(event):
	if event.is_action_pressed(&"ui_accept"):
		noise_seed = randi()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hex = pixel_to_hex(get_local_mouse_position())
		var tile = get_tile(hex)
		if tile:
			set_tile_type(hex, _next_type(tile.type))


static func _next_type(current: HexTile.Type) -> HexTile.Type:
	var values = HexTile.Type.values()
	return values[(current + 1) % values.size()]
