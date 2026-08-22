class_name Main
extends Node3D

## Main scene controller for OATHBOUND Phase 1 Vertical Slice.

@onready var player: PlayerController = $Player
@onready var combat_hud: CombatHUD = $CombatHUD

func _ready() -> void:
	if combat_hud and player:
		combat_hud.connect_player(player)
