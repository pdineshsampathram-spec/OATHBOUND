class_name CombatHUD
extends CanvasLayer

## Minimal combat HUD displaying Health Bar, Stamina Bar, State, and Network Status.

@onready var health_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/StaminaBar
@onready var state_label: Label = $Control/MarginContainer/VBoxContainer/StateLabel
@onready var network_label: Label = $Control/MarginContainer/VBoxContainer/NetworkLabel

var target_player: PlayerController = null

func _ready() -> void:
	layer = 10
	_update_network_status()

func connect_player(player: PlayerController) -> void:
	target_player = player
	if not target_player:
		return

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
		network_label.text = "Role: %s | Players: %d" % [role, count]
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
