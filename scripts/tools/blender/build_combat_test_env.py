#!/usr/bin/env python3
"""
build_combat_test_env.py — Authors the 10m x 10m Hero Combat Test Environment
using genuine 2K PBR texture sets (Tiles130, Ground037, Bricks083, Rocks025, Wood066).
"""

import bpy
import os
import math

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
TEX_DIR = os.path.join(BASE_DIR, "assets/textures")
OUT_DIR = os.path.join(BASE_DIR, "assets/environment/fortress")
os.makedirs(OUT_DIR, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_image_pbr_material(name, tex_subfolder, base_tint=(1,1,1,1), metallic_val=0.0, roughness_val=0.8, uv_scale=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Metallic'].default_value = metallic_val
    bsdf.inputs['Roughness'].default_value = roughness_val
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    # UV Mapping node for tiling
    tex_coord = nodes.new(type='ShaderNodeTexCoord')
    mapping = nodes.new(type='ShaderNodeMapping')
    mapping.inputs['Scale'].default_value = (uv_scale, uv_scale, uv_scale)
    links.new(tex_coord.outputs['UV'], mapping.inputs['Vector'])

    folder = os.path.join(TEX_DIR, tex_subfolder)
    if os.path.exists(folder):
        files = os.listdir(folder)
        # 1. Color / Albedo
        col_file = next((f for f in files if "Color" in f), None)
        if col_file:
            tex_col = nodes.new(type='ShaderNodeTexImage')
            tex_col.image = bpy.data.images.load(os.path.join(folder, col_file))
            links.new(mapping.outputs['Vector'], tex_col.inputs['Vector'])
            links.new(tex_col.outputs['Color'], bsdf.inputs['Base Color'])
        else:
            bsdf.inputs['Base Color'].default_value = base_tint

        # 2. Roughness
        rough_file = next((f for f in files if "Roughness" in f), None)
        if rough_file:
            tex_rough = nodes.new(type='ShaderNodeTexImage')
            tex_rough.image = bpy.data.images.load(os.path.join(folder, rough_file))
            tex_rough.image.colorspace_settings.name = 'Non-Color'
            links.new(mapping.outputs['Vector'], tex_rough.inputs['Vector'])
            links.new(tex_rough.outputs['Color'], bsdf.inputs['Roughness'])

        # 3. Normal Map
        norm_file = next((f for f in files if "NormalGL" in f or "NormalDX" in f), None)
        if norm_file:
            tex_norm = nodes.new(type='ShaderNodeTexImage')
            tex_norm.image = bpy.data.images.load(os.path.join(folder, norm_file))
            tex_norm.image.colorspace_settings.name = 'Non-Color'
            links.new(mapping.outputs['Vector'], tex_norm.inputs['Vector'])
            norm_node = nodes.new(type='ShaderNodeNormalMap')
            norm_node.inputs['Strength'].default_value = 1.3
            links.new(tex_norm.outputs['Color'], norm_node.inputs['Color'])
            links.new(norm_node.outputs['Normal'], bsdf.inputs['Normal'])
    else:
        bsdf.inputs['Base Color'].default_value = base_tint

    return mat

def build_combat_floor():
    reset_scene()
    mat_flagstone = create_image_pbr_material("Mat_Floor_Flagstone", "Tiles130", uv_scale=3.5)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.1))
    f = bpy.context.active_object
    f.name = "CombatFloor10m"
    f.scale = (10.0, 10.0, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.01)
    bpy.ops.object.mode_set(mode='OBJECT')
    f.data.materials.append(mat_flagstone)

    # Collision shape
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.1))
    col = bpy.context.active_object
    col.name = "CombatFloor10m-col"
    col.scale = (10.0, 10.0, 0.2)
    bpy.ops.object.transform_apply(scale=True)

    out_path = os.path.join(OUT_DIR, "combat_floor_10m.glb")
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Exported {out_path}")

def build_sandstone_wall():
    reset_scene()
    mat_sandstone = create_image_pbr_material("Mat_Wall_Sandstone", "Bricks083", uv_scale=2.0)
    parts = []

    # Main wall body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.0))
    w = bpy.context.active_object
    w.scale = (4.0, 0.8, 4.0)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(w)

    # Buttress
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.6, 2.0))
    b = bpy.context.active_object
    b.scale = (0.7, 0.5, 4.2)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(b)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    wall = bpy.context.active_object
    wall.name = "CombatWallSandstone"

    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.01)
    bpy.ops.object.mode_set(mode='OBJECT')
    wall.data.materials.append(mat_sandstone)

    # Collision
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.0))
    col = bpy.context.active_object
    col.name = "CombatWallSandstone-col"
    col.scale = (4.0, 0.8, 4.0)
    bpy.ops.object.transform_apply(scale=True)

    out_path = os.path.join(OUT_DIR, "combat_wall_sandstone.glb")
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Exported {out_path}")

def build_breached_wall():
    reset_scene()
    mat_rubble = create_image_pbr_material("Mat_Wall_Rubble", "Rocks025", uv_scale=2.0)
    parts = []

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.2, 0, 1.6))
    w1 = bpy.context.active_object
    w1.scale = (1.6, 0.8, 3.2)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(w1)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.2, 0, 0.9))
    w2 = bpy.context.active_object
    w2.scale = (1.6, 0.8, 1.8)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(w2)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    wall = bpy.context.active_object
    wall.name = "CombatWallBreached"

    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.01)
    bpy.ops.object.mode_set(mode='OBJECT')
    wall.data.materials.append(mat_rubble)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.2))
    col = bpy.context.active_object
    col.name = "CombatWallBreached-col"
    col.scale = (4.0, 0.8, 2.4)
    bpy.ops.object.transform_apply(scale=True)

    out_path = os.path.join(OUT_DIR, "combat_wall_breached.glb")
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Exported {out_path}")

if __name__ == "__main__":
    build_combat_floor()
    build_sandstone_wall()
    build_breached_wall()
