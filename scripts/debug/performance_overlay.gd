extends CanvasLayer

## PerformanceOverlay — Antigravity Debug Harness for OATHBOUND
## Toggled via F3. Monitored metrics: FPS, Frame Time, Draw Calls, VRAM, Object Count.

@onready var panel: PanelContainer = $PanelContainer
@onready var stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsLabel
@onready var status_indicator: ColorRect = $PanelContainer/MarginContainer/VBoxContainer/Header/StatusIndicator

var update_interval: float = 0.1
var time_since_last_update: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	visible = true # Visible by default during development for immediate feedback

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			visible = not visible
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible:
		return

	time_since_last_update += delta
	if time_since_last_update < update_interval:
		return

	time_since_last_update = 0.0
	_update_metrics()

func _update_metrics() -> void:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var process_time_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_time_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var video_mem_bytes: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var video_mem_mb: float = video_mem_bytes / (1024.0 * 1024.0)
	var objects: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	# Color code FPS health (40 FPS is hard project floor)
	if fps >= 55.0:
		status_indicator.color = Color(0.2, 0.9, 0.3, 1.0) # Green
	elif fps >= 40.0:
		status_indicator.color = Color(0.9, 0.8, 0.2, 1.0) # Yellow (acceptable)
	else:
		status_indicator.color = Color(0.95, 0.2, 0.2, 1.0) # Red (regression / below floor)

	var text: String = ""
	var cur_preset_name: String = GraphicsSettings.preset_name(GraphicsSettings.ultimate_quality)
	text += "FPS: %d (%.1f ms)\n" % [int(fps), process_time_ms]
	text += "Graphics: %s [F5-F8]\n" % [cur_preset_name.to_upper()]
	text += "Physics: %.1f ms\n" % [physics_time_ms]
	text += "Draw Calls: %d\n" % [draw_calls]
	text += "Primitives: %d\n" % [primitives]
	text += "VRAM: %.1f MB\n" % [video_mem_mb]
	text += "Objects / Nodes: %d / %d\n" % [objects, nodes]
	text += "Target: 40+ FPS | [F2] Settings"

	stats_label.text = text
