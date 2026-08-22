import bpy
import bmesh
import math
import os

# Blender Python script to author a realistic rigged and animated Medieval Knight for OATHBOUND
# Outputs: assets/characters/knight_character.glb with robust vertex skinning

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, base_color, metallic, roughness):
    mat = bpy.data.materials.new(name=name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Base Color'].default_value = base_color
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    return mat

def create_knight_armature():
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "KnightArmature"
    arm = arm_obj.data
    arm.name = "KnightSkeleton"

    bpy.ops.object.mode_set(mode='EDIT')
    ebs = arm.edit_bones

    root = ebs[0]
    root.name = "Root"
    root.head = (0, 0, 0)
    root.tail = (0, 0, 0.1)

    hips = ebs.new("Hips")
    hips.head = (0, 0, 0.95)
    hips.tail = (0, 0, 1.1)
    hips.parent = root

    spine = ebs.new("Spine")
    spine.head = (0, 0, 1.1)
    spine.tail = (0, 0, 1.3)
    spine.parent = hips

    chest = ebs.new("Chest")
    chest.head = (0, 0, 1.3)
    chest.tail = (0, 0, 1.55)
    chest.parent = spine

    neck = ebs.new("Neck")
    neck.head = (0, 0, 1.55)
    neck.tail = (0, 0, 1.65)
    neck.parent = chest

    head = ebs.new("Head")
    head.head = (0, 0, 1.65)
    head.tail = (0, 0, 1.88)
    head.parent = neck

    # Left Arm
    sh_l = ebs.new("Shoulder.L")
    sh_l.head = (0.08, 0, 1.5)
    sh_l.tail = (0.22, 0, 1.5)
    sh_l.parent = chest

    uarm_l = ebs.new("UpperArm.L")
    uarm_l.head = (0.22, 0, 1.5)
    uarm_l.tail = (0.26, 0, 1.2)
    uarm_l.parent = sh_l

    farm_l = ebs.new("Forearm.L")
    farm_l.head = (0.26, 0, 1.2)
    farm_l.tail = (0.28, 0.15, 0.95)
    farm_l.parent = uarm_l

    hand_l = ebs.new("Hand.L")
    hand_l.head = (0.28, 0.15, 0.95)
    hand_l.tail = (0.30, 0.22, 0.88)
    hand_l.parent = farm_l

    # Right Arm
    sh_r = ebs.new("Shoulder.R")
    sh_r.head = (-0.08, 0, 1.5)
    sh_r.tail = (-0.22, 0, 1.5)
    sh_r.parent = chest

    uarm_r = ebs.new("UpperArm.R")
    uarm_r.head = (-0.22, 0, 1.5)
    uarm_r.tail = (-0.26, 0, 1.2)
    uarm_r.parent = sh_r

    farm_r = ebs.new("Forearm.R")
    farm_r.head = (-0.26, 0, 1.2)
    farm_r.tail = (-0.28, 0.15, 0.95)
    farm_r.parent = uarm_r

    hand_r = ebs.new("Hand.R")
    hand_r.head = (-0.28, 0.15, 0.95)
    hand_r.tail = (-0.30, 0.22, 0.88)
    hand_r.parent = farm_r

    # Left Leg
    uleg_l = ebs.new("UpperLeg.L")
    uleg_l.head = (0.12, 0, 0.95)
    uleg_l.tail = (0.13, 0, 0.52)
    uleg_l.parent = hips

    lleg_l = ebs.new("LowerLeg.L")
    lleg_l.head = (0.13, 0, 0.52)
    lleg_l.tail = (0.14, -0.02, 0.1)
    lleg_l.parent = uleg_l

    foot_l = ebs.new("Foot.L")
    foot_l.head = (0.14, -0.02, 0.1)
    foot_l.tail = (0.14, 0.18, 0.0)
    foot_l.parent = lleg_l

    # Right Leg
    uleg_r = ebs.new("UpperLeg.R")
    uleg_r.head = (-0.12, 0, 0.95)
    uleg_r.tail = (-0.13, 0, 0.52)
    uleg_r.parent = hips

    lleg_r = ebs.new("LowerLeg.R")
    lleg_r.head = (-0.13, 0, 0.52)
    lleg_r.tail = (-0.14, -0.02, 0.1)
    lleg_r.parent = uleg_r

    foot_r = ebs.new("Foot.R")
    foot_r.head = (-0.14, -0.02, 0.1)
    foot_r.tail = (-0.14, 0.18, 0.0)
    foot_r.parent = lleg_r

    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj

def build_knight_mesh(arm_obj):
    steel_mat = create_pbr_material("KnightPlateSteel", (0.75, 0.76, 0.78, 1.0), 0.94, 0.28)
    gold_mat = create_pbr_material("ArmorGoldTrim", (0.88, 0.72, 0.25, 1.0), 0.90, 0.32)
    mail_mat = create_pbr_material("Chainmail", (0.35, 0.36, 0.38, 1.0), 0.85, 0.50)
    cloth_mat = create_pbr_material("HeraldicTabard", (0.65, 0.12, 0.14, 1.0), 0.0, 0.90)

    # 1. Torso / Cuirass
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.35))
    cuirass = bpy.context.active_object
    cuirass.scale = (0.42, 0.28, 0.46)
    bpy.ops.object.transform_apply(scale=True)
    cuirass.data.materials.append(steel_mat)

    # 2. Sallet Visored Helmet & Gorget
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.17, location=(0, 0.02, 1.76))
    helmet = bpy.context.active_object
    helmet.scale = (1.0, 1.2, 1.15)
    bpy.ops.object.transform_apply(scale=True)
    helmet.data.materials.append(steel_mat)

    # Visor Eye Slit
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.16, 1.76))
    visor = bpy.context.active_object
    visor.scale = (0.28, 0.04, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    visor.data.materials.append(gold_mat)

    # 3. Fluted Pauldrons
    for sign, s_name in [(-1, "R"), (1, "L")]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14, location=(sign * 0.28, 0, 1.54))
        p = bpy.context.active_object
        p.scale = (1.1, 1.2, 0.9)
        bpy.ops.object.transform_apply(scale=True)
        p.data.materials.append(steel_mat)

    # 4. Arms & Gauntlets
    for sign, s_name in [(-1, "R"), (1, "L")]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.28, location=(sign * 0.26, 0, 1.36))
        rere = bpy.context.active_object
        rere.data.materials.append(steel_mat)

        bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.26, location=(sign * 0.28, 0.08, 1.08))
        vam = bpy.context.active_object
        vam.data.materials.append(steel_mat)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(sign * 0.30, 0.18, 0.92))
        gaunt = bpy.context.active_object
        gaunt.scale = (0.09, 0.14, 0.08)
        bpy.ops.object.transform_apply(scale=True)
        gaunt.data.materials.append(gold_mat)

    # 5. Skirt
    bpy.ops.mesh.primitive_cylinder_add(radius=0.24, depth=0.32, location=(0, 0, 1.02), vertices=16)
    skirt = bpy.context.active_object
    skirt.data.materials.append(mail_mat)

    # 6. Legs
    for sign, s_name in [(-1, "R"), (1, "L")]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.38, location=(sign * 0.13, 0, 0.74))
        cuisse = bpy.context.active_object
        cuisse.data.materials.append(steel_mat)

        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.09, location=(sign * 0.13, 0.06, 0.52))
        poleyn = bpy.context.active_object
        poleyn.data.materials.append(gold_mat)

        bpy.ops.mesh.primitive_cylinder_add(radius=0.085, depth=0.38, location=(sign * 0.14, -0.01, 0.30))
        greave = bpy.context.active_object
        greave.data.materials.append(steel_mat)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(sign * 0.14, 0.07, 0.06))
        sabaton = bpy.context.active_object
        sabaton.scale = (0.12, 0.28, 0.10)
        bpy.ops.object.transform_apply(scale=True)
        sabaton.data.materials.append(steel_mat)

    # 7. Tabard
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, 0.15, 1.25))
    tabard = bpy.context.active_object
    tabard.scale = (0.32, 1.0, 0.65)
    bpy.ops.object.transform_apply(scale=True)
    tabard.data.materials.append(cloth_mat)

    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            obj.select_set(True)
    bpy.context.view_layer.objects.active = cuirass
    bpy.ops.object.join()
    knight_mesh = cuirass
    knight_mesh.name = "Knight_Body"

    # Direct vertex skinning by geometry position
    bone_names = [
        "Root", "Hips", "Spine", "Chest", "Neck", "Head",
        "Shoulder.L", "UpperArm.L", "Forearm.L", "Hand.L",
        "Shoulder.R", "UpperArm.R", "Forearm.R", "Hand.R",
        "UpperLeg.L", "LowerLeg.L", "Foot.L",
        "UpperLeg.R", "LowerLeg.R", "Foot.R"
    ]
    for bname in bone_names:
        knight_mesh.vertex_groups.new(name=bname)

    # Assign vertex weights
    for v in knight_mesh.data.vertices:
        x, y, z = v.co.x, v.co.y, v.co.z
        if z >= 1.62:
            knight_mesh.vertex_groups["Head"].add([v.index], 1.0, 'REPLACE')
        elif z >= 1.52:
            knight_mesh.vertex_groups["Neck"].add([v.index], 1.0, 'REPLACE')
        elif z >= 1.22:
            if x > 0.20:
                if z >= 1.45:
                    knight_mesh.vertex_groups["Shoulder.L"].add([v.index], 1.0, 'REPLACE')
                elif z >= 1.22:
                    knight_mesh.vertex_groups["UpperArm.L"].add([v.index], 1.0, 'REPLACE')
            elif x < -0.20:
                if z >= 1.45:
                    knight_mesh.vertex_groups["Shoulder.R"].add([v.index], 1.0, 'REPLACE')
                elif z >= 1.22:
                    knight_mesh.vertex_groups["UpperArm.R"].add([v.index], 1.0, 'REPLACE')
            else:
                knight_mesh.vertex_groups["Chest"].add([v.index], 1.0, 'REPLACE')
        elif z >= 0.98:
            if x > 0.20:
                if z >= 1.02:
                    knight_mesh.vertex_groups["Forearm.L"].add([v.index], 1.0, 'REPLACE')
                else:
                    knight_mesh.vertex_groups["Hand.L"].add([v.index], 1.0, 'REPLACE')
            elif x < -0.20:
                if z >= 1.02:
                    knight_mesh.vertex_groups["Forearm.R"].add([v.index], 1.0, 'REPLACE')
                else:
                    knight_mesh.vertex_groups["Hand.R"].add([v.index], 1.0, 'REPLACE')
            else:
                knight_mesh.vertex_groups["Spine"].add([v.index], 0.6, 'REPLACE')
                knight_mesh.vertex_groups["Hips"].add([v.index], 0.4, 'REPLACE')
        elif z >= 0.85:
            if x > 0.20:
                knight_mesh.vertex_groups["Hand.L"].add([v.index], 1.0, 'REPLACE')
            elif x < -0.20:
                knight_mesh.vertex_groups["Hand.R"].add([v.index], 1.0, 'REPLACE')
            else:
                knight_mesh.vertex_groups["Hips"].add([v.index], 1.0, 'REPLACE')
        elif z >= 0.50:
            if x >= 0:
                knight_mesh.vertex_groups["UpperLeg.L"].add([v.index], 1.0, 'REPLACE')
            else:
                knight_mesh.vertex_groups["UpperLeg.R"].add([v.index], 1.0, 'REPLACE')
        elif z >= 0.12:
            if x >= 0:
                knight_mesh.vertex_groups["LowerLeg.L"].add([v.index], 1.0, 'REPLACE')
            else:
                knight_mesh.vertex_groups["LowerLeg.R"].add([v.index], 1.0, 'REPLACE')
        else:
            if x >= 0:
                knight_mesh.vertex_groups["Foot.L"].add([v.index], 1.0, 'REPLACE')
            else:
                knight_mesh.vertex_groups["Foot.R"].add([v.index], 1.0, 'REPLACE')

    # Add Armature Modifier
    mod = knight_mesh.modifiers.new(name="Armature", type='ARMATURE')
    mod.object = arm_obj
    mod.use_vertex_groups = True

    knight_mesh.parent = arm_obj
    return knight_mesh

def create_action(arm_obj, name):
    action = bpy.data.actions.new(name=name)
    if not arm_obj.animation_data:
        arm_obj.animation_data_create()
    arm_obj.animation_data.action = action
    return action

def generate_animations(arm_obj):
    bpy.ops.object.select_all(action='DESELECT')
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    pbones = arm_obj.pose.bones

    # Ensure all bones use XYZ Euler rotation mode for clean glTF export
    for pb in pbones:
        pb.rotation_mode = 'XYZ'

    # 1. Idle (60 frames)
    act_idle = create_action(arm_obj, "idle")
    for f, z_off, spine_pitch in [(1, 0, 0), (30, -0.02, math.radians(2)), (60, 0, 0)]:
        pbones["Hips"].location = (0, 0, z_off)
        pbones["Hips"].keyframe_insert(data_path="location", frame=f)
        pbones["Chest"].rotation_euler = (spine_pitch, 0, 0)
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 2. Walk (40 frames cycle)
    act_walk = create_action(arm_obj, "walk")
    for f, l_rot, r_rot, hips_y in [
        (1, math.radians(25), math.radians(-25), 0),
        (10, 0, 0, 0.03),
        (20, math.radians(-25), math.radians(25), 0),
        (30, 0, 0, 0.03),
        (40, math.radians(25), math.radians(-25), 0)
    ]:
        pbones["UpperLeg.L"].rotation_euler = (l_rot, 0, 0)
        pbones["UpperLeg.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperLeg.R"].rotation_euler = (r_rot, 0, 0)
        pbones["UpperLeg.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperArm.L"].rotation_euler = (-l_rot * 0.8, 0, 0)
        pbones["UpperArm.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperArm.R"].rotation_euler = (-r_rot * 0.8, 0, 0)
        pbones["UpperArm.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Hips"].location = (0, 0, hips_y)
        pbones["Hips"].keyframe_insert(data_path="location", frame=f)

    # 3. Run (24 frames cycle)
    act_run = create_action(arm_obj, "run")
    for f, l_rot, r_rot in [
        (1, math.radians(45), math.radians(-45)),
        (6, 0, 0),
        (12, math.radians(-45), math.radians(45)),
        (18, 0, 0),
        (24, math.radians(45), math.radians(-45))
    ]:
        pbones["UpperLeg.L"].rotation_euler = (l_rot, 0, 0)
        pbones["UpperLeg.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperLeg.R"].rotation_euler = (r_rot, 0, 0)
        pbones["UpperLeg.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperArm.L"].rotation_euler = (-l_rot, 0, 0)
        pbones["UpperArm.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperArm.R"].rotation_euler = (-r_rot, 0, 0)
        pbones["UpperArm.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Chest"].rotation_euler = (math.radians(12), 0, 0)
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 4. Sprint (18 frames cycle)
    act_sprint = create_action(arm_obj, "sprint")
    for f, l_rot, r_rot in [
        (1, math.radians(60), math.radians(-60)),
        (5, 0, 0),
        (9, math.radians(-60), math.radians(60)),
        (14, 0, 0),
        (18, math.radians(60), math.radians(-60))
    ]:
        pbones["UpperLeg.L"].rotation_euler = (l_rot, 0, 0)
        pbones["UpperLeg.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperLeg.R"].rotation_euler = (r_rot, 0, 0)
        pbones["UpperLeg.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperArm.L"].rotation_euler = (-l_rot * 1.1, 0, 0)
        pbones["UpperArm.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperArm.R"].rotation_euler = (-r_rot * 1.1, 0, 0)
        pbones["UpperArm.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Chest"].rotation_euler = (math.radians(22), 0, 0)
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 5. Light Attack (28 frames)
    act_l_atk = create_action(arm_obj, "light_attack")
    for f, r_arm_rot, chest_yaw in [
        (1, (0, 0, 0), 0),
        (8, (math.radians(-20), math.radians(40), math.radians(30)), math.radians(-25)),
        (13, (math.radians(45), math.radians(-35), math.radians(-40)), math.radians(35)),
        (18, (math.radians(30), math.radians(-20), math.radians(-20)), math.radians(20)),
        (28, (0, 0, 0), 0)
    ]:
        pbones["UpperArm.R"].rotation_euler = r_arm_rot
        pbones["UpperArm.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Chest"].rotation_euler = (0, 0, chest_yaw)
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 6. Heavy Attack (42 frames)
    act_h_atk = create_action(arm_obj, "heavy_attack")
    for f, arm_pitch, spine_pitch in [
        (1, 0, 0),
        (14, math.radians(-85), math.radians(-18)),
        (20, math.radians(60), math.radians(32)),
        (26, math.radians(40), math.radians(20)),
        (42, 0, 0)
    ]:
        pbones["UpperArm.R"].rotation_euler = (arm_pitch, 0, math.radians(-10))
        pbones["UpperArm.R"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["UpperArm.L"].rotation_euler = (arm_pitch * 0.7, 0, math.radians(10))
        pbones["UpperArm.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Chest"].rotation_euler = (spine_pitch, 0, 0)
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 7. Block (20 frames)
    act_block = create_action(arm_obj, "block")
    for f in [1, 20]:
        pbones["UpperArm.L"].rotation_euler = (math.radians(-30), math.radians(20), math.radians(-45))
        pbones["UpperArm.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Forearm.L"].rotation_euler = (0, 0, math.radians(60))
        pbones["Forearm.L"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Chest"].rotation_euler = (math.radians(6), 0, math.radians(-12))
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 8. Parry (16 frames)
    act_parry = create_action(arm_obj, "parry")
    for f, arm_rot in [
        (1, (math.radians(-30), 0, math.radians(-45))),
        (5, (math.radians(20), math.radians(-25), math.radians(-10))),
        (16, (math.radians(-30), 0, math.radians(-45)))
    ]:
        pbones["UpperArm.L"].rotation_euler = arm_rot
        pbones["UpperArm.L"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 9. Dodge (24 frames)
    act_dodge = create_action(arm_obj, "dodge")
    for f, pitch, z_loc in [
        (1, 0, 0),
        (6, math.radians(80), -0.4),
        (12, math.radians(180), -0.55),
        (18, math.radians(270), -0.3),
        (24, math.radians(360), 0)
    ]:
        pbones["Hips"].rotation_euler = (pitch, 0, 0)
        pbones["Hips"].keyframe_insert(data_path="rotation_euler", frame=f)
        pbones["Hips"].location = (0, 0, z_loc)
        pbones["Hips"].keyframe_insert(data_path="location", frame=f)

    # 10. Hit Reaction (14 frames)
    act_hit = create_action(arm_obj, "hit_reaction")
    for f, chest_pitch in [(1, 0), (4, math.radians(-22)), (14, 0)]:
        pbones["Chest"].rotation_euler = (chest_pitch, 0, 0)
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 11. Stagger (24 frames)
    act_stagger = create_action(arm_obj, "stagger")
    for f, hips_y, pitch in [(1, 0, 0), (8, -0.3, math.radians(-35)), (16, -0.15, math.radians(-10)), (24, 0, 0)]:
        pbones["Hips"].location = (0, hips_y, 0)
        pbones["Hips"].keyframe_insert(data_path="location", frame=f)
        pbones["Chest"].rotation_euler = (pitch, 0, 0)
        pbones["Chest"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 12. Knockdown (40 frames)
    act_kd = create_action(arm_obj, "knockdown")
    for f, hips_z, hips_pitch in [
        (1, 0, 0),
        (12, -0.85, math.radians(-85)),
        (25, -0.85, math.radians(-85)),
        (40, 0, 0)
    ]:
        pbones["Hips"].location = (0, 0, hips_z)
        pbones["Hips"].keyframe_insert(data_path="location", frame=f)
        pbones["Hips"].rotation_euler = (hips_pitch, 0, 0)
        pbones["Hips"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 13. Death (30 frames)
    act_death = create_action(arm_obj, "death")
    for f, hips_z, hips_pitch in [
        (1, 0, 0),
        (15, -0.4, math.radians(40)),
        (30, -0.88, math.radians(88))
    ]:
        pbones["Hips"].location = (0, 0, hips_z)
        pbones["Hips"].keyframe_insert(data_path="location", frame=f)
        pbones["Hips"].rotation_euler = (hips_pitch, 0, 0)
        pbones["Hips"].keyframe_insert(data_path="rotation_euler", frame=f)

    # 14. Finisher (45 frames)
    act_finisher = create_action(arm_obj, "finisher")
    for f, arm_pitch, arm_yaw in [
        (1, 0, 0),
        (12, math.radians(-45), math.radians(-30)),
        (20, math.radians(80), math.radians(15)),
        (32, math.radians(60), math.radians(-10)),
        (45, 0, 0)
    ]:
        pbones["UpperArm.R"].rotation_euler = (arm_pitch, 0, arm_yaw)
        pbones["UpperArm.R"].keyframe_insert(data_path="rotation_euler", frame=f)

    bpy.ops.object.mode_set(mode='OBJECT')

if __name__ == "__main__":
    clear_scene()
    arm_obj = create_knight_armature()
    build_knight_mesh(arm_obj)
    generate_animations(arm_obj)

    out_path = os.path.abspath("assets/characters/knight_character.glb")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format='GLB',
        export_animations=True,
        export_skins=True,
        export_all_influences=True,
        use_selection=False
    )
    print(f"[Blender] Successfully exported fully-skinned & animated Knight -> {out_path}")
