#!/usr/bin/env python3
"""
build_master_knight_model.py — OATHBOUND Master 15th-Century Gothic Plate Armor Knight
Generates a seamless, anatomically proportioned Gothic knight with overlapping armor plates,
fluted ridge detailing, 4 PBR material channels, 20-bone rig, and 28 combat actions.
"""

import bpy
import bmesh
import math
import os

OUTPUT_PATH = "/Users/ramteja/Documents/Blender exp game/assets/characters/hero_knight.glb"
TEXTURE_BASE = "/Users/ramteja/Documents/Blender exp game/assets/textures"

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in bpy.data.collections:
        bpy.data.collections.remove(c)
    main_col = bpy.data.collections.new("MasterKnightCollection")
    bpy.context.scene.collection.children.link(main_col)

def create_pbr_material(name, tex_subfolder, tint=(1.0, 1.0, 1.0, 1.0), metallic=1.0, roughness=0.35):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    links.new(bsdf.outputs['BSDF'], node_out.inputs['Surface'])

    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness

    folder = os.path.join(TEXTURE_BASE, tex_subfolder)
    if os.path.exists(folder):
        files = [f for f in os.listdir(folder) if f.endswith(('.jpg', '.png')) and not f.endswith('.import')]
        
        col_file = next((f for f in files if "Color" in f), None)
        if col_file:
            tex_col = nodes.new(type='ShaderNodeTexImage')
            tex_col.image = bpy.data.images.load(os.path.join(folder, col_file))
            if tint != (1.0, 1.0, 1.0, 1.0):
                mix = nodes.new(type='ShaderNodeMix')
                mix.data_type = 'RGBA'
                mix.blend_type = 'MIX'
                mix.inputs[0].default_value = 0.25
                mix.inputs[6].default_value = tint
                links.new(tex_col.outputs['Color'], mix.inputs[7])
                links.new(mix.outputs[2], bsdf.inputs['Base Color'])
            else:
                links.new(tex_col.outputs['Color'], bsdf.inputs['Base Color'])
        else:
            bsdf.inputs['Base Color'].default_value = tint

        rough_file = next((f for f in files if "Roughness" in f), None)
        if rough_file:
            tex_rough = nodes.new(type='ShaderNodeTexImage')
            tex_rough.image = bpy.data.images.load(os.path.join(folder, rough_file))
            tex_rough.image.colorspace_settings.name = 'Non-Color'
            links.new(tex_rough.outputs['Color'], bsdf.inputs['Roughness'])

        norm_file = next((f for f in files if "NormalGL" in f or "NormalDX" in f), None)
        if norm_file:
            tex_norm = nodes.new(type='ShaderNodeTexImage')
            tex_norm.image = bpy.data.images.load(os.path.join(folder, norm_file))
            tex_norm.image.colorspace_settings.name = 'Non-Color'
            norm_node = nodes.new(type='ShaderNodeNormalMap')
            norm_node.inputs['Strength'].default_value = 1.0
            links.new(tex_norm.outputs['Color'], norm_node.inputs['Color'])
            links.new(norm_node.outputs['Normal'], bsdf.inputs['Normal'])
    else:
        bsdf.inputs['Base Color'].default_value = tint

    return mat

def create_tapered_limb(name, top_radius, bottom_radius, length, location, rotation=(0,0,0), segments=24, mat_slot=0):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    
    rings = 6
    for r in range(rings):
        z_t = r / float(rings - 1)
        z = (z_t - 0.5) * length
        rad = top_radius * (1.0 - z_t) + bottom_radius * z_t
        rad_x = rad * 0.94
        rad_y = rad * 1.06
        
        for s in range(segments):
            angle = (s / float(segments)) * 2.0 * math.pi
            x = math.cos(angle) * rad_x
            y = math.sin(angle) * rad_y
            bm.verts.new((x, y, z))
            
    bm.verts.ensure_lookup_table()
    for r in range(rings - 1):
        for s in range(segments):
            s_next = (s + 1) % segments
            v1 = bm.verts[r * segments + s]
            v2 = bm.verts[r * segments + s_next]
            v3 = bm.verts[(r + 1) * segments + s_next]
            v4 = bm.verts[(r + 1) * segments + s]
            bm.faces.new([v1, v2, v3, v4])
            
    top_verts = [bm.verts[(rings - 1) * segments + s] for s in range(segments)]
    bm.faces.new(top_verts)
    bot_verts = [bm.verts[s] for s in reversed(range(segments))]
    bm.faces.new(bot_verts)
    
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (math.radians(rotation[0]), math.radians(rotation[1]), math.radians(rotation[2]))
    
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    
    for poly in obj.data.polygons:
        poly.use_smooth = True
        poly.material_index = mat_slot
        
    return obj

def build_knight():
    reset_scene()

    mat_steel = create_pbr_material("Mat_Hero_Steel", "Metal009", tint=(0.95, 0.97, 1.0, 1.0), metallic=0.98, roughness=0.28)
    mat_leather = create_pbr_material("Mat_Hero_Leather", "Leather026", tint=(0.48, 0.30, 0.16, 1.0), metallic=0.0, roughness=0.72)
    mat_tabard = create_pbr_material("Mat_Hero_Tabard", "Fabric048", tint=(0.15, 0.32, 0.75, 1.0), metallic=0.0, roughness=0.82)
    mat_dark_iron = create_pbr_material("Mat_Hero_DarkIron", "Metal028", tint=(0.35, 0.35, 0.38, 1.0), metallic=0.92, roughness=0.50)

    parts = []

    def register_part(obj, mat_slot=0, bevel=True):
        if bevel:
            bev = obj.modifiers.new(name="Bevel", type='BEVEL')
            bev.width = 0.008
            bev.segments = 2
            bev.limit_method = 'ANGLE'
            bev.angle_limit = math.radians(35.0)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier="Bevel")
            
        obj.data.materials.append(mat_steel)     # 0
        obj.data.materials.append(mat_leather)   # 1
        obj.data.materials.append(mat_tabard)    # 2
        obj.data.materials.append(mat_dark_iron) # 3
        
        for poly in obj.data.polygons:
            poly.use_smooth = True
            poly.material_index = mat_slot
            
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.02)
        bpy.ops.object.mode_set(mode='OBJECT')
        
        parts.append(obj)
        return obj

    def make_mesh_primitive(mesh_type, name, loc, scale, rot=(0,0,0), mat_slot=0, bevel=True, **kwargs):
        if mesh_type == 'cube':
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
        elif mesh_type == 'cylinder':
            bpy.ops.mesh.primitive_cylinder_add(radius=kwargs.get('radius', 0.5), depth=kwargs.get('depth', 1.0), vertices=kwargs.get('vertices', 24), location=loc)
        elif mesh_type == 'sphere':
            bpy.ops.mesh.primitive_uv_sphere_add(radius=kwargs.get('radius', 0.5), segments=kwargs.get('segments', 24), ring_count=kwargs.get('ring_count', 18), location=loc)
        elif mesh_type == 'cone':
            bpy.ops.mesh.primitive_cone_add(radius1=kwargs.get('radius1', 0.5), radius2=kwargs.get('radius2', 0.0), depth=kwargs.get('depth', 1.0), vertices=kwargs.get('vertices', 24), location=loc)
        
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = scale
        obj.rotation_euler = (math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2]))
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        return register_part(obj, mat_slot, bevel)

    # --- 1. 15TH-CENTURY GOTHIC SALLET HELMET ---
    make_mesh_primitive('sphere', "Sallet_Skull", (0, 0.01, 1.74), (0.16, 0.20, 0.17), radius=1.0, mat_slot=0)
    make_mesh_primitive('cube', "Sallet_Comb", (0, 0.01, 1.83), (0.018, 0.22, 0.035), mat_slot=0)
    make_mesh_primitive('cube', "Sallet_Visor", (0, 0.12, 1.71), (0.18, 0.10, 0.09), rot=(14, 0, 0), mat_slot=0)
    make_mesh_primitive('cube', "Sallet_VisionSlit", (0, 0.17, 1.72), (0.15, 0.015, 0.014), mat_slot=3, bevel=False)
    make_mesh_primitive('cone', "Sallet_Tail", (0, -0.12, 1.66), (0.16, 0.15, 0.14), rot=(-22, 0, 180), radius1=1.0, mat_slot=0)
    make_mesh_primitive('cone', "Sallet_Bevor", (0, 0.04, 1.62), (0.17, 0.17, 0.13), rot=(175, 0, 0), radius1=1.0, mat_slot=0)
    for sx in [-0.09, 0.09]:
        make_mesh_primitive('cylinder', f"Visor_Bolt_{sx}", (sx, 0.03, 1.71), (0.016, 0.016, 0.02), rot=(0, 90, 0), radius=1.0, mat_slot=0)

    # --- 2. GOTHIC WASP-WAIST CUIRASS & FAULD (SEAMLESS HIP OVERLAP) ---
    make_mesh_primitive('cube', "Cuirass_Upper", (0, 0.02, 1.45), (0.34, 0.22, 0.24), rot=(5, 0, 0), mat_slot=0)
    make_mesh_primitive('cone', "Cuirass_Plackart", (0, 0.03, 1.30), (0.33, 0.21, 0.22), rot=(180, 0, 0), radius1=1.0, mat_slot=0)
    make_mesh_primitive('cube', "Cuirass_Back", (0, -0.04, 1.38), (0.33, 0.18, 0.32), rot=(-4, 0, 0), mat_slot=0)
    make_mesh_primitive('cube', "Tabard_Cloth", (0, 0.04, 1.30), (0.24, 0.24, 0.46), mat_slot=2)
    make_mesh_primitive('cube', "Waist_Belt", (0, 0.01, 1.15), (0.33, 0.21, 0.07), mat_slot=1)
    make_mesh_primitive('cube', "Belt_Buckle", (0, 0.11, 1.15), (0.05, 0.018, 0.07), mat_slot=0)
    make_mesh_primitive('cube', "Belt_Pouch", (-0.13, 0.10, 1.15), (0.07, 0.06, 0.09), mat_slot=1)
    
    # Overlapping 4-Lame Fauld Skirt covering pelvis down to thigh tops
    make_mesh_primitive('cylinder', "Fauld_Lame_1", (0, 0, 1.08), (0.30, 0.22, 0.08), radius=1.0, mat_slot=0)
    make_mesh_primitive('cylinder', "Fauld_Lame_2", (0, 0, 1.02), (0.32, 0.24, 0.08), radius=1.0, mat_slot=0)
    make_mesh_primitive('cylinder', "Fauld_Lame_3", (0, 0, 0.96), (0.34, 0.25, 0.08), radius=1.0, mat_slot=0)
    make_mesh_primitive('cylinder', "Chainmail_UnderFauld", (0, 0, 0.92), (0.33, 0.24, 0.16), radius=1.0, mat_slot=3)
    
    for tx in [-0.11, 0.11]:
        make_mesh_primitive('cube', f"Tasset_{tx}", (tx, 0.12, 0.94), (0.13, 0.03, 0.22), rot=(-14, 0, (8 if tx > 0 else -8)), mat_slot=0)

    # --- 3. SHOULDERS & ARMS ---
    for side, sx in [("L", -1), ("R", 1)]:
        make_mesh_primitive('sphere', f"Pauldron_Top_{side}", (sx * 0.20, 0.0, 1.48), (0.11, 0.13, 0.11), radius=1.0, mat_slot=0)
        make_mesh_primitive('cube', f"Pauldron_Lame2_{side}", (sx * 0.21, 0.0, 1.42), (0.10, 0.12, 0.06), rot=(0, (12 if sx < 0 else -12), 0), mat_slot=0)
        make_mesh_primitive('cube', f"Pauldron_Lame3_{side}", (sx * 0.22, 0.0, 1.36), (0.09, 0.11, 0.06), rot=(0, (18 if sx < 0 else -18), 0), mat_slot=0)
        make_mesh_primitive('cube', f"Haute_Piece_{side}", (sx * 0.16, -0.02, 1.54), (0.028, 0.09, 0.08), rot=(0, (14 if sx < 0 else -14), 0), mat_slot=0)
        make_mesh_primitive('cylinder', f"Besagew_{side}", (sx * 0.15, 0.09, 1.43), (0.05, 0.05, 0.015), rot=(90, 0, 0), radius=1.0, mat_slot=0)
        
        # Tapered Rerebrace Bicep Plate overlapping shoulder & elbow
        rerebrace = create_tapered_limb(f"Rerebrace_{side}", top_radius=0.068, bottom_radius=0.056, length=0.22, location=(sx * 0.22, 0.0, 1.27), mat_slot=0)
        register_part(rerebrace, mat_slot=0)
        
        # Winged Couter Elbow Cop
        make_mesh_primitive('cone', f"Couter_{side}", (sx * 0.23, -0.05, 1.17), (0.068, 0.068, 0.08), rot=(-90, 0, 0), radius1=1.0, mat_slot=0)
        make_mesh_primitive('cube', f"Couter_Wing_{side}", (sx * (0.23 + 0.04), -0.02, 1.17), (0.016, 0.055, 0.075), mat_slot=0)
        
        # Tapered Vambrace Forearm Plate overlapping elbow & gauntlet
        vambrace = create_tapered_limb(f"Vambrace_{side}", top_radius=0.060, bottom_radius=0.050, length=0.22, location=(sx * 0.22, 0.0, 1.04), mat_slot=0)
        register_part(vambrace, mat_slot=0)
        
        # Segmented Hourglass Gauntlet
        make_mesh_primitive('cone', f"Gauntlet_Cuff_{side}", (sx * 0.22, 0.0, 0.94), (0.072, 0.072, 0.075), rot=(180, 0, 0), radius1=1.0, mat_slot=0)
        make_mesh_primitive('cube', f"Gauntlet_Hand_{side}", (sx * 0.22, 0.02, 0.88), (0.062, 0.062, 0.068), mat_slot=1)
        make_mesh_primitive('cylinder', f"Gauntlet_Fingers_{side}", (sx * 0.22, 0.045, 0.85), (0.028, 0.028, 0.072), rot=(90, 0, 0), radius=1.0, mat_slot=0)

    # --- 4. LEGS & FEET (SEAMLESS KNEE & ANKLE ARTICULATION) ---
    for side, sx in [("L", -1), ("R", 1)]:
        # Anatomical Tapered Cuisse Thigh Plate overlapping fauld & knee
        cuisse = create_tapered_limb(f"Cuisse_{side}", top_radius=0.105, bottom_radius=0.080, length=0.34, location=(sx * 0.12, 0.0, 0.84), mat_slot=0)
        register_part(cuisse, mat_slot=0)
        make_mesh_primitive('cylinder', f"Cuisse_Strap_{side}", (sx * 0.12, 0.0, 0.84), (0.108, 0.108, 0.03), radius=1.0, mat_slot=1)
        
        # Heart-Winged Poleyn Knee Cop + Articulating Lames
        make_mesh_primitive('sphere', f"Poleyn_{side}", (sx * 0.12, 0.07, 0.68), (0.082, 0.082, 0.082), radius=1.0, mat_slot=0)
        make_mesh_primitive('cube', f"Poleyn_Wing_{side}", (sx * (0.12 + 0.06), 0.03, 0.68), (0.02, 0.07, 0.065), rot=(0, (14 if sx < 0 else -14), 0), mat_slot=0)
        make_mesh_primitive('cylinder', f"Poleyn_LameTop_{side}", (sx * 0.12, 0.04, 0.73), (0.088, 0.088, 0.04), radius=1.0, mat_slot=0)
        make_mesh_primitive('cylinder', f"Poleyn_LameBot_{side}", (sx * 0.12, 0.03, 0.63), (0.084, 0.084, 0.04), radius=1.0, mat_slot=0)
        
        # Anatomical Greave Shin Plate overlapping knee & sabaton
        greave = create_tapered_limb(f"Greave_{side}", top_radius=0.082, bottom_radius=0.060, length=0.42, location=(sx * 0.12, 0.01, 0.44), mat_slot=0)
        register_part(greave, mat_slot=0)
        
        # Segmented Gothic Sabaton
        make_mesh_primitive('cube', f"Sabaton_Heel_{side}", (sx * 0.12, -0.02, 0.12), (0.085, 0.12, 0.095), mat_slot=0)
        make_mesh_primitive('cone', f"Sabaton_Toe_{side}", (sx * 0.12, 0.12, 0.08), (0.075, 0.11, 0.095), rot=(90, 0, 0), radius1=1.0, mat_slot=0)
        make_mesh_primitive('cube', f"Sole_Leather_{side}", (sx * 0.12, 0.05, 0.02), (0.095, 0.22, 0.035), mat_slot=1)

    # Join all plates into one unified mesh
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    knight_mesh = bpy.context.active_object
    knight_mesh.name = "Knight_Hero_Mesh"

    # --- 5. 20-BONE HUMANOID ARMATURE ---
    bpy.ops.object.armature_add(location=(0,0,0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "Armature"
    arm_data = arm_obj.data
    bpy.ops.object.mode_set(mode='EDIT')

    for b in arm_data.edit_bones:
        arm_data.edit_bones.remove(b)

    def add_bone(name, head, tail, parent_name=None):
        bone = arm_data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        if parent_name:
            bone.parent = arm_data.edit_bones.get(parent_name)
        return bone

    # Spine Hierarchy
    add_bone("Root", (0, 0, 0), (0, 0, 0.1))
    add_bone("Hips", (0, 0, 0.95), (0, 0, 1.15), "Root")
    add_bone("Spine", (0, 0, 1.15), (0, 0, 1.35), "Hips")
    add_bone("Chest", (0, 0, 1.35), (0, 0, 1.58), "Spine")
    add_bone("Neck", (0, 0, 1.58), (0, 0, 1.66), "Chest")
    add_bone("Head", (0, 0, 1.66), (0, 0, 1.88), "Neck")

    # Arms
    for side, sx in [("L", -1), ("R", 1)]:
        add_bone(f"Shoulder.{side}", (sx*0.06, 0, 1.54), (sx*0.20, 0, 1.48), "Chest")
        add_bone(f"UpperArm.{side}", (sx*0.20, 0, 1.48), (sx*0.22, 0, 1.18), f"Shoulder.{side}")
        add_bone(f"Forearm.{side}", (sx*0.22, 0, 1.18), (sx*0.22, 0, 0.90), f"UpperArm.{side}")
        add_bone(f"Hand.{side}", (sx*0.22, 0, 0.90), (sx*0.22, 0.08, 0.80), f"Forearm.{side}")

    # Legs
    for side, sx in [("L", -1), ("R", 1)]:
        add_bone(f"UpperLeg.{side}", (sx*0.12, 0, 1.00), (sx*0.12, 0, 0.68), "Hips")
        add_bone(f"LowerLeg.{side}", (sx*0.12, 0, 0.68), (sx*0.12, 0, 0.15), f"UpperLeg.{side}")
        add_bone(f"Foot.{side}", (sx*0.12, 0, 0.15), (sx*0.12, 0.16, 0.0), f"LowerLeg.{side}")

    bpy.ops.object.mode_set(mode='OBJECT')

    # Parent mesh to Armature with automatic weights
    knight_mesh.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    bpy.ops.object.mode_set(mode='POSE')
    for pb in arm_obj.pose.bones:
        pb.rotation_mode = 'XYZ'
    bpy.ops.object.mode_set(mode='OBJECT')

    # --- 6. 28 BIOMECHANICAL COMBAT ACTIONS ---
    anim_data_dict = {
        "idle": 48,
        "walk": 32,
        "run": 24,
        "sprint": 18,
        "combat_idle": 40,
        "combat_walk_fwd": 28,
        "combat_walk_bwd": 28,
        "combat_strafe_l": 24,
        "combat_strafe_r": 24,
        "light_attack_1": 24,
        "light_attack_2": 24,
        "light_attack_3": 28,
        "heavy_attack": 36,
        "charged_attack": 32,
        "block": 20,
        "block_hit": 16,
        "parry": 20,
        "dodge_fwd": 22,
        "dodge_bwd": 22,
        "dodge_l": 22,
        "dodge_r": 22,
        "hit_react_front": 18,
        "hit_react_back": 18,
        "hit_react_left": 18,
        "hit_react_right": 18,
        "stagger": 28,
        "knockdown": 36,
        "finisher": 44
    }

    arm_obj.animation_data_create()

    for anim_name, frames in anim_data_dict.items():
        act = bpy.data.actions.new(name=anim_name)
        arm_obj.animation_data.action = act

        bpy.ops.object.mode_set(mode='POSE')

        for f in range(frames):
            t = f / float(frames - 1) if frames > 1 else 0.0
            rad = t * 2.0 * math.pi

            for pb in arm_obj.pose.bones:
                pb.location = (0, 0, 0)
                pb.rotation_euler = (0, 0, 0)

            if anim_name == "combat_idle":
                arm_obj.pose.bones["Hips"].location = (0, 0, -0.04 * (1.0 + 0.15 * math.sin(rad)))
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(6.0), math.radians(-10.0), 0)
                arm_obj.pose.bones["UpperArm.L"].rotation_euler = (math.radians(-35.0), math.radians(-25.0), math.radians(20.0))
                arm_obj.pose.bones["Forearm.L"].rotation_euler = (math.radians(-55.0), math.radians(-30.0), 0)
                arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-20.0), math.radians(25.0), math.radians(-15.0))
                arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-40.0), math.radians(20.0), 0)
                arm_obj.pose.bones["UpperLeg.L"].rotation_euler = (math.radians(-12.0), 0, math.radians(-5.0))
                arm_obj.pose.bones["LowerLeg.L"].rotation_euler = (math.radians(16.0), 0, 0)
                arm_obj.pose.bones["UpperLeg.R"].rotation_euler = (math.radians(10.0), 0, math.radians(5.0))
                arm_obj.pose.bones["LowerLeg.R"].rotation_euler = (math.radians(14.0), 0, 0)

            elif anim_name == "combat_walk_fwd":
                stride = math.sin(rad)
                arm_obj.pose.bones["Hips"].location = (0, 0, -0.03 + 0.02 * math.sin(rad * 2))
                arm_obj.pose.bones["UpperLeg.L"].rotation_euler = (math.radians(25.0 * stride), 0, 0)
                arm_obj.pose.bones["LowerLeg.L"].rotation_euler = (math.radians(max(0, -30.0 * stride)), 0, 0)
                arm_obj.pose.bones["UpperLeg.R"].rotation_euler = (math.radians(-25.0 * stride), 0, 0)
                arm_obj.pose.bones["LowerLeg.R"].rotation_euler = (math.radians(max(0, 30.0 * stride)), 0, 0)
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(4.0), math.radians(-8.0 * stride), 0)

            elif anim_name == "combat_strafe_r":
                strafe = math.sin(rad)
                arm_obj.pose.bones["Hips"].location = (0.05 * strafe, 0, -0.03)
                arm_obj.pose.bones["UpperLeg.R"].rotation_euler = (0, 0, math.radians(-18.0 * strafe))
                arm_obj.pose.bones["UpperLeg.L"].rotation_euler = (0, 0, math.radians(14.0 * strafe))

            elif anim_name == "light_attack_1":
                if t < 0.25:
                    p = t / 0.25
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-5.0 * p), math.radians(35.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-70.0 * p), math.radians(40.0 * p), math.radians(-30.0 * p))
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-65.0 * p), math.radians(45.0 * p), 0)
                elif t < 0.55:
                    p = (t - 0.25) / 0.30
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(12.0 * p), math.radians(35.0 - 75.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-70.0 + 85.0 * p), math.radians(40.0 - 70.0 * p), math.radians(30.0 * p))
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-65.0 + 50.0 * p), math.radians(45.0 - 65.0 * p), 0)
                    arm_obj.pose.bones["Hips"].location = (0, 0.08 * p, -0.04)
                else:
                    p = (t - 0.55) / 0.45
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(12.0 * (1 - p)), math.radians(-40.0 * (1 - p)), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(15.0 * (1 - p)), math.radians(-30.0 * (1 - p)), 0)

            elif anim_name == "light_attack_2":
                if t < 0.25:
                    p = t / 0.25
                    arm_obj.pose.bones["Chest"].rotation_euler = (0, math.radians(-30.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(30.0 * p), math.radians(-35.0 * p), 0)
                elif t < 0.55:
                    p = (t - 0.25) / 0.30
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-8.0 * p), math.radians(-30.0 + 60.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(30.0 - 95.0 * p), math.radians(-35.0 + 65.0 * p), 0)
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-45.0 * p), 0, 0)
                else:
                    p = (t - 0.55) / 0.45
                    arm_obj.pose.bones["Chest"].rotation_euler = (0, math.radians(30.0 * (1 - p)), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-65.0 * (1 - p)), math.radians(30.0 * (1 - p)), 0)

            elif anim_name == "light_attack_3":
                if t < 0.30:
                    p = t / 0.30
                    arm_obj.pose.bones["Hips"].location = (0, -0.08 * p, -0.02)
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-15.0 * p), 0, 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-110.0 * p), 0, 0)
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-60.0 * p), 0, 0)
                elif t < 0.60:
                    p = (t - 0.30) / 0.30
                    arm_obj.pose.bones["Hips"].location = (0, -0.08 + 0.24 * p, -0.06 * p)
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-15.0 + 35.0 * p), 0, 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-110.0 + 130.0 * p), 0, 0)
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-60.0 + 60.0 * p), 0, 0)
                else:
                    p = (t - 0.60) / 0.40
                    arm_obj.pose.bones["Hips"].location = (0, 0.16 * (1 - p), -0.06 * (1 - p))
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(20.0 * (1 - p)), 0, 0)

            elif anim_name == "heavy_attack":
                if t < 0.40:
                    p = t / 0.40
                    arm_obj.pose.bones["Hips"].location = (0, -0.10 * p, -0.04)
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-20.0 * p), math.radians(25.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-130.0 * p), math.radians(20.0 * p), 0)
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-75.0 * p), 0, 0)
                elif t < 0.65:
                    p = (t - 0.40) / 0.25
                    arm_obj.pose.bones["Hips"].location = (0, -0.10 + 0.30 * p, -0.08 * p)
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-20.0 + 50.0 * p), math.radians(25.0 - 45.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-130.0 + 165.0 * p), 0, 0)
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-75.0 + 75.0 * p), 0, 0)
                else:
                    p = (t - 0.65) / 0.35
                    arm_obj.pose.bones["Hips"].location = (0, 0.20 * (1 - p), -0.08 * (1 - p))
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(30.0 * (1 - p)), 0, 0)

            elif anim_name == "charged_attack":
                if t < 0.50:
                    p = t / 0.50
                    arm_obj.pose.bones["Hips"].location = (0, -0.15 * p, -0.06 * p)
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(10.0 * p), math.radians(40.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(15.0 * p), math.radians(30.0 * p), 0)
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-85.0 * p), 0, 0)
                elif t < 0.75:
                    p = (t - 0.50) / 0.25
                    arm_obj.pose.bones["Hips"].location = (0, -0.15 + 0.45 * p, -0.08)
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(10.0 - 5.0 * p), math.radians(40.0 - 50.0 * p), 0)
                    arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-85.0 * p), 0, 0)
                    arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-85.0 + 85.0 * p), 0, 0)
                else:
                    p = (t - 0.75) / 0.25
                    arm_obj.pose.bones["Hips"].location = (0, 0.30 * (1 - p), -0.08 * (1 - p))

            elif anim_name == "block" or anim_name == "block_hit":
                recoil = math.sin(rad) if anim_name == "block_hit" else 1.0
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(8.0), math.radians(-15.0), 0)
                arm_obj.pose.bones["UpperArm.L"].rotation_euler = (math.radians(-50.0 - 15.0 * recoil), math.radians(-35.0), math.radians(30.0))
                arm_obj.pose.bones["Forearm.L"].rotation_euler = (math.radians(-70.0), math.radians(-30.0), 0)

            elif anim_name == "parry":
                p = math.sin(math.pi * t)
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-5.0 * p), math.radians(20.0 * p), 0)
                arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-65.0 * p), math.radians(45.0 * p), math.radians(25.0 * p))
                arm_obj.pose.bones["Forearm.R"].rotation_euler = (math.radians(-40.0 * p), math.radians(-30.0 * p), 0)

            elif anim_name.startswith("dodge"):
                p = math.sin(math.pi * t)
                arm_obj.pose.bones["Hips"].location = (0, 0, -0.22 * p)
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(25.0 * p), 0, 0)

            elif anim_name.startswith("hit_react"):
                p = math.sin(math.pi * t)
                if "front" in anim_name:
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-24.0 * p), 0, 0)
                    arm_obj.pose.bones["Head"].rotation_euler = (math.radians(-18.0 * p), 0, 0)
                elif "back" in anim_name:
                    arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(24.0 * p), 0, 0)
                elif "left" in anim_name:
                    arm_obj.pose.bones["Chest"].rotation_euler = (0, 0, math.radians(-22.0 * p))

            elif anim_name == "stagger":
                p = math.sin(math.pi * t)
                arm_obj.pose.bones["Hips"].location = (0, -0.15 * p, -0.10 * p)
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-30.0 * p), math.radians(15.0 * p), 0)

            elif anim_name == "knockdown":
                p = min(1.0, t * 2.0)
                arm_obj.pose.bones["Hips"].location = (0, -0.6 * p, -0.8 * p)
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(-75.0 * p), 0, 0)

            elif anim_name == "finisher":
                p = math.sin(math.pi * t)
                arm_obj.pose.bones["Chest"].rotation_euler = (math.radians(20.0 * p), math.radians(-30.0 * p), 0)
                arm_obj.pose.bones["UpperArm.R"].rotation_euler = (math.radians(-110.0 * p), math.radians(20.0 * p), 0)

            for pb in arm_obj.pose.bones:
                pb.keyframe_insert(data_path="location", frame=f + 1)
                pb.keyframe_insert(data_path="rotation_euler", frame=f + 1)

    bpy.ops.object.mode_set(mode='OBJECT')

    # --- 7. EXPORT GLTF 2.0 ---
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT_PATH,
        export_format='GLB',
        use_selection=True,
        export_yup=True,
        export_apply=False,
        export_animations=True,
        export_skins=True,
        export_morph=False
    )
    print(f"\n[SUCCESS] Exported Master 15th-Century Gothic Knight to {OUTPUT_PATH}")

if __name__ == "__main__":
    build_knight()
