#!/usr/bin/env -S godot --script
extends SceneTree

## build_100m_arena_scene.gd — Generates the authentic 100m x 100m Ruined Fortress Arena

func _init() -> void:
	print("\n=== Generating OATHBOUND 100m x 100m Ruined Fortress Arena ===")

	var arena_root: Node3D = Node3D.new()
	arena_root.name = "RuinedFortress100m"

	# 1. Materials
	var mat_floor: Material = load("res://assets/materials/mat_flagstone_floor.tres")
	var mat_dirt: Material = load("res://assets/materials/mat_ground_dirt.tres")
	var mat_stone: Material = load("res://assets/materials/mat_fortress_sandstone.tres")
	var mat_rubble: Material = load("res://assets/materials/mat_fortress_rubble.tres")
	var mat_wood: Material = load("res://assets/materials/mat_oak_timber.tres")

	# 2. Photogrammetry Prop Scenes
	var prop_fire_pit: PackedScene = load("res://assets/props/stone_fire_pit.glb") if ResourceLoader.exists("res://assets/props/stone_fire_pit.glb") else null
	var prop_gate: PackedScene = load("res://assets/props/large_iron_gate.glb") if ResourceLoader.exists("res://assets/props/large_iron_gate.glb") else null
	var prop_crate: PackedScene = load("res://assets/props/wooden_crate_01.glb") if ResourceLoader.exists("res://assets/props/wooden_crate_01.glb") else null
	var prop_barrel: PackedScene = load("res://assets/props/barrel_03.glb") if ResourceLoader.exists("res://assets/props/barrel_03.glb") else null
	var prop_rocks: PackedScene = load("res://assets/props/rock_moss_set_01.glb") if ResourceLoader.exists("res://assets/props/rock_moss_set_01.glb") else null

	# 3. Environment & Lighting
	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.35, 0.54, 1.0)
	sky_mat.sky_horizon_color = Color(0.68, 0.62, 0.54, 1.0)
	sky_mat.ground_bottom_color = Color(0.18, 0.16, 0.14, 1.0)
	sky_mat.ground_horizon_color = Color(0.55, 0.50, 0.44, 1.0)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.65, 0.62, 0.58, 1.0)
	env.fog_density = 0.003
	env.fog_sky_affect = 0.4
	env_node.environment = env
	arena_root.add_child(env_node)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "DirectionalSun"
	sun.rotation_degrees = Vector3(-42.0, 135.0, 0.0)
	sun.light_color = Color(1.0, 0.94, 0.86, 1.0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	arena_root.add_child(sun)

	# 4. Arena Structure Hierarchy
	var terrain_node: Node3D = Node3D.new()
	terrain_node.name = "Terrain"
	arena_root.add_child(terrain_node)

	var architecture_node: Node3D = Node3D.new()
	architecture_node.name = "Architecture"
	arena_root.add_child(architecture_node)

	var props_node: Node3D = Node3D.new()
	props_node.name = "Props"
	arena_root.add_child(props_node)

	var spawns_node: Node3D = Node3D.new()
	spawns_node.name = "SpawnPoints"
	arena_root.add_child(spawns_node)

	# --- TERRAIN: 100m Ground Floor ---
	# Outer dirt ground (120m x 120m)
	_create_static_box(terrain_node, "OuterGround", Vector3(0, -0.5, 0), Vector3(120, 1.0, 120), mat_dirt)

	# Main Central Plaza Flagstones (45m x 45m)
	_create_static_box(terrain_node, "CentralPlazaFloor", Vector3(0, 0.02, 0), Vector3(45, 0.1, 45), mat_floor)

	# Western Ruins Floor (30m x 30m)
	_create_static_box(terrain_node, "WesternRuinsFloor", Vector3(-32, 0.02, 8), Vector3(30, 0.1, 30), mat_dirt)

	# Eastern Courtyard Floor (30m x 30m)
	_create_static_box(terrain_node, "EasternCourtyardFloor", Vector3(32, 0.02, -8), Vector3(30, 0.1, 30), mat_floor)

	# Southern Barbican Pathway (16m x 35m)
	_create_static_box(terrain_node, "SouthernPathwayFloor", Vector3(0, 0.02, 32), Vector3(16, 0.1, 35), mat_dirt)

	# --- BOUNDARY WALLS (100m x 100m Perimeter) ---
	var wall_h: float = 7.0
	var wall_thick: float = 3.0
	_create_static_box(architecture_node, "NorthPerimeterWall", Vector3(0, wall_h*0.5, -50), Vector3(100, wall_h, wall_thick), mat_stone)
	_create_static_box(architecture_node, "SouthPerimeterWall_L", Vector3(-30, wall_h*0.5, 50), Vector3(40, wall_h, wall_thick), mat_stone)
	_create_static_box(architecture_node, "SouthPerimeterWall_R", Vector3(30, wall_h*0.5, 50), Vector3(40, wall_h, wall_thick), mat_stone)
	_create_static_box(architecture_node, "WestPerimeterWall", Vector3(-50, wall_h*0.5, 0), Vector3(wall_thick, wall_h, 100), mat_stone)
	_create_static_box(architecture_node, "EastPerimeterWall", Vector3(50, wall_h*0.5, 0), Vector3(wall_thick, wall_h, 100), mat_stone)

	# --- ZONE 1: Central Battlefield (0, 0, 0) ---
	# Central Fire Pit
	if prop_fire_pit:
		var fp: Node3D = prop_fire_pit.instantiate()
		fp.name = "CentralFirePit"
		fp.position = Vector3(0, 0.05, 0)
		fp.scale = Vector3(1.5, 1.5, 1.5)
		props_node.add_child(fp)

	# Broken Pillars in Central Plaza
	var pillar_positions = [
		Vector3(-12, 0, -12), Vector3(12, 0, -12),
		Vector3(-12, 0, 12), Vector3(12, 0, 12),
		Vector3(-18, 0, 0), Vector3(18, 0, 0)
	]
	for i in range(pillar_positions.size()):
		var p_pos: Vector3 = pillar_positions[i]
		var p_h: float = 4.5 if i % 2 == 0 else 2.5 # Varied ruined heights
		_create_static_cylinder(architecture_node, "PlazaPillar_%d" % i, p_pos + Vector3(0, p_h*0.5, 0), 1.2, p_h, mat_stone)
		_create_static_box(props_node, "PillarRubble_%d" % i, p_pos + Vector3(0.8, 0.3, 0.6), Vector3(1.6, 0.6, 1.4), mat_rubble)

	# --- ZONE 2: Western Ruins (-32, 0, 8) ---
	# Ruined CQB partition walls
	_create_static_box(architecture_node, "WestRuinWall_1", Vector3(-32, 2.5, -2), Vector3(18, 5.0, 1.5), mat_stone)
	_create_static_box(architecture_node, "WestRuinWall_2", Vector3(-40, 2.0, 14), Vector3(1.5, 4.0, 16), mat_stone)
	_create_static_box(architecture_node, "WestRuinWall_3", Vector3(-24, 1.8, 18), Vector3(1.5, 3.5, 12), mat_stone)
	_create_static_box(architecture_node, "WestArchLintel", Vector3(-32, 4.2, 8), Vector3(8.0, 1.2, 1.5), mat_stone)

	# Supply crates and barrels in Western Ruins
	for i in range(5):
		if prop_crate:
			var cr: Node3D = prop_crate.instantiate()
			cr.position = Vector3(-34 + (i * 2.2), 0.0, 5 + ((i % 2) * 2.0))
			cr.rotation_degrees.y = i * 25.0
			props_node.add_child(cr)
		if prop_barrel:
			var br: Node3D = prop_barrel.instantiate()
			br.position = Vector3(-28 + (i * 1.8), 0.0, 12 - ((i % 2) * 1.5))
			br.rotation_degrees.y = i * 40.0
			props_node.add_child(br)

	# --- ZONE 3: Eastern Courtyard (32, 0, -8) ---
	# Courtyard low walls and mossy rock clusters
	_create_static_box(architecture_node, "EastCourtyardWall_1", Vector3(32, 1.5, 4), Vector3(20, 3.0, 1.2), mat_stone)
	_create_static_box(architecture_node, "EastCourtyardWall_2", Vector3(22, 1.5, -16), Vector3(1.2, 3.0, 16), mat_stone)
	if prop_rocks:
		for i in range(4):
			var rk: Node3D = prop_rocks.instantiate()
			rk.position = Vector3(28 + (i * 3.5), 0.0, -10 + (i * 4.0))
			rk.scale = Vector3(1.8, 1.8, 1.8)
			rk.rotation_degrees.y = i * 65.0
			props_node.add_child(rk)

	# --- ZONE 4: Southern Gate / Barbican (0, 0, 38) ---
	# Twin gatehouse towers
	_create_static_box(architecture_node, "GatehouseTower_L", Vector3(-7.5, 4.5, 48), Vector3(6.0, 9.0, 6.0), mat_stone)
	_create_static_box(architecture_node, "GatehouseTower_R", Vector3(7.5, 4.5, 48), Vector3(6.0, 9.0, 6.0), mat_stone)
	_create_static_box(architecture_node, "GatehouseArch", Vector3(0, 7.5, 48), Vector3(10.0, 3.0, 4.0), mat_stone)
	if prop_gate:
		var gt: Node3D = prop_gate.instantiate()
		gt.name = "BarbicanPortcullis"
		gt.position = Vector3(0, 0, 48)
		gt.scale = Vector3(1.8, 1.8, 1.8)
		props_node.add_child(gt)

	# --- ZONE 5: Upper Battlements (0, 6.0, -35) ---
	# Raised Stone Platform (35m x 14m, Height 6m)
	_create_static_box(architecture_node, "BattlementPlatform", Vector3(0, 3.0, -38), Vector3(35, 6.0, 14), mat_stone)
	# Wooden Walkway surface
	_create_static_box(architecture_node, "BattlementWoodDeck", Vector3(0, 6.05, -38), Vector3(35, 0.1, 14), mat_wood)
	# Stone Parapet / Crenellations
	_create_static_box(architecture_node, "BattlementParapet_Fwd", Vector3(0, 6.7, -31.2), Vector3(35, 1.4, 0.8), mat_stone)
	# Access Stairs Ramp (Width 5m, Rise 6m, Run 14m)
	var stairs_l: StaticBody3D = _create_static_box(architecture_node, "StairsRamp_West", Vector3(-15, 3.0, -24), Vector3(4.0, 0.6, 14.0), mat_stone)
	stairs_l.rotation_degrees.x = -23.0
	var stairs_r: StaticBody3D = _create_static_box(architecture_node, "StairsRamp_East", Vector3(15, 3.0, -24), Vector3(4.0, 0.6, 14.0), mat_stone)
	stairs_r.rotation_degrees.x = -23.0

	# --- 5 TACTICAL SPAWN POINTS ---
	var spawns = [
		{"name": "Spawn_Central", "pos": Vector3(0, 0.5, -16)},
		{"name": "Spawn_WestRuins", "pos": Vector3(-32, 0.5, 8)},
		{"name": "Spawn_EastCourtyard", "pos": Vector3(30, 0.5, -8)},
		{"name": "Spawn_SouthGate", "pos": Vector3(0, 0.5, 34)},
		{"name": "Spawn_Battlements", "pos": Vector3(0, 6.5, -36)}
	]
	for sp in spawns:
		var marker: Marker3D = Marker3D.new()
		marker.name = sp["name"]
		marker.position = sp["pos"]
		spawns_node.add_child(marker)

	# 5. Pack and Save PackedScene
	_set_owner_recursive(arena_root, arena_root)
	var packed_scene: PackedScene = PackedScene.new()
	var pack_err: Error = packed_scene.pack(arena_root)
	if pack_err != OK:
		printerr("[ERROR] Failed to pack arena scene: %d" % pack_err)
		quit(1)
		return

	var save_path: String = "res://scenes/arena/ruined_fortress_100m.tscn"
	var save_err: Error = ResourceSaver.save(packed_scene, save_path)
	if save_err != OK:
		printerr("[ERROR] Failed to save %s: %d" % [save_path, save_err])
		quit(1)
		return

	print("[SUCCESS] Successfully created and saved 100m Arena: %s" % save_path)
	quit(0)

static func _create_static_box(parent: Node, node_name: String, pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = pos

	var col: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	if mat:
		mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	parent.add_child(body)
	return body

static func _create_static_cylinder(parent: Node, node_name: String, pos: Vector3, radius: float, height: float, mat: Material) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = pos

	var col: CollisionShape3D = CollisionShape3D.new()
	var cyl_shape: CylinderShape3D = CylinderShape3D.new()
	cyl_shape.radius = radius
	cyl_shape.height = height
	col.shape = cyl_shape
	body.add_child(col)

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var cyl_mesh: CylinderMesh = CylinderMesh.new()
	cyl_mesh.top_radius = radius
	cyl_mesh.bottom_radius = radius
	cyl_mesh.height = height
	mesh_inst.mesh = cyl_mesh
	if mat:
		mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	parent.add_child(body)
	return body

static func _set_owner_recursive(node: Node, root_node: Node) -> void:
	if node != root_node:
		node.owner = root_node
	for child in node.get_children():
		_set_owner_recursive(child, root_node)
