class_name CombatHUD
extends CanvasLayer

## Minimal combat HUD displaying Health Bar, Stamina Bar, Poise Bar, Energy Bar, 4 Ability Slots,
## Match Timer, Live Warriors Count, Status Banners, and Match Results.

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

@onready var timer_label: Label = $Control/TopBanner/HBoxContainer/TimerLabel
@onready var alive_label: Label = $Control/TopBanner/HBoxContainer/AliveLabel
@onready var status_banner: Label = $Control/CenterBanner/StatusBanner
@onready var toast_label: Label = $Control/CenterBanner/ToastLabel
@onready var results_ui: MatchResultsUI = $MatchResultsUI

var target_player: PlayerController = null
var match_manager: MatchManager = null
var key_labels: Array[String] = ["[1]", "[2]", "[Q]", "[R]"]
var _toast_timer: float = 0.0

func _ready() -> void:
	layer = 10
	_update_network_status()
	status_banner.text = ""
	toast_label.text = ""

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_label.text = ""

	_update_debug_overlay()

func show_announcement(msg: String, duration: float = 2.0) -> void:
	if status_banner:
		status_banner.text = msg
		status_banner.modulate = Color(1.0, 0.85, 0.3, 1.0)
		var tween: Tween = create_tween()
		tween.tween_interval(duration * 0.7)
		tween.tween_property(status_banner, "modulate:a", 0.0, duration * 0.3)
		tween.tween_callback(func(): status_banner.text = "")

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

func connect_match_manager(mm: MatchManager) -> void:
	match_manager = mm
	if not match_manager: return

	match_manager.match_timer_updated.connect(_on_match_timer_updated)
	match_manager.match_state_changed.connect(_on_match_state_changed)
	match_manager.match_ended.connect(_on_match_ended)

	if results_ui:
		results_ui.rematch_requested.connect(func(): match_manager.request_rematch.rpc())

func show_combat_toast(msg: String, color: Color = Color(0.4, 0.9, 1.0)) -> void:
	if toast_label:
		toast_label.text = msg
		toast_label.modulate = color
		_toast_timer = 1.4

func _on_match_timer_updated(seconds_left: float) -> void:
	if not timer_label: return
	if match_manager and match_manager.current_state == MatchManager.MatchState.COUNTDOWN:
		timer_label.text = "STARTS IN: %d" % int(ceil(seconds_left))
		status_banner.text = "ROUND STARTS IN %d" % int(ceil(seconds_left))
		status_banner.modulate = Color(1.0, 0.85, 0.25)
	else:
		var mins: int = int(seconds_left) / 60
		var secs: int = int(seconds_left) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		if status_banner.text.begins_with("ROUND STARTS"):
			status_banner.text = "FIGHT!"
			status_banner.modulate = Color(1.0, 0.3, 0.3)
			var tween: Tween = create_tween()
			tween.tween_property(status_banner, "modulate:a", 0.0, 1.5)
			tween.tween_callback(func(): status_banner.text = "")

	_update_alive_count()

func _update_alive_count() -> void:
	if not alive_label or not get_parent(): return
	var p_node: Node = get_parent().get_node_or_null("Players")
	if p_node:
		var alive: int = 0
		var total: int = 0
		for child in p_node.get_children():
			if child is PlayerController:
				total += 1
				if not child.is_dead:
					alive += 1
		alive_label.text = "WARRIORS: %d / %d" % [alive, max(1, total)]

func _on_match_state_changed(new_state: MatchManager.MatchState) -> void:
	if new_state == MatchManager.MatchState.IN_PROGRESS:
		status_banner.text = "FIGHT!"
		status_banner.modulate = Color(1.0, 0.3, 0.3, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(status_banner, "modulate:a", 0.0, 1.5)
		tween.tween_callback(func(): status_banner.text = "")
	elif new_state == MatchManager.MatchState.COUNTDOWN:
		if results_ui:
			results_ui.visible = false

func _on_match_ended(results: Dictionary) -> void:
	if results_ui:
		results_ui.show_results(results)

func _update_network_status() -> void:
	if not network_label:
		return
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var role: String = "Host (Server)" if multiplayer.is_server() else "Client"
		var net_mgr = get_node_or_null("/root/NetworkManager")
		var count: int = net_mgr.players.size() if net_mgr else 1
		network_label.text = "Role: %s | Warriors: %d" % [role, count]
	else:
		network_label.text = "Mode: Solo Practice"

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
	if curr == "ParryState":
		show_combat_toast("PARRY!", Color(0.2, 0.85, 1.0))
	elif curr == "StaggeredState":
		show_combat_toast("POISE BROKEN!", Color(1.0, 0.4, 0.2))
	elif curr == "KnockedDownState":
		show_combat_toast("KNOCKDOWN!", Color(1.0, 0.2, 0.2))

# --- F3 Diagnostic Debug Overlay ---
var _debug_overlay_label: Label = null
var _show_debug: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_show_debug = not _show_debug
		if _debug_overlay_label:
			_debug_overlay_label.visible = _show_debug

func _update_debug_overlay() -> void:
	if not _show_debug:
		if _debug_overlay_label:
			_debug_overlay_label.visible = false
		return

	if not _debug_overlay_label:
		_debug_overlay_label = Label.new()
		_debug_overlay_label.name = "F3DebugOverlay"
		_debug_overlay_label.position = Vector2(20, 200)
		_debug_overlay_label.add_theme_font_size_override("font_size", 13)
		_debug_overlay_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3, 1.0))
		add_child(_debug_overlay_label)

	_debug_overlay_label.visible = true

	var p_state: String = target_player.state_machine.get_current_state_name() if (target_player and target_player.state_machine) else "None"
	var in_locked: bool = target_player.player_input_locked if target_player else false
	var mov_locked: bool = target_player.movement_locked if target_player else false
	var atk_locked: bool = target_player.attack_locked if target_player else false
	var ab_locked: bool = target_player.ability_locked if target_player else false
	var ddg_locked: bool = target_player.dodge_locked if target_player else false
	
	var ap = target_player._get_anim_player() if target_player else null
	var anim_name = ap.current_animation if ap else "None"
	var anim_speed = ap.speed_scale if ap else 1.0

	var ctc = get_node_or_null("/root/CombatTimeController")
	var ctc_info = ctc.get_debug_info() if (ctc and ctc.has_method("get_debug_info")) else {}

	_debug_overlay_label.text = """[F3 COMBAT DIAGNOSTICS]
Player State: %s
Input Locked: %s | Move Locked: %s | Attack Locked: %s
Ability Locked: %s | Dodge Locked: %s
Anim: %s (Speed: %.2fx)
Time Scale: %.3f (State: %s)
Hitstop Active: %s | Slowmo Active: %s
""" % [
		p_state, str(in_locked), str(mov_locked), str(atk_locked),
		str(ab_locked), str(ddg_locked),
		anim_name, anim_speed,
		Engine.time_scale, ctc_info.get("state", "NORMAL"),
		str(ctc_info.get("hitstop_active", false)), str(ctc_info.get("slowmo_active", false))
	]
