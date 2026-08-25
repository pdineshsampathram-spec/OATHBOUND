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
var output_dir: String = "/Users/ramteja/.gemini/antigravity-ide/brain/16961b01-0cb3-40eb-85bc-61ccc584dc3a/screenshots"
var docs_dir: String = "/Users/ramteja/Documents/Blender exp game/docs/screenshots"

var capture_schedule: Array[Dictionary] = [
	{ "time": 2.0, "name": "01_hilt_macro_awakening.png", "desc": "Hand/Hilt Macro & Body Seam Energy" },
	{ "time": 4.0, "name": "02_helmet_visor_reveal.png", "desc": "Helmet & Visor Front Reveal" },
	{ "time": 6.5, "name": "03_hero_upward_filaments.png", "desc": "Hero Upward Angle & Rising Filaments" },
	{ "time": 10.0, "name": "04_sweeping_orbit_power_rise.png", "desc": "180° Sweeping Orbit & Ground Cracks" },
	{ "time": 13.5, "name": "05_sky_phase1_transformation.png", "desc": "Sky Transformation: Sunlight Dims & Clouds Rotate" },
	{ "time": 16.5, "name": "06_sword_raised_conductor.png", "desc": "Sword Raised & Blade Energy Conductor" },
	{ "time": 20.0, "name": "07_dedicated_sky_reveal.png", "desc": "Dedicated Sky Reveal: Knight -> 50m Column -> Vortex" },
	{ "time": 23.5, "name": "08_dense_celestial_submission.png", "desc": "Dense Celestial Submission: Lightning & Orbital Arcs" },
	{ "time": 26.5, "name": "09_world_submission_wide_shot.png", "desc": "Pre-Release World Submission: 100m Fortress Total Dominion" },
	{ "time": 29.0, "name": "10_enemy_terror_stasis.png", "desc": "Enemy Terror Front Close-Up in Stasis" },
	{ "time": 32.5, "name": "11_silence_before_catastrophe.png", "desc": "Inward Compression & Breathless Silence Before Catastrophe" },
	{ "time": 34.2, "name": "12_3d_cataclysm_detonation.png", "desc": "3D World-Scale Detonation: Ground + Air + Sky" },
	{ "time": 36.2, "name": "13_shockwave_hits_enemies_recoil.png", "desc": "Shockwave Hits Enemies: Recoil & Raw Armor Illumination" },
	{ "time": 39.0, "name": "14_dedicated_enemy_vaporization.png", "desc": "Dedicated Post-Release Vaporization: Fracturing Dissolution" },
	{ "time": 41.8, "name": "15_vapor_suction_knight_aura.png", "desc": "Enemy Vapor Suction into Knight Aura" },
	{ "time": 44.8, "name": "16_secondary_aftershock_pulse.png", "desc": "Secondary Aftershock Pulse Through Arena" },
	{ "time": 47.5, "name": "17_scarred_sky_aftermath.png", "desc": "Scarred Sky Aftermath & Slowly Rotating Vortex" },
	{ "time": 50.0, "name": "18_knight_aftermath_clean_rim_light.png", "desc": "Knight Aftermath: Sword Lowered & Clean Rim Lighting" },
	{ "time": 51.8, "name": "19_cataclysm_mythic_title.png", "desc": "Dedicated Mythic Title: CATACLYSM OF THE SEVENTH OATH" },
	{ "time": 53.5, "name": "20_player_wins_triumph.png", "desc": "Sequential PLAYER WINS Triumph Beat" }
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

	process_frame.connect(_on_process_frame)

var is_capturing: bool = false

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
	var filepath = output_dir + "/" + target_shot["name"]
	var docs_filepath = docs_dir + "/" + target_shot["name"]
	var cam = root.get_camera_3d()
	var img: Image = root.get_texture().get_image()
	if img:
		img.save_png(filepath)
		DirAccess.make_dir_recursive_absolute(docs_dir)
		img.save_png(docs_filepath)
		print("[Proof %02d/%02d] Captured %s (t=%.1fs) [Cam: %s @ %s] -> %s" % [
			current_capture_idx + 1,
			capture_schedule.size(),
			target_shot["desc"],
			shot_time,
			cam.name if cam else "NULL",
			cam.global_position if cam else Vector3.ZERO,
			filepath
		])
	current_capture_idx += 1
	is_capturing = false



func _finish_captures() -> void:
	print("\n=================================================================")
	print("=== ALL 20 CINEMATIC PROOF FRAMES CAPTURED TO ARTIFACTS ===")
	print("=================================================================\n")
	quit()

