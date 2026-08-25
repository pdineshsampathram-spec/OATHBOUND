class_name GraphicsSettings
extends Node

## GraphicsSettings — Runtime Quality Preset Manager for OATHBOUND.
## Global static manager handling ULTRA/HIGH/MEDIUM/LOW quality presets.
## All VFX, particle, shader, and cinematic systems query this for quality decisions.
##
## Hard rules:
## - Knight animation, sword motion, enemy acting, camera choreography,
##   shockwave timing, vaporization, and damage are IDENTICAL across all presets.
## - Only visual density and expensive rendering features scale.

enum QualityPreset { LOW = 0, MEDIUM = 1, HIGH = 2, ULTRA = 3 }

const CONFIG_PATH: String = "user://graphics_settings.cfg"

## Master quality preset
static var ultimate_quality: QualityPreset = QualityPreset.HIGH

## Per-feature controls (driven by preset, but individually overridable)
static var vfx_density: float = 0.75
static var particle_quality: QualityPreset = QualityPreset.HIGH
static var particle_count_multiplier: float = 0.7
static var atmosphere_quality: QualityPreset = QualityPreset.HIGH
static var sky_quality: QualityPreset = QualityPreset.HIGH
static var volumetric_quality: QualityPreset = QualityPreset.HIGH
static var shadow_quality: QualityPreset = QualityPreset.HIGH
static var bloom_enabled: bool = true
static var distortion_enabled: bool = true
static var debris_quality: QualityPreset = QualityPreset.HIGH
static var texture_quality: QualityPreset = QualityPreset.HIGH
static var cinematic_resolution_scale: float = 1.0
static var post_processing_quality: QualityPreset = QualityPreset.HIGH

static var _instance: GraphicsSettings = null

signal quality_changed(new_preset: QualityPreset)

var _dialog_instance: Node = null
var _toast_layer: CanvasLayer = null
var _toast_label: Label = null
var _toast_panel: PanelContainer = null
var _toast_timer: float = 0.0

const DIALOG_SCENE_PATH: String = "res://scenes/ui/graphics_settings_dialog.tscn"


func _init() -> void:
	_instance = self
	load_from_config()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_toast_ui()


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_panel:
			_toast_panel.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F5:
				apply_preset(QualityPreset.LOW)
				show_toast("⚡ Graphics: LOW (Fastest Performance)")
				get_viewport().set_input_as_handled()
			KEY_F6:
				apply_preset(QualityPreset.MEDIUM)
				show_toast("⚡ Graphics: MEDIUM (Balanced)")
				get_viewport().set_input_as_handled()
			KEY_F7:
				apply_preset(QualityPreset.HIGH)
				show_toast("⚡ Graphics: HIGH (Apple M1 Target — 60 FPS)")
				get_viewport().set_input_as_handled()
			KEY_F8:
				apply_preset(QualityPreset.ULTRA)
				show_toast("⚡ Graphics: ULTRA (Cinematic Visual Benchmark)")
				get_viewport().set_input_as_handled()
			KEY_F2:
				toggle_settings_dialog()
				get_viewport().set_input_as_handled()


func _setup_toast_ui() -> void:
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 125
	_toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_toast_layer)

	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	_toast_panel.anchor_left = 1.0
	_toast_panel.anchor_right = 1.0
	_toast_panel.offset_left = -340.0
	_toast_panel.offset_top = 18.0
	_toast_panel.offset_right = -16.0
	_toast_panel.offset_bottom = 54.0
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.9, 0.75, 0.35, 0.9)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	_toast_panel.add_theme_stylebox_override("panel", sb)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_toast_panel.add_child(margin)

	_toast_label = Label.new()
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	_toast_label.add_theme_font_size_override("font_size", 13)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(_toast_label)

	_toast_layer.add_child(_toast_panel)


static func show_toast(msg: String, duration: float = 2.5) -> void:
	if not _instance or not _instance._toast_panel or not _instance._toast_label:
		return
	_instance._toast_label.text = msg
	_instance._toast_panel.visible = true
	_instance._toast_timer = duration


static func toggle_settings_dialog() -> void:
	if not _instance:
		return
	if not _instance._dialog_instance:
		if ResourceLoader.exists(DIALOG_SCENE_PATH):
			var scn: PackedScene = load(DIALOG_SCENE_PATH)
			if scn:
				_instance._dialog_instance = scn.instantiate()
				_instance.add_child(_instance._dialog_instance)
	if _instance._dialog_instance and _instance._dialog_instance.has_method("toggle_dialog"):
		_instance._dialog_instance.toggle_dialog()


static func open_settings_dialog() -> void:
	if not _instance:
		return
	if not _instance._dialog_instance:
		if ResourceLoader.exists(DIALOG_SCENE_PATH):
			var scn: PackedScene = load(DIALOG_SCENE_PATH)
			if scn:
				_instance._dialog_instance = scn.instantiate()
				_instance.add_child(_instance._dialog_instance)
	if _instance._dialog_instance and _instance._dialog_instance.has_method("open_dialog"):
		_instance._dialog_instance.open_dialog()


## Apply a full quality preset, setting all per-feature controls to matching values.
static func apply_preset(preset: QualityPreset) -> void:
	ultimate_quality = preset

	match preset:
		QualityPreset.ULTRA:
			vfx_density = 1.0
			particle_quality = QualityPreset.ULTRA
			particle_count_multiplier = 1.0
			atmosphere_quality = QualityPreset.ULTRA
			sky_quality = QualityPreset.ULTRA
			volumetric_quality = QualityPreset.ULTRA
			shadow_quality = QualityPreset.ULTRA
			bloom_enabled = true
			distortion_enabled = true
			debris_quality = QualityPreset.ULTRA
			texture_quality = QualityPreset.ULTRA
			cinematic_resolution_scale = 1.0
			post_processing_quality = QualityPreset.ULTRA

		QualityPreset.HIGH:
			vfx_density = 0.75
			particle_quality = QualityPreset.HIGH
			particle_count_multiplier = 0.7
			atmosphere_quality = QualityPreset.HIGH
			sky_quality = QualityPreset.HIGH
			volumetric_quality = QualityPreset.HIGH
			shadow_quality = QualityPreset.HIGH
			bloom_enabled = true
			distortion_enabled = true
			debris_quality = QualityPreset.HIGH
			texture_quality = QualityPreset.HIGH
			cinematic_resolution_scale = 1.0
			post_processing_quality = QualityPreset.HIGH

		QualityPreset.MEDIUM:
			vfx_density = 0.5
			particle_quality = QualityPreset.MEDIUM
			particle_count_multiplier = 0.45
			atmosphere_quality = QualityPreset.MEDIUM
			sky_quality = QualityPreset.MEDIUM
			volumetric_quality = QualityPreset.MEDIUM
			shadow_quality = QualityPreset.MEDIUM
			bloom_enabled = true
			distortion_enabled = false
			debris_quality = QualityPreset.MEDIUM
			texture_quality = QualityPreset.MEDIUM
			cinematic_resolution_scale = 0.85
			post_processing_quality = QualityPreset.MEDIUM

		QualityPreset.LOW:
			vfx_density = 0.3
			particle_quality = QualityPreset.LOW
			particle_count_multiplier = 0.25
			atmosphere_quality = QualityPreset.LOW
			sky_quality = QualityPreset.LOW
			volumetric_quality = QualityPreset.LOW
			shadow_quality = QualityPreset.LOW
			bloom_enabled = false
			distortion_enabled = false
			debris_quality = QualityPreset.LOW
			texture_quality = QualityPreset.LOW
			cinematic_resolution_scale = 0.75
			post_processing_quality = QualityPreset.LOW

	_apply_engine_settings()
	if _instance:
		_instance.quality_changed.emit(preset)
	save_to_config()


## Get a scaled particle count. Base count is the ULTRA amount.
static func get_scaled_particle_count(ultra_count: int) -> int:
	return maxi(1, int(float(ultra_count) * particle_count_multiplier))


## Returns true if the given quality level is at or above the current setting for a feature.
static func meets_quality(feature_quality: QualityPreset, minimum: QualityPreset) -> bool:
	return int(feature_quality) >= int(minimum)


## Get the quality level as an integer (0-3) for shader uniform usage.
static func get_quality_level_int() -> int:
	return int(ultimate_quality)


## Alias for get_quality_level_int() — shorter name for shader code.
static func get_quality_int() -> int:
	return int(ultimate_quality)


## Get mesh radial segments for procedural spheres/cylinders at current quality.
static func get_mesh_segments() -> int:
	match ultimate_quality:
		QualityPreset.ULTRA: return 48
		QualityPreset.HIGH: return 32
		QualityPreset.MEDIUM: return 16
		QualityPreset.LOW: return 12
	return 32


## Get mesh ring count for procedural spheres at current quality.
static func get_mesh_rings() -> int:
	match ultimate_quality:
		QualityPreset.ULTRA: return 24
		QualityPreset.HIGH: return 16
		QualityPreset.MEDIUM: return 8
		QualityPreset.LOW: return 6
	return 16


## Whether to enable cinematic enemy fear glow (emissive rim on enemies).
static func should_enable_fear_glow() -> bool:
	return int(ultimate_quality) >= int(QualityPreset.HIGH)


## Whether to enable cinematic atmosphere haze around Knight.
static func should_enable_atmosphere() -> bool:
	return int(ultimate_quality) >= int(QualityPreset.MEDIUM)


## Whether to enable the compression core visual during Phase 7-8.
static func should_enable_compression_core() -> bool:
	return int(ultimate_quality) >= int(QualityPreset.MEDIUM)


## Whether to enable the radial detonation hemisphere on release.
static func should_enable_radial_detonation() -> bool:
	return true  # Enabled at all tiers — it's the climax


## Maximum simultaneous GPU particle emitters during Ultimate.
static func get_max_cinematic_emitters() -> int:
	match ultimate_quality:
		QualityPreset.ULTRA: return 10
		QualityPreset.HIGH: return 8
		QualityPreset.MEDIUM: return 5
		QualityPreset.LOW: return 3
	return 8


## Get the appropriate asset path suffix for the current quality tier.
## Returns "" for ULTRA (use base asset), "_high", "_medium", or "_low" for others.
static func get_asset_quality_suffix() -> String:
	match ultimate_quality:
		QualityPreset.ULTRA:
			return ""
		QualityPreset.HIGH:
			return "_high"
		QualityPreset.MEDIUM:
			return "_medium"
		QualityPreset.LOW:
			return "_low"
	return ""


## Try to load the quality-appropriate variant of a Blender asset.
## Falls back to the base (ULTRA) asset if variant doesn't exist.
static func load_quality_asset(base_path: String) -> PackedScene:
	if ultimate_quality == QualityPreset.ULTRA:
		return load(base_path)

	# Try quality-specific variant
	var ext_pos: int = base_path.rfind(".")
	if ext_pos > 0:
		var variant_path: String = base_path.substr(0, ext_pos) + get_asset_quality_suffix() + base_path.substr(ext_pos)
		if ResourceLoader.exists(variant_path):
			return load(variant_path)

	# Fallback chain: try next higher quality, then base
	var fallback_order: Array[QualityPreset] = []
	match ultimate_quality:
		QualityPreset.LOW:
			fallback_order = [QualityPreset.MEDIUM, QualityPreset.HIGH]
		QualityPreset.MEDIUM:
			fallback_order = [QualityPreset.HIGH]

	for fb_quality in fallback_order:
		var suffix: String = ""
		match fb_quality:
			QualityPreset.HIGH: suffix = "_high"
			QualityPreset.MEDIUM: suffix = "_medium"
		var fb_path: String = base_path.substr(0, ext_pos) + suffix + base_path.substr(ext_pos)
		if ResourceLoader.exists(fb_path):
			return load(fb_path)

	# Final fallback: use base (ULTRA) asset
	return load(base_path)


## --- SNAPSHOT / RESTORE (for Cinematic Quality Boost) ---

static func snapshot() -> Dictionary:
	return {
		"ultimate_quality": ultimate_quality,
		"vfx_density": vfx_density,
		"particle_quality": particle_quality,
		"particle_count_multiplier": particle_count_multiplier,
		"atmosphere_quality": atmosphere_quality,
		"sky_quality": sky_quality,
		"volumetric_quality": volumetric_quality,
		"shadow_quality": shadow_quality,
		"bloom_enabled": bloom_enabled,
		"distortion_enabled": distortion_enabled,
		"debris_quality": debris_quality,
		"texture_quality": texture_quality,
		"cinematic_resolution_scale": cinematic_resolution_scale,
		"post_processing_quality": post_processing_quality,
	}


static func restore_from_snapshot(snap: Dictionary) -> void:
	if snap.is_empty():
		return
	ultimate_quality = snap.get("ultimate_quality", QualityPreset.HIGH)
	vfx_density = snap.get("vfx_density", 0.75)
	particle_quality = snap.get("particle_quality", QualityPreset.HIGH)
	particle_count_multiplier = snap.get("particle_count_multiplier", 0.7)
	atmosphere_quality = snap.get("atmosphere_quality", QualityPreset.HIGH)
	sky_quality = snap.get("sky_quality", QualityPreset.HIGH)
	volumetric_quality = snap.get("volumetric_quality", QualityPreset.HIGH)
	shadow_quality = snap.get("shadow_quality", QualityPreset.HIGH)
	bloom_enabled = snap.get("bloom_enabled", true)
	distortion_enabled = snap.get("distortion_enabled", true)
	debris_quality = snap.get("debris_quality", QualityPreset.HIGH)
	texture_quality = snap.get("texture_quality", QualityPreset.HIGH)
	cinematic_resolution_scale = snap.get("cinematic_resolution_scale", 1.0)
	post_processing_quality = snap.get("post_processing_quality", QualityPreset.HIGH)
	_apply_engine_settings()


## --- PERSISTENCE ---

static func save_to_config() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("graphics", "ultimate_quality", int(ultimate_quality))
	cfg.set_value("graphics", "vfx_density", vfx_density)
	cfg.set_value("graphics", "particle_count_multiplier", particle_count_multiplier)
	cfg.set_value("graphics", "bloom_enabled", bloom_enabled)
	cfg.set_value("graphics", "distortion_enabled", distortion_enabled)
	cfg.set_value("graphics", "cinematic_resolution_scale", cinematic_resolution_scale)
	cfg.save(CONFIG_PATH)


static func load_from_config() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		# No saved config — use default HIGH preset
		apply_preset(QualityPreset.HIGH)
		return

	var saved_quality: int = cfg.get_value("graphics", "ultimate_quality", int(QualityPreset.HIGH))
	apply_preset(saved_quality as QualityPreset)

	# Override individual values if user has custom settings
	if cfg.has_section_key("graphics", "vfx_density"):
		vfx_density = cfg.get_value("graphics", "vfx_density", vfx_density)
	if cfg.has_section_key("graphics", "particle_count_multiplier"):
		particle_count_multiplier = cfg.get_value("graphics", "particle_count_multiplier", particle_count_multiplier)
	if cfg.has_section_key("graphics", "bloom_enabled"):
		bloom_enabled = cfg.get_value("graphics", "bloom_enabled", bloom_enabled)
	if cfg.has_section_key("graphics", "distortion_enabled"):
		distortion_enabled = cfg.get_value("graphics", "distortion_enabled", distortion_enabled)
	if cfg.has_section_key("graphics", "cinematic_resolution_scale"):
		cinematic_resolution_scale = cfg.get_value("graphics", "cinematic_resolution_scale", cinematic_resolution_scale)


## --- ENGINE INTEGRATION ---

static func _apply_engine_settings() -> void:
	# Shadow quality
	match shadow_quality:
		QualityPreset.ULTRA:
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		QualityPreset.HIGH:
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		QualityPreset.MEDIUM:
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		QualityPreset.LOW:
			RenderingServer.directional_shadow_atlas_set_size(512, true)

	if _instance:
		var viewport: Viewport = _instance.get_viewport()
		if viewport:
			# MSAA
			match post_processing_quality:
				QualityPreset.ULTRA:
					viewport.msaa_3d = Viewport.MSAA_4X
				QualityPreset.HIGH:
					viewport.msaa_3d = Viewport.MSAA_2X
				QualityPreset.MEDIUM, QualityPreset.LOW:
					viewport.msaa_3d = Viewport.MSAA_DISABLED

			# Scaling
			if cinematic_resolution_scale < 1.0:
				viewport.scaling_3d_scale = cinematic_resolution_scale
			else:
				viewport.scaling_3d_scale = 1.0


## --- PRESET NAME HELPERS ---

static func preset_name(preset: QualityPreset) -> String:
	match preset:
		QualityPreset.LOW: return "Low"
		QualityPreset.MEDIUM: return "Medium"
		QualityPreset.HIGH: return "High"
		QualityPreset.ULTRA: return "Ultra"
	return "Unknown"


static func preset_from_int(value: int) -> QualityPreset:
	return clampi(value, 0, 3) as QualityPreset
