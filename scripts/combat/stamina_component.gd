class_name StaminaComponent
extends Node

## StaminaComponent — Manages stamina resource, consumption, drain, and delayed regeneration.

signal stamina_changed(current_stamina: float, max_stamina: float)
signal stamina_depleted()

@export var max_stamina: float = 100.0:
	set(value):
		max_stamina = maxf(1.0, value)
		current_stamina = clampf(current_stamina, 0.0, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)

@export var regen_rate: float = 25.0
@export var regen_delay: float = 0.8

var current_stamina: float = 100.0
var _delay_timer: float = 0.0
var can_regenerate: bool = true

func _ready() -> void:
	current_stamina = max_stamina

func initialize(max_stm: float, rate: float, delay: float) -> void:
	max_stamina = max_stm
	current_stamina = max_stamina
	regen_rate = rate
	regen_delay = delay
	_delay_timer = 0.0
	stamina_changed.emit(current_stamina, max_stamina)

func _process(delta: float) -> void:
	if not can_regenerate:
		return

	if _delay_timer > 0.0:
		_delay_timer -= delta
		return

	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + regen_rate * delta)
		stamina_changed.emit(current_stamina, max_stamina)

func has_enough(amount: float) -> bool:
	return current_stamina >= amount

func consume(amount: float) -> bool:
	if amount <= 0.0:
		return true

	if current_stamina < amount:
		return false

	current_stamina -= amount
	_delay_timer = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)

	if current_stamina <= 0.0:
		stamina_depleted.emit()

	return true

func drain(rate: float, delta: float) -> bool:
	if rate <= 0.0:
		return true

	var amount: float = rate * delta
	if current_stamina <= 0.0:
		return false

	current_stamina = maxf(0.0, current_stamina - amount)
	_delay_timer = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)

	if current_stamina <= 0.0:
		stamina_depleted.emit()
		return false

	return true

func reset_delay() -> void:
	_delay_timer = regen_delay
