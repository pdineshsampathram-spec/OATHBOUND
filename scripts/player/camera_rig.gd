class_name CameraRig
extends Node3D

## CameraRig — Cinematic Third-Person Combat Camera with Trauma Shake, Dynamic FOV, and Adaptive Combat Framing.

@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = deg_to_rad(-70.0)
@export var max_pitch: float = deg_to_rad(60.0)
@export var default_distance: float = 4.0
@export var combat_distance: float = 3.2
@export var target_offset: Vector3 = Vector3(0.0, 1.4, 0.0)

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _pitch: float = -0.15
var _yaw: float = 0.0
var is_mouse_captured: bool = false
var is_active_local: bool = true

# Cinematic Polish & Trauma
var _trauma: float = 0.0
var _trauma_decay: float = 3.5
var _target_distance: float = 4.0
var _current_distance: float = 4.0
var _punch_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	top_level = true
	_target_distance = default_distance
	_current_distance = default_distance

	if spring_arm:
		spring_arm.spring_length = default_distance
		var parent_node: Node = get_parent()
		if parent_node is CollisionObject3D:
			spring_arm.add_excluded_object(parent_node.get_rid())

func setup_authority(is_local: bool) -> void:
	is_active_local = is_local
	set_process(is_local)
	set_process_unhandled_input(is_local)
	
	if camera:
		camera.current = is_local

	if is_local:
		_capture_mouse()
	else:
		_release_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active_local:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_mouse_capture()

	if is_mouse_captured and event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, min_pitch, max_pitch)

func _process(delta: float) -> void:
	if not is_active_local:
		return

	var target_node: Node3D = get_parent() as Node3D
	if target_node:
		# Check if parent is in combat stance to adapt distance
		var p_ctrl: PlayerController = target_node as PlayerController
		if p_ctrl and p_ctrl.is_combat_stance:
			_target_distance = combat_distance
		else:
			_target_distance = default_distance

		_current_distance = lerp(_current_distance, _target_distance, 6.0 * delta)
		if spring_arm:
			spring_arm.spring_length = _current_distance

		# Smooth trauma & punch decay
		if _trauma > 0.0:
			_trauma = max(0.0, _trauma - _trauma_decay * delta)
			var shake: float = _trauma * _trauma * 0.08
			_punch_offset = Vector3(
				randf_range(-shake, shake),
				randf_range(-shake, shake),
				randf_range(-shake, shake)
			)
		else:
			_punch_offset = _punch_offset.lerp(Vector3.ZERO, 12.0 * delta)

		global_position = target_node.global_position + target_offset + _punch_offset

	# Update yaw & pitch
	rotation.y = _yaw
	if spring_arm:
		spring_arm.rotation.x = _pitch

func apply_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func trigger_impact_punch(intensity: float = 0.05) -> void:
	apply_trauma(intensity * 3.0)

func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	is_mouse_captured = true

func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_mouse_captured = false

func _toggle_mouse_capture() -> void:
	if is_mouse_captured:
		_release_mouse()
	else:
		_capture_mouse()

func get_camera_forward() -> Vector3:
	if camera:
		return -camera.global_transform.basis.z
	return Vector3.FORWARD

func get_camera_right() -> Vector3:
	if camera:
		return camera.global_transform.basis.x
	return Vector3.RIGHT
