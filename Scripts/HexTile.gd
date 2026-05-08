class_name HexTile
extends RefCounted

enum Type { GRASS, FOREST, DESERT, WATER, MOUNTAIN, SNOW }

var coords: HexCoords
var type: Type
var data: Dictionary  # for any extra attributes

func _init(_coords: HexCoords, _type: Type = Type.GRASS):
	coords = _coords
	type = _type
