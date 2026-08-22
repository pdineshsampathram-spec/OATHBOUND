extends SceneTree

const SCREENSHOT_DIR = "res://docs/screenshots"

func _init() -> void:
	print("=== Starting OATHBOUND In-Engine Benchmark Screenshot Captures ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	
	var main_scene: PackedScene = load("res://scenes/debug/quality_benchmark_arena.tscn")
	if not main_scene:
		printerr("Failed to load quality_benchmark_arena.tscn")
		quit(1)
		return

	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)

	# Execute captures after frames render
	_capture_sequence(root_node)

func _capture_sequence(arena: Node) -> void:
	var player = arena.get_node_or_null("HeroKnightPlayer")
	var cam_rig = player.get_node_or_null("CameraRig") if player else null
	var cam: Camera3D = cam_rig.get_node_or_null("SpringArm3D/Camera3D") if cam_rig else null

	# Let shaders compile and lighting settle
	for i in range(25):
		await process_frame

	# 1. Gameplay Third-Person View
	if cam:
		_save_viewport_shot("01_gameplay_camera_thirdperson.png")

	# 2. Knight Close-up View (Focusing on PBR Armor, Sallet, Plackart, Tabard)
	if cam:
		var orig_pos = cam.global_position
		var orig_rot = cam.global_rotation
		cam.global_position = player.global_position + Vector3(0.6, 1.3, 1.8)
		cam.look_at(player.global_position + Vector3(0, 1.2, 0), Vector3.UP)
		for i in range(5): await process_frame
		_save_viewport_shot("02_hero_knight_pbr_closeup.png")
		cam.global_position = orig_pos
		cam.global_rotation = orig_rot

	# 3. Heavy Attack Startup Pose
	if player and player.has_method("_play_skeletal_animation"):
		player._play_skeletal_animation("heavy_attack", 0.0)
		for i in range(8): await process_frame
		_save_viewport_shot("03_heavy_attack_startup.png")

	# 4. Blade at Contact
	if player:
		player._play_skeletal_animation("light_attack", 0.0)
		ImpactVFX.spawn_hit_sparks(player, player.global_position + Vector3(0, 1.2, -1.2), false)
		for i in range(5): await process_frame
		_save_viewport_shot("04_blade_contact_strike.png")

	# 5. Hitstop Reaction
	if player and player.has_method("rpc_flash_hit"):
		player.rpc_flash_hit()
		for i in range(3): await process_frame
		_save_viewport_shot("05_hitstop_reaction.png")

	# 6. Successful Parry
	if player:
		player._play_skeletal_animation("parry", 0.0)
		ImpactVFX.spawn_hit_sparks(player, player.global_position + Vector3(0, 1.1, -0.6), true)
		for i in range(5): await process_frame
		_save_viewport_shot("06_successful_parry_deflection.png")

	# 7. Dodge
	if player:
		player._play_skeletal_animation("dodge", 0.0)
		for i in range(6): await process_frame
		_save_viewport_shot("07_combat_dodge.png")

	# 8. Finisher Strike
	if player:
		player._play_skeletal_animation("finisher", 0.0)
		ImpactVFX.spawn_hit_sparks(player, player.global_position + Vector3(0, 1.3, -1.0), true)
		for i in range(8): await process_frame
		_save_viewport_shot("08_finisher_execution.png")

	print("=== All 8 Visual Benchmark Screenshots Captured Successfully! ===")
	quit(0)

func _save_viewport_shot(filename: String) -> void:
	var img: Image = root.get_texture().get_image()
	var global_path: String = ProjectSettings.globalize_path(SCREENSHOT_DIR + "/" + filename)
	img.save_png(global_path)
	print("[SAVED SCREENSHOT] " + global_path)
