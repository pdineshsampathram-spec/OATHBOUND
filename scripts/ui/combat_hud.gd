class_name CombatHUD
extends CanvasLayer

## Minimal combat HUD displaying Health Bar, Stamina Bar, Poise Bar, State, Ability Cooldown, and Network Status.

@onready var char_label: Label = $Control/MarginContainer/VBoxContainer/CharLabel
@onready var health_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/StaminaBar
@onready var poise_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/PoiseBar
@onready var ability_label: Label = $Control/MarginContainer/VBoxContainer/AbilityLabel
@onready var state_label: Label = $Control/MarginContainer/VBoxContainer/StateLabel
@onready var network_label: Label = $Control/MarginContainer/VBoxContainer/NetworkLabel

var target_player: PlayerController = null

func _ready() -> void:
	layer = 10
	_update_network_status()

func _process(_delta: float) -> void:
	if target_player:
		# Update poise bar
		if poise_bar and target_player.character_data:
			poise_bar.max_value = target_player.character_data.max_poise
			poise_bar.value = target_player.current_poise

		# Update ability cooldown
		if ability_label and target_player.character_data:
			var a_name: String = target_player.character_data.ability_name
			if target_player.ability_cooldown_remaining > 0.0:
				ability_label.text = "[Q] %s: %.1fs (Cooldown)" % [a_name, target_player.ability_cooldown_remaining]
				ability_label.modulate = Color(0.7, 0.7, 0.7, 0.8)
			else:
				ability_label.text = "[Q] %s: READY" % a_name
				ability_label.modulate = Color(0.4, 0.95, 0.5, 1.0)

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
