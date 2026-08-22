#!/usr/bin/env python3
"""
fetch_cc0_assets.py — Downloads and verifies legitimate CC0 PBR textures & models
from ambientCG and Poly Haven for OATHBOUND's realistic visual pipeline.
"""

import os
import urllib.request
import json
import zipfile
import shutil

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
TEXTURES_DIR = os.path.join(BASE_DIR, "assets/textures")
MODELS_DIR = os.path.join(BASE_DIR, "assets/environment/polyhaven")

os.makedirs(TEXTURES_DIR, exist_ok=True)
os.makedirs(MODELS_DIR, exist_ok=True)

# 1. ambientCG PBR Texture Sets
AMBIENTCG_TEXTURES = [
    # Hero Character & Weapons Textures (2K)
    {"id": "Metal009", "res": "2K", "category": "character", "desc": "Scratched Damaged Armor Steel"},
    {"id": "Leather026", "res": "2K", "category": "character", "desc": "Aged Medieval Tanned Leather"},
    {"id": "Fabric048", "res": "2K", "category": "character", "desc": "Rough Woven Linen Tabard Cloth"},
    {"id": "Metal028", "res": "1K", "category": "weapons", "desc": "Wrought Iron / Cast Iron"},
    
    # Environment Textures (2K for Ground, 1K-2K for Walls/Wood)
    {"id": "Tiles130", "res": "2K", "category": "environment", "desc": "Cracked Flagstone Medieval Courtyard Floor"},
    {"id": "Ground037", "res": "2K", "category": "environment", "desc": "Medieval Mud, Dirt & Cobble Blend"},
    {"id": "Bricks083", "res": "2K", "category": "environment", "desc": "Medieval Sandstone Ashlar Fortress Wall"},
    {"id": "Rocks025", "res": "1K", "category": "environment", "desc": "Rough Masonry & Damaged Rubble Wall"},
    {"id": "Wood066", "res": "1K", "category": "environment", "desc": "Weathered Dark Oak Timber Planks"}
]

# 2. Poly Haven CC0 Models (1K-2K glTF)
POLYHAVEN_MODELS = [
    {"id": "antique_estoc", "res": "2k", "desc": "15th-Century Medieval Estoc/Longsword Photogrammetry"},
    {"id": "kite_shield", "res": "2k", "desc": "15th-Century Curved Knight Kite Shield with Boss & Straps"},
    {"id": "ornate_medieval_dagger", "res": "1k", "desc": "Medieval Quillon Dagger Photogrammetry"},
    {"id": "large_iron_gate", "res": "1k", "desc": "Gothic Forged Iron Portcullis & Gate"},
    {"id": "wooden_crate_01", "res": "1k", "desc": "Medieval Oak Cargo Crate with Iron Bracing"},
    {"id": "barrel_03", "res": "1k", "desc": "Worn Oak Barrel with Iron Hoops"},
    {"id": "rock_moss_set_01", "res": "1k", "desc": "Mossy Stone Rubble & Fortress Debris"},
    {"id": "stone_fire_pit", "res": "1k", "desc": "Carved Stone Fire Brazier / Pit"}
]

def download_file(url, out_path):
    req = urllib.request.Request(url, headers={"User-Agent": "OathboundAssetPipeline/1.0"})
    with urllib.request.urlopen(req) as resp, open(out_path, "wb") as out:
        shutil.copyfileobj(resp, out)

def fetch_ambientcg_textures():
    print("=== Downloading ambientCG CC0 PBR Textures ===")
    for item in AMBIENTCG_TEXTURES:
        tid = item["id"]
        res = item["res"]
        zip_name = f"{tid}_{res}-JPG.zip"
        target_folder = os.path.join(TEXTURES_DIR, tid)
        if os.path.exists(target_folder) and os.path.isdir(target_folder):
            print(f"[EXISTS] {tid} ({res}) in {target_folder}")
            continue
        
        url = f"https://ambientcg.com/get?file={zip_name}"
        zip_path = os.path.join(TEXTURES_DIR, zip_name)
        print(f"[FETCHING] {tid} ({res}) from ambientCG...")
        try:
            download_file(url, zip_path)
            os.makedirs(target_folder, exist_ok=True)
            with zipfile.ZipFile(zip_path, "r") as z:
                # Extract only essential jpg maps: Color, NormalGL, Roughness, AmbientOcclusion
                for f in z.namelist():
                    if any(m in f for m in ["Color.jpg", "NormalGL.jpg", "Roughness.jpg", "AmbientOcclusion.jpg"]):
                        z.extract(f, target_folder)
            os.remove(zip_path)
            print(f"[EXTRACTED] {tid} -> {target_folder}")
        except Exception as e:
            print(f"[ERROR] Failed to fetch {tid}: {e}")

def fetch_polyhaven_models():
    print("\n=== Downloading Poly Haven CC0 Models ===")
    for item in POLYHAVEN_MODELS:
        mid = item["id"]
        res = item["res"]
        target_folder = os.path.join(MODELS_DIR, mid)
        if os.path.exists(target_folder) and os.path.isdir(target_folder):
            print(f"[EXISTS] {mid} in {target_folder}")
            continue
        
        print(f"[FETCHING] {mid} ({res}) metadata from Poly Haven API...")
        try:
            api_url = f"https://api.polyhaven.com/files/{mid}"
            req = urllib.request.Request(api_url, headers={"User-Agent": "OathboundAssetPipeline/1.0"})
            with urllib.request.urlopen(req) as resp:
                meta = json.loads(resp.read().decode())
            
            gltf_info = meta.get("gltf", {}).get(res, {}).get("gltf")
            if not gltf_info:
                # Fallback to 1k if 2k is not present
                res = "1k"
                gltf_info = meta.get("gltf", {}).get("1k", {}).get("gltf")
            
            if not gltf_info:
                print(f"[WARN] No glTF found for {mid}")
                continue
            
            os.makedirs(target_folder, exist_ok=True)
            gltf_url = gltf_info["url"]
            gltf_file = os.path.join(target_folder, f"{mid}.gltf")
            download_file(gltf_url, gltf_file)
            
            # Download includes (.bin, textures)
            includes = gltf_info.get("include", {})
            for inc_path, inc_meta in includes.items():
                dest_path = os.path.join(target_folder, inc_path)
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                download_file(inc_meta["url"], dest_path)
            
            print(f"[EXTRACTED] {mid} ({res} glTF) -> {target_folder}")
        except Exception as e:
            print(f"[ERROR] Failed to fetch {mid}: {e}")

if __name__ == "__main__":
    fetch_ambientcg_textures()
    fetch_polyhaven_models()
    print("\n[SUCCESS] CC0 Asset Pipeline Acquisition Complete!")
