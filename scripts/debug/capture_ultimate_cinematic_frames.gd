extends SceneTree

## Dedicated Visual Capture & Quality Validation Harness for CATACLYSM OF THE SEVENTH OATH.
## Spawns the Knight and 3 Solo Enemies in the full fortress arena.
## Triggers the Ultimate and captures full-resolution PNG frames at every key cinematic beat:
## - Beat 01: Awakening (t = 2.0s / Power = 0.06)
## - Beat 02: Power Buildup & Arena Response (t = 6.0s / Power = 0.18)
## - Beat 03: Battlefield Pressure & Floor Cracks (t = 12.0s / Power = 0.36)
## - Beat 04: Sword Ascension & Anti-Gravity Rubble (t = 17.0s / Power = 0.51)
## - Beat 05: Arena Submission & Sky Dominance (t = 22.0s / Power = 0.66)
## - Beat 06: Enemy Terror in Stasis (t = 25.0s / Power = 0.75)
## - Beat 07: Dedicated Enemy Vaporization & Inward Suction (t = 29.0s / Power = 0.87)
## - Beat 08: Zenith Energy Compression (t = 33.0s / Power = 0.98)
## - Beat 09: Cataclysmic Detonation & 65m Sky Pillar (t = 34.5s / Release)
## - Beat 10: Traveling Shockwave Front (t = 37.0s / Climax)
## - Beat 11: Atmospheric Aftermath & Scarred Sky (t = 40.0s / Aftermath)
## - Beat 12: Hero Victory Portrait & Title (t = 45.0s / Triumph)

var test_scene: Node3D = null
var knight: PlayerController = null
var director: Node = null
var output_dir: String = "/Users/ramteja/.gemini/antigravity-ide/brain/9e282b9a-7562-4985-83bc-555bb997215c/screenshots"

var capture_schedule: Array[Dictionary] = [
	{ "time": 2.0, "name": "01_awakening_preparation.png", "desc": "Awakening & Initial Tension" },
	{ "time": 6.0, "name": "02_power_buildup_world_responds.png", "desc": "Power Buildup & Dust/Torch Response" },
	{ "time": 12.0, "name": "03_battlefield_pressure_ground_cracks.png", "desc": "Battlefield Pressure & Ground Veins" },
	{ "time": 17.0, "name": "04_sword_ascension_anti_gravity_rubble.png", "desc": "Sword Ascension & Floating Rubble" },
	{ "time": 22.0, "name": "05_arena_submission_sky_dominance.png", "desc": "Arena Submission & Sky Vortex" },
	{ "time": 25.0, "name": "06_enemy_terror_stasis.png", "desc": "Enemy Terror & Stasis Acting" },
	{ "time": 29.0, "name": "07_enemy_vaporization_inward_suction.png", "desc": "Enemy Physical Breakdown & Inward Suction" },
	{ "time": 33.0, "name": "08_zenith_energy_compression.png", "desc": "Zenith Compression & Breathless Silence" },
	{ "time": 34.5, "name": "09_cataclysmic_detonation_sky_pillar.png", "desc": "Cataclysmic Detonation & 65m Sky Pillar" },
	{ "time": 37.0, "name": "10_traveling_shockwave_front.png", "desc": "Traveling 100m Shockwave Front" },
	{ "time": 40.0, "name": "11_atmospheric_aftermath_scarred_sky.png", "desc": "Atmospheric Aftermath & Scarred Sky" },
	{ "time": 45.0, "name": "12_hero_victory_portrait.png", "desc": "Hero Victory Portrait & Title Card" }
]

var current_capture_idx: int = 0
var elapsed: float = 0.0

func _init() -> void:
	print("\n=================================================================")
	print("=== STARTING ULTIMATE CINEMATIC VISUAL PROOF CAPTURE ===")
	print("=================================================================")
	
	DirAccess.make_dir_recursive_absolute(output_dir)
	
	var timer: SceneTreeTimer = create_timer(0.05)
	timer.timeout.connect(_setup_scene)

func _setup_scene() -> void:
	var packed: PackedScene = load("res://scenes/test/ultimate_quality_test_scene.tscn")
	test_scene = packed.instantiate()
	root.add_child(test_scene)
	knight = test_scene.get_node("Knight")

	# Setup 3 Solo Enemies
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
	print(">> Launching CATACLYSM OF THE SEVENTH OATH in full arena with 3 enemies...")
	
	director = UltimateCinematicDirector.launch_cinematic(knight, targets, func():
		print("\n>> Cinematic completed successfully!")
		_finish_captures()
	)

var is_capturing: bool = false

func _process(delta: float) -> bool:
	elapsed += delta

	if not is_capturing and current_capture_idx < capture_schedule.size():
		var target_shot: Dictionary = capture_schedule[current_capture_idx]
		if elapsed >= target_shot["time"]:
			is_capturing = true
			_do_capture(target_shot)

	return false

func _do_capture(target_shot: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var filepath = output_dir + "/" + target_shot["name"]
	var cam = root.get_viewport().get_camera_3d()
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(filepath)
		print("[Proof %02d/%02d] Captured %s (t=%.1fs) [Cam: %s @ %s] -> %s" % [
			current_capture_idx + 1,
			capture_schedule.size(),
			target_shot["desc"],
			elapsed,
			cam.name if cam else "NULL",
			cam.global_position if cam else Vector3.ZERO,
			filepath
		])
	current_capture_idx += 1
	is_capturing = false

func _finish_captures() -> void:
	print("\n=================================================================")
	print("=== ALL 12 CINEMATIC PROOF FRAMES CAPTURED TO ARTIFACTS ===")
	print("=================================================================\n")
	quit()
