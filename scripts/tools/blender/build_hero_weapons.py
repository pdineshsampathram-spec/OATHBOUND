#!/usr/bin/env python3
"""
build_hero_weapons.py — Authors the Hero Longsword and Hero Kite Shield.
Features detailed double-edged blade with fuller, brass crossguard, leather grip with riser ring,
and curved wooden heater shield with riveted steel rim, center umbo boss, and leather enarmes.
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

def build_hero_longsword(out_path):
    reset_scene()
    mat_blade = create_pbr_material("Mat_Hero_SwordBlade", (0.80, 0.82, 0.86, 1.0), 0.98, 0.20)
    mat_guard = create_pbr_material("Mat_Hero_SwordGuard", (0.85, 0.72, 0.28, 1.0), 0.90, 0.30)
    mat_grip  = create_pbr_material("Mat_Hero_SwordGrip",  (0.24, 0.12, 0.06, 1.0), 0.0,  0.60)
    mat_pommel= create_pbr_material("Mat_Hero_SwordPommel",(0.82, 0.70, 0.25, 1.0), 0.92, 0.28)

    parts = []

    # 1. Double-edged blade with fuller
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.65))
    blade = bpy.context.active_object
    blade.scale = (0.05, 0.018, 0.90)
    bpy.ops.object.transform_apply(scale=True)
    blade.data.materials.append(mat_blade)
    parts.append(blade)

    # Blade point taper
    bpy.ops.mesh.primitive_cone_add(radius1=0.038, depth=0.18, vertices=4, location=(0, 0, 1.18))
    tip = bpy.context.active_object
    tip.scale = (1.2, 0.45, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    tip.data.materials.append(mat_blade)
    parts.append(tip)

    # 2. Sculpted cruciform crossguard
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.18))
    guard = bpy.context.active_object
    guard.scale = (0.28, 0.035, 0.035)
    bpy.ops.object.transform_apply(scale=True)
    guard.data.materials.append(mat_guard)
    parts.append(guard)

    # 3. Cord-wrapped leather grip with riser
    bpy.ops.mesh.primitive_cylinder_add(radius=0.022, depth=0.22, vertices=10, location=(0, 0, 0.06))
    grip = bpy.context.active_object
    grip.data.materials.append(mat_grip)
    parts.append(grip)

    # Central riser ring
    bpy.ops.mesh.primitive_torus_add(major_radius=0.024, minor_radius=0.005, location=(0, 0, 0.06))
    riser = bpy.context.active_object
    riser.data.materials.append(mat_guard)
    parts.append(riser)

    # 4. Octagonal scent-stopper pommel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.06, vertices=8, location=(0, 0, -0.07))
    pommel = bpy.context.active_object
    pommel.data.materials.append(mat_pommel)
    parts.append(pommel)

    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    sword = bpy.context.active_object
    sword.name = "HeroLongsword"

    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Exported Hero Longsword to: {out_path}")

def build_hero_kite_shield(out_path):
    reset_scene()
    mat_wood = create_pbr_material("Mat_Hero_ShieldWood", (0.16, 0.24, 0.46, 1.0), 0.0,  0.65) # Royal Blue Crest
    mat_rim  = create_pbr_material("Mat_Hero_ShieldRim",  (0.72, 0.74, 0.78, 1.0), 0.95, 0.28) # Steel Rim
    mat_boss = create_pbr_material("Mat_Hero_ShieldBoss", (0.85, 0.70, 0.26, 1.0), 0.90, 0.30) # Brass Boss
    mat_strap= create_pbr_material("Mat_Hero_ShieldStrap",(0.26, 0.14, 0.07, 1.0), 0.0,  0.65) # Leather

    parts = []

    # 1. Curved heater body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    body = bpy.context.active_object
    body.scale = (0.46, 0.04, 0.70)
    bpy.ops.object.transform_apply(scale=True)
    body.data.materials.append(mat_wood)
    parts.append(body)

    # Lower triangular taper
    bpy.ops.mesh.primitive_cone_add(radius1=0.23, depth=0.35, vertices=4, location=(0, 0, -0.48))
    bottom = bpy.context.active_object
    bottom.scale = (1.0, 0.18, 1.0)
    bottom.rotation_euler = (math.radians(180), 0, math.radians(45))
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    bottom.data.materials.append(mat_wood)
    parts.append(bottom)

    # 2. Steel reinforcing rim
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.01, 0.34))
    rim_top = bpy.context.active_object
    rim_top.scale = (0.48, 0.05, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    rim_top.data.materials.append(mat_rim)
    parts.append(rim_top)

    # 3. Central umbo boss (convex iron/brass shield boss)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.10, segments=12, ring_count=8, location=(0, 0.03, 0.05))
    boss = bpy.context.active_object
    boss.scale = (1.0, 0.45, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    boss.data.materials.append(mat_boss)
    parts.append(boss)

    # 4. Rear leather forearm straps
    bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.28, vertices=8, location=(0, -0.04, 0.05))
    strap = bpy.context.active_object
    strap.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(rotation=True)
    strap.data.materials.append(mat_strap)
    parts.append(strap)

    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    shield = bpy.context.active_object
    shield.name = "HeroKiteShield"

    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Exported Hero Kite Shield to: {out_path}")

def main():
    wep_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../assets/characters/weapons"))
    os.makedirs(wep_dir, exist_ok=True)
    build_hero_longsword(os.path.join(wep_dir, "hero_longsword.glb"))
    build_hero_kite_shield(os.path.join(wep_dir, "hero_kite_shield.glb"))

if __name__ == "__main__":
    main()
