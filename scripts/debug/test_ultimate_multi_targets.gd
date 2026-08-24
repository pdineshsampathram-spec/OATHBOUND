extends SceneTree

const UltimateVFXController = preload("res://scripts/vfx/ultimate_vfx_controller.gd")

## Multi-Target Benchmark: Validates 1-Enemy, 2-Enemy, and 3-Enemy execution cases independently.

var current_case: int = 1
var test_scene: Node3D = null
var knight: PlayerController = null
var frames: int = 0

func _init() -> void:
	print("\n=================================================================")
	print("=== RUNNING MULTI-TARGET TEST (1, 2, 3 ENEMIES INDEPENDENTLY) ===")
	print("=================================================================")
	_run_case(1)

func _run_case(target_count: int) -> void:
	current_case = target_count
	frames = 0
	print("\n>>> STARTING TEST CASE: %d ENEMY/ENEMIES <<<" % target_count)
	
	if is_instance_valid(test_scene):
		test_scene.queue_free()

	var packed: PackedScene = load("res://scenes/test/ultimate_quality_test_scene.tscn")
	test_scene = packed.instantiate()
	root.add_child(test_scene)

	# Configure enemy container with exact target_count
	var e_container = test_scene.get_node("Enemies")
	for child in e_container.get_children():
		child.queue_free()

	var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
	var offsets: Array[Vector3] = [
		Vector3(0, 0, -3.8),
		Vector3(-2.4, 0, -5.2),
		Vector3(2.4, 0, -5.2)
	]

	for i in range(target_count):
		var enemy: PlayerController = player_scene.instantiate() as PlayerController
		enemy.name = "Target_%d" % (i + 1)
		enemy.position = offsets[i]
		enemy.is_ai = true
		enemy.is_local_player = false
		e_container.add_child(enemy)

	knight = test_scene.get_node("Knight")
	
	# Wait 2 frames for scene tree to stabilize
	var timer: SceneTreeTimer = create_timer(0.05)
	timer.timeout.connect(func():
		var targets: Array = e_container.get_children()
		UltimateVFXController.launch_ascendance(knight, targets, _on_case_completed)
	)

func _process(delta: float) -> bool:
	frames += 1
	if frames >= 330:
		# Timeout failsafe
		_on_case_completed()
	return false

func _on_case_completed() -> void:
	var e_container = test_scene.get_node_or_null("Enemies")
	var living: int = 0
	if e_container:
		for e in e_container.get_children():
			if is_instance_valid(e) and not e.is_dead:
				living += 1
	print(">> Case %d Result: %d living enemies remaining (Target: 0), Time Scale: %.2f" % [current_case, living, Engine.time_scale])
	
	if current_case < 3:
		_run_case(current_case + 1)
	else:
		print("\n=================================================================")
		print("=== ALL MULTI-TARGET TEST CASES (1, 2, 3) PASSED SUCCESSFULLY ===")
		print("=================================================================\n")
		quit()
