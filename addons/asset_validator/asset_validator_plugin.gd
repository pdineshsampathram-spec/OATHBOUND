@tool
extends EditorPlugin

## EditorPlugin integrating AssetValidator into Godot 4 editor UI.

var tool_button: Button = null

func _enter_tree() -> void:
	tool_button = Button.new()
	tool_button.text = "Validate Assets (AGENTS.md)"
	tool_button.pressed.connect(_on_validate_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, tool_button)
	print("[AssetValidator] Plugin loaded. Tool button added to Editor Toolbar.")

func _exit_tree() -> void:
	if tool_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, tool_button)
		tool_button.free()

func _on_validate_pressed() -> void:
	print("[AssetValidator] Running art pipeline and storage validation...")
	var results: Dictionary = AssetValidator.run_validation()
	var report_md: String = AssetValidator.format_report_markdown(results)

	var f: FileAccess = FileAccess.open("res://docs/asset-validation-report.md", FileAccess.WRITE)
	if f:
		f.store_string(report_md)
		f.close()
		print("[AssetValidator] Report generated -> res://docs/asset-validation-report.md")

	if not results.errors.is_empty():
		push_error("[AssetValidator] Failed with %d error(s)! Check docs/asset-validation-report.md" % results.errors.size())
	elif not results.warnings.is_empty():
		push_warning("[AssetValidator] Passed with %d warning(s). Check docs/asset-validation-report.md" % results.warnings.size())
	else:
		print("[AssetValidator] SUCCESS: All assets & storage allocations comply with AGENTS.md!")
