class_name CameraRig
extends Node3D

## CameraRig — Third-person orbit camera with SpringArm3D collision and mouse look.

@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = deg_to_rad(-70.0)
@export var max_pitch: float = deg_to_rad(60.0)
@export var default_distance: float = 4.0
@export var target_offset: Vector3 = Vector3(0.0, 1.4, 0.0)

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _pitch: float = -0.15 # Slight downward angle initially
var _yaw: float = 0.0
var is_mouse_captured: bool = true

func _ready() -> void:
	top_level = true # Keep camera rig world-oriented so player rotations don't spin camera
	_capture_mouse()
	
	if spring_arm:
		spring_arm.spring_length = default_distance
		spring_arm.add_excluded_object(get_parent().get_rid())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_mouse_capture()

	if is_mouse_captured and event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, min_pitch, max_pitch)

func _process(_delta: float) -> void:
	var target_node: Node3D = get_parent() as Node3D
	if target_node:
		global_position = target_node.global_position + target_offset

	# Update yaw on base rig, pitch on spring arm
	rotation.y = _yaw
	if spring_arm:
		spring_arm.rotation.x = _pitch

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
	return -camera.global_transform.basis.z

func get_camera_right() -> Vector3:
	return camera.global_transform.basis.x
