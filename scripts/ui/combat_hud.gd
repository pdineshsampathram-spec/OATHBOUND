class_name CombatHUD
extends CanvasLayer

## Minimal combat HUD displaying Health Bar, Stamina Bar, Poise Bar, Energy Bar, 4 Ability Slots, State, and Network Status.

@onready var char_label: Label = $Control/MarginContainer/VBoxContainer/CharLabel
@onready var health_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/StaminaBar
@onready var poise_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/PoiseBar
@onready var energy_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/EnergyBar
@onready var abilities_container: HBoxContainer = $Control/MarginContainer/VBoxContainer/AbilitiesContainer
@onready var ab_slot_0: Label = $Control/MarginContainer/VBoxContainer/AbilitiesContainer/Slot0
@onready var ab_slot_1: Label = $Control/MarginContainer/VBoxContainer/AbilitiesContainer/Slot1
@onready var ab_slot_2: Label = $Control/MarginContainer/VBoxContainer/AbilitiesContainer/Slot2
@onready var ab_slot_3: Label = $Control/MarginContainer/VBoxContainer/AbilitiesContainer/Slot3
@onready var state_label: Label = $Control/MarginContainer/VBoxContainer/StateLabel
@onready var network_label: Label = $Control/MarginContainer/VBoxContainer/NetworkLabel

var target_player: PlayerController = null
var key_labels: Array[String] = ["[1]", "[2]", "[Q]", "[R]"]

func _ready() -> void:
	layer = 10
	_update_network_status()

func _process(_delta: float) -> void:
	if not target_player:
		return

	# Update poise bar
	if poise_bar and target_player.character_data:
		poise_bar.max_value = target_player.character_data.max_poise
		poise_bar.value = target_player.current_poise

	# Update energy bar
	if energy_bar and target_player.ability_system:
		energy_bar.max_value = target_player.ability_system.max_energy
		energy_bar.value = target_player.ability_system.current_energy

	# Update 4 ability slot status labels
	if target_player.ability_system:
		var slots: Array[Label] = [ab_slot_0, ab_slot_1, ab_slot_2, ab_slot_3]
		for i in range(slots.size()):
			var slot_lbl: Label = slots[i]
			if not slot_lbl:
				continue
			var ab: AbilityData = target_player.ability_system.get_ability(i)
			if ab:
				var cd: float = target_player.ability_system.cooldowns[i]
				var has_energy: bool = target_player.ability_system.current_energy >= ab.energy_cost
				if cd > 0.0:
					slot_lbl.text = "%s %s: %.1fs" % [key_labels[i], ab.ability_name, cd]
					slot_lbl.modulate = Color(0.6, 0.6, 0.6, 0.7)
				elif not has_energy:
					slot_lbl.text = "%s %s (%.0f EN)" % [key_labels[i], ab.ability_name, ab.energy_cost]
					slot_lbl.modulate = Color(0.9, 0.4, 0.4, 0.9)
				else:
					slot_lbl.text = "%s %s" % [key_labels[i], ab.ability_name]
					if i == 3: # Ultimate
						slot_lbl.modulate = Color(1.0, 0.85, 0.2, 1.0)
					else:
						slot_lbl.modulate = Color(0.4, 0.95, 0.5, 1.0)
			else:
				slot_lbl.text = "%s —" % key_labels[i]

func connect_player(player: PlayerController) -> void:
	target_player = player
	if not target_player:
		return

	if char_label and target_player.character_data:
		char_label.text = "%s — %s" % [target_player.character_data.character_name.to_upper(), target_player.character_data.character_title]

	if target_player.health_component:
		target_player.health_component.health_changed.connect(_on_health_changed)
		_on_health_changed(target_player.health_component.current_health, target_player.health_component.max_health)

	if target_player.stamina_component:
		target_player.stamina_component.stamina_changed.connect(_on_stamina_changed)
		_on_stamina_changed(target_player.stamina_component.current_stamina, target_player.stamina_component.max_stamina)

	if target_player.state_machine:
		target_player.state_machine.state_changed.connect(_on_state_changed)
		_on_state_changed("", target_player.state_machine.get_current_state_name())

	_update_network_status()

func _update_network_status() -> void:
	if not network_label:
		return
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var role: String = "Host (Server)" if multiplayer.is_server() else "Client"
		var count: int = NetworkManager.players.size()
		network_label.text = "Role: %s | Warriors: %d" % [role, count]
	else:
		network_label.text = "Mode: Solo / Local Practice"

func _on_health_changed(curr: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = curr

func _on_stamina_changed(curr: float, max_stm: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stm
		stamina_bar.value = curr

func _on_state_changed(_prev: String, curr: String) -> void:
	if state_label:
		state_label.text = "State: %s" % curr.replace("State", "")
