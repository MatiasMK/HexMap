extends Camera2D

@export var speed: float = 400.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.2
@export var max_zoom: float = 5.0


func _process(delta: float):
	var dir = Vector2()
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	position += dir.normalized() * speed * delta

	if Input.is_key_pressed(KEY_E):
		zoom += Vector2(zoom_step * delta * 10, zoom_step * delta * 10)
	if Input.is_key_pressed(KEY_Q):
		zoom -= Vector2(zoom_step * delta * 10, zoom_step * delta * 10)
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
