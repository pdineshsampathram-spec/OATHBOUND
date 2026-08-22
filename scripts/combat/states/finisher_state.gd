class_name FinisherState
extends State

## FinisherState — Cinematic execution strike performed on vulnerable or critical-health foes.

var _timer: float = 0.0
var _target: Node = null
var _damage_dealt: bool = false

func enter(msg: Dictionary = {}) -> void:
	_timer = 0.0
	_damage_dealt = false
	_target = msg.get("target", null)

	if character:
		if _target and _target is Node3D:
			# Face the victim directly
			var dir_to_target: Vector3 = (_target.global_position - character.global_position).normalized()
			dir_to_target.y = 0
			if dir_to_target.length_squared() > 0.01:
				character.visual_pivot.look_at(character.visual_pivot.global_position + dir_to_target, Vector3.UP)

		character.play_finisher_animation()
		if character.stamina_component:
			character.stamina_component.can_regenerate = false

func exit() -> void:
	if character and character.stamina_component:
		character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	# Impact point at 0.6s
	if _timer >= 0.6 and not _damage_dealt:
		_damage_dealt = true
		if _target and is_instance_valid(_target):
			var dmg: float = character.character_data.finisher_damage
			if _target.has_method("take_damage"):
				_target.take_damage(dmg, character)
			elif _target.has_node("HealthComponent"):
				var hc: HealthComponent = _target.get_node("HealthComponent") as HealthComponent
				if hc:
					hc.take_damage(dmg, character)

	character.apply_gravity(delta)
	character.apply_deceleration(delta, 16.0)
	character.move_and_slide()

	if _timer >= character.character_data.finisher_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
