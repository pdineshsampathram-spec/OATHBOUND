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
