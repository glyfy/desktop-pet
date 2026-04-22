class_name PetBehaviors
extends RefCounted

const STATE_SLEEP := &"sleep"
const STATE_WANDER := &"wander"
const STATE_ATTACK_MOUSE := &"attack_mouse"
const STATE_FIGURE_EIGHT := &"figure_eight"

const ATTACK_PHASE_APPROACH := &"approach"
const ATTACK_PHASE_WINDUP := &"windup"
const ATTACK_PHASE_TACKLE := &"tackle"
const ATTACK_PHASE_RECOVER := &"recover"

const WANDER_SPEED := 120.0
const WANDER_MIN_DISTANCE := 90.0
const WANDER_MAX_DISTANCE := 260.0
const WANDER_ARRIVAL_DISTANCE := 10.0
const WANDER_IDLE_MIN := 0.3
const WANDER_IDLE_MAX := 1.1

const ATTACK_APPROACH_SPEED := 200.0
const ATTACK_TRIGGER_DISTANCE := 100.0
const ATTACK_WINDUP_TIME := 0.28
const ATTACK_TACKLE_SPEED := 680.0
const ATTACK_TACKLE_DISTANCE := 220.0
const ATTACK_RECOVERY_TIME := 0.8
const ATTACK_STOP_DISTANCE := 10.0

const FIGURE_EIGHT_HORIZONTAL_RADIUS := 160.0
const FIGURE_EIGHT_VERTICAL_RADIUS := 160.0
const FIGURE_EIGHT_SPEED := 5

var window_helper
var visuals
var rng := RandomNumberGenerator.new()

var drag_cooldown := 0.8
var behavior_weights := {}
var behavior_durations := {}

var drag_pause_timer := 0.0
var current_behavior: StringName = STATE_WANDER
var behavior_timer := 0.0

var wander_target := Vector2.ZERO
var wander_idle_timer := 0.0

var attack_phase: StringName = ATTACK_PHASE_APPROACH
var attack_phase_timer := 0.0
var tackle_direction := Vector2.RIGHT
var tackle_target := Vector2.ZERO

var figure_eight_anchor := Vector2.ZERO
var figure_eight_elapsed := 0.0


func setup(helper, pet_visuals, config: Dictionary) -> void:
	window_helper = helper
	visuals = pet_visuals
	rng.randomize()
	drag_cooldown = config["drag_cooldown"]
	behavior_weights = config["weights"]
	behavior_durations = config["durations"]


func start() -> void:
	window_helper.move_to_corner()
	_enter_behavior(_choose_next_behavior(StringName()))


func on_drag_started() -> void:
	drag_pause_timer = drag_cooldown
	_cancel_attack()


func process(delta: float) -> void:
	if drag_pause_timer > 0.0:
		drag_pause_timer = maxf(drag_pause_timer - delta, 0.0)
		return

	behavior_timer = maxf(behavior_timer - delta, 0.0)
	if behavior_timer <= 0.0:
		_enter_behavior(_choose_next_behavior(current_behavior))

	match current_behavior:
		STATE_SLEEP:
			_process_sleep(delta)
		STATE_WANDER:
			_process_wander(delta)
		STATE_ATTACK_MOUSE:
			_process_attack_mouse(delta)
		STATE_FIGURE_EIGHT:
			_process_figure_eight(delta)


func _process_sleep(_delta: float) -> void:
	pass


func _process_wander(delta: float) -> void:
	var current_position := Vector2(window_helper.window.position)

	if wander_idle_timer > 0.0:
		wander_idle_timer = maxf(wander_idle_timer - delta, 0.0)
		return

	var to_target := wander_target - current_position
	if to_target.length() <= WANDER_ARRIVAL_DISTANCE:
		wander_idle_timer = rng.randf_range(WANDER_IDLE_MIN, WANDER_IDLE_MAX)
		wander_target = _random_wander_target(current_position)
		return

	var step := minf(WANDER_SPEED * delta, to_target.length())
	var next_position := current_position + to_target.normalized() * step
	window_helper.window.position = window_helper.clamp_window_position(Vector2i(next_position.round()))


func _process_attack_mouse(delta: float) -> void:
	var current_position := Vector2(window_helper.window.position)
	var mouse_position := Vector2(DisplayServer.mouse_get_position())

	match attack_phase:
		ATTACK_PHASE_APPROACH:
			var target_position: Vector2 = window_helper.mouse_target_position(mouse_position)
			var to_target: Vector2 = target_position - current_position
			if to_target.length() <= ATTACK_TRIGGER_DISTANCE:
				_begin_attack(mouse_position)
				return

			var step := minf(ATTACK_APPROACH_SPEED * delta, to_target.length())
			var next_position: Vector2 = current_position + to_target.normalized() * step
			window_helper.window.position = window_helper.clamp_window_position(Vector2i(next_position.round()))
		ATTACK_PHASE_WINDUP:
			attack_phase_timer = maxf(attack_phase_timer - delta, 0.0)
			var live_direction: Vector2 = mouse_position - window_helper.window_center()
			if not live_direction.is_zero_approx():
				tackle_direction = live_direction.normalized()
			if attack_phase_timer <= 0.0:
				var tackle_destination := current_position + tackle_direction * ATTACK_TACKLE_DISTANCE
				tackle_target = Vector2(window_helper.clamp_window_position(Vector2i(tackle_destination.round())))
				attack_phase = ATTACK_PHASE_TACKLE
		ATTACK_PHASE_TACKLE:
			var to_target := tackle_target - current_position
			if to_target.length() <= ATTACK_STOP_DISTANCE:
				attack_phase = ATTACK_PHASE_RECOVER
				attack_phase_timer = ATTACK_RECOVERY_TIME
				return

			var step := minf(ATTACK_TACKLE_SPEED * delta, to_target.length())
			var next_position := current_position + to_target.normalized() * step
			window_helper.window.position = window_helper.clamp_window_position(Vector2i(next_position.round()))
			window_helper.drag_mouse_with_pet(tackle_direction)
		ATTACK_PHASE_RECOVER:
			attack_phase_timer = maxf(attack_phase_timer - delta, 0.0)
			if attack_phase_timer <= 0.0:
				attack_phase = ATTACK_PHASE_APPROACH


func _process_figure_eight(delta: float) -> void:
	figure_eight_elapsed += delta * FIGURE_EIGHT_SPEED

	var sin_t := sin(figure_eight_elapsed)
	var cos_t := cos(figure_eight_elapsed)
	var offset := Vector2(
		sin_t * FIGURE_EIGHT_HORIZONTAL_RADIUS,
		sin_t * cos_t * FIGURE_EIGHT_VERTICAL_RADIUS
	)
	var next_position := figure_eight_anchor + offset
	window_helper.window.position = window_helper.clamp_window_position(Vector2i(next_position.round()))


func _enter_behavior(next_behavior: StringName) -> void:
	current_behavior = next_behavior
	behavior_timer = _duration_for_behavior(current_behavior)
	visuals.apply_behavior_visuals(current_behavior)
	visuals.refresh_window_layout()

	match current_behavior:
		STATE_SLEEP:
			_cancel_attack()
		STATE_WANDER:
			_cancel_attack()
			wander_idle_timer = 0.0
			wander_target = _random_wander_target(Vector2(window_helper.window.position))
		STATE_ATTACK_MOUSE:
			attack_phase = ATTACK_PHASE_APPROACH
			attack_phase_timer = 0.0
			tackle_direction = Vector2.RIGHT
			tackle_target = Vector2(window_helper.window.position)
		STATE_FIGURE_EIGHT:
			_cancel_attack()
			figure_eight_elapsed = 0.0
			figure_eight_anchor = window_helper.figure_eight_anchor_from_current_position(
				FIGURE_EIGHT_HORIZONTAL_RADIUS,
				FIGURE_EIGHT_VERTICAL_RADIUS
			)


func _choose_next_behavior(previous_behavior: StringName) -> StringName:
	var behaviors := [STATE_SLEEP, STATE_WANDER, STATE_ATTACK_MOUSE, STATE_FIGURE_EIGHT]
	var total_weight := 0

	for behavior in behaviors:
		if behavior == previous_behavior:
			continue
		total_weight += int(behavior_weights.get(behavior, 0))

	if total_weight <= 0:
		return STATE_WANDER

	var roll := rng.randi_range(1, total_weight)
	var running_total := 0
	for behavior in behaviors:
		if behavior == previous_behavior:
			continue
		running_total += int(behavior_weights.get(behavior, 0))
		if roll <= running_total:
			return behavior

	return STATE_WANDER


func _duration_for_behavior(behavior: StringName) -> float:
	return _random_duration(behavior_durations.get(behavior, Vector2(5.0, 8.0)))


func _random_duration(duration_range: Vector2) -> float:
	return rng.randf_range(duration_range.x, duration_range.y)


func _begin_attack(mouse_position: Vector2) -> void:
	var direction: Vector2 = mouse_position - window_helper.window_center()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))

	tackle_direction = direction.normalized()
	attack_phase = ATTACK_PHASE_WINDUP
	attack_phase_timer = ATTACK_WINDUP_TIME


func _cancel_attack() -> void:
	attack_phase = ATTACK_PHASE_APPROACH
	attack_phase_timer = 0.0


func _random_wander_target(origin: Vector2) -> Vector2:
	var min_position: Vector2 = window_helper.minimum_position()
	var max_position: Vector2 = window_helper.maximum_position()

	for _attempt in 8:
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(WANDER_MIN_DISTANCE, WANDER_MAX_DISTANCE)
		var candidate := origin + Vector2.RIGHT.rotated(angle) * distance
		candidate.x = clampf(candidate.x, min_position.x, max_position.x)
		candidate.y = clampf(candidate.y, min_position.y, max_position.y)

		if candidate.distance_to(origin) >= WANDER_ARRIVAL_DISTANCE:
			return candidate

	return origin
