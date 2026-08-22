# Storage Budget Tracking

**Hard Limit:** 20 GB Max

## Target Allocation
| Category | Budget Target | Current Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Source / Project** | 2–3 GB | ~484 KB | Normal | GDScript, scenes, configs |
| **Environment Assets** | 4–5 GB | 0 MB | Normal | Blockout geometry in .tscn |
| **Characters & Animations** | 3–4 GB | 4 KB | Normal | CharacterData resource |
| **Textures & Materials** | 3–4 GB | 0 MB | Normal | StandardMaterial3D in .tscn |
| **Audio & VFX** | 1–2 GB | 0 MB | Normal | Procedural tweens |
| **Cache & Builds** | 3–4 GB | ~1 MB | Normal | `.godot` cache |
| **Safety Margin** | ~2 GB | N/A | Available | Buffer to prevent hitting storage ceiling |
| **Total Project** | **20 GB Max** | **~1.5 MB** | **Healthy** | Monitored via `/perf-check` |
