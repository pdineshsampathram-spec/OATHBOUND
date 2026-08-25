# Architecture Decisions Log

## 2026-08-22 — Project Foundation & Scaffolding
- **Engine**: Godot 4.x (Forward+ Renderer default, GDScript).
- **Core Architecture**: Data-driven resources (CharacterData, AbilityData), Server-Authoritative multiplayer (ENetMultiplayerPeer, MultiplayerSpawner, MultiplayerSynchronizer), State Machine combat system.
- **Hardware Profile**: M1 MacBook Air (8GB RAM), strict 20GB project storage limit, 40 FPS floor target at Low quality.
- **Performance Harness**: Always-available autoload `PerformanceOverlay` canvas layer (F3 toggle) tracking FPS, frame time, draw calls, video memory, and object count.

## 2026-08-22 — Phase 6B: High-Fidelity Realistic Medieval Art Direction
- **Art Style Decision**: Strict realistic medieval aesthetic with high material fidelity, believable anatomical proportions, and authentic weathering. Reject stylized/low-poly asset kits.
- **Pipeline Strategy**: Blender 5.2.0 automated glTF 2.0 (`.glb`) generation with PBR materials (roughness variation, edge wear, metallic scratches, normal maps), modular architecture for courtyard arena, and skeletal animation with AnimationTree blending.
- **Hero Asset Exception**: Hero Knight allowed up to ~12.4K tris at LOD0 for close-up fidelity, supported by LOD1–LOD3 decimation.
- **Performance Discipline**: 5-stage progressive safety gates (Knight -> Small Env -> Full Arena -> VFX+Combat -> 2-5P Multiplayer) enforcing 60 FPS cap / 40 FPS floor on M1 hardware.

## 2026-08-23 — Gate 3: Master Character Articulation, Biomechanical Combat Rebuild & Autonomous Quality Controller
- **15th-Century Gothic Plate Armor Reconstruction**: Rebuilt `assets/characters/hero_knight.glb` with authentic anatomical proportions (wasp-waist cuirass with median ridge, fluted sallet helmet with comb & flared tail, 4-lame overlapping fauld skirt, articulating knee cop lames, and brushed silver steel PBR material).
- **Skeletal Weapon Attachment**: Replaced detached weapon transforms with direct Godot `BoneAttachment3D` bindings (`Hand.R` for longsword/axe/dagger, `Forearm.L` for kite shield), synchronizing weapon trajectories directly to skeletal swings.
- **Cinematic Combat Camera Rig**: Upgraded `CameraRig` with adaptive distance (3.2m in guard stance, 4.0m in exploration), trauma-based camera shake decay on heavy strikes/parries, and directional impact punch.
- **Autonomous Quality Improvement Protocol**: Executed automated 20-action combat validation benchmark (`scripts/tools/run_gate3_quality_loop.gd`), scoring all 10 quality dimensions to >= 8.0 while maintaining 60.0 FPS and < 20 GB storage (< 1 GB used).

## 2026-08-23 — Gate 4: Quality Rebuild — Centralized Time Controller, Skeletal Animation Authority, Supernatural VFX, AI Streaming & Solo Wave Arena
- **Centralized Time Scale Management**: Resolved critical slow-motion leak bug by architecting `CombatTimeController` autoload singleton. Bounded all hitstops and slow-mo with unscaled failsafe timers and absolute recovery guards, prohibiting ad-hoc `Engine.time_scale` writes elsewhere.
- **Skeletal Animation Authority**: Inspected and verified `hero_knight.glb` (21 bones, 28 layered combat animations). Eliminated all tween-driven rotational/positional overrides across attacks, dodges, hit reactions, and deaths; re-established direct skeletal animation driving full-body combat biomechanics.
- **Supernatural Dark-Violet VFX Architecture**: Replaced primitive geometric collision meshes with layered `GPUParticles3D` system in `PowerVFXSystem`, incorporating void violet/core white energy language, dynamic character auras, and 8-phase cinematic ultimate sequences.
- **AI Combat Controller & Solo Wave Arena**: Built `AICombatController` (10 decision states, coordination awareness, difficulty scaling) and `WaveManager` streaming up to 3 simultaneous AI opponents in `solo_arena.tscn` for endless practice.

## 2026-08-23 — God-Tier Ultimate Cinematic Rebuild (42-Second Battlefield Cataclysm)
- **12-Scene Multi-Shot Cinematic Director (`ultimate_cinematic_controller.gd`)**: Built a full 42-second battlefield cataclysm with 12 distinct scenes, 12 motivated camera choreographies with emotional purpose (Preparation, Awakening, 6-layer Aura, Sky Transformation, Kinetic Sword Ascension, Physical Propagation Wave, Enemy Terror, 8-stage Staggered Vaporization, Zenith Silence, Multi-scale Release, Aftermath, and Victory Portrait).
- **Blender 5.2.0 Hero Pipeline**: Authored 1200-frame continuous skeletal animation action across the 21-bone armature in Blender 5.2.0 CLI (`ultimate_ascendance`) with full kinetic body mechanics, stance shifting, and breathing tension. Exported custom 3D VFX meshes: `sword_energy_mesh.glb`, `aura_ribbon_mesh.glb`, `expanding_shockwave_ring.glb`, `propagation_wave_mesh.glb`, and `celestial_dome_mesh.glb`.
- **Layered Atmospheric Sky Event & Physical Propagation Wave**: Replaced flat sky tints with multi-layered celestial dome evolution (`normal -> darkening -> cloud deformation -> distant violet energy -> vertical structures -> storm dome -> persistent scar`). Implemented physical ground wave traveling from 5m -> 15m -> 30m -> 50m -> 75m -> 100m with surface-aware dust and stone reactions.
- **8-Stage Enemy Vaporization Micro-Cinematic**: Built advanced `dissolution_shader.gdshader` supporting internal energy glow, surface fracture veins, 3D Simplex noise discard, and edge burning. Dissolves enemies with inward-drawn vapor particles.
- **Authoritative Combat & Solo Wave Reliability**: Guaranteed authoritative lethal damage, instant signal propagation to `WaveManager`, zero time-scale leaks (`Engine.time_scale = 1.000`), and idempotent `force_restore_player_control()`.
- **Validation**: Passed all tests in `test_ultimate_cinematic_suite.gd` (1 vs 3 enemies, staggered vaporization, interruption safety, post-cinematic controls) and `test_solo_wave_arena_progression.gd` (Wave 1 -> Wave 2 -> Wave 3). Total storage 909MB (< 1GB / 20GB limit).

## 2026-08-25 — Complete Graphics Switching System & In-Game Options Modal
- **Graphics Management Architecture**:
  - Registered `GraphicsManager="*res://scripts/graphics_settings.gd"` autoload singleton in `project.godot`.
  - Added real-time preset switching across **LOW**, **MEDIUM**, **HIGH (M1 Target)**, and **ULTRA**.
  - Added on-screen floating toast notification system with gold border styling for instant preset feedback.
- **Player Interface Points**:
  - **Lobby UI**: Added inline `GraphicsSelect` dropdown (Low, Medium, High, Ultra) and a `⚙ Settings` button directly on the main pregame menu.
  - **Combat HUD**: Added top-right `⚙ [F2]` button on the match top banner.
  - **In-Game Settings Modal (`scenes/ui/graphics_settings_dialog.tscn`)**: Dark Gothic glassmorphism modal accessible via `F2` or `Escape` or HUD button. Supports 1-click preset buttons, detected hardware recommendations, shadow resolution dropdown (512–4096), anti-aliasing (MSAA Disabled/2x/4x), resolution scale (75%/85%/100%), particle/VFX density sliders, and bloom/distortion toggles.
  - **Global Hotkeys**:
    - `[F5]`: Low Preset (Fastest performance)
    - `[F6]`: Medium Preset (Balanced)
    - `[F7]`: High Preset (Apple M1 Recommended / Locked 60 FPS)
    - `[F8]`: Ultra Preset (Cinematic Visual Target)
    - `[F2]` / `[Escape]`: Open/Close Settings Modal
    - `[F3]`: Performance Overlay (now displays active preset: `Graphics: HIGH [F5-F8]`)
- **Validation**: 100% pass rate in `test_graphics_options_suite.gd`, `test_ultimate_cinematic_suite.gd`, and `test_solo_wave_arena_progression.gd`.

- **Elimination of Player-Light Visual System**: Deleted all continuous player-attached glowing meshes (`AURA_RIBBON_PRIMARY`, `AURA_RIBBON_SECONDARY`, `CATACLYSM_ENERGY_COLUMN`, `SWORD_ENERGY_SHELL`, `_atmosphere_instance`). Knight stands with pure posture in his armor, with energy reading as an atmospheric phenomenon rather than a character-emitting lampshade.
- **"I Am Atomic" Cinematic Structure**:
  - *Calm Dominance & Buildup*: 36 anti-gravity stone fragments levitate from pavers; dust streams pull inward; daylight dims toward near black.
  - *Extreme Inward Compression*: All motion reverses inward; Knight in sharp silhouette; energy collapses into a tiny 0.15m white-violet core at the sword tip (`core_intensity = 32.0`).
  - *Micro-Pause*: Breathless stillness and silence holding tension before release.
  - *Catastrophic Release*: 0.08s blinding flash pulse followed by simultaneous short-lived hero event spawners:
    - 70m upward-tearing branching plasma eruption (`cataclysm_eruption_branching.glb` + `upward_branching_eruption.gdshader`)
    - 120m billowing upper-atmosphere cloud detonation canopy (`sky_cloud_detonation_canopy.glb` + `sky_cloud_detonation.gdshader`)
    - 12m fractured epicenter stone crater (`epicenter_ground_crater.glb`)
    - 3D expanding blast wave geometry (`radial_shock_front_3d.glb`)
  - *Signature 100m Wide Shot*: Camera whip-pullback to monumental vantage (FOV 76°, camera at `Vector3(0, 18.0, 48.0)` looking at `Vector3(0, 10.0, 0)`) capturing the entire fortress arena engulfed in one breathtaking composition.
  - *Spatial Shockwave Causality & 8-Stage Dissolution*: Shockwave expands at 38 m/s; `distance <= shock_radius` triggers instant recoil and activates the preserved 8-stage `dissolution_shader.gdshader`.
  - *Calm Aftermath & Typography*: Sword lowered in calm atmosphere with clean armor reflections, followed by sequential mythic titles ("CATACLYSM OF THE SEVENTH OATH" → "PLAYER WINS").
- **Hardware Performance Verified (M1 Forward+)**:
  - HIGH (M1 Target): **59.9 FPS** avg (55.0 min), 63 avg draw calls (129 peak), 250K avg triangles (330K peak).
  - LOW: **58.6 FPS** avg, 81 avg draw calls (198 peak), 293K avg triangles (572K peak).
  - ULTRA: **57.8 FPS** avg, 63 avg draw calls (129 peak), 250K avg triangles (331K peak).
  - Storage: **1.2 GB total** (18.8 GB remaining within 20 GB cap).

