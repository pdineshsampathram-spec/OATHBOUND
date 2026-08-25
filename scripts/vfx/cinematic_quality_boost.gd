class_name CinematicQualityBoost
extends RefCounted

const GraphicsSettings = preload("res://scripts/graphics_settings.gd")

## CinematicQualityBoost — Temporary rendering enhancement during Ultimate cinematic.
## Caches user's current GraphicsSettings, enables cinematic-grade visual features,
## then restores exact previous state when the cinematic ends.
##
## IMPORTANT: Benchmark this carefully on M1. Do NOT assume MSAA+volumetric+DOF is free.
## The engage/disengage cycle should be safe at any quality preset.
##
## Usage:
##   var boost = CinematicQualityBoost.new()
##   boost.engage(get_viewport(), environment_ref)
##   # ... cinematic plays ...
##   boost.disengage()

var _cached_snapshot: Dictionary = {}
var _is_active: bool = false
var _viewport_rid: RID = RID()
var _cached_viewport_msaa: Viewport.MSAA = Viewport.MSAA_DISABLED
var _cached_viewport_scale: float = 1.0
var _cached_env_glow_enabled: bool = false
var _cached_env_glow_intensity: float = 0.0
var _cached_env_glow_bloom: float = 0.0
var _cached_env_volumetric_fog: bool = false
var _cached_env_sdfgi: bool = false

var _env_ref: WeakRef = WeakRef.new()
var _viewport_ref: WeakRef = WeakRef.new()


## Engage cinematic quality boost.
## Temporarily elevates visual settings for the duration of the Ultimate cinematic.
## Only boosts features when the user's current preset is HIGH or above to avoid
## pushing already-struggling hardware further.
func engage(viewport: Viewport, environment: Environment) -> void:
	if _is_active:
		return
	if not viewport or not environment:
		push_warning("[CinematicQualityBoost] Cannot engage — missing viewport or environment")
		return

	_is_active = true
	_viewport_ref = weakref(viewport)
	_env_ref = weakref(environment)

	# Cache current GraphicsSettings state
	_cached_snapshot = GraphicsSettings.snapshot()

	# Cache viewport-level settings
	_cached_viewport_msaa = viewport.msaa_3d
	_cached_viewport_scale = viewport.scaling_3d_scale

	# Cache environment settings
	_cached_env_glow_enabled = environment.glow_enabled
	_cached_env_glow_intensity = environment.glow_intensity
	_cached_env_glow_bloom = environment.glow_bloom
	_cached_env_volumetric_fog = environment.volumetric_fog_enabled
	_cached_env_sdfgi = environment.sdfgi_enabled

	# Only boost if user is at HIGH or ULTRA — don't push MEDIUM/LOW hardware
	var current_preset: GraphicsSettings.QualityPreset = GraphicsSettings.ultimate_quality
	if int(current_preset) < int(GraphicsSettings.QualityPreset.HIGH):
		print(">> [CINEMATIC_BOOST] User preset is %s — skipping boost to protect performance" % GraphicsSettings.preset_name(current_preset))
		return

	print(">> [CINEMATIC_BOOST] Engaging cinematic quality boost (base preset: %s)" % GraphicsSettings.preset_name(current_preset))

	# --- Apply cinematic enhancements ---

	# Enhanced anti-aliasing during cinematic
	if current_preset == GraphicsSettings.QualityPreset.ULTRA:
		viewport.msaa_3d = Viewport.MSAA_4X
	elif current_preset == GraphicsSettings.QualityPreset.HIGH:
		viewport.msaa_3d = Viewport.MSAA_2X

	# Always render at full resolution during cinematic
	viewport.scaling_3d_scale = 1.0

	# Enable/enhance glow for cinematic energy bloom
	environment.glow_enabled = true
	environment.glow_intensity = maxf(environment.glow_intensity, 0.6)
	environment.glow_bloom = maxf(environment.glow_bloom, 0.15)

	# ULTRA-only: enable volumetric fog for atmospheric depth
	if current_preset == GraphicsSettings.QualityPreset.ULTRA:
		environment.volumetric_fog_enabled = true


## Disengage cinematic quality boost.
## Restores the user's exact previous settings — no residual changes.
func disengage() -> void:
	if not _is_active:
		return

	_is_active = false

	# Restore viewport settings
	var viewport: Viewport = _viewport_ref.get_ref() as Viewport
	if viewport:
		viewport.msaa_3d = _cached_viewport_msaa
		viewport.scaling_3d_scale = _cached_viewport_scale

	# Restore environment settings
	var environment: Environment = _env_ref.get_ref() as Environment
	if environment:
		environment.glow_enabled = _cached_env_glow_enabled
		environment.glow_intensity = _cached_env_glow_intensity
		environment.glow_bloom = _cached_env_glow_bloom
		environment.volumetric_fog_enabled = _cached_env_volumetric_fog
		environment.sdfgi_enabled = _cached_env_sdfgi

	# Restore GraphicsSettings snapshot
	GraphicsSettings.restore_from_snapshot(_cached_snapshot)

	print(">> [CINEMATIC_BOOST] Disengaged — user settings restored")


## Check if cinematic boost is currently active.
func is_active() -> bool:
	return _is_active


## Force cleanup (safety valve if cinematic is interrupted).
func force_disengage() -> void:
	if _is_active:
		disengage()
