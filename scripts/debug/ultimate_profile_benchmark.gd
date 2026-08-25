class_name UltimateProfileBenchmark
extends Node

const GraphicsSettings = preload("res://scripts/graphics_settings.gd")

## UltimateProfileBenchmark — Phase 8 Cinematic Profiling Harness.
## Captures frame-by-frame performance data during the Ultimate cinematic
## across all quality presets (ULTRA/HIGH/MEDIUM/LOW).
##
## Usage: Add as autoload or attach to a test scene.
##   1. Ensure solo_arena scene is loaded with at least 3 enemies.
##   2. Call run_benchmark() — triggers Ultimate and captures data.
##   3. Results written to user://ultimate_profile_results.json
##
## Captures per frame during the Ultimate:
##   - FPS, frame_time_ms, draw_calls, primitives, vram_mb
##   - Phase (which Ultimate phase is active)
##   - Sequence time

const SAMPLE_INTERVAL: float = 0.05  # 20 samples/sec
const REPORT_PATH: String = "user://ultimate_profile_results.json"

var _is_profiling: bool = false
var _current_preset: GraphicsSettings.QualityPreset = GraphicsSettings.QualityPreset.HIGH
var _presets_to_test: Array[GraphicsSettings.QualityPreset] = []
var _preset_index: int = 0
var _samples: Array[Dictionary] = []
var _all_results: Dictionary = {}
var _sample_timer: float = 0.0
var _benchmark_start_time: float = 0.0
var _knight: Node = null
var _cinematic_active: bool = false

signal benchmark_complete(results: Dictionary)


func _ready() -> void:
	set_process(false)


## Run full benchmark across all quality presets.
## Knight must be in the scene and have ultimate ability available.
func run_benchmark(knight_node: Node = null) -> void:
	if _is_profiling:
		print("[ProfileBenchmark] Already running.")
		return

	_knight = knight_node
	if not _knight:
		# Try to find knight in scene
		_knight = get_tree().root.find_child("Knight", true, false)
	if not _knight:
		push_error("[ProfileBenchmark] No Knight found in scene. Cannot benchmark.")
		return

	_all_results = {}
	_presets_to_test = [
		GraphicsSettings.QualityPreset.LOW,
		GraphicsSettings.QualityPreset.MEDIUM,
		GraphicsSettings.QualityPreset.HIGH,
		GraphicsSettings.QualityPreset.ULTRA,
	]
	_preset_index = 0
	_is_profiling = true

	print("[ProfileBenchmark] Starting benchmark across %d presets..." % _presets_to_test.size())
	_run_next_preset()


func _run_next_preset() -> void:
	if _preset_index >= _presets_to_test.size():
		_finish_benchmark()
		return

	_current_preset = _presets_to_test[_preset_index]
	var preset_name: String = GraphicsSettings.preset_name(_current_preset)
	print("[ProfileBenchmark] === Testing %s ===" % preset_name)

	# Apply preset
	GraphicsSettings.apply_preset(_current_preset)

	# Wait 2 frames for settings to propagate
	await get_tree().process_frame
	await get_tree().process_frame

	_samples = []
	_sample_timer = 0.0
	_benchmark_start_time = Time.get_ticks_msec() / 1000.0
	_cinematic_active = true
	set_process(true)

	# Trigger the Ultimate
	if _knight.has_method("trigger_ultimate_ability"):
		_knight.trigger_ultimate_ability()
	elif _knight.has_method("_execute_ultimate"):
		_knight._execute_ultimate()
	else:
		push_error("[ProfileBenchmark] Knight has no ultimate trigger method.")
		_cinematic_active = false
		set_process(false)
		return

	# Wait for cinematic to complete (max 65s timeout)
	var timeout: float = 0.0
	while _cinematic_active and timeout < 65.0:
		await get_tree().create_timer(0.5).timeout
		timeout += 0.5

		# Check if Ultimate Director still exists
		var director = get_tree().root.find_child("UltimateCinematicDirector", true, false)
		if not director and timeout > 5.0:
			_cinematic_active = false

	set_process(false)
	_store_preset_results()
	_preset_index += 1

	# Cooldown between presets
	print("[ProfileBenchmark] Cooldown (3s)...")
	await get_tree().create_timer(3.0).timeout
	_run_next_preset()


func _process(delta: float) -> void:
	if not _cinematic_active:
		return

	_sample_timer += delta
	if _sample_timer < SAMPLE_INTERVAL:
		return
	_sample_timer = 0.0

	var sample: Dictionary = {
		"time": Time.get_ticks_msec() / 1000.0 - _benchmark_start_time,
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"frame_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	}
	_samples.append(sample)


func _store_preset_results() -> void:
	var preset_name: String = GraphicsSettings.preset_name(_current_preset)
	var total_samples: int = _samples.size()

	if total_samples == 0:
		print("[ProfileBenchmark] WARNING: No samples collected for %s" % preset_name)
		_all_results[preset_name] = {"error": "no_samples"}
		return

	# Compute statistics
	var fps_values: Array[float] = []
	var draw_call_values: Array[int] = []
	var vram_values: Array[float] = []
	var min_fps: float = 999.0
	var max_fps: float = 0.0
	var total_fps: float = 0.0
	var max_draw_calls: int = 0
	var max_vram: float = 0.0
	var frames_below_40: int = 0
	var frames_below_30: int = 0

	for s in _samples:
		var fps: float = s["fps"]
		fps_values.append(fps)
		total_fps += fps
		min_fps = minf(min_fps, fps)
		max_fps = maxf(max_fps, fps)
		if fps < 40.0:
			frames_below_40 += 1
		if fps < 30.0:
			frames_below_30 += 1

		var dc: int = s["draw_calls"]
		draw_call_values.append(dc)
		max_draw_calls = maxi(max_draw_calls, dc)

		var vm: float = s["vram_mb"]
		vram_values.append(vm)
		max_vram = maxf(max_vram, vm)

	var avg_fps: float = total_fps / float(total_samples)

	# 1% low FPS (worst 1% of frames)
	fps_values.sort()
	var p1_index: int = maxi(0, int(float(total_samples) * 0.01))
	var p1_low_fps: float = fps_values[p1_index]

	# 5% low FPS
	var p5_index: int = maxi(0, int(float(total_samples) * 0.05))
	var p5_low_fps: float = fps_values[p5_index]

	var result: Dictionary = {
		"preset": preset_name,
		"quality_int": int(_current_preset),
		"total_samples": total_samples,
		"duration_s": _samples[-1]["time"] if total_samples > 0 else 0.0,
		"avg_fps": snapped(avg_fps, 0.1),
		"min_fps": snapped(min_fps, 0.1),
		"max_fps": snapped(max_fps, 0.1),
		"p1_low_fps": snapped(p1_low_fps, 0.1),
		"p5_low_fps": snapped(p5_low_fps, 0.1),
		"frames_below_40": frames_below_40,
		"frames_below_30": frames_below_30,
		"pct_below_40": snapped(float(frames_below_40) / float(total_samples) * 100.0, 0.1),
		"max_draw_calls": max_draw_calls,
		"max_vram_mb": snapped(max_vram, 0.1),
		"samples": _samples,
	}

	_all_results[preset_name] = result

	# Print summary
	var meets_floor: String = "✅ PASS" if min_fps >= 40.0 else "❌ FAIL (min %.1f)" % min_fps
	print("[ProfileBenchmark] %s: avg=%.1f fps, min=%.1f, 1%%low=%.1f, draws=%d, vram=%.1fMB — %s" % [
		preset_name, avg_fps, min_fps, p1_low_fps, max_draw_calls, max_vram, meets_floor
	])


func _finish_benchmark() -> void:
	_is_profiling = false

	# Build summary comparison table
	var summary: Dictionary = {
		"benchmark_date": Time.get_datetime_string_from_system(),
		"hardware": _detect_hardware_string(),
		"presets": _all_results,
		"recommendation": _generate_recommendation(),
	}

	# Write JSON report
	var json_string: String = JSON.stringify(summary, "\t")
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[ProfileBenchmark] Results written to %s" % REPORT_PATH)
	else:
		push_error("[ProfileBenchmark] Failed to write results file.")

	# Print comparison table
	print("")
	print("╔═══════════════════════════════════════════════════════════╗")
	print("║        ULTIMATE CINEMATIC BENCHMARK RESULTS              ║")
	print("╠═══════════╦═══════╦═══════╦═══════╦════════╦═════════════╣")
	print("║ Preset    ║ Avg   ║ Min   ║ 1%low ║ Draws  ║ Status      ║")
	print("╠═══════════╬═══════╬═══════╬═══════╬════════╬═════════════╣")
	for key in ["Low", "Medium", "High", "Ultra"]:
		if _all_results.has(key):
			var r: Dictionary = _all_results[key]
			if r.has("error"):
				print("║ %-9s ║ ERROR ║       ║       ║        ║             ║" % key)
			else:
				var status: String = "PASS" if r["min_fps"] >= 40.0 else "FAIL"
				print("║ %-9s ║ %5.1f ║ %5.1f ║ %5.1f ║ %6d ║ %-11s ║" % [
					key, r["avg_fps"], r["min_fps"], r["p1_low_fps"], r["max_draw_calls"], status
				])
	print("╚═══════════╩═══════╩═══════╩═══════╩════════╩═════════════╝")
	print("")

	benchmark_complete.emit(summary)


func _detect_hardware_string() -> String:
	var gpu: String = RenderingServer.get_video_adapter_name()
	var renderer: String = RenderingServer.get_video_adapter_api_version()
	return "%s (%s)" % [gpu, renderer]


func _generate_recommendation() -> String:
	# Find the highest preset that maintains 40+ FPS floor
	var best_preset: String = "Low"
	for key in ["Low", "Medium", "High", "Ultra"]:
		if _all_results.has(key) and not _all_results[key].has("error"):
			if _all_results[key]["min_fps"] >= 40.0:
				best_preset = key
	return "Recommended preset for this hardware: %s" % best_preset
