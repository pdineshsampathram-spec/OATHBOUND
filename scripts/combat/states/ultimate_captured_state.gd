class_name UltimateCapturedState
extends State

## UltimateCapturedState — Dedicated battlefield subjugation state.
## Freezes target enemy in terror/stagger during OATHBOUND ASCENDANCE.
## Disables all movement, AI decisions, navigation, attacks, dodges, and blocks.

var _knight_ref: Node3D = null

func enter(msg: Dictionary = {}) -> void:
	if not character:
		return

	character.velocity = Vector3.ZERO
	character.is_blocking = false
	character.block_active_duration = 999.0
	
	if character.stamina_component:
		character.stamina_component.can_regenerate = false

	# Suspend AI combat driver
	if character.ai_controller and character.ai_controller.has_method("set_active"):
		character.ai_controller.set_active(false)

	# Get Knight reference to face the executioner
	if msg.has("knight") and is_instance_valid(msg["knight"]):
		_knight_ref = msg["knight"]
		var to_knight: Vector3 = (_knight_ref.global_position - character.global_position)
		to_knight.y = 0
		if to_knight.length_squared() > 0.01:
			character.visual_pivot.look_at(character.global_position - to_knight.normalized(), Vector3.UP)

	# Play terror / stagger reaction
	character._play_skeletal_animation("stagger", 0.08)

func physics_process_state(_delta: float) -> void:
	if not character or character.is_dead:
		return

	# Keep enemy rooted in place
	character.velocity = Vector3.ZERO
	character.move_and_slide()

	# Keep facing Knight in helpless dread
	if is_instance_valid(_knight_ref):
		var to_knight: Vector3 = (_knight_ref.global_position - character.global_position)
		to_knight.y = 0
		if to_knight.length_squared() > 0.01:
			var target_rot_y: float = atan2(-to_knight.x, -to_knight.z)
			character.visual_pivot.rotation.y = lerp_angle(character.visual_pivot.rotation.y, target_rot_y, 0.1)

func exit() -> void:
	if character:
		if character.ai_controller and character.ai_controller.has_method("set_active"):
			character.ai_controller.set_active(true)
		if character.stamina_component:
			character.stamina_component.can_regenerate = true
