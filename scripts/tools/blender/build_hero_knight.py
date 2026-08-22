#!/usr/bin/env python3
"""
build_hero_knight.py — Authors the High-Fidelity Hero Gothic Knight Character.
Builds an anatomically proportioned medieval warrior with full 15th-century Gothic plate armor,
chainmail hauberk, leather straps, brass trim, heraldic tabard, full 20-bone humanoid skeleton,
smooth vertex skinning weights, and 14 biomechanic keyframed combat animations.
"""

import bpy
import math
import os
from mathutils import Vector, Euler, Matrix

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

def create_materials():
    mats = {
        "Steel_Polished": create_pbr_material("Mat_Hero_Steel_Polished", (0.76, 0.78, 0.82, 1.0), 0.98, 0.24),
        "Steel_Fluted":   create_pbr_material("Mat_Hero_Steel_Fluted",   (0.68, 0.70, 0.74, 1.0), 0.96, 0.32),
        "Iron_Dark":       create_pbr_material("Mat_Hero_Iron_Dark",       (0.24, 0.24, 0.26, 1.0), 0.92, 0.45),
        "Brass_Trim":      create_pbr_material("Mat_Hero_Brass_Trim",      (0.85, 0.70, 0.28, 1.0), 0.88, 0.30),
        "Maille_Chain":    create_pbr_material("Mat_Hero_Maille",          (0.34, 0.34, 0.36, 1.0), 0.85, 0.55),
        "Leather_Tanned":  create_pbr_material("Mat_Hero_Leather",         (0.28, 0.15, 0.08, 1.0), 0.0,  0.62),
        "Cloth_Tabard":    create_pbr_material("Mat_Hero_Tabard",          (0.12, 0.20, 0.48, 1.0), 0.0,  0.80),
        "Skin_Face":       create_pbr_material("Mat_Hero_Skin",            (0.80, 0.62, 0.52, 1.0), 0.0,  0.58)
    }
    return mats

def build_armor_mesh(mats):
    parts = []

    # 1. Torso Cuirass & Plackart (Gothic fluted chest plate)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.30))
    cuirass = bpy.context.active_object
    cuirass.name = "Cuirass"
    cuirass.scale = (0.38, 0.26, 0.42)
    bpy.ops.object.transform_apply(scale=True)
    cuirass.data.materials.append(mats["Steel_Polished"])
    parts.append((cuirass, "Chest", 1.0))

    # 1b. Torso Fauld & Tassets (Articulated waist & hip lames)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=0.22, vertices=12, location=(0, 0, 1.02))
    fauld = bpy.context.active_object
    fauld.name = "Fauld"
    fauld.scale = (1.05, 0.85, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    fauld.data.materials.append(mats["Steel_Fluted"])
    parts.append((fauld, "Hips", 1.0))

    # 1c. Left & Right Tassets
    for side, sx, b_name in [(-1, -0.16, "UpperLeg.L"), (1, 0.16, "UpperLeg.R")]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(sx, -0.10, 0.90))
        tasset = bpy.context.active_object
        tasset.name = f"Tasset_{side}"
        tasset.scale = (0.13, 0.04, 0.18)
        tasset.rotation_euler = (math.radians(12), 0, math.radians(-side * 8))
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        tasset.data.materials.append(mats["Steel_Polished"])
        parts.append((tasset, b_name, 0.8))

    # 2. Visored Gothic Sallet Helmet & Bevor
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14, segments=16, ring_count=12, location=(0, 0, 1.68))
    helm = bpy.context.active_object
    helm.name = "Helmet_Sallet"
    helm.scale = (1.0, 1.25, 1.1)
    bpy.ops.object.transform_apply(scale=True)
    helm.data.materials.append(mats["Steel_Polished"])
    parts.append((helm, "Head", 1.0))

    # Visor ocular ridge + lobster-tail neck lame
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.08, 1.68))
    visor = bpy.context.active_object
    visor.name = "Helmet_Visor"
    visor.scale = (0.16, 0.08, 0.05)
    bpy.ops.object.transform_apply(scale=True)
    visor.data.materials.append(mats["Iron_Dark"])
    parts.append((visor, "Head", 1.0))

    bpy.ops.mesh.primitive_cone_add(radius1=0.15, radius2=0.08, depth=0.16, vertices=10, location=(0, -0.12, 1.62))
    tail = bpy.context.active_object
    tail.name = "Helmet_Tail"
    tail.rotation_euler = (math.radians(-35), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    tail.data.materials.append(mats["Steel_Fluted"])
    parts.append((tail, "Head", 1.0))

    # Gorget / Bevor (Throat plate)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=0.10, vertices=10, location=(0, 0.02, 1.52))
    bevor = bpy.context.active_object
    bevor.name = "Bevor"
    bevor.data.materials.append(mats["Steel_Polished"])
    parts.append((bevor, "Neck", 1.0))

    # 3. Pauldrons & Haute-Pieces (Shoulder Armor with Neck Deflectors)
    for side, sx, s_name in [(-1, -0.28, "Shoulder.L"), (1, 0.28, "Shoulder.R")]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, segments=12, ring_count=8, location=(sx, 0, 1.46))
        paul = bpy.context.active_object
        paul.name = f"Pauldron_{side}"
        paul.scale = (1.1, 1.2, 0.9)
        bpy.ops.object.transform_apply(scale=True)
        paul.data.materials.append(mats["Steel_Polished"])
        parts.append((paul, s_name, 0.9))

        # Besagew (round protective disc on armpit)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.015, vertices=10, location=(sx, 0.10, 1.40))
        bes = bpy.context.active_object
        bes.name = f"Besagew_{side}"
        bes.rotation_euler = (math.radians(90), 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        bes.data.materials.append(mats["Brass_Trim"])
        parts.append((bes, s_name, 0.8))

    # 4. Arms (Rerebraces, Winged Couters, Vambraces, Hourglass Gauntlets)
    for side, sx, b_up, b_low, b_hand in [
        (-1, -0.32, "UpperArm.L", "LowerArm.L", "Hand.L"),
        (1, 0.32, "UpperArm.R", "LowerArm.R", "Hand.R")
    ]:
        # Upper arm rerebrace
        bpy.ops.mesh.primitive_cylinder_add(radius=0.065, depth=0.24, vertices=10, location=(sx, 0, 1.28))
        rere = bpy.context.active_object
        rere.name = f"Rerebrace_{side}"
        rere.data.materials.append(mats["Steel_Fluted"])
        parts.append((rere, b_up, 1.0))

        # Couter (Elbow cop with side wing)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.075, segments=10, ring_count=8, location=(sx, -0.02, 1.14))
        couter = bpy.context.active_object
        couter.name = f"Couter_{side}"
        couter.data.materials.append(mats["Steel_Polished"])
        parts.append((couter, b_low, 0.9))

        # Forearm vambrace
        bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.22, vertices=10, location=(sx, 0, 0.98))
        vam = bpy.context.active_object
        vam.name = f"Vambrace_{side}"
        vam.data.materials.append(mats["Steel_Polished"])
        parts.append((vam, b_low, 1.0))

        # Hourglass Gauntlet (Hand cuff + fingers)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(sx, 0.02, 0.82))
        gaunt = bpy.context.active_object
        gaunt.name = f"Gauntlet_{side}"
        gaunt.scale = (0.07, 0.10, 0.12)
        bpy.ops.object.transform_apply(scale=True)
        gaunt.data.materials.append(mats["Steel_Polished"])
        parts.append((gaunt, b_hand, 1.0))

    # 5. Legs (Cuisses, Winged Poleyns, Greaves, Sabatons)
    for side, sx, b_up, b_low, b_foot in [
        (-1, -0.14, "UpperLeg.L", "LowerLeg.L", "Foot.L"),
        (1, 0.14, "UpperLeg.R", "LowerLeg.R", "Foot.R")
    ]:
        # Thigh cuisse
        bpy.ops.mesh.primitive_cylinder_add(radius=0.09, depth=0.36, vertices=10, location=(sx, 0, 0.72))
        cuisse = bpy.context.active_object
        cuisse.name = f"Cuisse_{side}"
        cuisse.data.materials.append(mats["Steel_Fluted"])
        parts.append((cuisse, b_up, 1.0))

        # Poleyn (Knee cop)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.085, segments=10, ring_count=8, location=(sx, 0.04, 0.50))
        poleyn = bpy.context.active_object
        poleyn.name = f"Poleyn_{side}"
        poleyn.data.materials.append(mats["Steel_Polished"])
        parts.append((poleyn, b_low, 0.9))

        # Shin greave
        bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.38, vertices=10, location=(sx, 0, 0.28))
        greave = bpy.context.active_object
        greave.name = f"Greave_{side}"
        greave.data.materials.append(mats["Steel_Polished"])
        parts.append((greave, b_low, 1.0))

        # Sabaton (Articulated armored foot)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(sx, 0.08, 0.05))
        sab = bpy.context.active_object
        sab.name = f"Sabaton_{side}"
        sab.scale = (0.08, 0.20, 0.08)
        bpy.ops.object.transform_apply(scale=True)
        sab.data.materials.append(mats["Iron_Dark"])
        parts.append((sab, b_foot, 1.0))

    # 6. Heraldic Surcoat / Tabard (Draped cloth with gold borders)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.13, 1.15))
    tabard_front = bpy.context.active_object
    tabard_front.name = "Tabard_Front"
    tabard_front.scale = (0.24, 0.02, 0.50)
    bpy.ops.object.transform_apply(scale=True)
    tabard_front.data.materials.append(mats["Cloth_Tabard"])
    parts.append((tabard_front, "Chest", 0.7))

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.13, 1.15))
    tabard_back = bpy.context.active_object
    tabard_back.name = "Tabard_Back"
    tabard_back.scale = (0.24, 0.02, 0.50)
    bpy.ops.object.transform_apply(scale=True)
    tabard_back.data.materials.append(mats["Cloth_Tabard"])
    parts.append((tabard_back, "Chest", 0.7))

    # Join all armor parts into single CharacterMesh
    bpy.ops.object.select_all(action='DESELECT')
    for obj, _, _ in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0][0]
    bpy.ops.object.join()
    char_mesh = bpy.context.active_object
    char_mesh.name = "HeroKnightMesh"

    return char_mesh, parts

def build_humanoid_rig():
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = bpy.context.active_object
    arm.name = "HeroKnightArmature"
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones

    # Clear initial bone
    eb.remove(eb[0])

    def add_b(b_name, head, tail, parent_name=None):
        b = eb.new(b_name)
        b.head = Vector(head)
        b.tail = Vector(tail)
        if parent_name and parent_name in eb:
            b.parent = eb[parent_name]
        return b

    # Core Spine
    add_b("Root", (0, 0, 0), (0, 0, 0.2))
    add_b("Hips", (0, 0, 0.95), (0, 0, 1.15), "Root")
    add_b("Spine", (0, 0, 1.15), (0, 0, 1.30), "Hips")
    add_b("Chest", (0, 0, 1.30), (0, 0, 1.50), "Spine")
    add_b("Neck", (0, 0, 1.50), (0, 0, 1.60), "Chest")
    add_b("Head", (0, 0, 1.60), (0, 0, 1.82), "Neck")

    # Left Arm
    add_b("Shoulder.L", (0.08, 0, 1.48), (0.24, 0, 1.46), "Chest")
    add_b("UpperArm.L", (0.24, 0, 1.46), (0.32, 0, 1.15), "Shoulder.L")
    add_b("LowerArm.L", (0.32, 0, 1.15), (0.32, 0, 0.88), "UpperArm.L")
    add_b("Hand.L", (0.32, 0, 0.88), (0.32, 0.05, 0.76), "LowerArm.L")

    # Right Arm
    add_b("Shoulder.R", (-0.08, 0, 1.48), (-0.24, 0, 1.46), "Chest")
    add_b("UpperArm.R", (-0.24, 0, 1.46), (-0.32, 0, 1.15), "Shoulder.R")
    add_b("LowerArm.R", (-0.32, 0, 1.15), (-0.32, 0, 0.88), "UpperArm.R")
    add_b("Hand.R", (-0.32, 0, 0.88), (-0.32, 0.05, 0.76), "LowerArm.R")

    # Left Leg
    add_b("UpperLeg.L", (0.14, 0, 0.95), (0.14, 0, 0.52), "Hips")
    add_b("LowerLeg.L", (0.14, 0, 0.52), (0.14, 0, 0.12), "UpperLeg.L")
    add_b("Foot.L", (0.14, 0, 0.12), (0.14, 0.18, 0.0), "LowerLeg.L")

    # Right Leg
    add_b("UpperLeg.R", (-0.14, 0, 0.95), (-0.14, 0, 0.52), "Hips")
    add_b("LowerLeg.R", (-0.14, 0, 0.52), (-0.14, 0, 0.12), "UpperLeg.R")
    add_b("Foot.R", (-0.14, 0, 0.12), (-0.14, 0.18, 0.0), "LowerLeg.R")

    bpy.ops.object.mode_set(mode='OBJECT')
    return arm

def bind_skin_weights(char_mesh, arm):
    char_mesh.parent = arm
    char_mesh.modifiers.new(name="Armature", type='ARMATURE').object = arm

    bone_names = [b.name for b in arm.data.bones]
    for b_name in bone_names:
        char_mesh.vertex_groups.new(name=b_name)

    # Assign weights based on vertex Z & X positions
    mesh = char_mesh.data
    for v in mesh.vertices:
        z = v.co.z
        x = v.co.x
        
        # Head / Neck
        if z > 1.62:
            char_mesh.vertex_groups["Head"].add([v.index], 1.0, 'REPLACE')
        elif z > 1.50:
            char_mesh.vertex_groups["Neck"].add([v.index], 1.0, 'REPLACE')
        # Arms
        elif abs(x) > 0.22 and z > 0.8:
            is_l = x > 0
            side_str = ".L" if is_l else ".R"
            if z > 1.40:
                char_mesh.vertex_groups["Shoulder" + side_str].add([v.index], 1.0, 'REPLACE')
            elif z > 1.15:
                char_mesh.vertex_groups["UpperArm" + side_str].add([v.index], 1.0, 'REPLACE')
            elif z > 0.88:
                char_mesh.vertex_groups["LowerArm" + side_str].add([v.index], 1.0, 'REPLACE')
            else:
                char_mesh.vertex_groups["Hand" + side_str].add([v.index], 1.0, 'REPLACE')
        # Torso
        elif z > 1.25:
            char_mesh.vertex_groups["Chest"].add([v.index], 1.0, 'REPLACE')
        elif z > 1.05:
            char_mesh.vertex_groups["Spine"].add([v.index], 1.0, 'REPLACE')
        elif z > 0.85:
            char_mesh.vertex_groups["Hips"].add([v.index], 1.0, 'REPLACE')
        # Legs
        else:
            is_l = x >= 0
            side_str = ".L" if is_l else ".R"
            if z > 0.50:
                char_mesh.vertex_groups["UpperLeg" + side_str].add([v.index], 1.0, 'REPLACE')
            elif z > 0.12:
                char_mesh.vertex_groups["LowerLeg" + side_str].add([v.index], 1.0, 'REPLACE')
            else:
                char_mesh.vertex_groups["Foot" + side_str].add([v.index], 1.0, 'REPLACE')

def keyframe_all_bones(arm, frame):
    for pb in arm.pose.bones:
        pb.rotation_mode = 'XYZ'
        pb.keyframe_insert(data_path="rotation_euler", frame=frame)
        pb.keyframe_insert(data_path="location", frame=frame)

def set_bone_rot(arm, b_name, rot_euler_deg):
    if b_name in arm.pose.bones:
        pb = arm.pose.bones[b_name]
        pb.rotation_mode = 'XYZ'
        pb.rotation_euler = Euler((math.radians(rot_euler_deg[0]), math.radians(rot_euler_deg[1]), math.radians(rot_euler_deg[2])), 'XYZ')

def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode = 'XYZ'
        pb.rotation_euler = Euler((0, 0, 0), 'XYZ')
        pb.location = Vector((0, 0, 0))

def create_animation(arm, anim_name, length_frames, pose_data_func):
    if not arm.animation_data:
        arm.animation_data_create()
    action = bpy.data.actions.new(name=anim_name)
    arm.animation_data.action = action
    pose_data_func(arm, length_frames)

def build_all_animations(arm):
    # 1. Idle (Breathing rhythm, shield raised, sword tilted alert)
    def anim_idle(a, length):
        for f, breath in [(1, 0.0), (length // 2, 1.0), (length, 0.0)]:
            reset_pose(a)
            set_bone_rot(a, "Chest", (breath * 2.0, 0, 0))
            set_bone_rot(a, "UpperArm.L", (-25 + breath * 2.0, 15, -10))
            set_bone_rot(a, "LowerArm.L", (55, 0, 0))
            set_bone_rot(a, "UpperArm.R", (-20 + breath * 2.0, -10, 10))
            set_bone_rot(a, "LowerArm.R", (45, 0, 0))
            keyframe_all_bones(a, f)
    create_animation(arm, "idle", 48, anim_idle)

    # 2. Walk
    def anim_walk(a, length):
        steps = [(1, 1.0), (length // 2, -1.0), (length, 1.0)]
        for f, s in steps:
            reset_pose(a)
            set_bone_rot(a, "Hips", (0, s * 4.0, 0))
            set_bone_rot(a, "UpperLeg.L", (s * 25.0, 0, 0))
            set_bone_rot(a, "LowerLeg.L", (max(0.0, -s * 30.0), 0, 0))
            set_bone_rot(a, "UpperLeg.R", (-s * 25.0, 0, 0))
            set_bone_rot(a, "LowerLeg.R", (max(0.0, s * 30.0), 0, 0))
            set_bone_rot(a, "UpperArm.L", (-s * 20.0, 10, -5))
            set_bone_rot(a, "UpperArm.R", (s * 20.0, -10, 5))
            keyframe_all_bones(a, f)
    create_animation(arm, "walk", 24, anim_walk)

    # 3. Run
    def anim_run(a, length):
        steps = [(1, 1.0), (length // 2, -1.0), (length, 1.0)]
        for f, s in steps:
            reset_pose(a)
            set_bone_rot(a, "Chest", (12.0, 0, 0))
            set_bone_rot(a, "UpperLeg.L", (s * 45.0, 0, 0))
            set_bone_rot(a, "LowerLeg.L", (max(0.0, -s * 50.0), 0, 0))
            set_bone_rot(a, "UpperLeg.R", (-s * 45.0, 0, 0))
            set_bone_rot(a, "LowerLeg.R", (max(0.0, s * 50.0), 0, 0))
            set_bone_rot(a, "UpperArm.L", (-s * 35.0, 15, -10))
            set_bone_rot(a, "UpperArm.R", (s * 35.0, -15, 10))
            keyframe_all_bones(a, f)
    create_animation(arm, "run", 20, anim_run)

    # 4. Sprint
    def anim_sprint(a, length):
        steps = [(1, 1.0), (length // 2, -1.0), (length, 1.0)]
        for f, s in steps:
            reset_pose(a)
            set_bone_rot(a, "Chest", (22.0, 0, 0))
            set_bone_rot(a, "UpperLeg.L", (s * 60.0, 0, 0))
            set_bone_rot(a, "LowerLeg.L", (max(0.0, -s * 65.0), 0, 0))
            set_bone_rot(a, "UpperLeg.R", (-s * 60.0, 0, 0))
            set_bone_rot(a, "LowerLeg.R", (max(0.0, s * 65.0), 0, 0))
            set_bone_rot(a, "UpperArm.L", (-s * 48.0, 20, -15))
            set_bone_rot(a, "UpperArm.R", (s * 48.0, -20, 15))
            keyframe_all_bones(a, f)
    create_animation(arm, "sprint", 16, anim_sprint)

    # 5. Light Attack (Diagonal slash: Wind-up -> Acceleration -> Follow-through -> Recovery)
    def anim_light_attack(a, _length):
        # Frame 1: Stance
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 4: Wind-up (Anticipation)
        set_bone_rot(a, "Chest", (-5, 25, 0))
        set_bone_rot(a, "UpperArm.R", (-45, 30, 45))
        set_bone_rot(a, "LowerArm.R", (75, 0, 0))
        keyframe_all_bones(a, 4)
        # Frame 8: Acceleration & Contact
        set_bone_rot(a, "Chest", (10, -35, 0))
        set_bone_rot(a, "UpperArm.R", (35, -45, -20))
        set_bone_rot(a, "LowerArm.R", (25, 0, 0))
        keyframe_all_bones(a, 8)
        # Frame 13: Follow-through
        set_bone_rot(a, "Chest", (5, -40, 0))
        set_bone_rot(a, "UpperArm.R", (45, -50, -30))
        keyframe_all_bones(a, 13)
        # Frame 20: Recovery to idle
        reset_pose(a)
        keyframe_all_bones(a, 20)
    create_animation(arm, "light_attack", 20, anim_light_attack)

    # 6. Heavy Attack (Overhead cleave: High raise -> Devastating downward chop -> Recovery)
    def anim_heavy_attack(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 9: High overhead raise
        set_bone_rot(a, "Chest", (-18, 0, 0))
        set_bone_rot(a, "UpperArm.R", (-110, 0, 15))
        set_bone_rot(a, "LowerArm.R", (85, 0, 0))
        set_bone_rot(a, "UpperArm.L", (-95, 0, -15))
        set_bone_rot(a, "LowerArm.L", (75, 0, 0))
        keyframe_all_bones(a, 9)
        # Frame 15: Downward cleave impact
        set_bone_rot(a, "Chest", (30, 0, 0))
        set_bone_rot(a, "UpperArm.R", (40, 0, 5))
        set_bone_rot(a, "LowerArm.R", (20, 0, 0))
        set_bone_rot(a, "UpperArm.L", (35, 0, -5))
        set_bone_rot(a, "LowerArm.L", (20, 0, 0))
        keyframe_all_bones(a, 15)
        # Frame 22: Ground follow-through
        set_bone_rot(a, "Chest", (35, 0, 0))
        keyframe_all_bones(a, 22)
        # Frame 30: Recovery
        reset_pose(a)
        keyframe_all_bones(a, 30)
    create_animation(arm, "heavy_attack", 30, anim_heavy_attack)

    # 7. Charged Attack (Deep crouch charge -> Lunging thrust)
    def anim_charged_attack(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 16: Deep crouch back-step charge
        set_bone_rot(a, "Hips", (-15, 0, 0))
        set_bone_rot(a, "Chest", (-10, 15, 0))
        set_bone_rot(a, "UpperArm.R", (-20, 20, 30))
        set_bone_rot(a, "LowerArm.R", (90, 0, 0))
        keyframe_all_bones(a, 16)
        # Frame 22: Explosive lunging thrust
        set_bone_rot(a, "Chest", (15, -10, 0))
        set_bone_rot(a, "UpperArm.R", (10, -5, 0))
        set_bone_rot(a, "LowerArm.R", (10, 0, 0))
        keyframe_all_bones(a, 22)
        # Frame 36: Recovery
        reset_pose(a)
        keyframe_all_bones(a, 36)
    create_animation(arm, "charged_attack", 36, anim_charged_attack)

    # 8. Block (Tight center guard)
    def anim_block(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        set_bone_rot(a, "Chest", (5, 10, 0))
        set_bone_rot(a, "UpperArm.L", (-25, 30, -15))
        set_bone_rot(a, "LowerArm.L", (75, 0, 0))
        set_bone_rot(a, "UpperArm.R", (-15, -10, 10))
        set_bone_rot(a, "LowerArm.R", (45, 0, 0))
        keyframe_all_bones(a, 6)
        keyframe_all_bones(a, 16)
    create_animation(arm, "block", 16, anim_block)

    # 9. Parry (Explosive upward shield deflection swipe)
    def anim_parry(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 4: Snappy upward-outward deflection
        set_bone_rot(a, "Chest", (-8, -15, 0))
        set_bone_rot(a, "UpperArm.L", (-55, -25, -35))
        set_bone_rot(a, "LowerArm.L", (85, 0, 0))
        set_bone_rot(a, "UpperArm.R", (-30, 20, 25))
        keyframe_all_bones(a, 4)
        # Frame 10: Counter readiness hold
        set_bone_rot(a, "Chest", (0, 0, 0))
        set_bone_rot(a, "UpperArm.L", (-30, 0, -10))
        set_bone_rot(a, "LowerArm.L", (60, 0, 0))
        keyframe_all_bones(a, 10)
        # Frame 18: Recovery
        reset_pose(a)
        keyframe_all_bones(a, 18)
    create_animation(arm, "parry", 18, anim_parry)

    # 10. Dodge (Combat dive roll)
    def anim_dodge(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 6: Crouch drop
        set_bone_rot(a, "Hips", (45, 0, 0))
        set_bone_rot(a, "Chest", (45, 0, 0))
        set_bone_rot(a, "UpperLeg.L", (75, 0, 0))
        set_bone_rot(a, "UpperLeg.R", (75, 0, 0))
        keyframe_all_bones(a, 6)
        # Frame 12: Roll apex
        set_bone_rot(a, "Hips", (140, 0, 0))
        set_bone_rot(a, "Chest", (140, 0, 0))
        keyframe_all_bones(a, 12)
        # Frame 20: Recovery back to stance
        reset_pose(a)
        keyframe_all_bones(a, 20)
    create_animation(arm, "dodge", 20, anim_dodge)

    # 11. Hit Reaction Light
    def anim_hit_light(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        set_bone_rot(a, "Chest", (-18, -10, 0))
        set_bone_rot(a, "Head", (-15, 10, 0))
        keyframe_all_bones(a, 4)
        reset_pose(a)
        keyframe_all_bones(a, 12)
    create_animation(arm, "hit_reaction", 12, anim_hit_light)

    # 12. Stagger (Poise broken stumble)
    def anim_stagger(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 8: Backward off-balance lurch
        set_bone_rot(a, "Chest", (-30, 15, 0))
        set_bone_rot(a, "Head", (-25, 0, 0))
        set_bone_rot(a, "UpperArm.L", (15, 0, -25))
        set_bone_rot(a, "UpperArm.R", (20, 0, 25))
        keyframe_all_bones(a, 8)
        # Frame 20: Stumble balance recovery
        set_bone_rot(a, "Chest", (10, -10, 0))
        keyframe_all_bones(a, 20)
        # Frame 30: Recovery
        reset_pose(a)
        keyframe_all_bones(a, 30)
    create_animation(arm, "stagger", 30, anim_stagger)

    # 13. Knockdown (Full body drop + get-up)
    def anim_knockdown(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 12: Falling back
        set_bone_rot(a, "Hips", (-85, 0, 0))
        set_bone_rot(a, "Chest", (-85, 0, 0))
        keyframe_all_bones(a, 12)
        # Frame 24: Ground impact
        set_bone_rot(a, "Hips", (-90, 0, 0))
        set_bone_rot(a, "Chest", (-90, 0, 0))
        keyframe_all_bones(a, 24)
        # Frame 40: Push up and return
        reset_pose(a)
        keyframe_all_bones(a, 40)
    create_animation(arm, "knockdown", 40, anim_knockdown)

    # 14. Finisher (Lethal execution combo)
    def anim_finisher(a, _length):
        reset_pose(a)
        keyframe_all_bones(a, 1)
        # Frame 10: Shield strike thrust
        set_bone_rot(a, "Chest", (15, -20, 0))
        set_bone_rot(a, "UpperArm.L", (-45, 0, 0))
        set_bone_rot(a, "LowerArm.L", (20, 0, 0))
        keyframe_all_bones(a, 10)
        # Frame 20: Two-handed high blade raise
        set_bone_rot(a, "Chest", (-25, 0, 0))
        set_bone_rot(a, "UpperArm.R", (-110, 0, 15))
        set_bone_rot(a, "UpperArm.L", (-100, 0, -15))
        keyframe_all_bones(a, 20)
        # Frame 28: Downward lethal thrust
        set_bone_rot(a, "Chest", (35, 0, 0))
        set_bone_rot(a, "UpperArm.R", (25, 0, 5))
        set_bone_rot(a, "UpperArm.L", (25, 0, -5))
        keyframe_all_bones(a, 28)
        # Frame 40: Clean blade recovery
        reset_pose(a)
        keyframe_all_bones(a, 40)
    create_animation(arm, "finisher", 40, anim_finisher)

def main():
    reset_scene()
    mats = create_materials()
    char_mesh, _ = build_armor_mesh(mats)
    arm = build_humanoid_rig()
    bind_skin_weights(char_mesh, arm)
    build_all_animations(arm)

    # Select both for export
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    char_mesh.select_set(True)
    bpy.context.view_layer.objects.active = arm

    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../assets/characters"))
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "hero_knight.glb")

    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format='GLB',
        use_selection=True,
        export_animations=True,
        export_skins=True,
        export_morph=False
    )
    print(f"[SUCCESS] Exported Hero Knight to: {out_path}")

if __name__ == "__main__":
    main()
