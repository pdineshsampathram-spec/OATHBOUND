#!/usr/bin/env python3
"""
process_polyhaven_props.py — Converts Poly Haven CC0 glTF models into optimized GLBs:
- stone_fire_pit
- rock_moss_set_01 (with decimate to fit LOD budget ~4.5k tris)
- wooden_crate_01
- barrel_03
- large_iron_gate (with decimate to fit LOD budget ~6k tris)
"""

import bpy
import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
POLY_DIR = os.path.join(BASE_DIR, "assets/environment/polyhaven")
OUT_DIR = os.path.join(BASE_DIR, "assets/environment/fortress")
os.makedirs(OUT_DIR, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def convert_prop(prop_name, out_filename, decimate_ratio=1.0, scale_fac=1.0):
    reset_scene()
    gltf_path = os.path.join(POLY_DIR, f"{prop_name}/{prop_name}.gltf")
    if not os.path.exists(gltf_path):
        print(f"[WARN] {gltf_path} does not exist")
        return

    bpy.ops.import_scene.gltf(filepath=gltf_path)
    bpy.ops.object.select_all(action='SELECT')

    for obj in bpy.context.selected_objects:
        if obj.type == 'MESH':
            bpy.context.view_layer.objects.active = obj
            if decimate_ratio < 1.0:
                mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
                mod.ratio = decimate_ratio
                bpy.ops.object.modifier_apply(modifier="Decimate")
            if scale_fac != 1.0:
                obj.scale = (obj.scale.x * scale_fac, obj.scale.y * scale_fac, obj.scale.z * scale_fac)
                bpy.ops.object.transform_apply(scale=True)

    out_path = os.path.join(OUT_DIR, out_filename)
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Exported {out_filename} to {out_path}")

if __name__ == "__main__":
    convert_prop("stone_fire_pit", "prop_stone_fire_pit.glb", scale_fac=1.2)
    convert_prop("rock_moss_set_01", "prop_mossy_rocks.glb", decimate_ratio=0.10, scale_fac=1.0)
    convert_prop("wooden_crate_01", "prop_wooden_crate.glb", scale_fac=1.0)
    convert_prop("barrel_03", "prop_oak_barrel.glb", scale_fac=1.1)
    convert_prop("large_iron_gate", "prop_iron_gate.glb", decimate_ratio=0.20, scale_fac=1.0)
