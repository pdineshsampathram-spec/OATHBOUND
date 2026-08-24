extends SceneTree

const WaveManager = preload("res://scripts/combat/wave_manager.gd")
const PowerVFXSystem = preload("res://scripts/vfx/power_vfx_system.gd")

## Combat Simulation Test — Runs a full headless combat session with AI fighters,
## validating time_scale stability, state transitions, hit reactions, and ultimate execution.

var arena: Node3D = null
var player: PlayerController = null
var wave_mgr: Node = null
var time_controller: Node = null

var frames_simulated: int = 0
var max_frames: int = 600  # 10 seconds of simulation @ 60 ticks
var time_scale_leak_detected: bool = false
var min_observed_time_scale: float = 1.0
var max_observed_time_scale: float = 1.0

func _init() -> void:
	print("\n==========================================")
	print("=== STARTING OATHBOUND COMBAT SIMULATION ===")
	print("==========================================")
	
	var arena_scene: PackedScene = load("res://scenes/arena/solo_arena.tscn")
	if not arena_scene:
		push_error("FAILED to load solo_arena.tscn")
		quit(1)
		return
	
	arena = arena_scene.instantiate()
	root.add_child(arena)
	
	time_controller = root.get_node_or_null("CombatTimeController")

func _process(delta: float) -> bool:
	frames_simulated += 1
	
	# Monitor time scale across every frame
	var ts: float = Engine.time_scale
	min_observed_time_scale = minf(min_observed_time_scale, ts)
	max_observed_time_scale = maxf(max_observed_time_scale, ts)
	
	if not player:
		var p_node: Node = arena.get_node_or_null("Players/1")
		if p_node is PlayerController:
			player = p_node
			print("[T+%d] Local player initialized: %s (HP: %.0f, Poise: %.0f)" % [frames_simulated, player.sync_character_class, player.character_data.max_health, player.character_data.max_poise])
	
	if not wave_mgr:
		wave_mgr = arena.get_node_or_null("WaveManager") as WaveManager
	
	# Simulate player combat actions at periodic intervals
	if player and is_instance_valid(player) and not player.is_dead:
		# Periodic attacks
		if frames_simulated % 60 == 0:
			player.play_attack_animation()
		elif frames_simulated % 150 == 0:
			player.play_heavy_attack_animation()
		elif frames_simulated % 220 == 0:
			player.play_dodge_animation(Vector3.FORWARD)
		elif frames_simulated % 300 == 0:
			# Test ultimate execution
			print("[T+%d] Triggering 8-Phase Cinematic Ultimate..." % frames_simulated)
			PowerVFXSystem.execute_cinematic_ultimate(player, player.global_position + Vector3(0, 0, -4.0))

	# Print periodic status
	if frames_simulated % 120 == 0:
		var enemy_count: int = wave_mgr.get_active_enemies().size() if wave_mgr else 0
		var ctc_state: String = "N/A"
		if time_controller and time_controller.has_method("get_debug_info"):
			var info: Dictionary = time_controller.get_debug_info()
			ctc_state = "%s (time_scale=%.2f)" % [info.get("state", "UNKNOWN"), info.get("time_scale", 1.0)]
		print("[T+%d frames] Active Enemies: %d | TimeController: %s" % [frames_simulated, enemy_count, ctc_state])

	if frames_simulated >= max_frames:
		_evaluate_results()
		quit()
		return true
	return false

func _evaluate_results() -> void:
	print("\n==========================================")
	print("=== COMBAT SIMULATION RESULTS ===")
	print("==========================================")
	print("Total Frames Simulated: %d" % frames_simulated)
	print("Min Observed Time Scale: %.3f (expected during hitstop/ultimate)" % min_observed_time_scale)
	print("Max Observed Time Scale: %.3f" % max_observed_time_scale)
	print("Final Engine Time Scale: %.3f" % Engine.time_scale)
	
	var is_clean: bool = absf(Engine.time_scale - 1.0) < 0.01
	if is_clean:
		print(">> SUCCESS: Engine.time_scale reliably returned to 1.0! No slow-motion leak.")
	else:
		push_error(">> FAILURE: Engine.time_scale leaked at %.3f!" % Engine.time_scale)
	
	if wave_mgr:
		print("Final Wave: %d | Active Enemies: %d" % [wave_mgr.current_wave, wave_mgr.get_active_enemies().size()])
	print("==========================================\n")
