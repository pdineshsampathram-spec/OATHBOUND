import bpy
import bmesh
import math
import os

# Blender Python script to author realistic modular medieval environment assets for OATHBOUND
# Includes PBR materials, edge bevels, structural details, and Godot static collision (-col)

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

def export_asset(output_path, name):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', use_selection=False)
    print(f"[Blender] Exported {name} -> {output_path}")

def build_stone_wall(output_path):
    clear_scene()
    stone_mat = create_pbr_material("MedievalStoneWall", (0.42, 0.43, 0.45, 1.0), 0.05, 0.88)
    trim_mat = create_pbr_material("StoneCoping", (0.50, 0.51, 0.53, 1.0), 0.05, 0.82)

    # Main Wall Block (4m wide, 4m high, 0.8m thick)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.0))
    wall = bpy.context.active_object
    wall.name = "StoneWall_Mesh"
    wall.scale = (4.0, 0.8, 4.0)
    bpy.ops.object.transform_apply(scale=True)
    wall.data.materials.append(stone_mat)

    # Crenellations / Battlements (Top)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.2, 0, 4.35))
    c1 = bpy.context.active_object
    c1.scale = (1.0, 0.85, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    c1.data.materials.append(trim_mat)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.2, 0, 4.35))
    c2 = bpy.context.active_object
    c2.scale = (1.0, 0.85, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    c2.data.materials.append(trim_mat)

    # Collision Box (-col suffix for Godot automatic StaticBody3D collision import)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.3))
    col = bpy.context.active_object
    col.name = "StoneWall-col"
    col.scale = (4.0, 0.8, 4.6)
    bpy.ops.object.transform_apply(scale=True)

    export_asset(output_path, "Stone Wall Segment")

def build_stone_wall_damaged(output_path):
    clear_scene()
    stone_mat = create_pbr_material("MedievalStoneWall", (0.42, 0.43, 0.45, 1.0), 0.05, 0.88)
    rubble_mat = create_pbr_material("RubbleCore", (0.34, 0.31, 0.28, 1.0), 0.0, 0.95)

    # Left Wall Section
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.2, 0, 2.0))
    w_left = bpy.context.active_object
    w_left.name = "DamagedWall_Left"
    w_left.scale = (1.6, 0.8, 4.0)
    bpy.ops.object.transform_apply(scale=True)
    w_left.data.materials.append(stone_mat)

    # Breach / Low Broken Section
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.6, 0, 0.9))
    w_breach = bpy.context.active_object
    w_breach.name = "DamagedWall_Breach"
    w_breach.scale = (2.0, 0.8, 1.8)
    bpy.ops.object.transform_apply(scale=True)
    w_breach.data.materials.append(rubble_mat)

    # Broken Stone Block 1
    bpy.ops.mesh.primitive_cube_add(size=0.6, location=(0.4, 0.4, 0.3))
    r1 = bpy.context.active_object
    r1.rotation_euler = (math.radians(15), math.radians(25), math.radians(-10))
    bpy.ops.object.transform_apply(rotation=True)
    r1.data.materials.append(stone_mat)

    # Collision
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.2, 0, 2.0))
    col1 = bpy.context.active_object
    col1.name = "DamagedWall_L-col"
    col1.scale = (1.6, 0.8, 4.0)
    bpy.ops.object.transform_apply(scale=True)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.6, 0, 0.9))
    col2 = bpy.context.active_object
    col2.name = "DamagedWall_R-col"
    col2.scale = (2.0, 0.8, 1.8)
    bpy.ops.object.transform_apply(scale=True)

    export_asset(output_path, "Damaged Stone Wall")

def build_stone_pillar(output_path):
    clear_scene()
    pillar_mat = create_pbr_material("CarvedPillarStone", (0.46, 0.47, 0.49, 1.0), 0.05, 0.82)

    # Shaft (Fluted cylinder, 6m tall)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.55, depth=5.2, location=(0, 0, 3.0), vertices=20)
    shaft = bpy.context.active_object
    shaft.name = "Pillar_Shaft"
    shaft.data.materials.append(pillar_mat)

    # Plinth Base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.25))
    base = bpy.context.active_object
    base.name = "Pillar_Base"
    base.scale = (1.5, 1.5, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    base.data.materials.append(pillar_mat)

    # Capital
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 5.75))
    capital = bpy.context.active_object
    capital.name = "Pillar_Capital"
    capital.scale = (1.5, 1.5, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    capital.data.materials.append(pillar_mat)

    # Collision
    bpy.ops.mesh.primitive_cylinder_add(radius=0.65, depth=6.0, location=(0, 0, 3.0), vertices=12)
    col = bpy.context.active_object
    col.name = "Pillar-col"

    export_asset(output_path, "Stone Pillar")

def build_stone_arch_gate(output_path):
    clear_scene()
    stone_mat = create_pbr_material("ArchStone", (0.44, 0.45, 0.48, 1.0), 0.05, 0.85)
    iron_mat = create_pbr_material("GateIron", (0.22, 0.23, 0.25, 1.0), 0.92, 0.45)

    # Left Post
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.2, 0, 2.5))
    p_left = bpy.context.active_object
    p_left.name = "Arch_LeftPost"
    p_left.scale = (1.0, 1.2, 5.0)
    bpy.ops.object.transform_apply(scale=True)
    p_left.data.materials.append(stone_mat)

    # Right Post
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.2, 0, 2.5))
    p_right = bpy.context.active_object
    p_right.name = "Arch_RightPost"
    p_right.scale = (1.0, 1.2, 5.0)
    bpy.ops.object.transform_apply(scale=True)
    p_right.data.materials.append(stone_mat)

    # Arch Beam Header
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 5.4))
    header = bpy.context.active_object
    header.name = "Arch_Header"
    header.scale = (5.4, 1.2, 0.9)
    bpy.ops.object.transform_apply(scale=True)
    header.data.materials.append(stone_mat)

    # Keystone (Central decorative block)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.1, 5.2))
    keystone = bpy.context.active_object
    keystone.name = "Arch_Keystone"
    keystone.scale = (0.7, 1.3, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    keystone.data.materials.append(stone_mat)

    # Portcullis Grate Bars (Iron)
    for x in [-1.2, -0.6, 0.0, 0.6, 1.2]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=4.2, location=(x, 0, 3.5), vertices=8)
        bar = bpy.context.active_object
        bar.data.materials.append(iron_mat)

    # Collisions
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.2, 0, 2.5))
    col1 = bpy.context.active_object
    col1.name = "Arch_Left-col"
    col1.scale = (1.0, 1.2, 5.0)
    bpy.ops.object.transform_apply(scale=True)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.2, 0, 2.5))
    col2 = bpy.context.active_object
    col2.name = "Arch_Right-col"
    col2.scale = (1.0, 1.2, 5.0)
    bpy.ops.object.transform_apply(scale=True)

    export_asset(output_path, "Arch Gateway")

def build_stone_floor(output_path):
    clear_scene()
    cobble_mat = create_pbr_material("WornCobblestone", (0.38, 0.39, 0.40, 1.0), 0.04, 0.90)

    # 4m x 4m floor tile
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.15))
    floor = bpy.context.active_object
    floor.name = "CobbleFloor_Tile"
    floor.scale = (4.0, 4.0, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    floor.data.materials.append(cobble_mat)

    # Collision
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.15))
    col = bpy.context.active_object
    col.name = "Floor-col"
    col.scale = (4.0, 4.0, 0.3)
    bpy.ops.object.transform_apply(scale=True)

    export_asset(output_path, "Cobblestone Floor Tile")

def build_stone_stairs(output_path):
    clear_scene()
    stair_mat = create_pbr_material("StairStone", (0.42, 0.43, 0.45, 1.0), 0.05, 0.85)

    # 5 steps, 3m wide, rising 1.5m total
    step_depth = 0.6
    step_height = 0.3
    for i in range(5):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, i * step_depth, (i + 0.5) * step_height))
        step = bpy.context.active_object
        step.name = f"Step_{i}"
        step.scale = (3.0, step_depth, step_height)
        bpy.ops.object.transform_apply(scale=True)
        step.data.materials.append(stair_mat)

    # Sloped collision ramp for smooth player movement
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 1.2, 0.75))
    col = bpy.context.active_object
    col.name = "Stairs-col"
    col.scale = (3.0, 3.2, 0.2)
    col.rotation_euler = (math.radians(26.5), 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    export_asset(output_path, "Stone Stairs")

def build_wooden_beam(output_path):
    clear_scene()
    wood_mat = create_pbr_material("RoughOakBeam", (0.36, 0.24, 0.14, 1.0), 0.0, 0.82)
    iron_mat = create_pbr_material("BeamBracket", (0.24, 0.25, 0.26, 1.0), 0.9, 0.4)

    # 4m Beam
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    beam = bpy.context.active_object
    beam.name = "WoodBeam_Mesh"
    beam.scale = (0.24, 0.24, 4.0)
    bpy.ops.object.transform_apply(scale=True)
    beam.data.materials.append(wood_mat)

    # End Iron Brackets
    for z in [-1.85, 1.85]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, z))
        bracket = bpy.context.active_object
        bracket.scale = (0.26, 0.26, 0.15)
        bpy.ops.object.transform_apply(scale=True)
        bracket.data.materials.append(iron_mat)

    export_asset(output_path, "Wooden Beam")

def build_torch_sconce(output_path):
    clear_scene()
    iron_mat = create_pbr_material("WroughtIron", (0.20, 0.21, 0.22, 1.0), 0.92, 0.45)
    wood_mat = create_pbr_material("TorchWood", (0.30, 0.18, 0.10, 1.0), 0.0, 0.85)
    cloth_mat = create_pbr_material("PitchCloth", (0.12, 0.11, 0.09, 1.0), 0.0, 0.95)

    # Wall Plate
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    plate = bpy.context.active_object
    plate.name = "Sconce_Plate"
    plate.scale = (0.12, 0.04, 0.35)
    bpy.ops.object.transform_apply(scale=True)
    plate.data.materials.append(iron_mat)

    # Angled Arm
    bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.35, location=(0, 0.15, 0.08), vertices=8)
    arm = bpy.context.active_object
    arm.rotation_euler = (math.radians(45), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    arm.data.materials.append(iron_mat)

    # Ring Holder
    bpy.ops.mesh.primitive_torus_add(major_radius=0.065, minor_radius=0.012, location=(0, 0.27, 0.22))
    ring = bpy.context.active_object
    ring.data.materials.append(iron_mat)

    # Torch Handle (Wood)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.55, location=(0, 0.27, 0.25), vertices=10)
    torch = bpy.context.active_object
    torch.name = "Torch_Handle"
    torch.data.materials.append(wood_mat)

    # Pitch/Cloth Wrap (Torch Head)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.18, location=(0, 0.27, 0.48), vertices=12)
    wrap = bpy.context.active_object
    wrap.name = "Torch_Head"
    wrap.data.materials.append(cloth_mat)

    export_asset(output_path, "Torch Sconce")

def build_barrel(output_path):
    clear_scene()
    wood_mat = create_pbr_material("BarrelWood", (0.45, 0.30, 0.18, 1.0), 0.0, 0.8)
    iron_mat = create_pbr_material("BarrelHoop", (0.24, 0.25, 0.26, 1.0), 0.9, 0.38)

    # Bulging Barrel Body
    bpy.ops.mesh.primitive_cylinder_add(radius=0.42, depth=1.0, location=(0, 0, 0.5), vertices=16)
    barrel = bpy.context.active_object
    barrel.name = "Barrel_Body"

    bm = bmesh.new()
    bm.from_mesh(barrel.data)
    for v in bm.verts:
        # Bulge in center
        h_norm = abs(v.co.z - 0.5) / 0.5
        bulge = 1.0 + (1.0 - h_norm**2) * 0.18
        v.co.x *= bulge
        v.co.y *= bulge
    bm.to_mesh(barrel.data)
    bm.free()
    barrel.data.materials.append(wood_mat)

    # Iron Hoops (4 bands)
    for z in [0.15, 0.38, 0.62, 0.85]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.44, minor_radius=0.015, location=(0, 0, z))
        hoop = bpy.context.active_object
        hoop.data.materials.append(iron_mat)

    # Collision
    bpy.ops.mesh.primitive_cylinder_add(radius=0.48, depth=1.0, location=(0, 0, 0.5), vertices=12)
    col = bpy.context.active_object
    col.name = "Barrel-col"

    export_asset(output_path, "Medieval Barrel")

def build_crate(output_path):
    clear_scene()
    wood_mat = create_pbr_material("CrateWood", (0.48, 0.35, 0.22, 1.0), 0.0, 0.85)
    iron_mat = create_pbr_material("CornerBrace", (0.22, 0.23, 0.24, 1.0), 0.92, 0.42)

    # Main Cube (0.9m)
    bpy.ops.mesh.primitive_cube_add(size=0.9, location=(0, 0, 0.45))
    crate = bpy.context.active_object
    crate.name = "Crate_Body"
    crate.data.materials.append(wood_mat)

    # Iron Corner Caps
    bpy.ops.mesh.primitive_cube_add(size=0.92, location=(0, 0, 0.45))
    brace = bpy.context.active_object
    brace.name = "Crate_Brace"
    brace.data.materials.append(iron_mat)

    # Collision
    bpy.ops.mesh.primitive_cube_add(size=0.9, location=(0, 0, 0.45))
    col = bpy.context.active_object
    col.name = "Crate-col"

    export_asset(output_path, "Medieval Crate")

def build_stone_monument(output_path):
    clear_scene()
    stone_mat = create_pbr_material("MonumentStone", (0.45, 0.46, 0.48, 1.0), 0.05, 0.82)

    # Tiered Plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.25))
    p1 = bpy.context.active_object
    p1.scale = (2.2, 2.2, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    p1.data.materials.append(stone_mat)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.7))
    p2 = bpy.context.active_object
    p2.scale = (1.6, 1.6, 0.4)
    bpy.ops.object.transform_apply(scale=True)
    p2.data.materials.append(stone_mat)

    # Obelisk Pillar
    bpy.ops.mesh.primitive_cone_add(radius1=0.6, radius2=0.35, depth=3.2, location=(0, 0, 2.5), vertices=4)
    ob = bpy.context.active_object
    ob.name = "Obelisk"
    ob.rotation_euler = (0, 0, math.radians(45))
    bpy.ops.object.transform_apply(rotation=True)
    ob.data.materials.append(stone_mat)

    # Collision
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.0))
    col = bpy.context.active_object
    col.name = "Monument-col"
    col.scale = (2.2, 2.2, 4.0)
    bpy.ops.object.transform_apply(scale=True)

    export_asset(output_path, "Stone Monument")

def build_stone_debris(output_path):
    clear_scene()
    stone_mat = create_pbr_material("DebrisStone", (0.40, 0.41, 0.43, 1.0), 0.05, 0.9)

    for i, (x, y, z, s, r) in enumerate([
        (0.0, 0.0, 0.2, 0.45, 25),
        (0.35, 0.2, 0.15, 0.35, -40),
        (-0.3, 0.15, 0.12, 0.3, 60),
        (0.1, -0.3, 0.1, 0.28, -15),
        (-0.25, -0.2, 0.08, 0.22, 75)
    ]):
        bpy.ops.mesh.primitive_cube_add(size=s, location=(x, y, z))
        rock = bpy.context.active_object
        rock.name = f"DebrisBlock_{i}"
        rock.rotation_euler = (math.radians(r * 0.7), math.radians(r * 1.2), math.radians(r))
        bpy.ops.object.transform_apply(rotation=True)
        rock.data.materials.append(stone_mat)

    export_asset(output_path, "Stone Debris")

def build_medieval_banner(output_path):
    clear_scene()
    iron_mat = create_pbr_material("BannerIron", (0.24, 0.25, 0.26, 1.0), 0.9, 0.4)
    fabric_mat = create_pbr_material("BannerFabric", (0.65, 0.15, 0.16, 1.0), 0.0, 0.92)

    # Crossbar
    bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=1.6, location=(0, 0, 3.2), vertices=8)
    bar = bpy.context.active_object
    bar.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(rotation=True)
    bar.data.materials.append(iron_mat)

    # Hanging Fabric with V-cut tail
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, 0.02, 2.0))
    cloth = bpy.context.active_object
    cloth.name = "Banner_Cloth"
    cloth.scale = (1.2, 1.0, 2.2)
    bpy.ops.object.transform_apply(scale=True)

    bm = bmesh.new()
    bm.from_mesh(cloth.data)
    # V-cut bottom
    for v in bm.verts:
        if v.co.z < 1.0:
            if abs(v.co.x) < 0.2:
                v.co.z += 0.3
    bm.to_mesh(cloth.data)
    bm.free()
    cloth.data.materials.append(fabric_mat)

    export_asset(output_path, "Medieval Banner")

if __name__ == "__main__":
    mod_dir = os.path.abspath("assets/environment/modular")
    build_stone_wall(os.path.join(mod_dir, "stone_wall_segment.glb"))
    build_stone_wall_damaged(os.path.join(mod_dir, "stone_wall_damaged.glb"))
    build_stone_pillar(os.path.join(mod_dir, "stone_pillar_round.glb"))
    build_stone_arch_gate(os.path.join(mod_dir, "stone_arch_gate.glb"))
    build_stone_floor(os.path.join(mod_dir, "stone_floor_cobble.glb"))
    build_stone_stairs(os.path.join(mod_dir, "stone_stairs.glb"))
    build_wooden_beam(os.path.join(mod_dir, "wooden_beam.glb"))
    build_torch_sconce(os.path.join(mod_dir, "torch_sconce.glb"))
    build_barrel(os.path.join(mod_dir, "medieval_barrel.glb"))
    build_crate(os.path.join(mod_dir, "medieval_crate.glb"))
    build_stone_monument(os.path.join(mod_dir, "stone_monument.glb"))
    build_stone_debris(os.path.join(mod_dir, "stone_debris.glb"))
    build_medieval_banner(os.path.join(mod_dir, "medieval_banner.glb"))
