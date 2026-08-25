# OATHBOUND — Ultimate Visual Milestone Push Report

## Milestone: ULTIMATE VISUAL SHOWCASE BASELINE

---

### 1. Repository & Git Status

| Property | Value |
| :--- | :--- |
| **GitHub Remote** | `https://github.com/pdineshsampathram-spec/OATHBOUND.git` |
| **Active Branch** | `master` (tracking `origin/master`) |
| **Feature Commit Hash** | `525e41f` (*feat(vfx): implement final visual override, dedicated hero assets, and real-time graphics switching*) |
| **Showcase Commit Hash**| `fed9652` (*docs: add Cataclysm of the Seventh Oath visual showcase, walkthrough, and 14-frame ULTRA gallery*) |
| **Milestone Tag** | `ULTIMATE_VISUAL_SHOWCASE_BASELINE` |
| **Push Status** | **100% Pushed & Verified on Remote** |

---

### 2. Screenshot & Asset Verification

| Metric | Detail | Status |
| :--- | :--- | :--- |
| **Total Showcase Frames** | 14 Lossless PNG Frames | **Verified** |
| **Capture Preset** | ULTRA Preset (MSAA 4X, 4K Shadows, Forward+ Metal) | **Verified** |
| **Showcase Directory** | `docs/showcase/ultimate/screenshots/` | **Preserved** |
| **Walkthrough Doc** | `docs/showcase/ultimate/CATACLYSM_OF_THE_SEVENTH_OATH_WALKTHROUGH.md` | **Verified** |
| **Showcase Hub** | `docs/showcase/README.md` | **Verified** |
| **Root Project README** | `README.md` | **Verified** |
| **Metadata File** | `docs/showcase/ultimate/metadata/capture_metadata.json` | **Verified** |

---

### 3. Hardware Performance & Storage Audit

*Measured on Apple M1 Metal Forward+:*

| Metric | LOW Preset | HIGH Preset (M1 Target) | ULTRA Preset (Benchmark) |
| :--- | :--- | :--- | :--- |
| **Average FPS** | **58.6 FPS** | **59.9 FPS** | **57.8 FPS** |
| **Minimum FPS** | 1.0 FPS | **55.0 FPS** | **21.0 FPS** |
| **Peak Draw Calls** | 198 | **129** | **129** |
| **Peak Triangles** | 572,132 | **330,494** | **331,178** |
| **Project Storage** | **1.2 GB total** / 20.0 GB cap (18.8 GB headroom) | | **PASSED** |

---

### 4. Validation Suites (100% Pass Rate)

1. `test_graphics_options_suite.gd`: **PASS** (4/4 stages: Presets, Dialog, Lobby, HUD)
2. `test_ultimate_cinematic_suite.gd`: **PASS** (4/4 stages: Solo/3-target vaporization, mid-cancel, recovery)
3. `test_solo_wave_arena_progression.gd`: **PASS** (Wave 1 lethal vaporization, death signals, Wave 2 transition)
4. `combat_simulation_test.gd`: **PASS** (600 simulated frames, zero time-scale leakage)
