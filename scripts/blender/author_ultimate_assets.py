"""
Blender 5.2.0 Automation Script: OATHBOUND Dedicated Ultimate Hero Art Library
Authors refined, fine organic filaments, sword arcs, ground fractures, and celestial structures.
ZERO giant bubbles, ZERO thick noodle ribbons.
"""

import bpy
import math
import os
from mathutils import Vector, Quaternion, Euler

def reset_blend():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def key_bone(pose, bone_name, frame, loc=None, rot_euler=None, scale=None):
    if bone_name not in pose.bones:
        return
    pbone = pose.bones[bone_name]
    pbone.rotation_mode = 'QUATERNION'
    if loc is not None:
        pbone.location = Vector(loc)
        pbone.keyframe_insert(data_path="location", frame=frame)
    if rot_euler is not None:
        rads = [math.radians(a) for a in rot_euler]
        euler_rot = Euler(rads, 'XYZ')
        pbone.rotation_quaternion = euler_rot.to_quaternion()
        pbone.keyframe_insert(data_path="rotation_quaternion", frame=frame)
    if scale is not None:
        pbone.scale = Vector(scale)
        pbone.keyframe_insert(data_path="scale", frame=frame)

def author_skeletal_actions(armature_obj):
    armature_obj.animation_data_create()
    bpy.context.view_layer.objects.active = armature_obj
    bpy.ops.object.mode_set(mode='POSE')
    pose = armature_obj.pose

    # --- 8 KNIGHT TRACKS ---
    # 1. ultimate_prepare
    act = bpy.data.actions.new(name="ultimate_prepare")
    armature_obj.animation_data.action = act
    key_bone(pose, "Root", 0, loc=(0,0,0), rot_euler=(0,0,0))
    key_bone(pose, "Hips", 0, loc=(0,0,0), rot_euler=(0,0,0))
    key_bone(pose, "Hips", 75, loc=(0,-0.06,-0.08), rot_euler=(8,0,0))
    key_bone(pose, "Spine", 75, rot_euler=(8,0,0))
    key_bone(pose, "Head", 75, rot_euler=(14,0,0))
    key_bone(pose, "UpperLeg.L", 75, rot_euler=(-18,8,-12))
    key_bone(pose, "LowerLeg.L", 75, rot_euler=(30,0,0))
    key_bone(pose, "UpperLeg.R", 75, rot_euler=(-15,-8,12))
    key_bone(pose, "LowerLeg.R", 75, rot_euler=(32,0,0))
    key_bone(pose, "UpperArm.R", 75, rot_euler=(-18,12,-28))
    key_bone(pose, "Forearm.R", 75, rot_euler=(-72,0,18))
    key_bone(pose, "Hand.R", 75, rot_euler=(-25,12,12))

    # 2. ultimate_awaken
    act = bpy.data.actions.new(name="ultimate_awaken")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,-0.06,-0.08), rot_euler=(8,0,0))
    key_bone(pose, "Head", 0, rot_euler=(14,0,0))
    key_bone(pose, "Hips", 75, loc=(0,-0.02,-0.03), rot_euler=(2,0,0))
    key_bone(pose, "Chest", 75, rot_euler=(-6,0,0), scale=(1.08,1.08,1.08))
    key_bone(pose, "Head", 75, rot_euler=(-8,0,0))
    key_bone(pose, "UpperArm.R", 75, rot_euler=(-35,18,-18))

    # 3. ultimate_channel
    act = bpy.data.actions.new(name="ultimate_channel")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,-0.02,-0.03), rot_euler=(2,0,0))
    key_bone(pose, "Hips", 120, loc=(0,0.01,0.01), rot_euler=(-4,0,0))
    key_bone(pose, "Spine", 120, rot_euler=(-8,0,0))
    key_bone(pose, "Chest", 120, rot_euler=(-12,0,0), scale=(1.09,1.09,1.09))
    key_bone(pose, "Head", 120, rot_euler=(-14,0,0))
    key_bone(pose, "UpperArm.R", 120, rot_euler=(-55,22,-15))
    key_bone(pose, "Forearm.R", 120, rot_euler=(-50,8,20))

    # 4. ultimate_sword_raise
    act = bpy.data.actions.new(name="ultimate_sword_raise")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,0.01,0.01), rot_euler=(-4,0,0))
    key_bone(pose, "Hips", 150, loc=(0,0.04,0.05), rot_euler=(-8,0,0))
    key_bone(pose, "Spine", 150, rot_euler=(-14,0,0))
    key_bone(pose, "Chest", 150, rot_euler=(-20,0,0), scale=(1.10,1.10,1.10))
    key_bone(pose, "Head", 150, rot_euler=(-26,0,0))
    key_bone(pose, "UpperArm.R", 150, rot_euler=(-160,20,-15))
    key_bone(pose, "Forearm.R", 150, rot_euler=(-15,10,18))
    key_bone(pose, "Hand.R", 150, rot_euler=(12,15,-25))

    # 5. ultimate_zenith
    act = bpy.data.actions.new(name="ultimate_zenith")
    armature_obj.animation_data.action = act
    for f in [0, 60, 120, 180]:
        b = 1.09 + (0.015 * math.sin(f * 0.05))
        key_bone(pose, "Hips", f, loc=(0,0.04,0.05), rot_euler=(-8,0,0))
        key_bone(pose, "Chest", f, rot_euler=(-20,0,0), scale=(b,b,b))
        key_bone(pose, "Head", f, rot_euler=(-26,0,0))
        key_bone(pose, "UpperArm.R", f, rot_euler=(-160,20,-15))
        key_bone(pose, "Hand.R", f, rot_euler=(12,15,-25))

    # 6. ultimate_release
    act = bpy.data.actions.new(name="ultimate_release")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,0.04,0.05), rot_euler=(-8,0,0))
    key_bone(pose, "Hips", 35, loc=(0,-0.09,-0.14), rot_euler=(16,0,0))
    key_bone(pose, "Spine", 35, rot_euler=(22,0,0))
    key_bone(pose, "Chest", 35, rot_euler=(28,0,0))
    key_bone(pose, "Head", 35, rot_euler=(18,0,0))
    key_bone(pose, "UpperArm.R", 35, rot_euler=(18,15,-20))
    key_bone(pose, "Forearm.R", 35, rot_euler=(-32,0,25))
    key_bone(pose, "Hand.R", 35, rot_euler=(-42,10,15))
    key_bone(pose, "Hips", 120, loc=(0,-0.08,-0.12), rot_euler=(14,0,0))

    # 7. ultimate_aftermath
    act = bpy.data.actions.new(name="ultimate_aftermath")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,-0.08,-0.12), rot_euler=(14,0,0))
    key_bone(pose, "Hips", 120, loc=(0,-0.02,-0.03), rot_euler=(4,0,0))
    key_bone(pose, "Spine", 120, rot_euler=(2,0,0))
    key_bone(pose, "Head", 120, rot_euler=(0,0,0))
    key_bone(pose, "UpperArm.R", 120, rot_euler=(-15,12,-12))

    # 8. ultimate_victory
    act = bpy.data.actions.new(name="ultimate_victory")
    armature_obj.animation_data.action = act
    key_bone(pose, "Root", 0, loc=(0,0,0), rot_euler=(0,0,0))
    key_bone(pose, "Hips", 0, loc=(0,0,0), rot_euler=(2,0,-2))
    key_bone(pose, "Chest", 0, rot_euler=(-5,0,0), scale=(1.04,1.04,1.04))
    key_bone(pose, "Head", 0, rot_euler=(-2,0,0))
    key_bone(pose, "UpperArm.R", 0, rot_euler=(-20,15,-15))
    key_bone(pose, "Forearm.R", 0, rot_euler=(-45,0,10))
    key_bone(pose, "Hips", 120, loc=(0,0,0), rot_euler=(2,0,-2))

    # --- 6 ENEMY TRACKS ---
    # 9. ultimate_enemy_interrupt
    act = bpy.data.actions.new(name="ultimate_enemy_interrupt")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,0,0), rot_euler=(15,0,0))
    key_bone(pose, "UpperArm.R", 0, rot_euler=(-80,20,0))
    key_bone(pose, "Hips", 20, loc=(0,-0.05,-0.08), rot_euler=(-12,0,0))
    key_bone(pose, "Spine", 20, rot_euler=(-15,0,0))
    key_bone(pose, "UpperArm.R", 20, rot_euler=(10,10,-20))
    key_bone(pose, "Hips", 45, loc=(0,-0.06,-0.10), rot_euler=(-10,0,0))

    # 10. ultimate_enemy_terror
    act = bpy.data.actions.new(name="ultimate_enemy_terror")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,-0.06,-0.10), rot_euler=(-10,0,0))
    key_bone(pose, "Head", 0, rot_euler=(10,-25,0))
    key_bone(pose, "UpperLeg.L", 60, rot_euler=(-25,10,-10))
    key_bone(pose, "LowerLeg.L", 60, rot_euler=(40,0,0))
    key_bone(pose, "UpperLeg.R", 60, rot_euler=(-22,-10,10))
    key_bone(pose, "LowerLeg.R", 60, rot_euler=(38,0,0))
    key_bone(pose, "Head", 60, rot_euler=(-15,-35,10))

    # 11. ultimate_enemy_stasis
    act = bpy.data.actions.new(name="ultimate_enemy_stasis")
    armature_obj.animation_data.action = act
    for f in [0, 30, 60, 90]:
        w = 0.02 * math.sin(f * 0.4)
        key_bone(pose, "Hips", f, loc=(w,-0.06,-0.10), rot_euler=(-10,0,0))
        key_bone(pose, "Head", f, rot_euler=(-15,-35,10))

    # 12. ultimate_enemy_breakdown
    act = bpy.data.actions.new(name="ultimate_enemy_breakdown")
    armature_obj.animation_data.action = act
    for f in [0, 30, 60, 90]:
        w = 0.04 * math.sin(f * 0.8)
        key_bone(pose, "Hips", f, loc=(w,-0.12,-0.14), rot_euler=(-15,0,0))
        key_bone(pose, "Spine", f, rot_euler=(15,0,0))

    # 13. ultimate_enemy_dissolve
    act = bpy.data.actions.new(name="ultimate_enemy_dissolve")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,-0.06,-0.10), rot_euler=(-10,0,0))
    key_bone(pose, "Hips", 50, loc=(0,-0.25,-0.25), rot_euler=(-25,0,0))
    key_bone(pose, "UpperLeg.L", 50, rot_euler=(-60,10,-10))
    key_bone(pose, "LowerLeg.L", 50, rot_euler=(95,0,0))
    key_bone(pose, "UpperLeg.R", 50, rot_euler=(-60,-10,10))
    key_bone(pose, "LowerLeg.R", 50, rot_euler=(95,0,0))
    key_bone(pose, "Spine", 50, rot_euler=(30,0,0))
    key_bone(pose, "UpperArm.L", 50, rot_euler=(-60,-20,20))
    key_bone(pose, "UpperArm.R", 50, rot_euler=(-60,20,-20))
    key_bone(pose, "Hips", 120, loc=(0,-0.35,-0.30), rot_euler=(-35,0,0))

    # 14. ultimate_enemy_collapse
    act = bpy.data.actions.new(name="ultimate_enemy_collapse")
    armature_obj.animation_data.action = act
    key_bone(pose, "Hips", 0, loc=(0,-0.35,-0.30), rot_euler=(-35,0,0))
    key_bone(pose, "Hips", 60, loc=(0,-0.50,-0.45), rot_euler=(-50,0,0))

    bpy.ops.object.mode_set(mode='OBJECT')

def export_asset(obj, path):
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f">> Exported {path}")

# --- FINE ORGANIC FILAMENTS (NO GIANT NOODLES) ---
def make_fine_energy_filaments(name, count=4, radius=0.25, height=2.0, turns=2.5):
    reset_blend()
    c = bpy.data.curves.new(name=name, type='CURVE')
    c.dimensions = '3D'
    c.resolution_u = 16
    for strand in range(count):
        s = c.splines.new('BEZIER')
        s.bezier_points.add(8)
        offset = (strand / float(count)) * 2.0 * math.pi
        for i, pt in enumerate(s.bezier_points):
            t = i / 8.0
            h = t * height - 0.1
            r = (radius + 0.12 * math.sin(t * math.pi)) * (1.0 - 0.15 * t)
            angle = t * math.pi * turns + offset
            pt.co = Vector((math.cos(angle)*r, math.sin(angle)*r, h))
            pt.handle_left_type = 'AUTO'
            pt.handle_right_type = 'AUTO'
            pt.radius = math.sin(t * math.pi) * 0.4
    obj = bpy.data.objects.new(name, c)
    bpy.context.collection.objects.link(obj)
    c.extrude = 0.012 # Extremely fine thin filament
    c.bevel_depth = 0.003
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    m = bpy.data.materials.new(name=name + "Mat")
    obj.data.materials.append(m)
    return obj

def create_ground_energy_cracks(path):
    reset_blend()
    bpy.ops.mesh.primitive_circle_add(vertices=48, radius=6.0, fill_type='NGON')
    obj = bpy.context.active_object
    obj.name = "GroundEnergyCracks"
    m = bpy.data.materials.new(name="GroundCracksMat")
    obj.data.materials.append(m)
    export_asset(obj, path)

def create_fluted_ring(name, major_r, minor_r, path):
    reset_blend()
    bpy.ops.mesh.primitive_torus_add(major_radius=major_r, minor_radius=minor_r, major_segments=36, minor_segments=6)
    obj = bpy.context.active_object
    obj.name = name
    m = bpy.data.materials.new(name=name + "Mat")
    obj.data.materials.append(m)
    export_asset(obj, path)

def create_shard_cluster(name, path):
    reset_blend()
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.15)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = Vector((0.08, 0.08, 0.45))
    bpy.ops.object.transform_apply(scale=True)
    m = bpy.data.materials.new(name=name + "Mat")
    obj.data.materials.append(m)
    export_asset(obj, path)

# --- 1. PLAYER-TO-SKY ASCENDING ENERGY STREAM (HERO ASSET) ---
def create_player_to_sky_energy_stream(path):
    reset_blend()
    
    # Layer A: 6 Braided Organic Helical Filaments
    c = bpy.data.curves.new(name="AscendingStrands", type='CURVE')
    c.dimensions = '3D'
    c.resolution_u = 24
    height = 42.0
    strand_count = 6
    
    for strand in range(strand_count):
        s = c.splines.new('BEZIER')
        s.bezier_points.add(14)
        strand_phase = (strand / float(strand_count)) * 2.0 * math.pi
        
        for i, pt in enumerate(s.bezier_points):
            t = i / 14.0 # 0.0 at sword, 1.0 at sky
            h = t * height
            # Radius expands organically from 0.08m at blade to 0.5m in mid-air to 3.5m at sky canopy
            r = (0.08 + 0.45 * t + 3.0 * (t ** 3.0)) + 0.12 * math.sin(t * 12.0 + strand_phase)
            # Twisting angle
            turns = 5.0
            angle = t * math.pi * turns + strand_phase
            
            x = math.cos(angle) * r
            y = math.sin(angle) * r
            z = h
            pt.co = Vector((x, y, z))
            pt.handle_left_type = 'AUTO'
            pt.handle_right_type = 'AUTO'
            pt.radius = (1.0 - 0.2 * t) * (0.02 + 0.03 * math.sin(t * math.pi))
            
    c.extrude = 0.018
    c.bevel_depth = 0.008
    obj_strands = bpy.data.objects.new("AscendingStrandsObj", c)
    bpy.context.collection.objects.link(obj_strands)
    bpy.context.view_layer.objects.active = obj_strands
    bpy.ops.object.convert(target='MESH')

    # Layer B: Fluted Sword Collar Base (Hugging blade tip)
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.25, radius2=0.04, depth=1.2, location=(0, 0, 0.6))
    collar_obj = bpy.context.active_object
    collar_obj.name = "SwordCollar"

    # Layer C: Accelerating Astral Energy Shards along the column
    shard_objs = []
    for s_idx in range(12):
        st = (s_idx + 1) / 13.0
        sh_z = (st ** 1.3) * height
        sh_ang = st * math.pi * 7.0 + (s_idx * 1.618)
        sh_r = (0.15 + 0.6 * st)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.08, location=(math.cos(sh_ang)*sh_r, math.sin(sh_ang)*sh_r, sh_z))
        shard = bpy.context.active_object
        shard.scale = Vector((0.4, 0.4, 2.2))
        bpy.ops.object.transform_apply(scale=True)
        shard_objs.append(shard)

    # Join all layers into a unified hero asset
    bpy.ops.object.select_all(action='DESELECT')
    obj_strands.select_set(True)
    collar_obj.select_set(True)
    for sh in shard_objs:
        sh.select_set(True)
    bpy.context.view_layer.objects.active = obj_strands
    bpy.ops.object.join()
    
    obj_strands.name = "PlayerToSkyEnergyStream"
    m = bpy.data.materials.new(name="PlayerToSkyEnergyMat")
    obj_strands.data.materials.append(m)
    export_asset(obj_strands, path)

# --- 2. SKY CELESTIAL ARCS & ORBITAL RINGS ---
def create_sky_celestial_arcs(path):
    reset_blend()
    
    # 3 Concentric Fluted Celestial Rings tilted in 3D
    ring_specs = [
        (28.0, 0.35, (12.0, 8.0, 0.0), 32.0),
        (42.0, 0.50, (-18.0, -14.0, 25.0), 38.0),
        (56.0, 0.70, (24.0, -10.0, -35.0), 44.0)
    ]
    ring_objs = []
    for r_major, r_minor, rot_deg, z_pos in ring_specs:
        bpy.ops.mesh.primitive_torus_add(major_radius=r_major, minor_radius=r_minor, major_segments=48, minor_segments=8, location=(0, 0, z_pos))
        ring = bpy.context.active_object
        ring.rotation_euler = Euler([math.radians(a) for a in rot_deg], 'XYZ')
        bpy.ops.object.transform_apply(rotation=True, location=False)
        ring_objs.append(ring)
        
    # Intersecting Celestial Arcs
    c = bpy.data.curves.new(name="CelestialArcs", type='CURVE')
    c.dimensions = '3D'
    c.resolution_u = 24
    for arc_idx in range(6):
        s = c.splines.new('BEZIER')
        s.bezier_points.add(6)
        base_ang = (arc_idx / 6.0) * 2.0 * math.pi
        for p_i, pt in enumerate(s.bezier_points):
            t = p_i / 6.0
            ang = base_ang + (t - 0.5) * 1.8
            r = 30.0 + 25.0 * math.sin(t * math.pi)
            z = 35.0 + 15.0 * math.cos(t * math.pi)
            pt.co = Vector((math.cos(ang)*r, math.sin(ang)*r, z))
            pt.handle_left_type = 'AUTO'
            pt.handle_right_type = 'AUTO'
    c.extrude = 0.08
    c.bevel_depth = 0.04
    arc_obj = bpy.data.objects.new("CelestialArcsObj", c)
    bpy.context.collection.objects.link(arc_obj)
    bpy.context.view_layer.objects.active = arc_obj
    bpy.ops.object.convert(target='MESH')
    ring_objs.append(arc_obj)
    
    # Join into single asset
    bpy.ops.object.select_all(action='DESELECT')
    for ro in ring_objs:
        ro.select_set(True)
    bpy.context.view_layer.objects.active = ring_objs[0]
    bpy.ops.object.join()
    master_arcs = ring_objs[0]
    master_arcs.name = "SkyCelestialArcs"
    m = bpy.data.materials.new(name="SkyCelestialArcsMat")
    master_arcs.data.materials.append(m)
    export_asset(master_arcs, path)

# --- 5. BREAKTHROUGH LIVING PLASMA COLUMN (CATACLYSM ENERGY COLUMN) ---
def create_cataclysm_energy_column(path):
    reset_blend()
    objs_to_join = []

    # 1. Inner Core Spine (0m to 65m)
    curve_core = bpy.data.curves.new('CoreSpineCurve', 'CURVE')
    curve_core.dimensions = '3D'
    curve_core.bevel_depth = 0.35
    curve_core.bevel_resolution = 8
    spline_core = curve_core.splines.new('BEZIER')
    
    num_pts = 16
    spline_core.bezier_points.add(num_pts - 1)
    for i in range(num_pts):
        t = i / float(num_pts - 1)
        z = t * 65.0
        # Gentle organic wobble along the height
        x = math.sin(t * 12.0) * (0.2 + t * 0.8)
        y = math.cos(t * 10.0) * (0.2 + t * 0.8)
        pt = spline_core.bezier_points[i]
        pt.co = Vector((x, y, z))
        pt.handle_left_type = 'AUTO'
        pt.handle_right_type = 'AUTO'
        pt.radius = 0.4 + (t * 2.2) # Expands upward into sky canopy

    obj_core = bpy.data.objects.new('EnergyColumn_Core', curve_core)
    bpy.context.collection.objects.link(obj_core)
    objs_to_join.append(obj_core)

    # 2. Four Intertwined Turbulent Plasma Lobes
    for lobe_idx in range(4):
        curve_lobe = bpy.data.curves.new(f'PlasmaLobeCurve_{lobe_idx}', 'CURVE')
        curve_lobe.dimensions = '3D'
        curve_lobe.bevel_depth = 0.22
        curve_lobe.bevel_resolution = 6
        spline_lobe = curve_lobe.splines.new('BEZIER')
        
        pts_count = 20
        spline_lobe.bezier_points.add(pts_count - 1)
        base_angle = (lobe_idx / 4.0) * math.pi * 2.0
        freq = 1.8 + (lobe_idx * 0.4)
        
        for i in range(pts_count):
            t = i / float(pts_count - 1)
            z = t * 65.0
            radius = (0.5 + t * 4.2) * (1.0 + 0.3 * math.sin(t * 14.0 + lobe_idx))
            ang = base_angle + (t * math.pi * 6.0 * freq)
            x = math.cos(ang) * radius
            y = math.sin(ang) * radius
            pt = spline_lobe.bezier_points[i]
            pt.co = Vector((x, y, z))
            pt.handle_left_type = 'AUTO'
            pt.handle_right_type = 'AUTO'
            pt.radius = 0.35 + (t * 1.6)
            
        obj_lobe = bpy.data.objects.new(f'EnergyColumn_Lobe_{lobe_idx}', curve_lobe)
        bpy.context.collection.objects.link(obj_lobe)
        objs_to_join.append(obj_lobe)

    # 3. Internal Lightning Filament Arcs (Zigzagging geometric paths)
    for lt_idx in range(6):
        curve_lt = bpy.data.curves.new(f'LightningCurve_{lt_idx}', 'CURVE')
        curve_lt.dimensions = '3D'
        curve_lt.bevel_depth = 0.08
        curve_lt.bevel_resolution = 3
        spline_lt = curve_lt.splines.new('POLY')
        
        num_lt_pts = 24
        spline_lt.points.add(num_lt_pts - 1)
        lt_base_ang = (lt_idx / 6.0) * math.pi * 2.0
        for i in range(num_lt_pts):
            t = i / float(num_lt_pts - 1)
            z = t * 65.0
            r = (0.3 + t * 2.5) + (math.sin(i * 3.7 + lt_idx) * 0.4)
            ang = lt_base_ang + (t * math.pi * 8.0) + (math.cos(i * 4.1) * 0.5)
            x = math.cos(ang) * r
            y = math.sin(ang) * r
            spline_lt.points[i].co = (x, y, z, 1.0)
            
        obj_lt = bpy.data.objects.new(f'EnergyColumn_Lightning_{lt_idx}', curve_lt)
        bpy.context.collection.objects.link(obj_lt)
        objs_to_join.append(obj_lt)

    # 4. Outer Atmospheric Dissipation Shroud (Fluted non-uniform envelope)
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=1.2, depth=65.0, location=(0, 0, 32.5))
    shroud_obj = bpy.context.active_object
    shroud_mesh = shroud_obj.data
    
    for v in shroud_mesh.vertices:
        norm_z = (v.co.z + 32.5) / 65.0 # 0.0 to 1.0
        r_scale = 0.8 + (norm_z * 7.5) # Expands from 1.0m to 8.5m
        wobble = 1.0 + (0.25 * math.sin(norm_z * 18.0 + math.atan2(v.co.y, v.co.x) * 3.0))
        v.co.x *= r_scale * wobble
        v.co.y *= r_scale * wobble

    objs_to_join.append(shroud_obj)

    # Convert curves to meshes and join into single hero asset
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs_to_join:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs_to_join[0]
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    
    col_obj = bpy.context.active_object
    col_obj.name = "CataclysmEnergyColumn"
    col_obj.location = Vector((0, 0, 0))
    
    mat = bpy.data.materials.new(name="DensePlasmaColumnMat")
    col_obj.data.materials.append(mat)
    
    export_asset(col_obj, path)

# --- 3. ATMOSPHERIC BLAST WAVE (3D LAYERED SHOCK FRONT) ---
def create_atmospheric_blast_wave(path):
    reset_blend()
    # 3-tier stepped parabolic shock wave front
    tiers = [
        (3.5, 0.15, 0.4),
        (5.5, 0.22, 1.2),
        (8.0, 0.30, 2.4)
    ]
    tier_objs = []
    for r_maj, r_min, z_off in tiers:
        bpy.ops.mesh.primitive_torus_add(major_radius=r_maj, minor_radius=r_min, major_segments=36, minor_segments=8, location=(0, 0, z_off))
        t_obj = bpy.context.active_object
        t_obj.scale = Vector((1.0, 1.0, 0.65))
        bpy.ops.object.transform_apply(scale=True)
        tier_objs.append(t_obj)
        
    bpy.ops.object.select_all(action='DESELECT')
    for to in tier_objs:
        to.select_set(True)
    bpy.context.view_layer.objects.active = tier_objs[0]
    bpy.ops.object.join()
    wave_obj = tier_objs[0]
    wave_obj.name = "AtmosphericBlastWave"
    m = bpy.data.materials.new(name="AtmosphericBlastMat")
    wave_obj.data.materials.append(m)
    export_asset(wave_obj, path)

# --- 4. SKY CATACLYSM BURST (UPPER ATMOSPHERE SHOCKWAVE DISK) ---
def create_sky_cataclysm_burst(path):
    reset_blend()
    # Multi-blade radiating starburst disk with fluted outer shock ring
    bpy.ops.mesh.primitive_circle_add(vertices=64, radius=35.0, fill_type='NGON', location=(0, 0, 38.0))
    burst_disk = bpy.context.active_object
    
    bpy.ops.mesh.primitive_torus_add(major_radius=36.0, minor_radius=1.8, major_segments=48, minor_segments=8, location=(0, 0, 38.0))
    burst_ring = bpy.context.active_object
    
    bpy.ops.object.select_all(action='DESELECT')
    burst_disk.select_set(True)
    burst_ring.select_set(True)
    bpy.context.view_layer.objects.active = burst_disk
    bpy.ops.object.join()
    burst_obj = burst_disk
    burst_obj.name = "SkyCataclysmBurst"
    m = bpy.data.materials.new(name="SkyCataclysmBurstMat")
    burst_obj.data.materials.append(m)
    export_asset(burst_obj, path)

def main():
    project_root = "/Users/ramteja/Documents/Blender exp game"
    lib_dir = os.path.join(project_root, "assets", "ultimate", "blender")
    vfx_dir = os.path.join(project_root, "assets", "vfx")
    char_dir = os.path.join(project_root, "assets", "characters")
    os.makedirs(lib_dir, exist_ok=True)
    os.makedirs(vfx_dir, exist_ok=True)

    # 1. Thin Organic Energy Filaments (Zero giant tubes)
    export_asset(make_fine_energy_filaments("AuraFilamentsPrimary", 4, 0.35, 2.2, 2.8), os.path.join(lib_dir, "aura_ribbon_primary.glb"))
    export_asset(make_fine_energy_filaments("AuraFilamentsSecondary", 5, 0.50, 2.5, -2.2), os.path.join(lib_dir, "aura_ribbon_secondary.glb"))
    export_asset(make_fine_energy_filaments("EnergyFilamentsCluster", 6, 0.25, 2.0, 4.0), os.path.join(lib_dir, "energy_filament_cluster.glb"))
    
    # 2. Blade and Hilt Geometry
    create_fluted_ring("SwordEnergyShell", 0.06, 0.015, os.path.join(lib_dir, "sword_energy_shell.glb"))
    create_fluted_ring("SwordEnergyArc", 0.12, 0.02, os.path.join(lib_dir, "sword_energy_arc.glb"))
    
    # 3. Ground & Shockwaves
    create_ground_energy_cracks(os.path.join(lib_dir, "ground_energy_cracks.glb"))
    create_fluted_ring("GroundEnergyRing", 3.2, 0.08, os.path.join(lib_dir, "ground_energy_ring.glb"))
    create_fluted_ring("PropagationFront", 4.5, 0.12, os.path.join(lib_dir, "propagation_front.glb"))
    create_fluted_ring("ShockwavePrimary", 2.2, 0.08, os.path.join(lib_dir, "shockwave_primary.glb"))
    create_fluted_ring("ShockwaveSecondary", 3.8, 0.10, os.path.join(lib_dir, "shockwave_secondary.glb"))
    create_shard_cluster("AstralShardSet", os.path.join(lib_dir, "astral_shard_set.glb"))
    create_shard_cluster("DissolveFragmentSet", os.path.join(lib_dir, "dissolve_fragment_set.glb"))
    create_shard_cluster("VaporCore", os.path.join(lib_dir, "vapor_core.glb"))
    export_asset(make_fine_energy_filaments("VaporStream", 4, 0.6, 2.5, 1.2), os.path.join(lib_dir, "vapor_stream.glb"))
    create_fluted_ring("SkyEnergySpiral", 45.0, 3.0, os.path.join(lib_dir, "sky_energy_spiral.glb"))
    create_ground_energy_cracks(os.path.join(lib_dir, "aftershock_energy.glb"))

    # 4. NEW HERO TOUCH-UP & BREAKTHROUGH ASSETS
    create_cataclysm_energy_column(os.path.join(lib_dir, "cataclysm_energy_column.glb"))
    create_player_to_sky_energy_stream(os.path.join(lib_dir, "player_to_sky_energy_stream.glb"))
    create_sky_celestial_arcs(os.path.join(lib_dir, "sky_celestial_arcs.glb"))
    create_atmospheric_blast_wave(os.path.join(lib_dir, "atmospheric_blast_wave.glb"))
    create_sky_cataclysm_burst(os.path.join(lib_dir, "sky_cataclysm_burst.glb"))


    # Also keep vfx dir aliases in sync
    export_asset(make_fine_energy_filaments("AuraSpiralRibbonsMesh", 4, 0.35, 2.2, 2.8), os.path.join(vfx_dir, "aura_ribbon_mesh.glb"))
    create_fluted_ring("ExpandingShockwaveRing", 2.2, 0.08, os.path.join(vfx_dir, "expanding_shockwave_ring.glb"))
    create_fluted_ring("PropagationWaveMesh", 3.5, 0.10, os.path.join(vfx_dir, "propagation_wave_mesh.glb"))

    # Re-export hero_knight.glb with all 14 actions
    knight_glb_path = os.path.join(char_dir, "hero_knight.glb")
    if os.path.exists(knight_glb_path):
        reset_blend()
        bpy.ops.import_scene.gltf(filepath=knight_glb_path)
        armature = None
        for obj in bpy.data.objects:
            if obj.type == 'ARMATURE':
                armature = obj
                break
        if armature:
            author_skeletal_actions(armature)
            bpy.ops.export_scene.gltf(
                filepath=knight_glb_path,
                export_format='GLB',
                export_animations=True,
                export_anim_single_armature=True
            )
            print(f">> Successfully exported {knight_glb_path} with all 14 cinematic actions!")

if __name__ == "__main__":
    main()

