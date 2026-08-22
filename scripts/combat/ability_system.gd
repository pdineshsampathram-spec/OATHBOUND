class_name AbilitySystem
extends Node

## AbilitySystem — Manages character supernatural energy, 4 ability slots, cooldowns, and active buffs.

signal energy_changed(current: float, max_val: float)
signal ability_cast(slot_index: int, ability: AbilityData)
signal buff_started(buff_name: String, duration: float)
signal buff_ended(buff_name: String)

@export var max_energy: float = 100.0
@export var energy_regen_rate: float = 15.0

var current_energy: float = 100.0
var cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var abilities: Array[AbilityData] = []

# Active Buff Timers
var holy_guard_timer: float = 0.0
var blood_rage_timer: float = 0.0
var smoke_veil_timer: float = 0.0

var player: PlayerController = null

func initialize(owner_player: PlayerController, char_data: CharacterData) -> void:
	player = owner_player
	if char_data:
		max_energy = char_data.max_energy
		energy_regen_rate = char_data.energy_regen_rate
		current_energy = max_energy
		abilities = char_data.abilities.duplicate()
	else:
		current_energy = 100.0
		abilities.clear()

	cooldowns = [0.0, 0.0, 0.0, 0.0]
	energy_changed.emit(current_energy, max_energy)

func _physics_process(delta: float) -> void:
	# Regenerate energy on server
	if player and player.is_server_authority and not player.is_dead:
		if current_energy < max_energy:
			current_energy = minf(max_energy, current_energy + energy_regen_rate * delta)
			energy_changed.emit(current_energy, max_energy)

	# Decrement cooldowns
	for i in range(cooldowns.size()):
		if cooldowns[i] > 0.0:
			cooldowns[i] = maxf(0.0, cooldowns[i] - delta)

	# Decrement Buff Timers
	if holy_guard_timer > 0.0:
		holy_guard_timer = maxf(0.0, holy_guard_timer - delta)
		if holy_guard_timer == 0.0:
			buff_ended.emit("HolyGuard")

	if blood_rage_timer > 0.0:
		blood_rage_timer = maxf(0.0, blood_rage_timer - delta)
		if blood_rage_timer == 0.0:
			buff_ended.emit("BloodRage")

	if smoke_veil_timer > 0.0:
		smoke_veil_timer = maxf(0.0, smoke_veil_timer - delta)
		if smoke_veil_timer == 0.0:
			buff_ended.emit("SmokeVeil")

func get_ability(slot: int) -> AbilityData:
	if slot >= 0 and slot < abilities.size():
		return abilities[slot]
	return null

func can_cast(slot: int) -> bool:
	var ab: AbilityData = get_ability(slot)
	if not ab:
		return false
	if cooldowns[slot] > 0.0:
		return false
	if current_energy < ab.energy_cost:
		return false
	if ab.stamina_cost > 0.0 and player and player.stamina_component:
		if not player.stamina_component.has_enough(ab.stamina_cost):
			return false
	return true

func consume_and_trigger_cooldown(slot: int) -> bool:
	var ab: AbilityData = get_ability(slot)
	if not ab:
		return false

	current_energy -= ab.energy_cost
	energy_changed.emit(current_energy, max_energy)

	if ab.stamina_cost > 0.0 and player and player.stamina_component:
		player.stamina_component.consume(ab.stamina_cost)

	cooldowns[slot] = ab.cooldown
	ability_cast.emit(slot, ab)
	return true

func apply_buff(buff_name: String, duration: float) -> void:
	match buff_name:
		"HolyGuard":
			holy_guard_timer = duration
			buff_started.emit("HolyGuard", duration)
		"BloodRage":
			blood_rage_timer = duration
			buff_started.emit("BloodRage", duration)
		"SmokeVeil":
			smoke_veil_timer = duration
			buff_started.emit("SmokeVeil", duration)

func get_incoming_damage_multiplier() -> float:
	var mult: float = 1.0
	if holy_guard_timer > 0.0:
		mult *= 0.5 # 50% damage reduction
	return mult

func get_outgoing_damage_multiplier() -> float:
	var mult: float = 1.0
	if blood_rage_timer > 0.0:
		mult *= 1.4 # +40% attack damage
	if smoke_veil_timer > 0.0:
		mult *= 1.5 # +50% ambush damage from stealth
		smoke_veil_timer = 0.0 # Breaks stealth on attack
		buff_ended.emit("SmokeVeil")
	return mult

func is_stealthed() -> bool:
	return smoke_veil_timer > 0.0
