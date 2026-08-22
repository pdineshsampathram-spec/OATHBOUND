class_name CombatCamera
extends Camera3D

## CombatCamera — Handles third-person combat framing with dynamic trauma-based screen shake,
## parry deflection jolts, finisher camera orbits, and death pullbacks.

@export var target: Node3D = null
@export var follow_speed: float = 12.0
@export var rotation_speed: float = 0.003
@export var default_distance: float = 3.8
@export var default_height: float = 1.9

var _trauma: float = 0.0
var _trauma_decay: float = 3.5
var _noise_y: float = 0.0
var _base_transform: Transform3D
var _orbit_angle: float = 0.0
var _is_finisher_mode: bool = false
var _finisher_timer: float = 0.0

func _ready() -> void:
	top_level = true
	_base_transform = transform

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = max(0.0, _trauma - _trauma_decay * delta)
		_apply_shake(delta)

	if _is_finisher_mode:
		_process_finisher_cam(delta)
	elif target and is_instance_valid(target):
		_follow_target(delta)

func _follow_target(delta: float) -> void:
	var target_pos: Vector3 = target.global_position + Vector3(0, default_height, 0)
	var forward: Vector3 = -target.global_transform.basis.z
	var desired_pos: Vector3 = target_pos - forward * default_distance

	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	look_at(target_pos, Vector3.UP)

func add_trauma(amount: float) -> void:
	_trauma = clamp(_trauma + amount, 0.0, 1.0)

func trigger_hit_shake(is_heavy: bool = false) -> void:
	add_trauma(0.4 if is_heavy else 0.2)

func trigger_parry_jolt() -> void:
	add_trauma(0.35)

func trigger_finisher_cam(duration: float = 1.2) -> void:
	_is_finisher_mode = true
	_finisher_timer = duration
	Engine.time_scale = 0.4 # Cinematic slow-motion

func _process_finisher_cam(delta: float) -> void:
	_finisher_timer -= delta / Engine.time_scale
	if _finisher_timer <= 0.0:
		_is_finisher_mode = false
		Engine.time_scale = 1.0
		return

	if target and is_instance_valid(target):
		_orbit_angle += 1.5 * delta
		var offset: Vector3 = Vector3(sin(_orbit_angle), 0.4, cos(_orbit_angle)) * 2.5
		global_position = target.global_position + Vector3(0, 1.4, 0) + offset
		look_at(target.global_position + Vector3(0, 1.2, 0), Vector3.UP)

func _apply_shake(delta: float) -> void:
	_noise_y += delta * 45.0
	var shake_power: float = _trauma * _trauma
	var offset_x: float = sin(_noise_y * 1.3) * 0.08 * shake_power
	var offset_y: float = cos(_noise_y * 1.7) * 0.06 * shake_power
	var offset_z: float = sin(_noise_y * 0.9) * 0.04 * shake_power
	h_offset = offset_x
	v_offset = offset_y
