class_name HealthComponent
extends Node

## HealthComponent — Manages entity health, damage calculations, and death signals.

signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float, attacker: Node)
signal healed(amount: float)
signal died()

@export var max_health: float = 100.0:
	set(value):
		max_health = maxf(1.0, value)
		current_health = clampf(current_health, 0.0, max_health)
		health_changed.emit(current_health, max_health)

var current_health: float = 100.0
var is_invulnerable: bool = false

func _ready() -> void:
	current_health = max_health

func initialize(max_hp: float) -> void:
	max_health = max_hp
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: float, attacker: Node = null) -> float:
	if current_health <= 0.0 or is_invulnerable:
		return 0.0

	var actual_damage: float = maxf(0.0, amount)
	current_health = clampf(current_health - actual_damage, 0.0, max_health)
	
	damaged.emit(actual_damage, attacker)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		died.emit()

	return actual_damage

func heal(amount: float) -> void:
	if current_health <= 0.0 or amount <= 0.0:
		return

	current_health = clampf(current_health + amount, 0.0, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0.0
