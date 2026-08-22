class_name MatchResultsUI
extends Control

## MatchResultsUI — Displays round conclusion, victory/defeat banner, combat statistics breakdown,
## and rematch/lobby return actions.

signal rematch_requested
signal return_to_lobby_requested

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var winner_label: Label = $Panel/VBoxContainer/WinnerLabel
@onready var reason_label: Label = $Panel/VBoxContainer/ReasonLabel
@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/StatsList
@onready var rematch_btn: Button = $Panel/VBoxContainer/ButtonsRow/RematchButton
@onready var lobby_btn: Button = $Panel/VBoxContainer/ButtonsRow/LobbyButton

func _ready() -> void:
	visible = false
	rematch_btn.pressed.connect(_on_rematch_pressed)
	lobby_btn.pressed.connect(_on_lobby_pressed)

func show_results(results: Dictionary) -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var my_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var winner_id: int = results.get("winner_id", 1)
	var winner_name: String = results.get("winner_name", "Champion")
	var winner_class: String = results.get("winner_class", "Knight")
	var reason: String = results.get("reason", "MATCH CONCLUDED")

	if winner_id == my_id:
		title_label.text = "VICTORY"
		title_label.modulate = Color(1.0, 0.85, 0.2, 1.0) # Gold
	else:
		title_label.text = "DEFEAT"
		title_label.modulate = Color(0.9, 0.25, 0.25, 1.0) # Crimson

	winner_label.text = "CHAMPION: %s (%s)" % [winner_name, winner_class.to_upper()]
	reason_label.text = reason

	# Populate stats table
	for child in stats_container.get_children():
		child.queue_free()

	var stats: Dictionary = results.get("stats", {})
	for p_id in stats.keys():
		var row_data: Dictionary = stats[p_id]
		var p_name: String = row_data.get("name", "Player %d" % p_id)
		var p_class: String = row_data.get("class", "Knight")
		var dmg: float = row_data.get("damage_dealt", 0.0)
		var kills: int = row_data.get("kills", 0)
		var parries: int = row_data.get("parries", 0)

		var lbl: Label = Label.new()
		lbl.text = "⚔️ %s [%s] — Damage: %.0f | Kills: %d | Parries: %d" % [p_name, p_class, dmg, kills, parries]
		if p_id == winner_id:
			lbl.modulate = Color(1.0, 0.9, 0.4)
		stats_container.add_child(lbl)

	# Only host/server can trigger rematch in multiplayer
	var is_server: bool = not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	rematch_btn.visible = is_server
	if not is_server:
		reason_label.text += " (Waiting for host...)"

func _on_rematch_pressed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	rematch_requested.emit()

func _on_lobby_pressed() -> void:
	visible = false
	return_to_lobby_requested.emit()
	var net_mgr = get_node_or_null("/root/NetworkManager")
	if net_mgr and net_mgr.has_method("disconnect_game"):
		net_mgr.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
