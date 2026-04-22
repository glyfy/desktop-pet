class_name PetVisuals
extends RefCounted

var sprite: Sprite2D
var window_helper
var window_padding := 24
var pet_scale := 4.0
var texture_slots := {}
var placeholder_texture: Texture2D


func setup(target_sprite: Sprite2D, helper, padding: int, scale_value: float, textures: Dictionary) -> void:
	sprite = target_sprite
	window_helper = helper
	window_padding = padding
	pet_scale = scale_value
	texture_slots = textures
	placeholder_texture = _build_placeholder_texture()


func apply_behavior_visuals(behavior: StringName) -> void:
	sprite.texture = texture_slots.get(behavior, placeholder_texture)
	if sprite.texture == null:
		sprite.texture = placeholder_texture
	sprite.scale = Vector2.ONE * pet_scale


func refresh_window_layout() -> void:
	if sprite.texture == null:
		return

	var sprite_size := Vector2i(sprite.texture.get_size() * sprite.scale)
	var window_size := sprite_size + Vector2i(window_padding * 2, window_padding * 2)
	window_helper.window.size = window_size
	sprite.position = Vector2(window_size) * 0.5
	window_helper.window.position = window_helper.clamp_window_position(window_helper.window.position)
	_apply_mouse_passthrough()


func _apply_mouse_passthrough() -> void:
	if sprite.texture == null:
		return

	var sprite_size := sprite.texture.get_size() * sprite.scale
	var top_left := sprite.position - (sprite_size * 0.5)
	var bottom_right := top_left + sprite_size

	window_helper.window.mouse_passthrough_polygon = PackedVector2Array([
		top_left,
		Vector2(bottom_right.x, top_left.y),
		bottom_right,
		Vector2(top_left.x, bottom_right.y),
	])


func _build_placeholder_texture() -> Texture2D:
	var palette := {
		".": Color(0, 0, 0, 0),
		"A": Color("5ad2a0"),
		"B": Color("49b889"),
		"C": Color("173042"),
		"D": Color("ffffff"),
		"E": Color("f6a7b8"),
	}
	var rows := [
		"........................",
		".........BB....BB.......",
		"........BBBB..BBBB......",
		"........BBBBAABBBB......",
		".......AAAAAAAAAAAA.....",
		"......AAAAAAAAAAAAAA....",
		".....AAAAAAAAAAAAAAAA...",
		"....AAAAAAAAAAAAAAAAAA..",
		"...AAAAAAAAAAAAAAAAAAAA.",
		"...AAAAAADDAAAADDDAAAA..",
		"..AAAAAAADDDAAADDDAAAAA.",
		"..AAAAAAACDDAAACDCAAAAA.",
		"..AAAAAAACDDAAACDCAAAAA.",
		"..AAAAAAADDDAAADDDAAAAA.",
		"..AAAAAAAADDAAADDAAAAAA.",
		"..AAAAAAAAAAAAAAAAAAAAA.",
		"..AAAAAAAAAAAAAAAAAAAAA.",
		"..AAAAEAAAAAAAAAAAAEAAA.",
		"...AAAAAAAAAAAAAAAAAAA..",
		"...AAAAAAAAACCAAAAAAA...",
		"....AAAAAAAAAAAAAAAAA...",
		".....AAAAAAAAAAAAAAA....",
		"......AAAAAAAAAAAAAA....",
		".......AAAAAAAAAAAA.....",
		"........AAAAAAAAAA......",
		".........AAAAAA.........",
		"........CCCCCCCC........",
		"........................",
	]

	var image := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)

	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			image.set_pixel(x, y, palette[row[x]])

	return ImageTexture.create_from_image(image)
