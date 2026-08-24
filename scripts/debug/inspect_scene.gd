extends SceneTree

func _init() -> void:
	print("--- INSPECTING HERO KNIGHT & PLAYER SCENE ---")
	var knight_scene: PackedScene = load("res://assets/characters/hero_knight.glb")
	if knight_scene:
		var knight: Node = knight_scene.instantiate()
		print("Hero Knight instantiated successfully:")
		_print_tree_recursive(knight, 0)
	else:
		print("FAILED to load hero_knight.glb")
	
	print("\n--- INSPECTING PLAYER.TSCN ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if player_scene:
		var player: Node = player_scene.instantiate()
		print("Player instantiated successfully:")
		_print_tree_recursive(player, 0)
	else:
		print("FAILED to load player.tscn")
	
	quit()

func _print_tree_recursive(node: Node, depth: int) -> void:
	var indent: String = "  ".repeat(depth)
	var extra: String = ""
	if node is AnimationPlayer:
		var ap: AnimationPlayer = node as AnimationPlayer
		var anims: PackedStringArray = ap.get_animation_list()
		extra = " [AnimationPlayer with %d anims: %s]" % [anims.size(), ", ".join(anims)]
	elif node is Skeleton3D:
		var skel: Skeleton3D = node as Skeleton3D
		extra = " [Skeleton3D with %d bones]" % skel.get_bone_count()
	elif node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		extra = " [MeshInstance3D with %s]" % (mi.mesh.resource_name if mi.mesh else "no mesh")
	
	print("%s%s (%s)%s" % [indent, node.name, node.get_class(), extra])
	for child in node.get_children():
		_print_tree_recursive(child, depth + 1)
