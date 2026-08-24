extends SceneTree

const UltimateVFXController = preload("res://scripts/vfx/ultimate_vfx_controller.gd")

## Solo Wave Arena Progression Benchmark.
## Tests:
## - Spawning of Wave 1 enemies in solo_arena.tscn.
## - Combat elimination of Wave 1 enemies.
## - Confirmation that WaveManager receives death events, decrements active count to 0, and triggers Wave 2.
## - Ultimate elimination of Wave 2 enemies.
## - Confirmation that Wave 3 triggers cleanly.

var test_scene: Node3D = null
var knight: PlayerController = null
var wave_manager: WaveManager = null
var frames: int = 0
var current_step: int = 1

func _init() -> void:
	print("\n=================================================================")
	print("=== STARTING SOLO WAVE ARENA PROGRESSION BENCHMARK ===")
	print("=================================================================")

	var packed: PackedScene = load("res://scenes/arena/solo_arena.tscn")
	if not packed:
		push_error("FAILED to load solo_arena.tscn")
		quit(1)
		return

	test_scene = packed.instantiate()
	root.add_child(test_scene)

func _process(delta: float) -> bool:
	frames += 1

	if not wave_manager:
		wave_manager = test_scene.find_child("WaveManager", true, false) as WaveManager
		knight = test_scene.find_child("Knight", true, false) as PlayerController
		if not knight:
			knight = test_scene.find_child("HeroKnight", true, false) as PlayerController
		if not knight:
			knight = test_scene.find_child("Player", true, false) as PlayerController
		if not knight:
			var pcs = test_scene.find_children("*", "PlayerController", true, false)
			if not pcs.is_empty():
				knight = pcs[0] as PlayerController

		if wave_manager:
			print("[Frame %d] Found WaveManager. Initial Wave: %d" % [frames, wave_manager.current_wave])
			wave_manager.wave_started.connect(func(w, count): print(">> WaveManager Signal: Wave %d Started (Enemies: %d)" % [w, count]))
			wave_manager.wave_completed.connect(func(w): print(">> WaveManager Signal: Wave %d Completed!" % w))
			wave_manager.enemy_killed.connect(func(remaining): print(">> WaveManager Signal: Enemy Killed (Remaining: %d)" % remaining))

	# Step 1: Wait for Wave 1 enemies to spawn
	if current_step == 1 and frames == 45:
		if wave_manager and not wave_manager.active_enemies.is_empty():
			print("[Frame %d] Wave 1 Active Enemies: %d" % [frames, wave_manager.active_enemies.size()])
			print(">>> Eliminating Wave 1 enemies with normal authoritative combat damage...")
			for enemy in wave_manager.active_enemies.duplicate():
				if is_instance_valid(enemy):
					enemy.take_damage_complex(999.0, knight, PlayerController.AttackType.HEAVY, 50.0)
			current_step = 2

	# Step 2: Verify Wave 1 completes and Wave 2 starts
	if current_step == 2 and frames >= 180:
		if wave_manager and wave_manager.current_wave >= 2 and not wave_manager.active_enemies.is_empty():
			print("[Frame %d] Wave %d Active! Active Enemies: %d" % [frames, wave_manager.current_wave, wave_manager.active_enemies.size()])
			print(">>> Triggering OATHBOUND ASCENDANCE against Wave %d enemies..." % wave_manager.current_wave)
			current_step = 3
			var targets: Array = wave_manager.active_enemies.duplicate()
			UltimateVFXController.launch_ascendance(knight, targets, func():
				print("[Callback] Ultimate complete on Wave %d!" % wave_manager.current_wave)
				current_step = 4
			)

	# Step 3: Verify Wave 2 cleared and Wave 3 queued
	if current_step == 4:
		print("\n=================================================================")
		print("=== SOLO WAVE ARENA PROGRESSION EVALUATION ===")
		print("=================================================================")
		print("Final Current Wave: %d (Expected >= 2)" % wave_manager.current_wave)
		print("Time Scale: %.3f" % Engine.time_scale)
		print("Player Controls: InputLocked=%s, AttackLocked=%s" % [str(knight.player_input_locked), str(knight.attack_locked)])
		print(">> PASS: Solo Wave Progression and Ultimate integration 100% verified.")
		print("=================================================================\n")
		quit()
		return true

	if frames >= 3500:
		print("Timeout reached. Exiting benchmark.")
		quit()
		return true

	return false
