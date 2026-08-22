class_name MatchManager
extends Node

## MatchManager — Server-authoritative match lifecycle, round timer, player survival evaluation,
## scoring, and rematch coordination.

enum MatchState { WAITING, COUNTDOWN, IN_PROGRESS, ENDED }

signal match_state_changed(state: MatchState)
signal match_timer_updated(seconds_left: float)
signal match_ended(results: Dictionary)

@export var match_duration: float = 180.0
@export var countdown_duration: float = 3.0

var current_state: MatchState = MatchState.WAITING
var time_remaining: float = 180.0
var countdown_timer: float = 3.0

var player_stats: Dictionary = {} # id -> { "name": String, "class": String, "damage_dealt": float, "kills": int, "parries": int }

var _is_server: bool = true

func _ready() -> void:
	_is_server = not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	time_remaining = match_duration
	countdown_timer = countdown_duration

	if _is_server:
		start_countdown()

func _physics_process(delta: float) -> void:
	if not _is_server:
		return

	match current_state:
		MatchState.COUNTDOWN:
			countdown_timer -= delta
			rpc("rpc_sync_countdown", countdown_timer)
			if countdown_timer <= 0.0:
				current_state = MatchState.IN_PROGRESS
				time_remaining = match_duration
				rpc("rpc_match_started", time_remaining)

		MatchState.IN_PROGRESS:
			time_remaining = max(0.0, time_remaining - delta)
			rpc("rpc_sync_timer", time_remaining)

			_evaluate_match_conditions()

func start_countdown() -> void:
	current_state = MatchState.COUNTDOWN
	countdown_timer = countdown_duration
	time_remaining = match_duration
	_init_player_stats()
	rpc("rpc_match_countdown_started")

func record_damage(attacker_id: int, damage_amount: float) -> void:
	if not _is_server: return
	if not player_stats.has(attacker_id):
		_init_player_stats()
	if player_stats.has(attacker_id):
		player_stats[attacker_id]["damage_dealt"] += damage_amount

func record_kill(attacker_id: int) -> void:
	if not _is_server: return
	if not player_stats.has(attacker_id):
		_init_player_stats()
	if player_stats.has(attacker_id):
		player_stats[attacker_id]["kills"] += 1

func record_parry(defender_id: int) -> void:
	if not _is_server: return
	if not player_stats.has(defender_id):
		_init_player_stats()
	if player_stats.has(defender_id):
		player_stats[defender_id]["parries"] += 1

func _evaluate_match_conditions() -> void:
	var players_node: Node = get_parent().get_node_or_null("Players")
	if not players_node:
		return

	var active_players: Array[PlayerController] = []
	var alive_players: Array[PlayerController] = []

	for child in players_node.get_children():
		if child is PlayerController:
			active_players.append(child)
			if not child.is_dead:
				alive_players.append(child)

	# 1. Timeout Condition
	if time_remaining <= 0.0:
		_end_match(alive_players, "TIME EXPIRED")
		return

	# 2. Last Warrior Standing (in multiplayer matches with 2+ players)
	if active_players.size() >= 2:
		if alive_players.size() <= 1:
			_end_match(alive_players, "VICTORY BY COMBAT")
		return

	# 3. Solo Practice condition (Dummy killed or player dies)
	if active_players.size() == 1:
		if alive_players.is_empty():
			_end_match([], "DEFEATED IN ARENA")

func _end_match(alive_players: Array[PlayerController], reason: String) -> void:
	current_state = MatchState.ENDED
	var winner_id: int = 1
	var winner_name: String = "Champion"
	var winner_class: String = "Knight"

	if not alive_players.is_empty():
		var p: PlayerController = alive_players[0]
		winner_id = p.peer_id
		winner_class = p.sync_character_class
		var p_info: Dictionary = NetworkManager.players.get(winner_id, {})
		winner_name = p_info.get("name", "Player %d" % winner_id)
	elif not player_stats.is_empty():
		# Winner by highest damage
		var max_dmg: float = -1.0
		for p_id in player_stats.keys():
			var d: float = player_stats[p_id].get("damage_dealt", 0.0)
			if d > max_dmg:
				max_dmg = d
				winner_id = p_id
				var p_info: Dictionary = NetworkManager.players.get(winner_id, {})
				winner_name = p_info.get("name", "Player %d" % winner_id)
				winner_class = p_info.get("character", "Knight")

	var results_data: Dictionary = {
		"winner_id": winner_id,
		"winner_name": winner_name,
		"winner_class": winner_class,
		"reason": reason,
		"stats": player_stats
	}

	rpc("rpc_match_ended", results_data)

func _init_player_stats() -> void:
	player_stats.clear()
	var players_node: Node = get_parent().get_node_or_null("Players")
	if players_node:
		for child in players_node.get_children():
			if child is PlayerController:
				var p_id: int = child.peer_id
				var p_info: Dictionary = NetworkManager.players.get(p_id, {})
				player_stats[p_id] = {
					"name": p_info.get("name", "Player %d" % p_id),
					"class": child.sync_character_class,
					"damage_dealt": 0.0,
					"kills": 0,
					"parries": 0
				}

@rpc("call_local", "reliable")
func rpc_match_countdown_started() -> void:
	current_state = MatchState.COUNTDOWN
	match_state_changed.emit(current_state)

@rpc("call_local", "unreliable")
func rpc_sync_countdown(seconds_left: float) -> void:
	countdown_timer = seconds_left
	match_timer_updated.emit(seconds_left)

@rpc("call_local", "reliable")
func rpc_match_started(initial_time: float) -> void:
	current_state = MatchState.IN_PROGRESS
	time_remaining = initial_time
	match_state_changed.emit(current_state)

@rpc("call_local", "unreliable")
func rpc_sync_timer(seconds_left: float) -> void:
	time_remaining = seconds_left
	match_timer_updated.emit(seconds_left)

@rpc("call_local", "reliable")
func rpc_match_ended(results: Dictionary) -> void:
	current_state = MatchState.ENDED
	match_state_changed.emit(current_state)
	match_ended.emit(results)

@rpc("any_peer", "call_local", "reliable")
func request_rematch() -> void:
	if not _is_server: return

	# Reset players in arena
	var players_node: Node = get_parent().get_node_or_null("Players")
	var spawn_pts_node: Node = get_parent().get_node_or_null("SpawnPoints")
	var pts: Array[Node] = spawn_pts_node.get_children() if spawn_pts_node else []

	if players_node:
		var idx: int = 0
		for child in players_node.get_children():
			if child is PlayerController:
				child.is_dead = false
				child.sync_is_dead = false
				if child.health_component:
					child.health_component.initialize(child.character_data.max_health)
				if child.stamina_component:
					child.stamina_component.initialize(child.character_data.max_stamina)
				if child.state_machine:
					child.state_machine.transition_to("IdleState")
				if child.visual_pivot:
					child.visual_pivot.position = Vector3.ZERO
					child.visual_pivot.rotation = Vector3.ZERO

				if not pts.is_empty():
					var pt: Marker3D = pts[idx % pts.size()] as Marker3D
					if pt:
						child.global_position = pt.global_position
						child.global_rotation.y = pt.global_rotation.y
				idx += 1

	start_countdown()
