class_name ChargedAttackState
extends State

## ChargedAttackState — Hold to charge power; release to unleash high damage and potential knockdown.

enum Phase { CHARGING, RELEASING }

var _phase: Phase = Phase.CHARGING
var _charge_timer: float = 0.0
var _release_timer: float = 0.0
var _hitbox_activated: bool = false
var _charge_ratio: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_phase = Phase.CHARGING
	_charge_timer = 0.0
	_release_timer = 0.0
	_hitbox_activated = false
	_charge_ratio = 0.0

	if character:
		if character.stamina_component:
			character.stamina_component.consume(character.character_data.charged_attack_stamina_cost)
			character.stamina_component.can_regenerate = false
		character.play_charge_buildup_animation()

func exit() -> void:
	if character:
		character.set_sword_hitbox_active(false)
		character.stop_charge_visual()
		character.current_attack_type = PlayerController.AttackType.LIGHT
		if character.stamina_component:
			character.stamina_component.can_regenerate = true

func physics_process_state(delta: float) -> void:
	if not character:
		return

	if character.is_dead:
		transition_to("DeadState")
		return

	match _phase:
		Phase.CHARGING:
			_charge_timer += delta
			var max_c: float = character.character_data.charged_attack_max_charge
			_charge_ratio = clampf(_charge_timer / max_c, 0.0, 1.0)

			# Slower movement or fixed during charge
			character.apply_gravity(delta)
			character.apply_deceleration(delta, 16.0)
			character.move_and_slide()

			# Auto-release if max charge reached or button released after min charge
			var min_c: float = character.character_data.charged_attack_min_charge
			var release_requested: bool = not character.is_attack_held()
			if _charge_timer >= max_c or (release_requested and _charge_timer >= min_c):
				_start_release()

		Phase.RELEASING:
			_release_timer += delta

			# Hitbox active between 0.15 and 0.4s
			if _release_timer >= 0.15 and _release_timer <= 0.4:
				if not _hitbox_activated:
					character.set_sword_hitbox_active(true)
					_hitbox_activated = true
			else:
				if _hitbox_activated and _release_timer > 0.4:
					character.set_sword_hitbox_active(false)

			character.apply_gravity(delta)
			character.apply_deceleration(delta, 6.0)
			character.move_and_slide()

			if _release_timer >= 0.65:
				var move_input: Vector2 = character.get_movement_input()
				if move_input.length_squared() > 0.01:
					transition_to("MovementState")
				else:
					transition_to("IdleState")

func _start_release() -> void:
	_phase = Phase.RELEASING
	_release_timer = 0.0
	_hitbox_activated = false

	if character:
		var is_knockdown: bool = (_charge_ratio >= character.character_data.charged_attack_knockdown_threshold)
		character.current_attack_type = PlayerController.AttackType.CHARGED_KNOCKDOWN if is_knockdown else PlayerController.AttackType.CHARGED
		character.current_charge_ratio = _charge_ratio

		# Strong forward lunge on release
		var facing_dir: Vector3 = -character.visual_pivot.global_transform.basis.z.normalized()
		var lunge_pwr: float = 3.5 * (1.0 + _charge_ratio)
		character.velocity.x = facing_dir.x * lunge_pwr
		character.velocity.z = facing_dir.z * lunge_pwr

		character.play_charged_attack_release_animation(_charge_ratio)
