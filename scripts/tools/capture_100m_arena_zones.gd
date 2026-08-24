#!/usr/bin/env -S godot --script
extends SceneTree

## capture_100m_arena_zones.gd — Captures high-fidelity views of all 5 zones in the 100m Arena

var arena_node: Node3D = null
var cam: Camera3D = null
var shot_idx: int = 0

func _init() -> void:
	print("\n=== Capturing OATHBOUND 100m Arena Tactical Zone Overviews ===")
	var scene_res: PackedScene = load("res://scenes/arena/ruined_fortress_100m.tscn")
	if not scene_res:
		printerr("[ERROR] Failed to load ruined_fortress_100m.tscn")
		quit(1)
		return

	arena_node = scene_res.instantiate()
	root.add_child(arena_node)

	cam = Camera3D.new()
	cam.current = true
	cam.fov = 70.0
	arena_node.add_child(cam)

	var timer: Timer = Timer.new()
	timer.wait_time = 0.2
	timer.autostart = true
	arena_node.add_child(timer)
	timer.timeout.connect(_on_timer_step)

func _on_timer_step() -> void:
	var zone_shots = [
		{
			"name": "arena_01_central_battlefield.png",
			"pos": Vector3(0, 8.0, 22.0),
			"target": Vector3(0, 1.0, 0)
		},
		{
			"name": "arena_02_western_ruins.png",
			"pos": Vector3(-18.0, 6.5, 20.0),
			"target": Vector3(-32.0, 2.0, 8.0)
		},
		{
			"name": "arena_03_eastern_courtyard.png",
			"pos": Vector3(16.0, 6.0, 10.0),
			"target": Vector3(32.0, 1.5, -8.0)
		},
		{
			"name": "arena_04_southern_barbican_gate.png",
			"pos": Vector3(0, 5.0, 18.0),
			"target": Vector3(0, 4.0, 48.0)
		},
		{
			"name": "arena_05_upper_battlements_vantage.png",
			"pos": Vector3(0, 12.0, -14.0),
			"target": Vector3(0, 6.0, -36.0)
		}
	]

	if shot_idx >= zone_shots.size():
		print("=== All 5 100m Arena Zone Screenshots Captured Successfully! ===")
		quit(0)
		return

	var shot = zone_shots[shot_idx]
	cam.global_position = shot["pos"]
	cam.look_at(shot["target"], Vector3.UP)

	var img: Image = root.get_texture().get_image()
	if img:
		var save_path: String = "/Users/ramteja/Documents/Blender exp game/docs/screenshots/" + shot["name"]
		img.save_png(save_path)
		print("[SAVED ARENA ZONE %d/5] %s" % [shot_idx + 1, save_path])

	shot_idx += 1
