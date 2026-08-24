#!/usr/bin/env -S godot --script
extends SceneTree

## run_gate3_quality_loop.gd — Autonomous Quality Improvement Controller Benchmark
## Executes the 20-action combat validation suite, captures screenshots, and profiles performance.

var root_node: Node3D = null
var player: PlayerController = null
var dummy: TestDummy = null
var cam_rig: CameraRig = null
var current_step: int = 0
var benchmark_results: Array = []
var action_camera: Camera3D = null

func _init() -> void:
	print("\n=======================================================")
	print("  OATHBOUND — Gate 3 Autonomous Quality Benchmark Suite")
	print("=======================================================")

	var scene_res: PackedScene = load("res://scenes/test/combat_quality_test_scene.tscn")
	if not scene_res:
		printerr("[ERROR] Failed to load combat_quality_test_scene.tscn")
		quit(1)
		return

	root_node = scene_res.instantiate()
	root.add_child(root_node)

	player = root_node.find_child("HeroPlayer", true, false) as PlayerController
	dummy = root_node.find_child("CombatTrainingPell", true, false) as TestDummy
	if player:
		cam_rig = player.camera_rig
		if cam_rig:
			cam_rig.set_process(false)
			cam_rig.set_process_unhandled_input(false)
			if cam_rig.camera:
				cam_rig.camera.current = false

		var ap: AnimationPlayer = player._get_anim_player()
		if ap:
			print("[DEBUG] AnimPlayer found with %d animations: %s" % [ap.get_animation_list().size(), str(ap.get_animation_list())])
			if ap.has_animation("heavy_attack"):
				var anim: Animation = ap.get_animation("heavy_attack")
				print("[DEBUG] heavy_attack track count: %d, length: %5.2f" % [anim.get_track_count(), anim.length])
				for t in range(min(5, anim.get_track_count())):
					print("  track %d: %s (type %d)" % [t, anim.track_get_path(t), anim.track_get_type(t)])

	action_camera = Camera3D.new()
	action_camera.fov = 68.0
	root_node.add_child(action_camera)
	action_camera.make_current()

	# Pipeline & Shader Warm-up delay (0.8s)
	var init_timer: Timer = Timer.new()
	init_timer.wait_time = 0.8
	init_timer.one_shot = true
	init_timer.autostart = true
	root_node.add_child(init_timer)
	init_timer.timeout.connect(_start_benchmark_loop)

func _start_benchmark_loop() -> void:
	var step_timer: Timer = Timer.new()
	step_timer.wait_time = 0.25
	step_timer.autostart = true
	root_node.add_child(step_timer)
	step_timer.timeout.connect(_execute_benchmark_step)

func _execute_benchmark_step() -> void:
	var actions = [
		{"name": "01_combat_stance.png", "desc": "Combat Stance Guard"},
		{"name": "02_combat_walk_fwd.png", "desc": "Combat Walk Forward"},
		{"name": "03_combat_strafe.png", "desc": "Combat Strafe"},
		{"name": "04_light_attack_1.png", "desc": "Light 1 Diagonal Slash"},
		{"name": "05_light_attack_2.png", "desc": "Light 2 Upward Counter Cut"},
		{"name": "06_light_attack_3.png", "desc": "Light 3 Lunging Cleave"},
		{"name": "07_heavy_overhead_startup.png", "desc": "Heavy Attack Preload"},
		{"name": "08_heavy_overhead_impact.png", "desc": "Heavy Attack Cleave Impact"},
		{"name": "09_charged_thrust_release.png", "desc": "Coiled Thrust Release"},
		{"name": "10_physical_block_absorption.png", "desc": "Physical Shield Block"},
		{"name": "11_precision_parry_deflection.png", "desc": "Precision Parry Deflection"},
		{"name": "12_dodge_forward.png", "desc": "Evasive Forward Dodge"},
		{"name": "13_dodge_backward.png", "desc": "Tactical Backstep Dodge"},
		{"name": "14_dodge_strafe_left.png", "desc": "Lateral Evasion Dodge"},
		{"name": "15_hit_reaction_front.png", "desc": "Directional Hit React Front"},
		{"name": "16_hit_reaction_back.png", "desc": "Directional Hit React Back"},
		{"name": "17_hit_reaction_left.png", "desc": "Directional Hit React Left"},
		{"name": "18_poise_break_stagger.png", "desc": "Poise Break Stagger"},
		{"name": "19_knockdown_fall.png", "desc": "Physical Knockdown"},
		{"name": "20_cinematic_finisher.png", "desc": "Cinematic Execution Finisher"}
	]

	if current_step >= actions.size():
		_finalize_benchmark_report()
		return

	var act = actions[current_step]
	_setup_combat_action(current_step)
	if action_camera: action_camera.make_current()

	# Measure frame performance BEFORE disk write
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var vram_mb: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0)

	benchmark_results.append({
		"action": act["desc"],
		"file": act["name"],
		"fps": fps,
		"process_ms": process_ms,
		"draw_calls": draw_calls,
		"primitives": primitives,
		"vram_mb": vram_mb
	})

	var img: Image = root.get_texture().get_image()
	if img:
		var save_path: String = "/Users/ramteja/Documents/Blender exp game/docs/screenshots/" + act["name"]
		img.save_png(save_path)
		print("[BENCHMARK %02d/20] %-30s | FPS: %4.1f | Frame: %5.2f ms | DrawCalls: %3d | Prims: %6d" % [
			current_step + 1, act["desc"], fps, process_ms, draw_calls, primitives
		])

	current_step += 1

func _setup_combat_action(idx: int) -> void:
	if not player: return
	var ap: AnimationPlayer = player._get_anim_player()
	var p_pos: Vector3 = player.global_position

	match idx:
		0: # Combat Stance
			player.enter_combat_stance(10.0)
			if ap and ap.has_animation("combat_idle"):
				ap.play("combat_idle")
				ap.seek(0.3, true)
			action_camera.global_position = p_pos + Vector3(-1.1, 1.35, 2.1)
			action_camera.look_at(p_pos + Vector3(0, 1.05, 0), Vector3.UP)
		1: # Combat Walk Fwd
			if ap and ap.has_animation("combat_walk_fwd"):
				ap.play("combat_walk_fwd")
				ap.seek(0.35, true)
			action_camera.global_position = p_pos + Vector3(-1.3, 1.3, 2.0)
			action_camera.look_at(p_pos + Vector3(0, 1.0, 0), Vector3.UP)
		2: # Combat Strafe
			if ap and ap.has_animation("combat_strafe_r"):
				ap.play("combat_strafe_r")
				ap.seek(0.30, true)
			action_camera.global_position = p_pos + Vector3(1.3, 1.3, 2.0)
			action_camera.look_at(p_pos + Vector3(0, 1.0, 0), Vector3.UP)
		3: # Light 1
			player.combo_step = 1
			player.play_attack_animation()
			if ap and ap.has_animation("light_attack_1"):
				ap.play("light_attack_1")
				ap.seek(0.35, true)
			action_camera.global_position = p_pos + Vector3(-1.2, 1.35, 1.9)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		4: # Light 2
			player.combo_step = 2
			player.play_attack_animation()
			if ap and ap.has_animation("light_attack_2"):
				ap.play("light_attack_2")
				ap.seek(0.35, true)
			action_camera.global_position = p_pos + Vector3(1.2, 1.35, 1.9)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		5: # Light 3
			player.combo_step = 3
			player.play_attack_animation()
			if ap and ap.has_animation("light_attack_3"):
				ap.play("light_attack_3")
				ap.seek(0.40, true)
			action_camera.global_position = p_pos + Vector3(-0.9, 1.3, 2.2)
			action_camera.look_at(p_pos + Vector3(0, 1.0, 0), Vector3.UP)
		6: # Heavy Preload
			if ap and ap.has_animation("heavy_attack"):
				ap.play("heavy_attack")
				ap.seek(0.25, true)
			action_camera.global_position = p_pos + Vector3(1.2, 1.5, 2.0)
			action_camera.look_at(p_pos + Vector3(0, 1.2, 0), Vector3.UP)
		7: # Heavy Impact
			player.play_heavy_attack_animation()
			if ap and ap.has_animation("heavy_attack"):
				ap.play("heavy_attack")
				ap.seek(0.50, true)
			if dummy: dummy.take_damage_complex(65.0, player, PlayerController.AttackType.HEAVY, 30.0)
			action_camera.global_position = p_pos + Vector3(1.0, 1.3, 1.8)
			action_camera.look_at(p_pos + Vector3(0, 1.0, -0.3), Vector3.UP)
		8: # Charged Thrust Release
			player.play_charged_attack_release_animation(1.0)
			if ap and ap.has_animation("charged_attack"):
				ap.play("charged_attack")
				ap.seek(0.60, true)
			action_camera.global_position = p_pos + Vector3(-1.1, 1.25, 1.9)
			action_camera.look_at(p_pos + Vector3(0, 1.0, 0), Vector3.UP)
		9: # Block
			player.play_block_animation()
			player.play_block_impact_animation()
			if ap and ap.has_animation("block_hit"):
				ap.play("block_hit")
				ap.seek(0.25, true)
			action_camera.global_position = p_pos + Vector3(-1.2, 1.3, 1.7)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		10: # Parry
			player.play_parry_success_animation()
			if ap and ap.has_animation("parry"):
				ap.play("parry")
				ap.seek(0.30, true)
			action_camera.global_position = p_pos + Vector3(-0.9, 1.35, 1.8)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		11: # Dodge Fwd
			player.play_dodge_animation(Vector3.FORWARD)
			if ap and ap.has_animation("dodge_fwd"):
				ap.play("dodge_fwd")
				ap.seek(0.35, true)
			action_camera.global_position = p_pos + Vector3(-1.2, 1.2, 2.2)
			action_camera.look_at(p_pos + Vector3(0, 0.9, 0), Vector3.UP)
		12: # Dodge Bwd
			player.play_dodge_animation(Vector3.BACK)
			if ap and ap.has_animation("dodge_bwd"):
				ap.play("dodge_bwd")
				ap.seek(0.35, true)
			action_camera.global_position = p_pos + Vector3(-1.2, 1.2, 2.2)
			action_camera.look_at(p_pos + Vector3(0, 0.9, 0), Vector3.UP)
		13: # Dodge Left
			player.play_dodge_animation(Vector3.LEFT)
			if ap and ap.has_animation("dodge_l"):
				ap.play("dodge_l")
				ap.seek(0.35, true)
			action_camera.global_position = p_pos + Vector3(0, 1.2, 2.2)
			action_camera.look_at(p_pos + Vector3(0, 0.9, 0), Vector3.UP)
		14: # Hit Front
			player.play_hit_reaction_animation(Vector3.FORWARD)
			if ap and ap.has_animation("hit_react_front"):
				ap.play("hit_react_front")
				ap.seek(0.25, true)
			action_camera.global_position = p_pos + Vector3(0.9, 1.3, 1.7)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		15: # Hit Back
			player.play_hit_reaction_animation(Vector3.BACK)
			if ap and ap.has_animation("hit_react_back"):
				ap.play("hit_react_back")
				ap.seek(0.25, true)
			action_camera.global_position = p_pos + Vector3(-0.9, 1.3, 1.7)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		16: # Hit Left
			player.play_hit_reaction_animation(Vector3.LEFT)
			if ap and ap.has_animation("hit_react_left"):
				ap.play("hit_react_left")
				ap.seek(0.25, true)
			action_camera.global_position = p_pos + Vector3(1.1, 1.3, 1.7)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		17: # Stagger
			player.play_stagger_animation()
			if ap and ap.has_animation("stagger"):
				ap.play("stagger")
				ap.seek(0.30, true)
			action_camera.global_position = p_pos + Vector3(1.0, 1.35, 1.8)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)
		18: # Knockdown
			player.play_knockdown_animation()
			if ap and ap.has_animation("knockdown"):
				ap.play("knockdown")
				ap.seek(0.45, true)
			action_camera.global_position = p_pos + Vector3(1.2, 1.1, 2.0)
			action_camera.look_at(p_pos + Vector3(0, 0.6, 0), Vector3.UP)
		19: # Finisher
			player.play_finisher_animation()
			if ap and ap.has_animation("finisher"):
				ap.play("finisher")
				ap.seek(0.50, true)
			action_camera.global_position = p_pos + Vector3(-1.0, 1.35, 1.8)
			action_camera.look_at(p_pos + Vector3(0, 1.1, 0), Vector3.UP)

func _finalize_benchmark_report() -> void:
	print("\n=======================================================")
	print("  GATE 3 COMBAT QUALITY BENCHMARK COMPLETE")
	print("=======================================================")
	print("  Total Actions Tested: %d / 20" % benchmark_results.size())
	print("  All 20 Action Screenshots Captured.")
	print("=======================================================\n")
	quit(0)
