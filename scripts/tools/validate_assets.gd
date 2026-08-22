@tool
extends SceneTree

## Standalone CLI tool to validate all assets & storage budgets against AGENTS.md.
## Usage: godot --headless --script res://scripts/tools/validate_assets.gd

const AssetValidator = preload("res://addons/asset_validator/validator.gd")

func _init() -> void:
	print("\n=======================================================")
	print("  OATHBOUND — Art Pipeline & Storage Validator (CLI)")
	print("=======================================================\n")

	var results: Dictionary = AssetValidator.run_validation()
	var report_md: String = AssetValidator.format_report_markdown(results)

	# Print to stdout
	print(report_md)

	# Save to docs/asset-validation-report.md
	var f: FileAccess = FileAccess.open("res://docs/asset-validation-report.md", FileAccess.WRITE)
	if f:
		f.store_string(report_md)
		f.close()
		print("\n[INFO] Written report to docs/asset-validation-report.md")

	if not results.errors.is_empty():
		print("\n[RESULT] FAILED with %d errors.\n" % results.errors.size())
		quit(1)
	else:
		print("\n[RESULT] PASSED successfully!\n")
		quit(0)
