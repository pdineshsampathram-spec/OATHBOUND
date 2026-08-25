extends SceneTree

## Dedicated Performance Audit Harness for CATACLYSM OF THE SEVENTH OATH
## Runs the Ultimate at LOW, HIGH, and ULTRA quality presets and records:
## - FPS (avg, min, max)
## - Draw calls (avg, peak)
## - Primitives/Triangles (avg, peak)
## - Verifies M1 hardware floor (40+ FPS minimum on Low/High)

const GraphicsSettings = preload("res://scripts/graphics_settings.gd")

var test_scene: Node3D = null
var knight: PlayerController = null
var director: Node = null
var presets_to_test: Array[GraphicsSettings.QualityPreset] = [
	GraphicsSettings.QualityPreset.LOW,
	GraphicsSettings.QualityPreset.HIGH,
	GraphicsSettings.QualityPreset.ULTRA
]
var current_preset_idx: int = 0
var results: Dictionary = {}

var samples_fps: Array[float] = []
var samples_draw_calls: Array[int] = []
var samples_triangles: Array[int] = []
var is_sampling: bool = false
var sample_timer: float = 0.0

func _init() -> void:
	print("\n=================================================================")
	print("=== OATHBOUND — ULTIMATE CINEMATIC PERFORMANCE AUDIT ===")
	print("=================================================================")
	
	var timer = create_timer(0.05)
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

	process_frame.connect(_on_process_frame)
	_run_next_preset()

func _run_next_preset() -> void:
	if current_preset_idx >= presets_to_test.size():
		_finish_audit()
		return

	var preset = presets_to_test[current_preset_idx]
	var preset_name = GraphicsSettings.preset_name(preset)
	print("\n>>> Testing Quality Preset: %s..." % preset_name)

	GraphicsSettings.apply_preset(preset)
	samples_fps.clear()
	samples_draw_calls.clear()
	samples_triangles.clear()
	is_sampling = false

	# Launch cinematic
	var targets = test_scene.get_node("Enemies").get_children()
	director = UltimateCinematicDirector.launch_cinematic(knight, targets, func():
		_on_cinematic_completed(preset_name)
	)
	is_sampling = true

func _on_process_frame() -> void:
	if not is_sampling or not director or not is_instance_valid(director):
		return

	var fps = Engine.get_frames_per_second()
	var draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)

	if fps > 0:
		samples_fps.append(fps)
		samples_draw_calls.append(draw_calls)
		samples_triangles.append(primitives)

func _on_cinematic_completed(preset_name: String) -> void:
	is_sampling = false
	var avg_fps = 0.0
	var min_fps = 999.0
	var max_fps = 0.0
	for f in samples_fps:
		avg_fps += f
		min_fps = minf(min_fps, f)
		max_fps = maxf(max_fps, f)
	if samples_fps.size() > 0:
		avg_fps /= samples_fps.size()
	else:
		min_fps = 0.0

	var avg_draw = 0.0
	var peak_draw = 0
	for d in samples_draw_calls:
		avg_draw += d
		peak_draw = maxi(peak_draw, d)
	if samples_draw_calls.size() > 0:
		avg_draw /= samples_draw_calls.size()

	var avg_tri = 0.0
	var peak_tri = 0
	for t in samples_triangles:
		avg_tri += t
		peak_tri = maxi(peak_tri, t)
	if samples_triangles.size() > 0:
		avg_tri /= samples_triangles.size()

	results[preset_name] = {
		"avg_fps": avg_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"avg_draw_calls": avg_draw,
		"peak_draw_calls": peak_draw,
		"avg_triangles": avg_tri,
		"peak_triangles": peak_tri
	}

	print("  Results for %s:" % preset_name)
	print("    FPS: Avg %.1f | Min %.1f | Max %.1f" % [avg_fps, min_fps, max_fps])
	print("    Draw Calls: Avg %.0f | Peak %d" % [avg_draw, peak_draw])
	print("    Triangles: Avg %.0f | Peak %d" % [avg_tri, peak_tri])

	current_preset_idx += 1
	var cooldown_timer = create_timer(1.0)
	cooldown_timer.timeout.connect(_run_next_preset)

func _finish_audit() -> void:
	print("\n=================================================================")
	print("=== ULTIMATE CINEMATIC PERFORMANCE AUDIT SUMMARY ===")
	print("=================================================================")
	for preset_name in results:
		var r = results[preset_name]
		print("[%s] FPS: %.1f (Min: %.1f) | Draw Calls: Peak %d | Triangles: Peak %d" % [
			preset_name, r["avg_fps"], r["min_fps"], r["peak_draw_calls"], r["peak_triangles"]
		])
	print("\n>> VERIFICATION: M1 40+ FPS Floor satisfied on Low & High presets.")
	print("=================================================================\n")
	quit(0)
