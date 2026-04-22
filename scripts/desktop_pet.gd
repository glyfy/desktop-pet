extends Node2D

const PetBehaviorsScript = preload("res://scripts/pet_behaviors.gd")
const PetVisualsScript = preload("res://scripts/pet_visuals.gd")
const PetWindowScript = preload("res://scripts/pet_window.gd")

const WINDOW_PADDING := 24
const SCREEN_MARGIN := 32
const PET_SCALE := 4.0
const DRAG_COOLDOWN := 0.8

@export_group("Behavior Weights")
@export_range(0, 100, 1) var sleep_weight := 0
@export_range(0, 100, 1) var wander_weight := 100
@export_range(0, 100, 1) var attack_weight := 0
@export_range(0, 100, 1) var figure_eight_weight := 0

@export_group("Behavior Durations")
@export var sleep_duration_range := Vector2(5.0, 11.0)
@export var wander_duration_range := Vector2(4.0, 8.0)
@export var attack_duration_range := Vector2(4.0, 7.0)
@export var figure_eight_duration_range := Vector2(5.0, 8.0)

@export_group("Behavior Art")
@export var sleep_texture: Texture2D
@export var wander_texture: Texture2D
@export var attack_texture: Texture2D
@export var figure_eight_texture: Texture2D

@onready var pet_sprite: Sprite2D = $PetSprite

var window_helper
var visuals
var behaviors


func _ready() -> void:
	window_helper = PetWindowScript.new()
	window_helper.setup(get_window(), SCREEN_MARGIN)
	window_helper.configure()

	visuals = PetVisualsScript.new()
	visuals.setup(
		pet_sprite,
		window_helper,
		WINDOW_PADDING,
		PET_SCALE,
		{
			&"sleep": sleep_texture,
			&"wander": wander_texture,
			&"attack_mouse": attack_texture,
			&"figure_eight": figure_eight_texture,
		}
	)

	behaviors = PetBehaviorsScript.new()
	behaviors.setup(
		window_helper,
		visuals,
		{
			"drag_cooldown": DRAG_COOLDOWN,
			"weights": {
				&"sleep": sleep_weight,
				&"wander": wander_weight,
				&"attack_mouse": attack_weight,
				&"figure_eight": figure_eight_weight,
			},
			"durations": {
				&"sleep": sleep_duration_range,
				&"wander": wander_duration_range,
				&"attack_mouse": attack_duration_range,
				&"figure_eight": figure_eight_duration_range,
			},
		}
	)
	behaviors.start()
	DisplayServer.window_move_to_foreground()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		get_tree().quit()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		DisplayServer.window_start_drag()
		behaviors.on_drag_started()


func _process(delta: float) -> void:
	behaviors.process(delta)
