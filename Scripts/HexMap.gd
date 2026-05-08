class_name HexMap
extends Node2D

@export var hex_size: float = 32.0
@export var map_radius: int = 5
@export var pointy_top: bool = true
@export var default_tile_type: HexTile.Type = HexTile.Type.GRASS

var tiles: Dictionary = {}  # key: Vector2i(q, r), value: HexTile

signal tile_changed(coords: HexCoords, new_type: HexTile.Type)


func _ready():
	generate_map()


func generate_map():
	tiles.clear()
	for hex in HexCoords.range(HexCoords.new(), map_radius):
		var key = Vector2i(hex.q, hex.r)
		tiles[key] = HexTile.new(hex, default_tile_type)
	queue_redraw()


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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hex = pixel_to_hex(get_local_mouse_position())
		var tile = get_tile(hex)
		if tile:
			set_tile_type(hex, _next_type(tile.type))


static func _next_type(current: HexTile.Type) -> HexTile.Type:
	var values = HexTile.Type.values()
	return values[(current + 1) % values.size()]
