class_name QualityTierTest
extends Node

const GraphicsSettings = preload("res://scripts/graphics_settings.gd")

## QualityTierTest — Phase 8/9 Quality Tier Comparison Tool.
## Hotkeys to instantly switch quality presets during gameplay
## for visual A/B comparison and profiling.
##
## Hotkeys:
##   F5 = LOW    F6 = MEDIUM    F7 = HIGH    F8 = ULTRA
##   F9 = Run automated profile benchmark
##   F10 = Toggle detailed stats overlay

var _benchmark: UltimateProfileBenchmark = null
var _toast_label: Label = null
var _toast_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Create floating toast label for preset feedback
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 125
	add_child(canvas)

	_toast_label = Label.new()
	_toast_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toast_label.position = Vector2(-320, 40)
	_toast_label.size = Vector2(300, 60)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_toast_label.add_theme_font_size_override("font_size", 20)
	_toast_label.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	_toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_toast_label.add_theme_constant_override("shadow_offset_x", 2)
	_toast_label.add_theme_constant_override("shadow_offset_y", 2)
	_toast_label.modulate.a = 0.0
	canvas.add_child(_toast_label)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_F5:
			_switch_preset(GraphicsSettings.QualityPreset.LOW)
		KEY_F6:
			_switch_preset(GraphicsSettings.QualityPreset.MEDIUM)
		KEY_F7:
			_switch_preset(GraphicsSettings.QualityPreset.HIGH)
		KEY_F8:
			_switch_preset(GraphicsSettings.QualityPreset.ULTRA)
		KEY_F9:
			_run_benchmark()
		KEY_F10:
			_toggle_detailed_stats()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.5:
			_toast_label.modulate.a = maxf(0.0, _toast_timer / 0.5)
		if _toast_timer <= 0.0:
			_toast_label.modulate.a = 0.0


func _switch_preset(preset: GraphicsSettings.QualityPreset) -> void:
	GraphicsSettings.apply_preset(preset)
	var name: String = GraphicsSettings.preset_name(preset)
	_show_toast("Quality: %s" % name)
	print("[QualityTier] Switched to %s" % name)


func _run_benchmark() -> void:
	if _benchmark:
		_show_toast("Benchmark already running...")
		return

	_show_toast("Starting benchmark...")
	_benchmark = UltimateProfileBenchmark.new()
	add_child(_benchmark)
	_benchmark.benchmark_complete.connect(func(results: Dictionary):
		_show_toast("Benchmark complete! See console.")
		if _benchmark:
			_benchmark.queue_free()
			_benchmark = null
	)
	_benchmark.run_benchmark()


func _toggle_detailed_stats() -> void:
	# Toggle the performance overlay
	var overlay = get_tree().root.find_child("PerformanceOverlay", true, false)
	if overlay:
		overlay.visible = not overlay.visible
		_show_toast("Stats: %s" % ("ON" if overlay.visible else "OFF"))
	else:
		_show_toast("No PerformanceOverlay found")


func _show_toast(message: String) -> void:
	if _toast_label:
		_toast_label.text = message
		_toast_label.modulate.a = 1.0
		_toast_timer = 2.5
