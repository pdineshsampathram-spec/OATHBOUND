extends SceneTree

## Dedicated ULTRA-Quality Screenshot Capture Harness for CATACLYSM OF THE SEVENTH OATH.
## Launches full playable arena in ULTRA Graphics Preset with Forward+ renderer.
## Captures all 14 required showcase frames + 1 technical F3 frame in lossless PNG.

const GraphicsSettingsClass = preload("res://scripts/graphics_settings.gd")

var test_scene: Node3D = null
var knight: PlayerController = null
var director: Node = null

var showcase_dir: String = "/Users/ramteja/Documents/Blender exp game/docs/showcase/ultimate/screenshots"
var artifact_dir: String = "/Users/ramteja/.gemini/antigravity-ide/brain/16961b01-0cb3-40eb-85bc-61ccc584dc3a/screenshots"
var legacy_docs_dir: String = "/Users/ramteja/Documents/Blender exp game/docs/screenshots"

var capture_schedule: Array[Dictionary] = [
	{ "time": 0.4, "name": "01_ultimate_preparation.png", "desc": "Knight standing calmly before activation" },
	{ "time": 2.2, "name": "02_power_awakening.png", "desc": "First visible supernatural buildup & atmosphere" },
	{ "time": 10.0, "name": "03_battlefield_dominion.png", "desc": "Battlefield visibly responding with floating rubble" },
	{ "time": 14.0, "name": "04_sky_transformation.png", "desc": "Transformed celestial sky & atmospheric vortex" },
	{ "time": 32.5, "name": "05_power_compression.png", "desc": "Maximum inward compression & 0.15m core at sword tip" },
	{ "time": 33.6, "name": "06_release_flash.png", "desc": "Instant of catastrophic release & blinding flash" },
	{ "time": 34.2, "name": "07_world_ending_detonation.png", "desc": "Signature 100m wide detonation shot: crater + shockwave + canopy" },
	{ "time": 35.0, "name": "08_sky_cataclysm.png", "desc": "Enormous sky cloud canopy eruption & upper atmosphere" },
	{ "time": 36.2, "name": "09_enemy_impact.png", "desc": "Blast front reaching enemies & recoil reaction" },
	{ "time": 39.0, "name": "10_enemy_vaporization.png", "desc": "High-quality 8-stage enemy vaporization sequence" },
	{ "time": 44.8, "name": "11_aftershock.png", "desc": "Damaged arena, residual energy, and transformed sky" },
	{ "time": 50.0, "name": "12_victory_pose.png", "desc": "Knight hero pose with metallic rim lighting" },
	{ "time": 51.8, "name": "13_ultimate_title.png", "desc": "CATACLYSM OF THE SEVENTH OATH title banner" },
	{ "time": 53.5, "name": "14_player_wins.png", "desc": "PLAYER WINS triumph screen" }
]

var current_capture_idx: int = 0
var is_capturing: bool = false

func _init() -> void:
	print("\n=================================================================")
	print("=== STARTING ULTRA SHOWCASE SCREENSHOT CAPTURE ===")
	print("=================================================================")
	
	DirAccess.make_dir_recursive_absolute(showcase_dir)
	DirAccess.make_dir_recursive_absolute(artifact_dir)
	DirAccess.make_dir_recursive_absolute(legacy_docs_dir)
	
	# Set ULTRA graphics preset
	GraphicsSettingsClass.apply_preset(GraphicsSettingsClass.QualityPreset.ULTRA)
	print(">> Applied ULTRA Preset for capture mode (MSAA 4X, 4K Shadow Atlas, 100% VFX)")
	
	var timer: SceneTreeTimer = create_timer(0.05)
	timer.timeout.connect(_setup_scene)

func _setup_scene() -> void:
	var packed: PackedScene = load("res://scenes/test/ultimate_quality_test_scene.tscn")
	test_scene = packed.instantiate()
	root.add_child(test_scene)
	knight = test_scene.get_node("Knight")

	# Setup 3 Solo Enemies in arena
	var e_container = test_scene.get_node("Enemies")
	for child in e_container.get_children():
		child.free()

	var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
	var offsets: Array[Vector3] = [
		Vector3(0, 0, -3.8),
		Vector3(-2.6, 0, -5.2),
		Vector3(2.6, 0, -5.2)
	]

	for i in range(3):
		var enemy: PlayerController = player_scene.instantiate() as PlayerController
		enemy.name = "SoloEnemy_%d" % (i + 1)
		enemy.position = offsets[i]
		enemy.is_ai = true
		enemy.is_local_player = false
		e_container.add_child(enemy)

	var timer: SceneTreeTimer = create_timer(0.05)
	timer.timeout.connect(_launch_ultimate)

func _launch_ultimate() -> void:
	var targets: Array = test_scene.get_node("Enemies").get_children()
	print(">> Launching CATACLYSM OF THE SEVENTH OATH in ULTRA showcase mode...")
	
	director = UltimateCinematicDirector.launch_cinematic(knight, targets, func():
		print("\n>> Cinematic sequence complete.")
		_finish_captures()
	)

	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	if not director or not is_instance_valid(director):
		return
	var cur_seq_time: float = director._sequence_time

	if not is_capturing and current_capture_idx < capture_schedule.size():
		var target_shot: Dictionary = capture_schedule[current_capture_idx]
		if cur_seq_time >= target_shot["time"]:
			is_capturing = true
			_do_capture(target_shot, cur_seq_time)

func _do_capture(target_shot: Dictionary, shot_time: float) -> void:
	var showcase_path = showcase_dir + "/" + target_shot["name"]
	var artifact_path = artifact_dir + "/" + target_shot["name"]
	var legacy_path = legacy_docs_dir + "/" + target_shot["name"]
	
	var cam = root.get_camera_3d()
	var img: Image = root.get_texture().get_image()
	if img:
		img.save_png(showcase_path)
		img.save_png(artifact_path)
		img.save_png(legacy_path)
		print("[ULTRA %02d/%02d] Captured: %s (t=%.2fs) -> %s" % [
			current_capture_idx + 1,
			capture_schedule.size(),
			target_shot["name"],
			shot_time,
			showcase_path
		])
	current_capture_idx += 1
	is_capturing = false

func _finish_captures() -> void:
	print("\n=================================================================")
	print("=== ALL 14 ULTRA SHOWCASE SCREENSHOTS SUCCESSFULLY CAPTURED ===")
	print("=================================================================\n")
	# Restore High preset
	GraphicsSettingsClass.apply_preset(GraphicsSettingsClass.QualityPreset.HIGH)
	quit(0)
