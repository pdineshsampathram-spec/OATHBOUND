# OATHBOUND — Blender Art Pipeline & Import Standards

This guide outlines the standard operating procedure for authoring 3D assets in Blender and importing them into Godot 4 Forward+ engine under OATHBOUND's hardware constraints (MacBook Air M1 8GB RAM, 20GB hard storage cap).

---

## 1. Hard Constraints & Budgets (AGENTS.md)

- **Performance Target**: 60 FPS capped (VSync ON), minimum 40 FPS floor at "Low" quality.
- **Renderer**: Forward+ (glTF 2.0 binary `.glb` format only; **NO FBX**).
- **Texture Resolutions**:
  - Maximum **2048×2048 (2K)** for all environment, prop, and standard character textures.
  - Textures above 2K are strictly restricted to the `/assets/hero_assets` folder.
  - Normal maps: BC5 / RGTC compression or PNG 16-bit.
  - Roughness / Metallic / AO: Packed into a single RMA texture (R = Occlusion, G = Roughness, B = Metallic).

---

## 2. Triangle Budgets by LOD Tier

| LOD Tier | Distance Range | Triangle Budget (Max) | Usage |
| :--- | :--- | :--- | :--- |
| **LOD0** | 0 – 10m | **10,000 tris** | Close-up hero props, character models, central arena landmarks |
| **LOD1** | 10 – 25m | **5,000 tris** | Standard combat viewing distance |
| **LOD2** | 25 – 50m | **2,000 tris** | Perimeter walls, arena arches, background architecture |
| **LOD3** | 50m+ | **500 tris** | Distant silhouettes, skybox elements, spectator stands |

---

## 3. Blender Export Workflow

### Naming Conventions
- Assets: `snake_case` (e.g. `stone_pillar_large.glb`, `arena_gate_arch.glb`)
- Multi-LOD assets:
  - `prop_name_lod0.glb`
  - `prop_name_lod1.glb`
  - `prop_name_lod2.glb`
  - `prop_name_lod3.glb`
- Colliders created in Blender:
  - Add `-col` suffix to mesh name for static collision (e.g. `stone_pillar-col`)
  - Add `-convcol` for convex hull collision (e.g. `arena_statue-convcol`)

### glTF 2.0 Binary (.glb) Export Settings
1. **Format**: `glTF Binary (.glb)`
2. **Include**: Selected Objects (Mesh, Material)
3. **Transform**:
   - `+Y Up` checked
   - `Apply Modifiers` checked
4. **Geometry**:
   - `Normals`: Export checked
   - `Tangents`: Export checked (if normal mapped)
   - `UVs`: Export checked
   - `Vertex Colors`: Export only if used for dirt/shading masks
5. **Animation / Skinning**: Disabled for static environment props; enabled only for character rigs.

---

## 4. Automated Import Validation

Run the validation tool at any time to verify compliance with all AGENTS.md rules:

### In-Editor:
Click the **"Validate Assets (AGENTS.md)"** button on the Godot Editor top toolbar.

### Via Command Line / CI:
```bash
godot --headless --script res://scripts/tools/validate_assets.gd
```

The output report will be generated and saved to [`docs/asset-validation-report.md`](file:///Users/ramteja/Documents/Blender%20exp%20game/docs/asset-validation-report.md).
