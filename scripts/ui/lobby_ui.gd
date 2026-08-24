class_name LobbyUI
extends Control

## LobbyUI — User interface for hosting, joining, character selection, and match launching.

@onready var name_input: LineEdit = $Panel/MarginContainer/VBoxContainer/NameRow/NameInput
@onready var char_select: OptionButton = $Panel/MarginContainer/VBoxContainer/CharRow/CharSelect
@onready var char_info_label: Label = $Panel/MarginContainer/VBoxContainer/CharInfoLabel
@onready var ip_input: LineEdit = $Panel/MarginContainer/VBoxContainer/JoinRow/IPInput
@onready var port_input: LineEdit = $Panel/MarginContainer/VBoxContainer/JoinRow/PortInput
@onready var host_btn: Button = $Panel/MarginContainer/VBoxContainer/ButtonsRow/HostButton
@onready var join_btn: Button = $Panel/MarginContainer/VBoxContainer/ButtonsRow/JoinButton
@onready var singleplayer_btn: Button = $Panel/MarginContainer/VBoxContainer/ButtonsRow/SoloButton
@onready var start_btn: Button = $Panel/MarginContainer/VBoxContainer/StartButton
@onready var player_list: ItemList = $Panel/MarginContainer/VBoxContainer/PlayerList
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel

var character_descriptions: Array[String] = [
	"KNIGHT (The Sentinel): 120 HP | 65 Poise | Longsword & Shield | High Defense | Ability [Q]: Shield Rush",
	"BERSERKER (The Ravager): 140 HP | 80 Poise | Two-Handed Greataxe | Crushing Damage | Ability [Q]: Ground Breaker",
	"SHADOW WARRIOR (The Phantom): 85 HP | 35 Poise | Dual Blades | High Agility & Evasion | Ability [Q]: Shadow Step"
]

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	_setup_character_options()

	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	singleplayer_btn.pressed.connect(_on_solo_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	char_select.item_selected.connect(_on_char_selected)

	NetworkManager.players_updated.connect(_update_player_list)
	NetworkManager.server_started.connect(_on_server_started)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)

	start_btn.visible = false
	status_label.text = "Select fighter archetype, enter name, and join arena."
	_update_player_list()

func _setup_character_options() -> void:
	char_select.clear()
	char_select.add_item("Knight (Sentinel)", 0)
	char_select.add_item("Berserker (Ravager)", 1)
	char_select.add_item("Shadow Warrior (Phantom)", 2)
	char_select.select(0)
	_on_char_selected(0)

func _on_char_selected(index: int) -> void:
	match index:
		0: NetworkManager.local_character_choice = "Knight"
		1: NetworkManager.local_character_choice = "Berserker"
		2: NetworkManager.local_character_choice = "Shadow Warrior"

	if index >= 0 and index < character_descriptions.size():
		char_info_label.text = character_descriptions[index]

func _on_host_pressed() -> void:
	_apply_player_settings()
	var port: int = port_input.text.to_int() if port_input.text.is_valid_int() else 9999
	var err: Error = NetworkManager.host_game(port)
	if err == OK:
		status_label.text = "Server hosted on port %d. Ready for players..." % port
		host_btn.disabled = true
		join_btn.disabled = true
		char_select.disabled = true
		start_btn.visible = true
	else:
		status_label.text = "Failed to host server: %s" % error_string(err)

func _on_join_pressed() -> void:
	_apply_player_settings()
	var ip: String = ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var port: int = port_input.text.to_int() if port_input.text.is_valid_int() else 9999
	
	status_label.text = "Connecting to %s:%d..." % [ip, port]
	host_btn.disabled = true
	join_btn.disabled = true
	char_select.disabled = true
	
	var err: Error = NetworkManager.join_game(ip, port)
	if err != OK:
		status_label.text = "Failed to connect: %s" % error_string(err)
		host_btn.disabled = false
		join_btn.disabled = false
		char_select.disabled = false

func _on_solo_pressed() -> void:
	_apply_player_settings()
	NetworkManager.players.clear()
	NetworkManager.players[1] = {
		"name": NetworkManager.local_player_name,
		"character": NetworkManager.local_character_choice
	}
	get_tree().change_scene_to_file("res://scenes/arena/solo_arena.tscn")

func _on_start_pressed() -> void:
	if multiplayer.is_server():
		NetworkManager.start_match.rpc()

func _apply_player_settings() -> void:
	var entered_name: String = name_input.text.strip_edges()
	if not entered_name.is_empty():
		NetworkManager.local_player_name = entered_name

func _update_player_list() -> void:
	if not player_list:
		return
	player_list.clear()
	for p_id in NetworkManager.players.keys():
		var p_info: Dictionary = NetworkManager.players[p_id]
		var title: String = "%s [%s] (ID: %d)" % [p_info.get("name", "Player"), p_info.get("character", "Knight"), p_id]
		player_list.add_item(title)

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		var count: int = NetworkManager.players.size()
		start_btn.text = "START MATCH (%d / 5 Players)" % count
		start_btn.disabled = false

func _on_server_started() -> void:
	status_label.text = "Hosting active. Ready for clients."

func _on_connected() -> void:
	status_label.text = "Connected to host! Waiting for match to start..."

func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Please check host IP and port."
	host_btn.disabled = false
	join_btn.disabled = false
	char_select.disabled = false

func _on_server_disconnected() -> void:
	status_label.text = "Disconnected from host."
	host_btn.disabled = false
	join_btn.disabled = false
	char_select.disabled = false
	start_btn.visible = false
