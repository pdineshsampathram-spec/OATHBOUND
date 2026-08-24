extends Node

## CombatTimeController — Centralized, safe management of ALL time-scale mutations.
## ONLY this singleton may touch Engine.time_scale.
## Guarantees cleanup via failsafe timers, not await chains.

signal hitstop_started()
signal hitstop_ended()
signal slowmo_started(speed: float, reason: String)
signal slowmo_ended(reason: String)

enum TimeState { NORMAL, HITSTOP, SLOWMO, FINISHER_SLOWMO }

var current_state: TimeState = TimeState.NORMAL
var _hitstop_timer: float = 0.0
var _slowmo_timer: float = 0.0
var _slowmo_speed: float = 1.0
var _slowmo_reason: String = ""
var _failsafe_timer: float = 0.0

# Maximum allowed slow-motion duration (absolute safety net)
const MAX_SLOWMO_DURATION: float = 5.0
const MAX_HITSTOP_DURATION: float = 0.5
const FAILSAFE_INTERVAL: float = 3.0

# Debug display
var debug_visible: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Must tick even when paused
	_force_normal()

func _physics_process(delta: float) -> void:
	# Use unscaled delta for timing
	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	
	match current_state:
		TimeState.HITSTOP:
			_hitstop_timer -= real_delta
			if _hitstop_timer <= 0.0:
				_end_hitstop()
		
		TimeState.SLOWMO, TimeState.FINISHER_SLOWMO:
			_slowmo_timer -= real_delta
			if _slowmo_timer <= 0.0:
				_end_slowmo()
		
		TimeState.NORMAL:
			# Failsafe: if Engine.time_scale drifted, fix it
			if absf(Engine.time_scale - 1.0) > 0.01:
				push_warning("CombatTimeController: time_scale drifted to %.3f, forcing restore" % Engine.time_scale)
				_force_normal()
	
	# Absolute failsafe timer
	if current_state != TimeState.NORMAL:
		_failsafe_timer -= real_delta
		if _failsafe_timer <= 0.0:
			push_warning("CombatTimeController: failsafe triggered, forcing normal time")
			force_restore_normal_time()

## --- Public API ---

## Trigger a micro-hitstop for combat feel. Safe, bounded, guaranteed cleanup.
func trigger_hitstop(duration: float) -> void:
	if duration <= 0.001:
		return
	duration = minf(duration, MAX_HITSTOP_DURATION)
	
	# Hitstop overrides previous hitstop but not slow-mo
	if current_state == TimeState.SLOWMO or current_state == TimeState.FINISHER_SLOWMO:
		return  # Don't interrupt slow-mo with hitstop
	
	current_state = TimeState.HITSTOP
	_hitstop_timer = duration
	_failsafe_timer = MAX_SLOWMO_DURATION
	Engine.time_scale = 0.05
	hitstop_started.emit()

## Trigger presentation slow-motion (e.g., finisher camera).
func trigger_slowmo(speed: float, duration: float, reason: String = "generic") -> void:
	speed = clampf(speed, 0.1, 0.9)
	duration = minf(duration, MAX_SLOWMO_DURATION)
	
	current_state = TimeState.FINISHER_SLOWMO if reason == "finisher" else TimeState.SLOWMO
	_slowmo_speed = speed
	_slowmo_timer = duration
	_slowmo_reason = reason
	_failsafe_timer = MAX_SLOWMO_DURATION
	Engine.time_scale = speed
	slowmo_started.emit(speed, reason)

## Force immediate restoration to normal time. Call this as a safety net.
func force_restore_normal_time() -> void:
	_force_normal()
	if current_state != TimeState.NORMAL:
		var prev_reason: String = _slowmo_reason
		current_state = TimeState.NORMAL
		_slowmo_reason = ""
		hitstop_ended.emit()
		slowmo_ended.emit(prev_reason)
	current_state = TimeState.NORMAL

## Check if currently in any altered time state.
func is_time_altered() -> bool:
	return current_state != TimeState.NORMAL

## Get current debug info for overlay display.
func get_debug_info() -> Dictionary:
	return {
		"time_scale": Engine.time_scale,
		"state": TimeState.keys()[current_state],
		"hitstop_remaining": _hitstop_timer if current_state == TimeState.HITSTOP else 0.0,
		"slowmo_remaining": _slowmo_timer if current_state != TimeState.NORMAL else 0.0,
		"slowmo_reason": _slowmo_reason,
	}

## --- Internal ---

func _end_hitstop() -> void:
	current_state = TimeState.NORMAL
	_hitstop_timer = 0.0
	Engine.time_scale = 1.0
	hitstop_ended.emit()

func _end_slowmo() -> void:
	var prev_reason: String = _slowmo_reason
	current_state = TimeState.NORMAL
	_slowmo_timer = 0.0
	_slowmo_reason = ""
	Engine.time_scale = 1.0
	slowmo_ended.emit(prev_reason)

func _force_normal() -> void:
	Engine.time_scale = 1.0
	_hitstop_timer = 0.0
	_slowmo_timer = 0.0
	_failsafe_timer = FAILSAFE_INTERVAL
	_slowmo_reason = ""
