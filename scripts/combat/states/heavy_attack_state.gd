class_name HeavyAttackState
extends State

## HeavyAttackState — Slower, high-damage attack that deals heavy poise damage and can break opponent guard.

var _timer: float = 0.0
var _hitbox_activated: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	_hitbox_activated = false

	if character:
		if character.stamina_component:
			character.stamina_component.consume(character.character_data.heavy_attack_stamina_cost)
			character.stamina_component.can_regenerate = false

		# Forward impulse
		var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
		character.velocity.x = facing_dir.x * character.character_data.heavy_attack_forward_impulse
		character.velocity.z = facing_dir.z * character.character_data.heavy_attack_forward_impulse

		character.current_attack_type = PlayerController.AttackType.HEAVY
		character.play_heavy_attack_animation()

func exit() -> void:
	if character:
		character.set_sword_hitbox_active(false)
		character.current_attack_type = PlayerController.AttackType.LIGHT
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	_timer += delta

	var start_t: float = character.character_data.heavy_attack_hitbox_start
	var end_t: float = character.character_data.heavy_attack_hitbox_end

	if _timer >= start_t and _timer <= end_t:
		if not _hitbox_activated:
			character.set_sword_hitbox_active(true)
			_hitbox_activated = true
	else:
		if _hitbox_activated and _timer > end_t:
			character.set_sword_hitbox_active(false)

	character.apply_gravity(delta)
	character.apply_deceleration(delta, 8.0)
	character.move_and_slide()

	if _timer >= character.character_data.heavy_attack_duration:
		var move_input: Vector2 = character.get_movement_input()
		if move_input.length_squared() > 0.01:
			transition_to("MovementState")
		else:
			transition_to("IdleState")
