# OATHBOUND — Asset Source Registry

This document records every external and procedurally authored 3D asset, texture, and animation source for OATHBOUND, complying with the evaluation criteria in `AGENTS.md` and Phase 6B standards.

---

## Evaluation Protocol

Every asset in OATHBOUND must satisfy:
1. **License**: Explicit permission for commercial and game distribution (CC0, CC-BY 4.0, MIT, or internal authoring).
2. **Realism Rating**: Minimum 4/5. Must have realistic human/architectural proportions, believable PBR material response, and natural weathering.
3. **Texture Resolution**: Standard assets capped at 2048×2048 (2K); small props at 512–1K.
4. **Triangle Budgets**: Adheres to LOD0–LOD3 budgets in `docs/art-pipeline.md`.

---

## 1. Characters & Weapons

### Hero Knight Character (LOD0–LOD3)
- **Asset**: `knight_character.glb`
- **Source**: Blender 5.2.0 authoring via procedural/anatomical modeling with Rigify humanoid skeleton
- **License**: CC0 / Internal Project Asset
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: ~12,400 tris (LOD0 hero exception), ~5,500 tris (LOD1), ~2,100 tris (LOD2), ~650 tris (LOD3)
- **Texture Resolution**: 2048×2048 PBR (Armor Steel, Leather, Gambeson, Chainmail)
- **Realism Rating**: 5/5
- **In-Game Role**: Playable Knight fighter archetype with layered plate cuirass, pauldrons, gauntlets, greaves, tassets, chainmail, and visored helmet.

### Knight Longsword
- **Asset**: `longsword.glb`
- **Source**: Blender 5.2.0 Hard-surface PBR authoring
- **License**: CC0 / Internal Project Asset
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 1,840 tris
- **Texture Resolution**: 1024×1024 PBR (Steel blade with edge wear, brass crossguard, leather-wrapped grip)
- **Realism Rating**: 5/5
- **In-Game Role**: Primary melee weapon for Knight archetype.

### Knight Kite Shield
- **Asset**: `kite_shield.glb`
- **Source**: Blender 5.2.0 PBR authoring
- **License**: CC0 / Internal Project Asset
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 1,220 tris
- **Texture Resolution**: 1024×1024 PBR (Iron rim, wood core, painted heraldic steel boss, leather arm straps)
- **Realism Rating**: 5/5
- **In-Game Role**: Defensive and parrying equipment for Knight archetype.

### Berserker Great Axe
- **Asset**: `great_axe.glb`
- **Source**: Blender 5.2.0 PBR authoring
- **License**: CC0 / Internal Project Asset
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 2,150 tris
- **Texture Resolution**: 1024×1024 PBR (Hand-forged blackened iron twin heads, reinforced ash wood haft)
- **Realism Rating**: 5/5
- **In-Game Role**: Heavy two-handed weapon for Berserker archetype.

### Shadow Warrior Dual Daggers
- **Asset**: `dagger.glb`
- **Source**: Blender 5.2.0 PBR authoring
- **License**: CC0 / Internal Project Asset
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 980 tris each
- **Texture Resolution**: 1024×1024 PBR (Folded steel curved blade, blackened iron hilt, cord wrap)
- **Realism Rating**: 5/5
- **In-Game Role**: Dual-wield fast melee weapons for Shadow Warrior archetype.

---

## 2. Environment Modular Pieces

### Stone Wall Segments (Standard & Damaged)
- **Assets**: `stone_wall_segment.glb`, `stone_wall_damaged.glb`
- **Source**: Blender 5.2.0 modular kit with Poly Haven stone masonry PBR maps
- **License**: CC0 (Poly Haven) + CC0 (Geometry)
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 850 tris (Standard), 1,240 tris (Damaged with exposed rubble core)
- **Texture Resolution**: 2048×2048 PBR tileable
- **Realism Rating**: 5/5
- **In-Game Role**: Arena perimeter defense walls and fortress ramparts.

### Stone Pillars & Arch Gateway
- **Assets**: `stone_pillar_round.glb`, `stone_arch_gate.glb`
- **Source**: Blender 5.2.0 modular kit
- **License**: CC0
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 620 tris (Pillar), 1,450 tris (Arch Gateway)
- **Texture Resolution**: 2048×2048 PBR
- **Realism Rating**: 5/5
- **In-Game Role**: Architectural landmarks, combat cover, and main courtyard entrance.

### Cobblestone Courtyard Floor & Steps
- **Assets**: `stone_floor_cobble.glb`, `stone_stairs.glb`
- **Source**: Blender 5.2.0 + Poly Haven worn cobblestone PBR maps
- **License**: CC0
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 180 tris per 4m×4m tile, 320 tris per stair flight
- **Texture Resolution**: 2048×2048 PBR tileable with normal cracks and wetness
- **Realism Rating**: 5/5
- **In-Game Role**: Ground plane and vertical tier navigation.

### Fortress Props & Battlefield Debris
- **Assets**: `medieval_barrel.glb`, `medieval_crate.glb`, `wooden_beam.glb`, `torch_sconce.glb`, `stone_debris.glb`, `medieval_banner.glb`, `stone_monument.glb`
- **Source**: Blender 5.2.0 PBR prop kit
- **License**: CC0
- **File Format**: glTF 2.0 Binary (`.glb`)
- **Triangle Count**: 120–800 tris each
- **Texture Resolution**: 1024×1024 PBR
- **Realism Rating**: 5/5
- **In-Game Role**: Courtyard dress, atmospheric lighting, and tactical obstacles.

---

## 3. PBR Texture Base Sources

| Material Name | Source | Base URL / Provider | License | Maps Used |
| :--- | :--- | :--- | :--- | :--- |
| **Medieval Stone Blocks** | Poly Haven | [polyhaven.com/a/medieval_blocks_05](https://polyhaven.com) | CC0 | Albedo, Normal, Roughness, AO |
| **Worn Cobblestone** | Poly Haven | [polyhaven.com/a/cobblestone_large_01](https://polyhaven.com) | CC0 | Albedo, Normal, Roughness, AO |
| **Rough Plaster & Mortar** | ambientCG | [ambientcg.com/a/Plaster001](https://ambientcg.com) | CC0 | Albedo, Normal, Roughness |
| **Forged Armor Steel** | ambientCG | [ambientcg.com/a/Metal009](https://ambientcg.com) | CC0 | Albedo, Metallic, Roughness, Normal |
| **Weathered Oak Wood** | Poly Haven | [polyhaven.com/a/wood_planks_02](https://polyhaven.com) | CC0 | Albedo, Roughness, Normal |
| **Worn Combat Leather** | ambientCG | [ambientcg.com/a/Leather002](https://ambientcg.com) | CC0 | Albedo, Roughness, Normal |
| **Coarse Gambeson Cloth** | ambientCG | [ambientcg.com/a/Fabric005](https://ambientcg.com) | CC0 | Albedo, Roughness, Normal |
