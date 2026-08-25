extends SceneTree

const GraphicsSettingsClass = preload("res://scripts/graphics_settings.gd")
const LobbyUIClass = preload("res://scripts/ui/lobby_ui.gd")
const CombatHUDClass = preload("res://scripts/ui/combat_hud.gd")

var _frame_count: int = 0
var _test_stage: int = 0
var _dialog_node: Node = null
var _lobby_node: Node = null
var _hud_node: Node = null

func _init() -> void:
	print("============================================================")
	print("RUNNING GRAPHICS SETTINGS & SWITCHING TEST SUITE")
	print("============================================================")
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1
	
	match _test_stage:
		0:
			_test_presets()
			_test_stage = 1
		1:
			_setup_dialog_test()
			_test_stage = 2
		2:
			_verify_dialog_test()
			_test_stage = 3
		3:
			_setup_lobby_test()
			_test_stage = 4
		4:
			_verify_lobby_test()
			_test_stage = 5
		5:
			_setup_hud_test()
			_test_stage = 6
		6:
			_verify_hud_test()
			_test_stage = 7
		7:
			print("\n============================================================")
			print("ALL GRAPHICS SWITCHING TESTS PASSED (100% SUCCESS)")
			print("============================================================")
			quit(0)

func _test_presets() -> void:
	print("\n[TEST 1] Testing GraphicsSettings Presets...")
	
	# Test Low
	GraphicsSettingsClass.apply_preset(GraphicsSettingsClass.QualityPreset.LOW)
	assert(GraphicsSettingsClass.ultimate_quality == GraphicsSettingsClass.QualityPreset.LOW, "Preset should be LOW")
	assert(GraphicsSettingsClass.vfx_density == 0.3, "VFX density should be 0.3 on LOW")
	assert(GraphicsSettingsClass.bloom_enabled == false, "Bloom should be false on LOW")
	print("  ✓ LOW preset verified (VFX density: %.2f, Bloom: %s)" % [GraphicsSettingsClass.vfx_density, GraphicsSettingsClass.bloom_enabled])

	# Test Medium
	GraphicsSettingsClass.apply_preset(GraphicsSettingsClass.QualityPreset.MEDIUM)
	assert(GraphicsSettingsClass.ultimate_quality == GraphicsSettingsClass.QualityPreset.MEDIUM, "Preset should be MEDIUM")
	assert(GraphicsSettingsClass.vfx_density == 0.5, "VFX density should be 0.5 on MEDIUM")
	print("  ✓ MEDIUM preset verified")

	# Test High (M1 Target)
	GraphicsSettingsClass.apply_preset(GraphicsSettingsClass.QualityPreset.HIGH)
	assert(GraphicsSettingsClass.ultimate_quality == GraphicsSettingsClass.QualityPreset.HIGH, "Preset should be HIGH")
	assert(GraphicsSettingsClass.vfx_density == 0.75, "VFX density should be 0.75 on HIGH")
	assert(GraphicsSettingsClass.bloom_enabled == true, "Bloom should be true on HIGH")
	print("  ✓ HIGH (M1 Target) preset verified")

	# Test Ultra
	GraphicsSettingsClass.apply_preset(GraphicsSettingsClass.QualityPreset.ULTRA)
	assert(GraphicsSettingsClass.ultimate_quality == GraphicsSettingsClass.QualityPreset.ULTRA, "Preset should be ULTRA")
	assert(GraphicsSettingsClass.vfx_density == 1.0, "VFX density should be 1.0 on ULTRA")
	print("  ✓ ULTRA preset verified")

	# Restore HIGH
	GraphicsSettingsClass.apply_preset(GraphicsSettingsClass.QualityPreset.HIGH)

func _setup_dialog_test() -> void:
	print("\n[TEST 2] Instantiating GraphicsSettingsDialog...")
	var scn: PackedScene = load("res://scenes/ui/graphics_settings_dialog.tscn")
	assert(scn != null, "GraphicsSettingsDialog scene must load")
	_dialog_node = scn.instantiate()
	root.add_child(_dialog_node)

func _verify_dialog_test() -> void:
	assert(_dialog_node != null, "Dialog node must exist")
	assert(_dialog_node.get_node_or_null("Control/Panel") != null, "Panel must exist")
	assert(_dialog_node.get_node_or_null("Control/Panel/VBoxContainer/PresetRow/LowButton") != null, "LowButton must exist")
	assert(_dialog_node.get_node_or_null("Control/Panel/VBoxContainer/PresetRow/HighButton") != null, "HighButton must exist")
	
	_dialog_node.call("open_dialog")
	assert(_dialog_node.visible == true, "Dialog must be visible when opened")
	_dialog_node.call("close_dialog")
	assert(_dialog_node.visible == false, "Dialog must be hidden when closed")
	
	_dialog_node.queue_free()
	_dialog_node = null
	print("  ✓ GraphicsSettingsDialog successfully instantiated, configured, and toggled")

func _setup_lobby_test() -> void:
	print("\n[TEST 3] Instantiating LobbyUI...")
	var scn: PackedScene = load("res://scenes/ui/lobby_ui.tscn")
	assert(scn != null, "LobbyUI scene must load")
	_lobby_node = scn.instantiate()
	root.add_child(_lobby_node)

func _verify_lobby_test() -> void:
	var graphics_select = _lobby_node.get_node_or_null("Panel/MarginContainer/VBoxContainer/GraphicsRow/GraphicsSelect")
	var settings_btn = _lobby_node.get_node_or_null("Panel/MarginContainer/VBoxContainer/GraphicsRow/SettingsButton")
	assert(graphics_select != null, "GraphicsSelect dropdown must exist in LobbyUI")
	assert(settings_btn != null, "SettingsButton must exist in LobbyUI")
	assert(graphics_select.item_count == 4, "GraphicsSelect must have 4 preset items")
	
	# Test dropdown interaction
	_lobby_node.call("_on_graphics_selected", 0)
	assert(GraphicsSettingsClass.ultimate_quality == GraphicsSettingsClass.QualityPreset.LOW, "Selecting Low must apply LOW")
	
	_lobby_node.call("_on_graphics_selected", 2)
	assert(GraphicsSettingsClass.ultimate_quality == GraphicsSettingsClass.QualityPreset.HIGH, "Selecting High must apply HIGH")
	
	_lobby_node.queue_free()
	_lobby_node = null
	print("  ✓ LobbyUI graphics selector and settings button verified")

func _setup_hud_test() -> void:
	print("\n[TEST 4] Instantiating CombatHUD...")
	var scn: PackedScene = load("res://scenes/ui/combat_hud.tscn")
	assert(scn != null, "CombatHUD scene must load")
	_hud_node = scn.instantiate()
	root.add_child(_hud_node)

func _verify_hud_test() -> void:
	var settings_btn = _hud_node.get_node_or_null("Control/TopBanner/HBoxContainer/SettingsBtn")
	assert(settings_btn != null, "CombatHUD must have SettingsBtn")
	print("  ✓ CombatHUD SettingsBtn verified (text: '%s')" % settings_btn.text)
	
	_hud_node.queue_free()
	_hud_node = null
