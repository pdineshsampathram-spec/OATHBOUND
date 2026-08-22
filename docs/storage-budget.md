# Storage Budget Tracking

**Hard Limit:** 20 GB Max

## Target Allocation
| Category | Budget Target | Current Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Source / Project** | 2–3 GB | ~0.9 MB | Normal | GDScript, scenes, networking, UI, configs |
| **Environment Assets** | 4–5 GB | ~0.5 MB | Normal | 14 Realistic modular .glb assets & PBR materials |
| **Characters & Animations** | 3–4 GB | ~1.1 MB | Normal | Rigged Knight .glb + 4 weapons + animations |
| **Textures & Materials** | 3–4 GB | ~0.1 MB | Normal | PBR materials embedded in .glb (2K max) |
| **Audio & VFX** | 1–2 GB | ~0.1 MB | Normal | In-memory procedural SFX + GPUParticles3D |
| **Cache & Builds** | 3–4 GB | ~2.6 MB | Normal | `.godot` cache |
| **Safety Margin** | ~2 GB | N/A | Available | Buffer to prevent hitting storage ceiling |
| **Total Project** | **20 GB Max** | **~5.2 MB** | **Healthy** | Monitored via `/perf-check` (0.026% of cap) |
