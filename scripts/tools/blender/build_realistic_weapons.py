import bpy
import bmesh
import math
import os

# Blender Python script to author realistic medieval weapons for OATHBOUND
# Output formats: glTF 2.0 Binary (.glb)

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, base_color, metallic, roughness, normal_tint=None):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    output.location = (400, 0)

    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)
    bsdf.inputs['Base Color'].default_value = base_color
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness

    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    return mat

def build_longsword(output_path):
    clear_scene()

    steel_mat = create_pbr_material("SteelBlade", (0.75, 0.76, 0.78, 1.0), 0.95, 0.28)
    brass_mat = create_pbr_material("BrassGuard", (0.85, 0.68, 0.32, 1.0), 0.88, 0.35)
    leather_mat = create_pbr_material("GripLeather", (0.22, 0.14, 0.08, 1.0), 0.0, 0.72)

    # 1. Blade (Double-edged with fuller)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.65))
    blade = bpy.context.active_object
    blade.name = "Longsword_Blade"
    blade.scale = (0.055, 0.012, 0.9)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    bm = bmesh.new()
    bm.from_mesh(blade.data)
    # Taper top vertices into a point
    for v in bm.verts:
        if v.co.z > 1.0:
            v.co.x *= 0.15
            v.co.y *= 0.15
            v.co.z += 0.12
        elif v.co.z > 0.2:
            # Subtle blade taper
            factor = 1.0 - (v.co.z - 0.2) * 0.15
            v.co.x *= factor
    bm.to_mesh(blade.data)
    bm.free()

    blade.data.materials.append(steel_mat)

    # 2. Crossguard (Quillons)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.022, depth=0.28, location=(0, 0, 0.18))
    guard = bpy.context.active_object
    guard.name = "Longsword_Crossguard"
    guard.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    guard.data.materials.append(brass_mat)

    # 3. Grip (Leather-wrapped handle)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.22, location=(0, 0, 0.06))
    grip = bpy.context.active_object
    grip.name = "Longsword_Grip"
    grip.data.materials.append(leather_mat)

    # 4. Pommel (Weighted scent-stopper / octagonal)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.034, location=(0, 0, -0.07))
    pommel = bpy.context.active_object
    pommel.name = "Longsword_Pommel"
    pommel.scale = (1.0, 0.8, 1.2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    pommel.data.materials.append(brass_mat)

    # Join all objects
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [blade, guard, grip, pommel]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = blade
    bpy.ops.object.join()
    blade.name = "Longsword"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', use_selection=False)
    print(f"[Blender] Exported realistic Longsword -> {output_path}")

def build_kite_shield(output_path):
    clear_scene()

    steel_mat = create_pbr_material("ShieldSteel", (0.65, 0.66, 0.68, 1.0), 0.9, 0.32)
    wood_mat = create_pbr_material("ShieldWood", (0.35, 0.22, 0.12, 1.0), 0.0, 0.85)
    heraldry_mat = create_pbr_material("ShieldHeraldry", (0.68, 0.12, 0.14, 1.0), 0.1, 0.55)
    leather_mat = create_pbr_material("ShieldLeather", (0.2, 0.12, 0.06, 1.0), 0.0, 0.8)

    # 1. Shield Body (Curved Heater / Kite shape)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    shield = bpy.context.active_object
    shield.name = "KiteShield_Body"
    shield.scale = (0.32, 0.03, 0.48)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    bm = bmesh.new()
    bm.from_mesh(shield.data)
    # Shape the kite shield curvature and lower point
    for v in bm.verts:
        # Lower point
        if v.co.z < -0.1:
            t = (-v.co.z - 0.1) / 0.38
            v.co.x *= (1.0 - t * 0.85)
        # Curve front outwards (convex)
        curve = (1.0 - (v.co.x / 0.32)**2) * 0.05
        if v.co.y > 0:
            v.co.y += curve
        else:
            v.co.y += curve * 0.8
    bm.to_mesh(shield.data)
    bm.free()
    shield.data.materials.append(heraldry_mat)

    # 2. Steel Rim
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.01, 0))
    rim = bpy.context.active_object
    rim.name = "KiteShield_Rim"
    rim.scale = (0.33, 0.035, 0.49)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    rim.data.materials.append(steel_mat)

    # 3. Central Steel Boss (Umbo)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.06, location=(0, 0.06, 0.08))
    boss = bpy.context.active_object
    boss.name = "KiteShield_Boss"
    boss.scale = (1.0, 0.4, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    boss.data.materials.append(steel_mat)

    # 4. Leather Straps (Back)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.015, depth=0.22, location=(0, -0.035, 0.05))
    strap = bpy.context.active_object
    strap.name = "KiteShield_Strap"
    strap.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    strap.data.materials.append(leather_mat)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in [shield, boss, strap]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = shield
    bpy.ops.object.join()
    shield.name = "KiteShield"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', use_selection=False)
    print(f"[Blender] Exported realistic Kite Shield -> {output_path}")

def build_great_axe(output_path):
    clear_scene()

    iron_mat = create_pbr_material("ForgedIron", (0.28, 0.29, 0.31, 1.0), 0.92, 0.42)
    edge_mat = create_pbr_material("SharpenedSteel", (0.8, 0.82, 0.84, 1.0), 0.98, 0.22)
    wood_mat = create_pbr_material("AshWoodHaft", (0.42, 0.28, 0.16, 1.0), 0.0, 0.78)
    leather_mat = create_pbr_material("GripWrap", (0.18, 0.11, 0.06, 1.0), 0.0, 0.82)

    # 1. Long Wood Haft (1.4m two-handed)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.024, depth=1.4, location=(0, 0, 0.5))
    haft = bpy.context.active_object
    haft.name = "GreatAxe_Haft"
    haft.data.materials.append(wood_mat)

    # 2. Leather Hand Grips (lower & upper)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.027, depth=0.35, location=(0, 0, 0.2))
    grip1 = bpy.context.active_object
    grip1.name = "GreatAxe_Grip1"
    grip1.data.materials.append(leather_mat)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.027, depth=0.3, location=(0, 0, 0.75))
    grip2 = bpy.context.active_object
    grip2.name = "GreatAxe_Grip2"
    grip2.data.materials.append(leather_mat)

    # 3. Double-Bearded Iron Axe Head
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.14, 0, 1.08))
    blade_fwd = bpy.context.active_object
    blade_fwd.name = "GreatAxe_MainBlade"
    blade_fwd.scale = (0.22, 0.025, 0.28)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    bm = bmesh.new()
    bm.from_mesh(blade_fwd.data)
    for v in bm.verts:
        # Fan out cutting edge
        if v.co.x > 0.22:
            v.co.y *= 0.15 # razor edge
            v.co.z *= 1.45 # wide crescent curve
    bm.to_mesh(blade_fwd.data)
    bm.free()
    blade_fwd.data.materials.append(edge_mat)

    # 4. Rear Spike / Hook
    bpy.ops.mesh.primitive_cone_add(radius1=0.04, radius2=0.005, depth=0.22, location=(-0.14, 0, 1.08))
    spike = bpy.context.active_object
    spike.name = "GreatAxe_RearSpike"
    spike.rotation_euler = (0, math.radians(-90), 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    spike.data.materials.append(iron_mat)

    # 5. Top Spear Tip
    bpy.ops.mesh.primitive_cone_add(radius1=0.025, radius2=0.002, depth=0.2, location=(0, 0, 1.3))
    top_spike = bpy.context.active_object
    top_spike.name = "GreatAxe_TopSpike"
    top_spike.data.materials.append(edge_mat)

    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [haft, grip1, grip2, blade_fwd, spike, top_spike]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = haft
    bpy.ops.object.join()
    haft.name = "GreatAxe"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', use_selection=False)
    print(f"[Blender] Exported realistic Great Axe -> {output_path}")

def build_dagger(output_path):
    clear_scene()

    steel_mat = create_pbr_material("DaggerSteel", (0.82, 0.83, 0.85, 1.0), 0.96, 0.24)
    dark_iron = create_pbr_material("DarkHilt", (0.18, 0.18, 0.2, 1.0), 0.85, 0.45)
    cord_mat = create_pbr_material("CordWrap", (0.12, 0.1, 0.08, 1.0), 0.0, 0.88)

    # Blade (Curved / piercing)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.26))
    blade = bpy.context.active_object
    blade.name = "Dagger_Blade"
    blade.scale = (0.032, 0.008, 0.32)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    bm = bmesh.new()
    bm.from_mesh(blade.data)
    for v in bm.verts:
        if v.co.z > 0.35:
            v.co.x *= 0.1
            v.co.y *= 0.1
            v.co.z += 0.05
    bm.to_mesh(blade.data)
    bm.free()
    blade.data.materials.append(steel_mat)

    # Small Crossguard
    bpy.ops.mesh.primitive_cylinder_add(radius=0.014, depth=0.12, location=(0, 0, 0.1))
    guard = bpy.context.active_object
    guard.name = "Dagger_Guard"
    guard.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    guard.data.materials.append(dark_iron)

    # Grip
    bpy.ops.mesh.primitive_cylinder_add(radius=0.013, depth=0.14, location=(0, 0, 0.02))
    grip = bpy.context.active_object
    grip.name = "Dagger_Grip"
    grip.data.materials.append(cord_mat)

    # Ring Pommel
    bpy.ops.mesh.primitive_torus_add(major_radius=0.022, minor_radius=0.006, location=(0, 0, -0.06))
    pommel = bpy.context.active_object
    pommel.name = "Dagger_Pommel"
    pommel.data.materials.append(dark_iron)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in [blade, guard, grip, pommel]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = blade
    bpy.ops.object.join()
    blade.name = "Dagger"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', use_selection=False)
    print(f"[Blender] Exported realistic Dagger -> {output_path}")

if __name__ == "__main__":
    base_dir = os.path.abspath("assets/characters/weapons")
    build_longsword(os.path.join(base_dir, "longsword.glb"))
    build_kite_shield(os.path.join(base_dir, "kite_shield.glb"))
    build_great_axe(os.path.join(base_dir, "great_axe.glb"))
    build_dagger(os.path.join(base_dir, "dagger.glb"))
