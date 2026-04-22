class_name PetWindow
extends RefCounted

var window: Window
var screen_margin := 32


func setup(target_window: Window, margin: int) -> void:
	window = target_window
	screen_margin = margin


func configure() -> void:
	window.borderless = true
	window.always_on_top = true
	window.unresizable = true
	window.transparent = true
	window.transparent_bg = true


func move_to_corner() -> void:
	var screen_rect := DisplayServer.screen_get_usable_rect()
	window.position = screen_rect.position + screen_rect.size - window.size - Vector2i(screen_margin, screen_margin)


func minimum_position() -> Vector2:
	var screen_rect := DisplayServer.screen_get_usable_rect()
	return Vector2(screen_rect.position) + Vector2(screen_margin, screen_margin)


func maximum_position() -> Vector2:
	var screen_rect := DisplayServer.screen_get_usable_rect()
	return Vector2(screen_rect.position + screen_rect.size - window.size - Vector2i(screen_margin, screen_margin))


func clamp_window_position(position: Vector2i) -> Vector2i:
	var min_position := minimum_position()
	var max_position := maximum_position()

	return Vector2i(
		clampi(position.x, int(min_position.x), int(max_position.x)),
		clampi(position.y, int(min_position.y), int(max_position.y))
	)


func window_center() -> Vector2:
	return Vector2(window.position) + (Vector2(window.size) * 0.5)


func mouse_target_position(mouse_position: Vector2) -> Vector2:
	return mouse_position - (Vector2(window.size) * 0.5)


func drag_mouse_with_pet(direction: Vector2) -> void:
	var carry_offset := Vector2(window.size) * 0.35
	var screen_target := window_center() + direction * carry_offset.x
	var local_target := screen_target - Vector2(window.position)
	Input.warp_mouse(local_target)


func figure_eight_anchor_from_current_position(horizontal_radius: float, vertical_radius: float) -> Vector2:
	var current_position := Vector2(window.position)
	var min_anchor := minimum_position() + Vector2(horizontal_radius, vertical_radius)
	var max_anchor := maximum_position() - Vector2(horizontal_radius, vertical_radius)

	return Vector2(
		clampf(current_position.x, min_anchor.x, max_anchor.x),
		clampf(current_position.y, min_anchor.y, max_anchor.y)
	)
