# OATHBOUND — Environment Quality & Material Architecture

## 1. 3-Tier Detail Hierarchy

### Tier 1: Hero Combat Zone (Primary Arena Floor & Immediate Surroundings)
- **Geometry**: High-detail interlocking ashlar stone blocks, beveled masonry edges, damaged coping stones, rubble debris clusters, cracked flagstone floor tiles with mortar crevices.
- **Materials**: Multi-pass PBR with roughness contrast (matte dry stone faces vs. glossy wet recessed mortar), subtle edge wear, moss patches.
- **Lighting**: Contact shadows from directional sun, localized warm light from torch braziers and sconces.

### Tier 2: Secondary Architecture (Perimeter Walls, Gates, Columns, Stairs)
- **Geometry**: Gothic arches with carved voussoirs, crenellated battlements, fluted Romanesque columns, iron-reinforced oak doors and spiked portcullis.
- **Materials**: Weathered stone, oxidized wrought iron bands, rough-hewn oak timber with dark base staining.
- **Lighting**: Soft shadow casting, bounce lighting from stone surfaces.

### Tier 3: Background Silhouette Zone (Framing Geometry)
- **Geometry**: Ruined watchtowers, broken parapets, distant parapet silhouettes enclosing the 40m x 40m arena.
- **Atmosphere**: Depth fog, volumetric haze, atmospheric sky scattering.

---

## 2. PBR Material Definitions

| Material ID | Base Color | Roughness | Metallic | Normal Detail | Surface Characteristics |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Stone_Ashlar** | Warm Grey `(0.55, 0.52, 0.48)` | 0.82 (crevices 0.45) | 0.0 | Chiseled masonry & bevels | Micro-pitting, chipped edges |
| **Stone_Damaged**| Ochre Grey `(0.48, 0.44, 0.39)` | 0.88 | 0.0 | Fractured stone & mortar core| Exposed rubble, broken edges |
| **Iron_Wrought** | Charcoal `(0.18, 0.18, 0.20)` | 0.42 | 0.95 | Hammered texture | Scratched edges, localized rust |
| **Oak_Timber**   | Dark Brown `(0.28, 0.18, 0.10)` | 0.75 | 0.0 | Linear wood grain | Splintered ends, dark damp base |
| **Steel_Armor**  | Silver Grey `(0.72, 0.74, 0.78)`| 0.28 (highlights 0.15)| 0.98 | Fluted plate seams | High specular shine, edge scratches |
| **Brass_Trim**   | Antique Gold `(0.85, 0.68, 0.25)`| 0.35 | 0.85 | Engraved filigree | Warm metallic sheen |
| **Leather_Tanned**| Russet `(0.32, 0.16, 0.08)`     | 0.65 | 0.0 | Subtle pebble grain | Stitched edges, worn creases |
| **Cloth_Heraldic**| Royal Blue / Crimson           | 0.85 | 0.0 | Woven fabric weave | Natural drape folds, hem wear |
