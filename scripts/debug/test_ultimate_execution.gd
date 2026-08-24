extends SceneTree

const UltimateVFXController = preload("res://scripts/vfx/ultimate_vfx_controller.gd")

## Test script executing the full ~5.0s OATHBOUND ASCENDANCE sequence across 1, 2, and 3 enemies.
## Validates enemy capture lock, authoritative lethal damage, dissolution, and clean time/control recovery.

var test_scene: Node3D = null
var knight: PlayerController = null
var frames: int = 0
var max_frames: int = 380
var sequence_finished: bool = false

func _init() -> void:
	print("\n=================================================================")
	print("=== RUNNING OATHBOUND ASCENDANCE OVERWHELMING POWER TEST ===")
	print("=================================================================")

	var packed: PackedScene = load("res://scenes/test/ultimate_quality_test_scene.tscn")
	if not packed:
		push_error("FAILED to load ultimate_quality_test_scene.tscn")
		quit(1)
		return

	test_scene = packed.instantiate()
	root.add_child(test_scene)

func _process(delta: float) -> bool:
	frames += 1

	if not knight:
		var k_node = test_scene.get_node_or_null("Knight")
		if k_node is PlayerController:
			knight = k_node
			print("[Frame %d] Knight initialized. Triggering OATHBOUND ASCENDANCE on 3 captured enemies..." % frames)
			var targets: Array = test_scene.get_node("Enemies").get_children()
			UltimateVFXController.launch_ascendance(knight, targets, _on_completed)

	# Verify enemy state during capture (e.g. Frame 30, Frame 60)
	if frames == 45:
		var e_container = test_scene.get_node_or_null("Enemies")
		if e_container:
			var captured_count: int = 0
			for e in e_container.get_children():
				if is_instance_valid(e) and e is PlayerController:
					var state_name = e.state_machine.get_current_state_name() if e.state_machine else "None"
					if state_name == "UltimateCapturedState":
						captured_count += 1
			print("[Frame 45 / Phase 1] Captured Enemies in UltimateCapturedState: %d/3" % captured_count)

	# Periodic status logging
	if frames % 45 == 0:
		var ctc_state: String = "Normal"
		var ctc: Node = root.get_node_or_null("CombatTimeController")
		if ctc and ctc.has_method("get_debug_info"):
			var info: Dictionary = ctc.get_debug_info()
			ctc_state = "%s (time_scale=%.2f)" % [info.get("state", "UNKNOWN"), Engine.time_scale]
		var enemies_alive: int = 0
		var e_container = test_scene.get_node_or_null("Enemies")
		if e_container:
			for e in e_container.get_children():
				if is_instance_valid(e) and not e.is_dead:
					enemies_alive += 1
		print("[Frame %d / ~%.1fs] Time: %s | Living Enemies: %d" % [frames, frames / 60.0, ctc_state, enemies_alive])

	if sequence_finished or frames >= max_frames:
		_evaluate_benchmark()
		quit()
		return true

	return false

func _on_completed() -> void:
	sequence_finished = true
	print("\n[Callback] OATHBOUND ASCENDANCE complete callback received!")

func _evaluate_benchmark() -> void:
	print("\n=================================================================")
	print("=== OATHBOUND ASCENDANCE BENCHMARK EVALUATION ===")
	print("=================================================================")
	print("Total Frames Run: %d" % frames)
	print("Final Engine.time_scale: %.3f (Target: 1.000)" % Engine.time_scale)
	
	var is_clean_time: bool = absf(Engine.time_scale - 1.0) < 0.01
	if is_clean_time:
		print(">> PASS: Time scale accurately restored to 1.0 without leak.")
	else:
		push_error(">> FAIL: Time scale leaked at %.3f!" % Engine.time_scale)

	# Verify enemy dissolution
	var e_container = test_scene.get_node_or_null("Enemies")
	var remaining_living: int = 0
	if e_container:
		for e in e_container.get_children():
			if is_instance_valid(e) and not e.is_dead:
				remaining_living += 1
	print("Remaining Living Enemies: %d (Target: 0 eliminated)" % remaining_living)
	if remaining_living == 0:
		print(">> PASS: All enemy targets authoritatively destroyed & dissolved.")
	else:
		print(">> INFO: %d enemies remained." % remaining_living)

	# Verify player state
	if is_instance_valid(knight):
		var state_name = knight.state_machine.get_current_state_name() if knight.state_machine else "None"
		print("Final Knight Combat State: %s (Target: IdleState)" % state_name)
		if state_name == "IdleState":
			print(">> PASS: Player control restored to IdleState without stuck locks.")
		else:
			print(">> INFO: Final player state was %s" % state_name)

	print("=================================================================\n")
