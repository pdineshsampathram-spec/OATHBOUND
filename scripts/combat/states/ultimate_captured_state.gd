class_name UltimateCapturedState
extends State

## UltimateCapturedState — Art-First Cinematic Rebuild.
## 5-stage escalating fear/subjugation system during CATACLYSM OF THE SEVENTH OATH.
##
## Stage 1 (0–8s):    INTERRUPT — Initial stagger, confusion, forced to face Knight
## Stage 2 (8–18s):   AWARENESS — Enemy recognizes power, begins involuntary step back
## Stage 3 (18–28s):  STASIS — Frozen in awe/dread, weight of energy pins them
## Stage 4 (28–33.5s):TERROR — Visible shaking, recoiling from compression, head turns away
## Stage 5 (33.5s+):  IMPACT — Shockwave hits, ragdoll/dissolve begins
##
## Director drives these stages via set_fear_stage() and the fear_intensity uniform.

var _knight_ref: Node3D = null
var _fear_stage: int = 1
var _fear_intensity: float = 0.0  # 0.0–1.0, driven by director
var _tremble_time: float = 0.0
var _initial_position: Vector3 = Vector3.ZERO
var _original_scale: Vector3 = Vector3.ONE

func enter(msg: Dictionary = {}) -> void:
	if not character:
		return

	character.velocity = Vector3.ZERO
	character.is_blocking = false
	character.block_active_duration = 999.0
	_initial_position = character.global_position
	_fear_stage = 1
	_fear_intensity = 0.0
	_tremble_time = 0.0

	if character.visual_pivot:
		_original_scale = character.visual_pivot.scale

	if character.stamina_component:
		character.stamina_component.can_regenerate = false

	# Suspend AI combat driver
	if character.ai_controller and character.ai_controller.has_method("set_active"):
		character.ai_controller.set_active(false)

	# Get Knight reference to face the executioner
	if msg.has("knight") and is_instance_valid(msg["knight"]):
		_knight_ref = msg["knight"]
		_face_knight_immediate()

	# Play initial interrupt/stagger
	character._play_skeletal_animation("ultimate_enemy_interrupt", 0.08)

func physics_process_state(delta: float) -> void:
	if not character or character.is_dead:
		return

	# Keep enemy rooted in place (zero sliding)
	character.velocity = Vector3.ZERO
	character.global_position = _initial_position
	character.move_and_slide()

	_tremble_time += delta

	# Gradual face-toward-Knight rotation (all stages)
	if is_instance_valid(_knight_ref):
		var to_knight: Vector3 = (_knight_ref.global_position - character.global_position)
		to_knight.y = 0
		if to_knight.length_squared() > 0.01:
			var target_rot_y: float = atan2(-to_knight.x, -to_knight.z)
			var lerp_speed: float = 0.08 if _fear_stage <= 2 else 0.04  # Slower rotation during terror
			character.visual_pivot.rotation.y = lerp_angle(character.visual_pivot.rotation.y, target_rot_y, lerp_speed)

	# Stage-specific physical reactions
	match _fear_stage:
		1:  # INTERRUPT — confusion stagger, recover to face knight
			pass  # Animation handles this

		2:  # AWARENESS — involuntary micro-retreats, breathing intensifies
			# Subtle weight shift (micro-sway)
			if character.visual_pivot:
				var sway = sin(_tremble_time * 2.5) * 0.003 * _fear_intensity
				character.visual_pivot.position.x = sway

		3:  # STASIS — frozen under pressure, body pressed down by energy weight
			# Slight vertical compression (crouching under force)
			if character.visual_pivot:
				var crouch = _fear_intensity * 0.04
				character.visual_pivot.position.y = -crouch

		4:  # TERROR — visible shaking, recoiling, head turns slightly away
			if character.visual_pivot:
				# Progressive trembling — increases with fear_intensity
				var tremble_freq: float = 12.0 + _fear_intensity * 20.0
				var tremble_amp: float = 0.003 + _fear_intensity * 0.012
				var tx = sin(_tremble_time * tremble_freq) * tremble_amp
				var tz = cos(_tremble_time * tremble_freq * 0.7) * tremble_amp * 0.6
				character.visual_pivot.position.x = tx
				character.visual_pivot.position.z = tz

				# Subtle recoil lean — leaning away from Knight
				if is_instance_valid(_knight_ref):
					var away_dir: Vector3 = (character.global_position - _knight_ref.global_position).normalized()
					away_dir.y = 0
					var lean = _fear_intensity * 0.015
					character.visual_pivot.position.x += away_dir.x * lean
					character.visual_pivot.position.z += away_dir.z * lean

				# Vertical compression intensifies
				character.visual_pivot.position.y = -_fear_intensity * 0.06

		5:  # IMPACT — shockwave has hit, handled by director dissolution
			pass


## Called by UltimateCinematicDirector to escalate fear stage and intensity.
func set_fear_stage(stage: int) -> void:
	if stage == _fear_stage:
		return
	_fear_stage = stage

	if not character or not character._get_anim_player():
		return

	var anim_player: AnimationPlayer = character._get_anim_player()

	match stage:
		1:
			if anim_player.current_animation != "ultimate_enemy_interrupt":
				character._play_skeletal_animation("ultimate_enemy_interrupt", 0.08)
		2:
			if anim_player.current_animation != "ultimate_enemy_aware":
				character._play_skeletal_animation("ultimate_enemy_aware", 0.15)
		3:
			if anim_player.current_animation != "ultimate_enemy_stasis":
				character._play_skeletal_animation("ultimate_enemy_stasis", 0.15)
		4:
			if anim_player.current_animation != "ultimate_enemy_terror":
				character._play_skeletal_animation("ultimate_enemy_terror", 0.12)
		5:
			if anim_player.current_animation != "ultimate_enemy_dissolve":
				character._play_skeletal_animation("ultimate_enemy_dissolve", 0.08)


## Called by director each frame to smoothly ramp fear_intensity (0.0 - 1.0).
func set_fear_intensity(intensity: float) -> void:
	_fear_intensity = clampf(intensity, 0.0, 1.0)


func _face_knight_immediate() -> void:
	if not character or not is_instance_valid(_knight_ref):
		return
	var to_knight: Vector3 = (_knight_ref.global_position - character.global_position)
	to_knight.y = 0
	if to_knight.length_squared() > 0.01:
		character.visual_pivot.look_at(character.global_position - to_knight.normalized(), Vector3.UP)


func exit() -> void:
	if character:
		if character.ai_controller and character.ai_controller.has_method("set_active"):
			character.ai_controller.set_active(true)
		if character.stamina_component:
			character.stamina_component.can_regenerate = true
		# Restore any visual pivot offsets
		if character.visual_pivot:
			character.visual_pivot.position = Vector3.ZERO
			character.visual_pivot.scale = _original_scale
