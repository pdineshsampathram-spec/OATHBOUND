#!/usr/bin/env -S godot --script
extends SceneTree

var root_node: Node3D = null
var player: PlayerController = null
var dummy: TestDummy = null
var cam_rig: CameraRig = null
var shot_idx: int = 0

func _init() -> void:
	print("\n=== Starting OATHBOUND Gate 2A Combat Quality Benchmark Captures ===")
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

	var timer: Timer = Timer.new()
	timer.wait_time = 0.2
	timer.autostart = true
	root_node.add_child(timer)
	timer.timeout.connect(_on_timer_step)

func _on_timer_step() -> void:
	var shot_names = [
		"01_combat_stance_guard.png",
		"02_light_combo_step1.png",
		"03_light_combo_step2.png",
		"04_light_combo_step3.png",
		"05_heavy_overhead_cleave.png",
		"06_blade_sweep_contact.png",
		"07_directional_hit_reaction.png",
		"08_physical_shield_block.png",
		"09_precision_parry_deflection.png",
		"10_evasive_dodge_roll.png"
	]

	if shot_idx >= shot_names.size():
		print("=== All 10 Combat Quality Benchmark Screenshots Captured Successfully! ===")
		quit(0)
		return

	var s_name: String = shot_names[shot_idx]
	_execute_shot_setup(shot_idx)

	var img: Image = root.get_texture().get_image()
	if img:
		var save_path: String = "/Users/ramteja/Documents/Blender exp game/docs/screenshots/" + s_name
		img.save_png(save_path)
		print("[SAVED COMBAT BENCHMARK %d/10] %s" % [shot_idx + 1, save_path])

	shot_idx += 1

func _execute_shot_setup(idx: int) -> void:
	if not player:
		return
	var ap: AnimationPlayer = player._get_anim_player()

	match idx:
		0:
			player.enter_combat_stance(10.0)
			if ap and ap.has_animation("combat_idle"):
				ap.play("combat_idle")
				ap.advance(0.3)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(0, 1.4, 2.4)
		1:
			player.combo_step = 1
			player.play_attack_animation()
			if ap and ap.has_animation("light_attack_1"):
				ap.play("light_attack_1")
				ap.advance(0.35)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(-0.6, 1.4, 2.2)
		2:
			player.combo_step = 2
			player.play_attack_animation()
			if ap and ap.has_animation("light_attack_2"):
				ap.play("light_attack_2")
				ap.advance(0.35)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(0.6, 1.4, 2.2)
		3:
			player.combo_step = 3
			player.play_attack_animation()
			if ap and ap.has_animation("light_attack_3"):
				ap.play("light_attack_3")
				ap.advance(0.40)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(0, 1.5, 2.5)
		4:
			player.play_heavy_attack_animation()
			if ap and ap.has_animation("heavy_attack"):
				ap.play("heavy_attack")
				ap.advance(0.45)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(0.8, 1.6, 2.2)
		5:
			player.combo_step = 1
			player.play_attack_animation()
			if ap and ap.has_animation("light_attack_1"):
				ap.play("light_attack_1")
				ap.advance(0.35)
			if dummy: dummy.take_damage_complex(35.0, player, PlayerController.AttackType.LIGHT, 15.0)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(-0.4, 1.3, 1.8)
		6:
			player.play_hit_reaction_animation(Vector3.FORWARD)
			if ap and ap.has_animation("hit_react_front"):
				ap.play("hit_react_front")
				ap.advance(0.25)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(0.5, 1.3, 1.8)
		7:
			player.play_block_animation()
			player.play_block_impact_animation()
			if ap and ap.has_animation("block_hit"):
				ap.play("block_hit")
				ap.advance(0.25)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(-0.8, 1.3, 1.8)
		8:
			player.play_parry_success_animation()
			if ap and ap.has_animation("parry"):
				ap.play("parry")
				ap.advance(0.30)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(-0.5, 1.4, 1.9)
		9:
			player.play_dodge_animation(Vector3(1, 0, 0))
			if ap and ap.has_animation("dodge_r"):
				ap.play("dodge_r")
				ap.advance(0.35)
			if cam_rig: cam_rig.global_position = player.global_position + Vector3(0, 1.2, 2.5)
