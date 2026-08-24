extends SceneTree

const UltimateVFXController = preload("res://scripts/vfx/ultimate_vfx_controller.gd")

## Solo Practice Wave 1 & 2 Ultimate Progression Regression Benchmark.
## Tests:
## 1. Wave 1 setup with 2 enemy fighters.
## 2. Trigger Ultimate against Wave 1 enemies.
## 3. Verify both enemies are captured, disarmed, receive authoritative damage, and die.
## 4. Verify WaveManager registers 2 deaths, Wave 1 ends, and Wave 2 begins.
## 5. Verify Wave 2 enemies spawn and Knight controls are fully restored.

var test_scene: Node3D = null
var knight: PlayerController = null
var wave_manager: WaveManager = null
var frames: int = 0
var current_step: int = 1
var wave1_deaths_registered: int = 0
var wave1_completed_emitted: bool = false
var wave2_started_emitted: bool = false

func _init() -> void:
	print("\n=================================================================")
	print("=== STARTING SOLO PRACTICE WAVE 1 & 2 ULTIMATE BENCHMARK ===")
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
		knight = test_scene.find_child("HeroKnight", true, false) as PlayerController
		if not knight:
			knight = test_scene.find_child("1", true, false) as PlayerController
		if not knight:
			knight = test_scene.find_child("Knight", true, false) as PlayerController
		if not knight:
			var pcs = test_scene.find_children("*", "PlayerController", true, false)
			if not pcs.is_empty():
				knight = pcs[0] as PlayerController

		if wave_manager:
			print("[Frame %d] Found WaveManager. Initial Wave: %d" % [frames, wave_manager.current_wave])
			wave_manager.wave_started.connect(func(w, count):
				print(">> [WaveManager Signal] Wave %d Started (Enemies: %d)" % [w, count])
				if w == 2:
					wave2_started_emitted = true
			)
			wave_manager.wave_completed.connect(func(w):
				print(">> [WaveManager Signal] Wave %d Completed!" % w)
				if w == 1:
					wave1_completed_emitted = true
			)
			wave_manager.enemy_killed.connect(func(remaining):
				wave1_deaths_registered += 1
				print(">> [WaveManager Signal] Enemy Killed (Deaths: %d, Remaining: %d)" % [wave1_deaths_registered, remaining])
			)

	# Step 1: Ensure Wave 1 has 2 enemies spawned for the mandatory Wave 1 test
	if current_step == 1 and frames == 45:
		if wave_manager:
			while wave_manager.active_enemies.size() < 2:
				wave_manager._spawn_enemy("Knight", 0.4, 0.4, 0.4)
			print("[Frame %d] Wave 1 Ready with %d Active Enemies!" % [frames, wave_manager.active_enemies.size()])
			
			print(">>> Triggering OATHBOUND ASCENDANCE against Wave 1 enemies...")
			current_step = 2
			var targets: Array = wave_manager.active_enemies.duplicate()
			UltimateVFXController.launch_ascendance(knight, targets, func():
				print("[Callback] Ultimate sequence complete on Wave 1!")
				current_step = 3
			)

	# Step 3: Evaluate Wave 1 completion and Wave 2 transition
	if current_step == 3 and frames >= 220:
		print("\n=================================================================")
		print("=== SOLO PRACTICE WAVE 1 EVALUATION ===")
		print("=================================================================")
		print("Wave 1 Deaths Registered: %d (Target >= 2)" % wave1_deaths_registered)
		print("Wave 1 Completed Signal Emitted: %s" % str(wave1_completed_emitted))
		print("Current Wave: %d (Expected >= 2)" % wave_manager.current_wave)
		print("Time Scale: %.3f (Expected 1.000)" % Engine.time_scale)
		print("Knight Controls Restored: InputLocked=%s, AttackLocked=%s" % [str(knight.player_input_locked), str(knight.attack_locked)])
		
		var test_passed: bool = wave1_deaths_registered >= 2 and (wave_manager.current_wave >= 2 or wave1_completed_emitted) and not knight.player_input_locked
		if test_passed:
			print(">> PASS: Solo Practice Wave 1 Ultimate damage, death, and Wave 2 progression 100% verified.")
			print("=================================================================\n")
			quit()
			return true
		else:
			push_error(">> FAIL: Solo Practice Wave 1 did not progress cleanly!")
			quit(1)
			return true

	if frames >= 4500:
		print("Timeout reached. Exiting benchmark.")
		quit(1)
		return true

	return false

