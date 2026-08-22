#!/usr/bin/env python3
"""
process_hero_weapons.py — Processes Poly Haven's CC0 photogrammetry models:
antique_estoc (2K PBR) -> hero_longsword.glb
kite_shield (2K PBR)   -> hero_kite_shield.glb
"""

import bpy
import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
POLY_DIR = os.path.join(BASE_DIR, "assets/environment/polyhaven")
OUT_DIR = os.path.join(BASE_DIR, "assets/characters/weapons")
os.makedirs(OUT_DIR, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def process_estoc():
    reset_scene()
    estoc_gltf = os.path.join(POLY_DIR, "antique_estoc/antique_estoc.gltf")
    if not os.path.exists(estoc_gltf):
        print(f"[ERROR] {estoc_gltf} does not exist")
        return

    bpy.ops.import_scene.gltf(filepath=estoc_gltf)
    bpy.ops.object.select_all(action='SELECT')
    # Standard sword length ~1.15m total
    # Align hilt to origin
    for obj in bpy.context.selected_objects:
        if obj.type == 'MESH':
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            # Re-scale if needed
            dim = obj.dimensions
            max_dim = max(dim.x, dim.y, dim.z)
            if max_dim > 0:
                scale_fac = 1.18 / max_dim
                obj.scale = (scale_fac, scale_fac, scale_fac)
                bpy.ops.object.transform_apply(scale=True)
    
    out_path = os.path.join(OUT_DIR, "hero_longsword.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Processed Hero Longsword to {out_path}")

def process_shield():
    reset_scene()
    shield_gltf = os.path.join(POLY_DIR, "kite_shield/kite_shield.gltf")
    if not os.path.exists(shield_gltf):
        print(f"[ERROR] {shield_gltf} does not exist")
        return

    bpy.ops.import_scene.gltf(filepath=shield_gltf)
    bpy.ops.object.select_all(action='SELECT')
    # Standard kite shield height ~0.95m
    for obj in bpy.context.selected_objects:
        if obj.type == 'MESH':
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            dim = obj.dimensions
            max_dim = max(dim.x, dim.y, dim.z)
            if max_dim > 0:
                scale_fac = 0.95 / max_dim
                obj.scale = (scale_fac, scale_fac, scale_fac)
                bpy.ops.object.transform_apply(scale=True)
    
    out_path = os.path.join(OUT_DIR, "hero_kite_shield.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB', use_selection=True)
    print(f"[SUCCESS] Processed Hero Kite Shield to {out_path}")

if __name__ == "__main__":
    process_estoc()
    process_shield()
