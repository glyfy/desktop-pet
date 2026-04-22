extends Control

const STATE_SLEEP := &"sleep"
const STATE_WANDER := &"wander"
const STATE_ATTACK_MOUSE := &"attack_mouse"
const STATE_FIGURE_EIGHT := &"figure_eight"

@onready var pet_window: Window = $PetWindow
@onready var pet = $PetWindow/Pet
@onready var activate_button: Button = %ActivateButton
@onready var deactivate_button: Button = %DeactivateButton
@onready var reset_button: Button = %ResetButton
@onready var status_value: Label = %StatusValue
@onready var sleep_slider: HSlider = %SleepSlider
@onready var wander_slider: HSlider = %WanderSlider
@onready var attack_slider: HSlider = %AttackSlider
@onready var figure_eight_slider: HSlider = %FigureEightSlider
@onready var sleep_value: Label = %SleepValue
@onready var wander_value: Label = %WanderValue
@onready var attack_value: Label = %AttackValue
@onready var figure_eight_value: Label = %FigureEightValue
@onready var total_value: Label = %TotalValue

var slider_map := {}
var value_labels := {}


func _ready() -> void:
	get_tree().root.gui_embed_subwindows = false
	get_window().title = "Birthday Present"
	pet_window.hide()

	slider_map = {
		STATE_SLEEP: sleep_slider,
		STATE_WANDER: wander_slider,
		STATE_ATTACK_MOUSE: attack_slider,
		STATE_FIGURE_EIGHT: figure_eight_slider,
	}
	value_labels = {
		STATE_SLEEP: sleep_value,
		STATE_WANDER: wander_value,
		STATE_ATTACK_MOUSE: attack_value,
		STATE_FIGURE_EIGHT: figure_eight_value,
	}

	activate_button.pressed.connect(_on_activate_pressed)
	deactivate_button.pressed.connect(_on_deactivate_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	for state in slider_map.keys():
		var slider: HSlider = slider_map[state]
		slider.value_changed.connect(_on_slider_changed.bind(state))

	_sync_ui_from_pet()
	_apply_weights_to_pet()
	_update_status()


func _on_activate_pressed() -> void:
	pet_window.show()
	DisplayServer.window_move_to_foreground(pet_window.get_window_id())
	pet.activate()
	_update_status()


func _on_deactivate_pressed() -> void:
	pet.deactivate()
	pet_window.hide()
	_update_status()


func _on_reset_pressed() -> void:
	sleep_slider.set_value_no_signal(25.0)
	wander_slider.set_value_no_signal(25.0)
	attack_slider.set_value_no_signal(25.0)
	figure_eight_slider.set_value_no_signal(25.0)
	_refresh_weight_labels()
	_apply_weights_to_pet()


func _on_slider_changed(_value: float, _state: StringName) -> void:
	_refresh_weight_labels()
	_apply_weights_to_pet()


func _sync_ui_from_pet() -> void:
	var weights: Dictionary = pet.get_behavior_weights()
	sleep_slider.set_value_no_signal(float(weights.get(STATE_SLEEP, 0)))
	wander_slider.set_value_no_signal(float(weights.get(STATE_WANDER, 0)))
	attack_slider.set_value_no_signal(float(weights.get(STATE_ATTACK_MOUSE, 0)))
	figure_eight_slider.set_value_no_signal(float(weights.get(STATE_FIGURE_EIGHT, 0)))
	_refresh_weight_labels()


func _refresh_weight_labels() -> void:
	var total_weight := 0
	for state in slider_map.keys():
		var slider: HSlider = slider_map[state]
		total_weight += int(slider.value)

	for state in slider_map.keys():
		var slider: HSlider = slider_map[state]
		var label: Label = value_labels[state]
		var percentage := 0
		if total_weight > 0:
			percentage = int(round((float(slider.value) / float(total_weight)) * 100.0))
		label.text = "%d%%" % percentage

	total_value.text = "100%" if total_weight > 0 else "0%"


func _apply_weights_to_pet() -> void:
	pet.set_behavior_weights({
		STATE_SLEEP: int(sleep_slider.value),
		STATE_WANDER: int(wander_slider.value),
		STATE_ATTACK_MOUSE: int(attack_slider.value),
		STATE_FIGURE_EIGHT: int(figure_eight_slider.value),
	})


func _update_status() -> void:
	var active: bool = pet.is_active()
	status_value.text = "ACTIVE" if active else "INACTIVE"
	status_value.add_theme_color_override(
		"font_color",
		Color("1f6b3a") if active else Color("a12626")
	)
	activate_button.disabled = active
	deactivate_button.disabled = not active
