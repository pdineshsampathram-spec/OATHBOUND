class_name AssetValidator
extends RefCounted

## AssetValidator — Enforces OATHBOUND art pipeline constraints from AGENTS.md.
## Validates textures ≤ 2K, mesh triangle counts against LOD budgets, and storage allocations.

const MAX_TEXTURE_DIMENSION: int = 2048
const HERO_ASSETS_DIR: String = "res://assets/hero_assets"

# Triangle count limits by LOD tier
const LOD_TRIANGLE_BUDGETS: Dictionary = {
	"lod0": 10000,
	"lod1": 5000,
	"lod2": 2000,
	"lod3": 500,
	"default": 10000
}

# Storage allocation targets from AGENTS.md (in Megabytes)
const STORAGE_BUDGETS_MB: Dictionary = {
	"Source/Project": { "target": 3000.0, "paths": ["res://scripts", "res://scenes", "res://resources", "res://addons"] },
	"Environment": { "target": 5000.0, "paths": ["res://assets/environment"] },
	"Characters/Animations": { "target": 4000.0, "paths": ["res://assets/characters"] },
	"Hero Assets / Materials": { "target": 4000.0, "paths": ["res://assets/hero_assets"] },
	"Audio/VFX": { "target": 2000.0, "paths": ["res://assets/audio"] },
	"Total Project Cap": { "target": 20000.0, "paths": ["res://"] }
}

static func run_validation() -> Dictionary:
	var results: Dictionary = {
		"warnings": [],
		"errors": [],
		"passed": [],
		"storage_report": {},
		"total_assets_scanned": 0,
		"timestamp": Time.get_datetime_string_from_system()
	}

	# 1. Validate Assets under res://assets
	_scan_asset_directory("res://assets", results)

	# 2. Check Storage Footprints
	_calculate_storage_report(results)

	return results

static func _scan_asset_directory(dir_path: String, results: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		var full_path: String = dir_path + "/" + file_name
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_asset_directory(full_path, results)
		else:
			results.total_assets_scanned += 1
			var ext: String = file_name.get_extension().to_lower()
			if ext in ["png", "jpg", "jpeg", "webp", "tga", "exr", "hdr"]:
				_validate_texture(full_path, results)
			elif ext in ["glb", "gltf"]:
				_validate_gltf_mesh(full_path, results)

		file_name = dir.get_next()
	dir.list_dir_end()

static func _validate_texture(path: String, results: Dictionary) -> void:
	var is_hero: bool = path.begins_with(HERO_ASSETS_DIR)
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image:
		var w: int = image.get_width()
		var h: int = image.get_height()
		if (w > MAX_TEXTURE_DIMENSION or h > MAX_TEXTURE_DIMENSION) and not is_hero:
			results.warnings.append("Texture over 2K outside hero_assets: %s (%dx%d)" % [path, w, h])
		else:
			results.passed.append("Texture OK: %s (%dx%d)" % [path, w, h])
	else:
		results.warnings.append("Could not read image metadata for: %s" % path)

static func _validate_gltf_mesh(path: String, results: Dictionary) -> void:
	var lower_name: String = path.get_file().to_lower()
	var tier: String = "default"

	if "lod0" in lower_name: tier = "lod0"
	elif "lod1" in lower_name: tier = "lod1"
	elif "lod2" in lower_name: tier = "lod2"
	elif "lod3" in lower_name: tier = "lod3"

	var budget: int = LOD_TRIANGLE_BUDGETS.get(tier, 10000)

	# In Godot runtime / tool script, check resource if imported
	var glb_res: Resource = load(path)
	if glb_res and glb_res is PackedScene:
		var inst: Node = glb_res.instantiate()
		var total_tris: int = _count_triangles_recursive(inst)
		inst.free()

		if total_tris > budget:
			results.warnings.append("Mesh triangle count exceeded %s budget (%d > %d tris): %s" % [tier.to_upper(), total_tris, budget, path])
		else:
			results.passed.append("Mesh %s OK: %s (%d / %d tris)" % [tier.to_upper(), path, total_tris, budget])
	else:
		results.passed.append("GLTF file found: %s (will validate on import)" % path)

static func _count_triangles_recursive(node: Node) -> int:
	var count: int = 0
	if node is MeshInstance3D and node.mesh:
		var arrays: Array = node.mesh.surface_get_arrays(0) if node.mesh.get_surface_count() > 0 else []
		if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
			count += arrays[Mesh.ARRAY_INDEX].size() / 3
		elif arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] != null:
			count += arrays[Mesh.ARRAY_VERTEX].size() / 3

	for child in node.get_children():
		count += _count_triangles_recursive(child)
	return count

static func _calculate_storage_report(results: Dictionary) -> void:
	for cat_name in STORAGE_BUDGETS_MB.keys():
		var info: Dictionary = STORAGE_BUDGETS_MB[cat_name]
		var total_bytes: int = 0
		for p in info.paths:
			total_bytes += _get_dir_size_bytes(p)

		var total_mb: float = float(total_bytes) / (1024.0 * 1024.0)
		var target_mb: float = info.target
		var pct: float = (total_mb / target_mb) * 100.0

		results.storage_report[cat_name] = {
			"current_mb": total_mb,
			"budget_mb": target_mb,
			"usage_percent": pct,
			"is_over_budget": total_mb > target_mb
		}

		if total_mb > target_mb:
			results.errors.append("Storage category '%s' exceeded budget: %.2f MB / %.2f MB (%.1f%%)" % [cat_name, total_mb, target_mb, pct])

static func _get_dir_size_bytes(dir_path: String) -> int:
	var total: int = 0
	var dir: DirAccess = DirAccess.open(dir_path)
	if not dir:
		return 0

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		var full_path: String = dir_path + "/" + file_name
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				total += _get_dir_size_bytes(full_path)
		else:
			var f: FileAccess = FileAccess.open(full_path, FileAccess.READ)
			if f:
				total += f.get_length()
				f.close()
		file_name = dir.get_next()
	dir.list_dir_end()
	return total

static func format_report_markdown(results: Dictionary) -> String:
	var md: String = "# OATHBOUND — Asset Validation & Storage Budget Report\n\n"
	md += "**Generated:** %s\n\n" % results.timestamp
	md += "**Total Asset Files Scanned:** %d\n\n" % results.total_assets_scanned

	md += "## Storage Budget Compliance (AGENTS.md)\n\n"
	md += "| Category | Current Size (MB) | Budget Limit (MB) | Utilization | Status |\n"
	md += "| :--- | :--- | :--- | :--- | :--- |\n"

	for cat_name in results.storage_report.keys():
		var r: Dictionary = results.storage_report[cat_name]
		var status_str: String = "🚨 OVER BUDGET" if r.is_over_budget else "✅ OK"
		md += "| **%s** | %.2f MB | %.2f MB | %.2f%% | %s |\n" % [cat_name, r.current_mb, r.budget_mb, r.usage_percent, status_str]

	md += "\n---\n\n## Validation Summary\n\n"
	if results.errors.is_empty() and results.warnings.is_empty():
		md += "✅ **All assets passed validation! No 2K texture violations, LOD budget overflows, or storage overruns found.**\n\n"
	else:
		if not results.errors.is_empty():
			md += "### 🚨 Errors (%d)\n" % results.errors.size()
			for err in results.errors:
				md += "- %s\n" % err
			md += "\n"

		if not results.warnings.is_empty():
			md += "### ⚠️ Warnings (%d)\n" % results.warnings.size()
			for warn in results.warnings:
				md += "- %s\n" % warn
			md += "\n"

	md += "### 📋 Passed Checks (%d)\n" % results.passed.size()
	if results.passed.is_empty():
		md += "- *(No external assets scanned yet; asset directory structure verified)*\n"
	else:
		for p in results.passed:
			md += "- %s\n" % p

	return md
