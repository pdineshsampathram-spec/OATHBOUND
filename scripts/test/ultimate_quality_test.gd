class_name UltimateQualityTest
extends Node3D

## UltimateQualityTest — Benchmark harness for OATHBOUND ASCENDANCE.
## Provides deterministic respawning of 3 enemy targets and repeated trigger capability for visual inspection.

const UltimateVFXController = preload("res://scripts/vfx/ultimate_vfx_controller.gd")

@onready var knight: PlayerController = $Knight
@onready var enemies_container: Node3D = $Enemies
@onready var test_btn: Button = $CanvasLayer/Control/TestButton
@onready var status_lbl: Label = $CanvasLayer/Control/StatusLabel
@onready var combat_hud: CombatHUD = $CombatHUD

var _is_running_ultimate: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	test_btn.pressed.connect(_on_test_button_pressed)
	
	if combat_hud and knight:
		combat_hud.connect_player(knight)
	
	_respawn_enemies()
	status_lbl.text = "Press 'Test Ultimate' or [R] key to trigger 4.5s cinematic sequence."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ultimate"):
		_on_test_button_pressed()

func _on_test_button_pressed() -> void:
	if _is_running_ultimate:
		return

	_is_running_ultimate = true
	test_btn.disabled = true
	status_lbl.text = "Executing OATHBOUND ASCENDANCE (4.5s)..."

	# Respawn enemies if dead
	_respawn_enemies()

	var targets: Array = enemies_container.get_children()
	
	# Launch OATHBOUND ASCENDANCE
	UltimateVFXController.launch_ascendance(knight, targets, _on_ultimate_finished)

func _on_ultimate_finished() -> void:
	_is_running_ultimate = false
	test_btn.disabled = false
	status_lbl.text = "Sequence Complete. Ready for next test."

func _respawn_enemies() -> void:
	# Clear existing
	for child in enemies_container.get_children():
		child.queue_free()

	var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
	var offsets: Array[Vector3] = [
		Vector3(0, 0, -3.8),     # Center enemy
		Vector3(-2.4, 0, -5.2),  # Left enemy
		Vector3(2.4, 0, -5.2)    # Right enemy
	]
	var classes: Array[String] = ["Berserker", "Shadow Warrior", "Knight"]

	for i in range(3):
		var enemy: PlayerController = player_scene.instantiate() as PlayerController
		enemy.name = "TargetEnemy_%d" % (i + 1)
		enemy.position = knight.position + offsets[i]
		enemy.sync_character_class = classes[i]
		enemy.is_ai = true
		enemy.is_local_player = false
		enemies_container.add_child(enemy)
