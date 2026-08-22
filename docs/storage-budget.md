# Storage Budget Tracking

**Hard Limit:** 20 GB Max

## Target Allocation
| Category | Budget Target | Current Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Source / Project** | 2–3 GB | ~1.1 MB | Normal | GDScript, scenes, networking, UI, configs |
| **Environment Assets** | 4–5 GB | ~1.2 MB | Normal | 16 High-fidelity fortress modular .glb assets & PBR materials |
| **Characters & Animations** | 3–4 GB | ~1.6 MB | Normal | Hero Knight .glb + Hero weapons + 14 biomechanic animations |
| **Textures & Materials** | 3–4 GB | ~0.1 MB | Normal | PBR materials embedded in .glb (2K max) |
| **Audio & VFX** | 1–2 GB | ~0.1 MB | Normal | In-memory procedural SFX + GPUParticles3D |
| **Cache & Builds** | 3–4 GB | ~2.9 MB | Normal | `.godot` cache |
| **Safety Margin** | ~2 GB | N/A | Available | Buffer to prevent hitting storage ceiling |
| **Total Project** | **20 GB Max** | **~6.9 MB** | **Healthy** | Monitored via `/perf-check` (0.034% of cap) |
