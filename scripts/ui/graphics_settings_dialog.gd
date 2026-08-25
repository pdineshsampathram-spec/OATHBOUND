class_name GraphicsSettingsDialog
extends CanvasLayer

## GraphicsSettingsDialog — In-Game & Lobby Graphics Options Modal
## Allows real-time switching of graphics presets (LOW, MEDIUM, HIGH, ULTRA),
## custom fine-tuning of shadows/bloom/particles/MSAA, and hardware detection.

@onready var panel: Panel = $Control/Panel
@onready var preset_low_btn: Button = $Control/Panel/VBoxContainer/PresetRow/LowButton
@onready var preset_med_btn: Button = $Control/Panel/VBoxContainer/PresetRow/MedButton
@onready var preset_high_btn: Button = $Control/Panel/VBoxContainer/PresetRow/HighButton
@onready var preset_ultra_btn: Button = $Control/Panel/VBoxContainer/PresetRow/UltraButton

@onready var recommendation_label: Label = $Control/Panel/VBoxContainer/RecommendationLabel

@onready var shadow_opt: OptionButton = $Control/Panel/VBoxContainer/GridContainer/ShadowOpt
@onready var msaa_opt: OptionButton = $Control/Panel/VBoxContainer/GridContainer/MsaaOpt
@onready var res_scale_opt: OptionButton = $Control/Panel/VBoxContainer/GridContainer/ResScaleOpt
@onready var debris_opt: OptionButton = $Control/Panel/VBoxContainer/GridContainer/DebrisOpt

@onready var bloom_check: CheckBox = $Control/Panel/VBoxContainer/TogglesRow/BloomCheck
@onready var distortion_check: CheckBox = $Control/Panel/VBoxContainer/TogglesRow/DistortionCheck

@onready var vfx_slider: HSlider = $Control/Panel/VBoxContainer/VfxRow/VfxSlider
@onready var vfx_val_label: Label = $Control/Panel/VBoxContainer/VfxRow/VfxValLabel

@onready var apply_btn: Button = $Control/Panel/VBoxContainer/BottomRow/ApplyButton
@onready var reset_btn: Button = $Control/Panel/VBoxContainer/BottomRow/ResetButton
@onready var close_btn: Button = $Control/Panel/VBoxContainer/BottomRow/CloseButton
@onready var close_x_btn: Button = $Control/Panel/HeaderRow/CloseXButton

var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_setup_options()
	_connect_signals()
	_update_ui_from_current_settings()

func _setup_options() -> void:
	if shadow_opt:
		shadow_opt.clear()
		shadow_opt.add_item("Low (512)", 0)
		shadow_opt.add_item("Medium (1024)", 1)
		shadow_opt.add_item("High (2048)", 2)
		shadow_opt.add_item("Ultra (4096)", 3)

	if msaa_opt:
		msaa_opt.clear()
		msaa_opt.add_item("Disabled", 0)
		msaa_opt.add_item("2x MSAA", 1)
		msaa_opt.add_item("4x MSAA", 2)

	if res_scale_opt:
		res_scale_opt.clear()
		res_scale_opt.add_item("100% (Native Sharp)", 0)
		res_scale_opt.add_item("85% (Balanced)", 1)
		res_scale_opt.add_item("75% (Max Performance)", 2)

	if debris_opt:
		debris_opt.clear()
		debris_opt.add_item("Low (Minimal)", 0)
		debris_opt.add_item("Medium (Moderate)", 1)
		debris_opt.add_item("High (Full Floating Arena)", 2)
		debris_opt.add_item("Ultra (Maximum Detail)", 3)

	if recommendation_label:
		var hw_name: String = OS.get_name()
		if hw_name == "macOS":
			recommendation_label.text = "💡 Apple M1 Detected: HIGH preset recommended for locked 60 FPS (V-Sync Forward+)."
		else:
			recommendation_label.text = "💡 Recommended: HIGH preset for optimal 60 FPS balance."

func _connect_signals() -> void:
	if preset_low_btn:
		preset_low_btn.pressed.connect(func(): _on_preset_selected(GraphicsSettings.QualityPreset.LOW))
	if preset_med_btn:
		preset_med_btn.pressed.connect(func(): _on_preset_selected(GraphicsSettings.QualityPreset.MEDIUM))
	if preset_high_btn:
		preset_high_btn.pressed.connect(func(): _on_preset_selected(GraphicsSettings.QualityPreset.HIGH))
	if preset_ultra_btn:
		preset_ultra_btn.pressed.connect(func(): _on_preset_selected(GraphicsSettings.QualityPreset.ULTRA))

	if vfx_slider:
		vfx_slider.value_changed.connect(_on_vfx_slider_changed)

	if apply_btn:
		apply_btn.pressed.connect(_on_apply_pressed)
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
	if close_btn:
		close_btn.pressed.connect(close_dialog)
	if close_x_btn:
		close_x_btn.pressed.connect(close_dialog)

	if GraphicsSettings._instance:
		GraphicsSettings._instance.quality_changed.connect(_on_quality_changed_external)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_F2:
			close_dialog()
			get_viewport().set_input_as_handled()

func open_dialog() -> void:
	_previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_ui_from_current_settings()
	visible = true

func close_dialog() -> void:
	visible = false
	if _previous_mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_dialog() -> void:
	if visible:
		close_dialog()
	else:
		open_dialog()

func _on_preset_selected(preset: GraphicsSettings.QualityPreset) -> void:
	GraphicsSettings.apply_preset(preset)
	_update_ui_from_current_settings()
	_show_feedback("Preset '%s' applied." % GraphicsSettings.preset_name(preset))

func _on_vfx_slider_changed(value: float) -> void:
	if vfx_val_label:
		vfx_val_label.text = "%d%%" % int(value * 100.0)

func _on_apply_pressed() -> void:
	# Custom overrides
	if shadow_opt:
		GraphicsSettings.shadow_quality = shadow_opt.selected as GraphicsSettings.QualityPreset
	if msaa_opt:
		match msaa_opt.selected:
			0: GraphicsSettings.post_processing_quality = GraphicsSettings.QualityPreset.LOW
			1: GraphicsSettings.post_processing_quality = GraphicsSettings.QualityPreset.HIGH
			2: GraphicsSettings.post_processing_quality = GraphicsSettings.QualityPreset.ULTRA
	if res_scale_opt:
		match res_scale_opt.selected:
			0: GraphicsSettings.cinematic_resolution_scale = 1.0
			1: GraphicsSettings.cinematic_resolution_scale = 0.85
			2: GraphicsSettings.cinematic_resolution_scale = 0.75
	if debris_opt:
		GraphicsSettings.debris_quality = debris_opt.selected as GraphicsSettings.QualityPreset
	if bloom_check:
		GraphicsSettings.bloom_enabled = bloom_check.button_pressed
	if distortion_check:
		GraphicsSettings.distortion_enabled = distortion_check.button_pressed
	if vfx_slider:
		GraphicsSettings.vfx_density = vfx_slider.value
		GraphicsSettings.particle_count_multiplier = vfx_slider.value

	GraphicsSettings._apply_engine_settings()
	GraphicsSettings.save_to_config()
	close_dialog()

func _on_reset_pressed() -> void:
	GraphicsSettings.apply_preset(GraphicsSettings.QualityPreset.HIGH)
	_update_ui_from_current_settings()
	_show_feedback("Reset to HIGH (Apple M1 Target).")

func _on_quality_changed_external(_preset: GraphicsSettings.QualityPreset) -> void:
	if visible:
		_update_ui_from_current_settings()

func _update_ui_from_current_settings() -> void:
	var cur: GraphicsSettings.QualityPreset = GraphicsSettings.ultimate_quality

	# Highlight active preset button
	_set_preset_button_active(preset_low_btn, cur == GraphicsSettings.QualityPreset.LOW)
	_set_preset_button_active(preset_med_btn, cur == GraphicsSettings.QualityPreset.MEDIUM)
	_set_preset_button_active(preset_high_btn, cur == GraphicsSettings.QualityPreset.HIGH)
	_set_preset_button_active(preset_ultra_btn, cur == GraphicsSettings.QualityPreset.ULTRA)

	if shadow_opt:
		shadow_opt.select(clampi(int(GraphicsSettings.shadow_quality), 0, 3))

	if msaa_opt:
		match GraphicsSettings.post_processing_quality:
			GraphicsSettings.QualityPreset.ULTRA: msaa_opt.select(2)
			GraphicsSettings.QualityPreset.HIGH: msaa_opt.select(1)
			_: msaa_opt.select(0)

	if res_scale_opt:
		if GraphicsSettings.cinematic_resolution_scale >= 0.95:
			res_scale_opt.select(0)
		elif GraphicsSettings.cinematic_resolution_scale >= 0.80:
			res_scale_opt.select(1)
		else:
			res_scale_opt.select(2)

	if debris_opt:
		debris_opt.select(clampi(int(GraphicsSettings.debris_quality), 0, 3))

	if bloom_check:
		bloom_check.button_pressed = GraphicsSettings.bloom_enabled
	if distortion_check:
		distortion_check.button_pressed = GraphicsSettings.distortion_enabled

	if vfx_slider:
		vfx_slider.value = GraphicsSettings.vfx_density
	if vfx_val_label:
		vfx_val_label.text = "%d%%" % int(GraphicsSettings.vfx_density * 100.0)

func _set_preset_button_active(btn: Button, active: bool) -> void:
	if not btn:
		return
	if active:
		btn.modulate = Color(1.0, 0.9, 0.4, 1.0)
		btn.text = "✓ " + btn.text.replace("✓ ", "")
	else:
		btn.modulate = Color(0.75, 0.75, 0.75, 0.85)
		btn.text = btn.text.replace("✓ ", "")

func _show_feedback(msg: String) -> void:
	if recommendation_label:
		recommendation_label.text = "✓ " + msg
		var tween = create_tween()
		tween.tween_interval(2.0)
		tween.tween_callback(func():
			if is_instance_valid(self) and recommendation_label:
				recommendation_label.text = "💡 Apple M1 Detected: HIGH preset recommended for locked 60 FPS."
		)
