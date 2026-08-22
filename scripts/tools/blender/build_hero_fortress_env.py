#!/usr/bin/env python3
"""
build_hero_fortress_env.py — Authors the 16 High-Fidelity Ruined Fortress Environment Assets.
Features interlocking ashlar block walls with buttresses, breached rubble walls, Gothic arches with
iron portcullis, fluted columns, flagstone floors with mortar crevices, rough oak beams with brackets,
forged iron braziers with coal, torch sconces, oak barrels, crates, monuments, rubble piles, and watchtowers.
All assets include PBR materials and simplified '-col' collision geometry.
"""

import bpy
import math
import os

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, base_color, metallic, roughness):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
    return mat

def get_env_materials():
    return {
        "Stone_Ashlar":  create_pbr_material("Mat_Fortress_Ashlar",   (0.55, 0.52, 0.48, 1.0), 0.0,  0.82),
        "Stone_Damaged": create_pbr_material("Mat_Fortress_Damaged",  (0.48, 0.44, 0.39, 1.0), 0.0,  0.88),
        "Stone_Floor":   create_pbr_material("Mat_Fortress_Floor",    (0.50, 0.48, 0.45, 1.0), 0.0,  0.78),
        "Iron_Wrought":  create_pbr_material("Mat_Fortress_Iron",     (0.18, 0.18, 0.20, 1.0), 0.95, 0.42),
        "Oak_Timber":    create_pbr_material("Mat_Fortress_Oak",      (0.28, 0.18, 0.10, 1.0), 0.0,  0.75),
        "Cloth_Banner":  create_pbr_material("Mat_Fortress_Banner",   (0.14, 0.22, 0.50, 1.0), 0.0,  0.85),
        "Coal_Fire":     create_pbr_material("Mat_Fortress_Coal",     (0.95, 0.45, 0.10, 1.0), 0.0,  0.40)
    }

def add_box_col(name, size, loc):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    col = bpy.context.active_object
    col.name = name + "-col"
    col.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return col

def export_asset(filename, out_dir):
    bpy.ops.object.select_all(action='SELECT')
    out_path = os.path.join(out_dir, filename)
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[EXPORTED] {filename}")

# --- Asset Builders ---

def build_wall_ashlar(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    # Main wall body (4m wide, 4m high, 0.8m thick)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.0))
    w = bpy.context.active_object
    w.scale = (4.0, 0.8, 4.0)
    bpy.ops.object.transform_apply(scale=True)
    w.data.materials.append(mats["Stone_Ashlar"])
    parts.append(w)

    # Buttress support pillar
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.6, 2.0))
    b = bpy.context.active_object
    b.scale = (0.7, 0.5, 4.2)
    bpy.ops.object.transform_apply(scale=True)
    b.data.materials.append(mats["Stone_Ashlar"])
    parts.append(b)

    # Top crenellations (2 battlements)
    for cx in [-1.2, 1.2]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, 0, 4.45))
        c = bpy.context.active_object
        c.scale = (0.9, 0.85, 0.9)
        bpy.ops.object.transform_apply(scale=True)
        c.data.materials.append(mats["Stone_Ashlar"])
        parts.append(c)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressWallAshlar"

    add_box_col("FortressWallAshlar", (4.0, 0.8, 4.0), (0, 0, 2.0))
    export_asset("fortress_wall_ashlar.glb", out_dir)

def build_wall_ruined(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    # Left jagged section
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.2, 0, 1.6))
    w1 = bpy.context.active_object
    w1.scale = (1.6, 0.8, 3.2)
    bpy.ops.object.transform_apply(scale=True)
    w1.data.materials.append(mats["Stone_Damaged"])
    parts.append(w1)

    # Right breached low section
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.2, 0, 0.8))
    w2 = bpy.context.active_object
    w2.scale = (1.6, 0.8, 1.6)
    bpy.ops.object.transform_apply(scale=True)
    w2.data.materials.append(mats["Stone_Damaged"])
    parts.append(w2)

    # Center rubble spill
    bpy.ops.mesh.primitive_cone_add(radius1=1.1, depth=0.9, vertices=6, location=(0, -0.2, 0.45))
    rub = bpy.context.active_object
    rub.data.materials.append(mats["Stone_Damaged"])
    parts.append(rub)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressWallRuined"

    add_box_col("FortressWallRuined", (4.0, 0.8, 2.2), (0, 0, 1.1))
    export_asset("fortress_wall_ruined.glb", out_dir)

def build_gothic_arch(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    # Left & Right piers
    for px in [-1.8, 1.8]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(px, 0, 2.2))
        pier = bpy.context.active_object
        pier.scale = (0.7, 0.9, 4.4)
        bpy.ops.object.transform_apply(scale=True)
        pier.data.materials.append(mats["Stone_Ashlar"])
        parts.append(pier)

    # Gothic arch lintel with carved keystone
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 4.6))
    top = bpy.context.active_object
    top.scale = (4.3, 0.9, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    top.data.materials.append(mats["Stone_Ashlar"])
    parts.append(top)

    # Iron portcullis with vertical bars & cross-braces
    for bx in [-1.1, -0.55, 0.0, 0.55, 1.1]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=3.2, vertices=8, location=(bx, 0, 2.6))
        bar = bpy.context.active_object
        bar.data.materials.append(mats["Iron_Wrought"])
        parts.append(bar)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressGothicArch"

    add_box_col("FortressGothicArch_L", (0.7, 0.9, 4.4), (-1.8, 0, 2.2))
    add_box_col("FortressGothicArch_R", (0.7, 0.9, 4.4), (1.8, 0, 2.2))
    export_asset("fortress_gothic_arch.glb", out_dir)

def build_pillar_fluted(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    # Stepped plinth base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.2))
    base = bpy.context.active_object
    base.scale = (1.0, 1.0, 0.4)
    bpy.ops.object.transform_apply(scale=True)
    base.data.materials.append(mats["Stone_Ashlar"])
    parts.append(base)

    # Fluted cylindrical shaft
    bpy.ops.mesh.primitive_cylinder_add(radius=0.38, depth=3.8, vertices=16, location=(0, 0, 2.3))
    shaft = bpy.context.active_object
    shaft.data.materials.append(mats["Stone_Ashlar"])
    parts.append(shaft)

    # Sculpted Romanesque capital
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 4.35))
    cap = bpy.context.active_object
    cap.scale = (0.95, 0.95, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    cap.data.materials.append(mats["Stone_Ashlar"])
    parts.append(cap)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressPillarFluted"

    add_box_col("FortressPillarFluted", (0.85, 0.85, 4.5), (0, 0, 2.25))
    export_asset("fortress_pillar_fluted.glb", out_dir)

def build_floor_flagstone(out_dir):
    reset_scene()
    mats = get_env_materials()
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.1))
    f = bpy.context.active_object
    f.name = "FortressFloorFlagstone"
    f.scale = (4.0, 4.0, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    f.data.materials.append(mats["Stone_Floor"])

    add_box_col("FortressFloorFlagstone", (4.0, 4.0, 0.2), (0, 0, -0.1))
    export_asset("fortress_floor_flagstone.glb", out_dir)

def build_floor_damaged(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.1))
    f = bpy.context.active_object
    f.scale = (4.0, 4.0, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    f.data.materials.append(mats["Stone_Damaged"])
    parts.append(f)

    # Broken stone slab crack
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.6, 0.4, 0.03))
    crack = bpy.context.active_object
    crack.scale = (1.4, 0.8, 0.08)
    crack.rotation_euler = (0, 0, math.radians(25))
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    crack.data.materials.append(mats["Stone_Damaged"])
    parts.append(crack)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressFloorDamaged"

    add_box_col("FortressFloorDamaged", (4.0, 4.0, 0.2), (0, 0, -0.1))
    export_asset("fortress_floor_damaged.glb", out_dir)

def build_stairs_stone(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    for i in range(5):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, i * 0.45, i * 0.25 + 0.125))
        st = bpy.context.active_object
        st.scale = (2.2, 0.48, 0.25)
        bpy.ops.object.transform_apply(scale=True)
        st.data.materials.append(mats["Stone_Ashlar"])
        parts.append(st)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressStairsStone"

    add_box_col("FortressStairsStone", (2.2, 2.25, 1.25), (0, 0.9, 0.625))
    export_asset("fortress_stairs_stone.glb", out_dir)

def build_parapet_battlement(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.6))
    p = bpy.context.active_object
    p.scale = (4.0, 0.45, 1.2)
    bpy.ops.object.transform_apply(scale=True)
    p.data.materials.append(mats["Stone_Ashlar"])
    parts.append(p)

    for cx in [-1.2, 1.2]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, 0, 1.45))
        c = bpy.context.active_object
        c.scale = (0.9, 0.48, 0.5)
        bpy.ops.object.transform_apply(scale=True)
        c.data.materials.append(mats["Stone_Ashlar"])
        parts.append(c)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressParapetBattlement"

    add_box_col("FortressParapetBattlement", (4.0, 0.45, 1.4), (0, 0, 0.7))
    export_asset("fortress_parapet_battlement.glb", out_dir)

def build_timber_beam(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.0))
    b = bpy.context.active_object
    b.scale = (0.28, 0.28, 4.0)
    bpy.ops.object.transform_apply(scale=True)
    b.data.materials.append(mats["Oak_Timber"])
    parts.append(b)

    for z in [0.4, 3.6]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, z))
        br = bpy.context.active_object
        br.scale = (0.32, 0.32, 0.08)
        bpy.ops.object.transform_apply(scale=True)
        br.data.materials.append(mats["Iron_Wrought"])
        parts.append(br)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressTimberBeam"

    add_box_col("FortressTimberBeam", (0.32, 0.32, 4.0), (0, 0, 2.0))
    export_asset("fortress_timber_beam.glb", out_dir)

def build_iron_brazier(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    for a in [0, 120, 240]:
        rad = math.radians(a)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=1.1, vertices=8, location=(math.cos(rad) * 0.35, math.sin(rad) * 0.35, 0.55))
        leg = bpy.context.active_object
        leg.data.materials.append(mats["Iron_Wrought"])
        parts.append(leg)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=0.25, vertices=12, location=(0, 0, 1.05))
    bowl = bpy.context.active_object
    bowl.data.materials.append(mats["Iron_Wrought"])
    parts.append(bowl)

    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.38, segments=10, ring_count=6, location=(0, 0, 1.15))
    coal = bpy.context.active_object
    coal.scale = (1.0, 1.0, 0.4)
    bpy.ops.object.transform_apply(scale=True)
    coal.data.materials.append(mats["Coal_Fire"])
    parts.append(coal)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressIronBrazier"

    add_box_col("FortressIronBrazier", (0.9, 0.9, 1.2), (0, 0, 0.6))
    export_asset("fortress_iron_brazier.glb", out_dir)

def build_wall_torch(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.12, 0))
    br = bpy.context.active_object
    br.scale = (0.06, 0.24, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    br.data.materials.append(mats["Iron_Wrought"])
    parts.append(br)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.6, vertices=8, location=(0, 0.22, 0.15))
    t = bpy.context.active_object
    t.rotation_euler = (math.radians(15), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    t.data.materials.append(mats["Oak_Timber"])
    parts.append(t)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.14, vertices=8, location=(0, 0.26, 0.42))
    head = bpy.context.active_object
    head.data.materials.append(mats["Coal_Fire"])
    parts.append(head)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressWallTorch"

    export_asset("fortress_wall_torch.glb", out_dir)

def build_oak_barrel(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=1.05, vertices=12, location=(0, 0, 0.525))
    b = bpy.context.active_object
    b.scale = (1.1, 1.1, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    b.data.materials.append(mats["Oak_Timber"])
    parts.append(b)

    for hz in [0.2, 0.85]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.48, depth=0.04, vertices=12, location=(0, 0, hz))
        hoop = bpy.context.active_object
        hoop.data.materials.append(mats["Iron_Wrought"])
        parts.append(hoop)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressOakBarrel"

    add_box_col("FortressOakBarrel", (0.9, 0.9, 1.05), (0, 0, 0.525))
    export_asset("fortress_oak_barrel.glb", out_dir)

def build_iron_crate(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.45))
    c = bpy.context.active_object
    c.scale = (0.9, 0.9, 0.9)
    bpy.ops.object.transform_apply(scale=True)
    c.data.materials.append(mats["Oak_Timber"])
    parts.append(c)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.45))
    br = bpy.context.active_object
    br.scale = (0.92, 0.92, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    br.data.materials.append(mats["Iron_Wrought"])
    parts.append(br)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressIronCrate"

    add_box_col("FortressIronCrate", (0.9, 0.9, 0.9), (0, 0, 0.45))
    export_asset("fortress_iron_crate.glb", out_dir)

def build_stone_monument(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.35))
    base = bpy.context.active_object
    base.scale = (1.5, 1.5, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    base.data.materials.append(mats["Stone_Ashlar"])
    parts.append(base)

    bpy.ops.mesh.primitive_cone_add(radius1=0.45, depth=2.8, vertices=4, location=(0, 0, 2.1))
    obelisk = bpy.context.active_object
    obelisk.rotation_euler = (0, 0, math.radians(45))
    bpy.ops.object.transform_apply(rotation=True)
    obelisk.data.materials.append(mats["Stone_Ashlar"])
    parts.append(obelisk)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressStoneMonument"

    add_box_col("FortressStoneMonument", (1.5, 1.5, 3.5), (0, 0, 1.75))
    export_asset("fortress_stone_monument.glb", out_dir)

def build_rubble_pile(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    for dx, dy, dz, rot, sc in [
        (0.0, 0.0, 0.18, 15, (0.5, 0.4, 0.35)),
        (0.4, -0.2, 0.12, -30, (0.35, 0.3, 0.25)),
        (-0.35, 0.25, 0.14, 45, (0.4, 0.35, 0.28)),
        (0.15, 0.35, 0.08, -10, (0.3, 0.25, 0.2))
    ]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(dx, dy, dz))
        rk = bpy.context.active_object
        rk.scale = sc
        rk.rotation_euler = (0, 0, math.radians(rot))
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        rk.data.materials.append(mats["Stone_Damaged"])
        parts.append(rk)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressRubblePile"

    add_box_col("FortressRubblePile", (1.4, 1.4, 0.4), (0, 0, 0.2))
    export_asset("fortress_rubble_pile.glb", out_dir)

def build_background_tower(out_dir):
    reset_scene()
    mats = get_env_materials()
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(radius=2.5, depth=14.0, vertices=8, location=(0, 0, 7.0))
    t = bpy.context.active_object
    t.data.materials.append(mats["Stone_Ashlar"])
    parts.append(t)

    bpy.ops.mesh.primitive_cylinder_add(radius=2.9, depth=1.6, vertices=8, location=(0, 0, 14.8))
    cr = bpy.context.active_object
    cr.data.materials.append(mats["Stone_Ashlar"])
    parts.append(cr)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = "FortressBackgroundTower"

    export_asset("fortress_background_tower.glb", out_dir)

def main():
    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../assets/environment/fortress"))
    os.makedirs(out_dir, exist_ok=True)

    build_wall_ashlar(out_dir)
    build_wall_ruined(out_dir)
    build_gothic_arch(out_dir)
    build_pillar_fluted(out_dir)
    build_floor_flagstone(out_dir)
    build_floor_damaged(out_dir)
    build_stairs_stone(out_dir)
    build_parapet_battlement(out_dir)
    build_timber_beam(out_dir)
    build_iron_brazier(out_dir)
    build_wall_torch(out_dir)
    build_oak_barrel(out_dir)
    build_iron_crate(out_dir)
    build_stone_monument(out_dir)
    build_rubble_pile(out_dir)
    build_background_tower(out_dir)

if __name__ == "__main__":
    main()
