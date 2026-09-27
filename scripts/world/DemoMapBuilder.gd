extends Node3D
class_name DemoMapBuilder

# Adapted for this project from the MIT-licensed procedural valley/open-world approach
# in https://github.com/flips100/realistic-open-world. No external binary assets are used.

const COMPUTER_SCENE := "res://scenes/equipment/MainComputer.tscn"
const COORDINATE_SCENE := "res://scenes/equipment/CoordinatePanel.tscn"
const DETECTOR_SCENE := "res://scenes/equipment/Detector.tscn"
const BREAKER_SCENE := "res://scenes/equipment/BreakerPanel.tscn"
const BED_SCENE := "res://scenes/equipment/Bed.tscn"
const RADIO_SCENE := "res://scenes/equipment/Radio.tscn"
const DISH_SCENE := "res://scenes/equipment/Dish.tscn"

const TERRAIN_SIZE := 420.0
const TERRAIN_RESOLUTION := 86
const WATER_LEVEL := -1.8
const BASE_CLEAR_RADIUS := 34.0

var height_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var ridge_noise: FastNoiseLite
var material_cache: Dictionary = {}

func _ready() -> void:
    _setup_noise()
    _setup_lighting()
    _build_terrain()
    _build_lake()
    _build_observatory_compound()
    _build_service_road()
    _build_satellite_array()
    _build_radio_tower()
    _build_cabin_area()
    _build_forest_and_rocks()
    _place_equipment()

func _setup_noise() -> void:
    height_noise = FastNoiseLite.new()
    height_noise.seed = 42042
    height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH as FastNoiseLite.NoiseType
    height_noise.frequency = 0.008
    height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM as FastNoiseLite.FractalType
    height_noise.fractal_octaves = 5
    height_noise.fractal_gain = 0.48

    detail_noise = FastNoiseLite.new()
    detail_noise.seed = 42059
    detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX as FastNoiseLite.NoiseType
    detail_noise.frequency = 0.035
    detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM as FastNoiseLite.FractalType
    detail_noise.fractal_octaves = 3

    ridge_noise = FastNoiseLite.new()
    ridge_noise.seed = 42071
    ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH as FastNoiseLite.NoiseType
    ridge_noise.frequency = 0.012
    ridge_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED as FastNoiseLite.FractalType
    ridge_noise.fractal_octaves = 4

func _setup_lighting() -> void:
    var sun := DirectionalLight3D.new()
    sun.name = "ValleySun"
    sun.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
    sun.light_color = Color(1.0, 0.92, 0.76)
    sun.light_energy = 2.35
    sun.shadow_enabled = true
    add_child(sun)

    var fill := DirectionalLight3D.new()
    fill.name = "ColdSkyFill"
    fill.rotation_degrees = Vector3(-18.0, -140.0, 0.0)
    fill.light_color = Color(0.55, 0.66, 0.85)
    fill.light_energy = 0.45
    fill.shadow_enabled = false
    add_child(fill)

    var base_light := OmniLight3D.new()
    base_light.name = "BaseWarmExteriorLight"
    base_light.position = Vector3(0.0, 7.0, 10.0)
    base_light.light_color = Color(1.0, 0.82, 0.55)
    base_light.light_energy = 4.0
    base_light.omni_range = 28.0
    add_child(base_light)

func _mat(id: String, color: Color, roughness: float = 0.85, metallic: float = 0.0) -> Material:
    if material_cache.has(id):
        return material_cache[id]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    material_cache[id] = material
    return material

func get_height_at(world_x: float, world_z: float) -> float:
    var base := height_noise.get_noise_2d(world_x, world_z) * 18.0
    var detail := detail_noise.get_noise_2d(world_x, world_z) * 2.2
    var ridge := absf(ridge_noise.get_noise_2d(world_x, world_z)) * 10.0
    var edge_x := world_x / (TERRAIN_SIZE * 0.5)
    var edge_z := world_z / (TERRAIN_SIZE * 0.5)
    var edge := clampf(edge_x * edge_x + edge_z * edge_z - 0.42, 0.0, 1.0)
    var mountains := edge * edge * 46.0
    var lake_dist := Vector2(world_x - 52.0, world_z + 34.0).length()
    var lake_basin := exp(-(lake_dist * lake_dist) / (58.0 * 58.0)) * 8.0
    var base_dist := Vector2(world_x, world_z).length()
    var base_flatten := clampf(1.0 - base_dist / BASE_CLEAR_RADIUS, 0.0, 1.0)
    var natural_height := base + detail + ridge + mountains - lake_basin
    return lerpf(natural_height, 0.0, base_flatten * base_flatten)

func _terrain_color(world_x: float, world_z: float, height: float) -> Color:
    var dx := get_height_at(world_x + 1.0, world_z) - get_height_at(world_x - 1.0, world_z)
    var dz := get_height_at(world_x, world_z + 1.0) - get_height_at(world_x, world_z - 1.0)
    var slope := sqrt(dx * dx + dz * dz)
    var grass := Color(0.25, 0.36, 0.20)
    var dirt := Color(0.34, 0.27, 0.18)
    var rock := Color(0.36, 0.37, 0.35)
    var snow := Color(0.72, 0.74, 0.76)
    var color := grass
    if height < WATER_LEVEL + 3.0:
        color = dirt
    elif slope > 5.5 or height > 28.0:
        color = rock.lerp(snow, clampf((height - 34.0) / 20.0, 0.0, 1.0))
    else:
        color = grass.lerp(dirt, clampf(slope / 7.0, 0.0, 0.65))
    var shade := 0.92 + detail_noise.get_noise_2d(world_x * 1.7, world_z * 1.7) * 0.08
    return Color(color.r * shade, color.g * shade, color.b * shade, 1.0)

func _build_terrain() -> void:
    var surface_tool := SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES as Mesh.PrimitiveType)
    var half := TERRAIN_SIZE * 0.5
    var step := TERRAIN_SIZE / float(TERRAIN_RESOLUTION)
    for z in range(TERRAIN_RESOLUTION):
        for x in range(TERRAIN_RESOLUTION):
            var x0 := -half + float(x) * step
            var z0 := -half + float(z) * step
            var x1 := x0 + step
            var z1 := z0 + step
            var a := Vector3(x0, get_height_at(x0, z0), z0)
            var b := Vector3(x1, get_height_at(x1, z0), z0)
            var c := Vector3(x1, get_height_at(x1, z1), z1)
            var d := Vector3(x0, get_height_at(x0, z1), z1)
            _add_terrain_tri(surface_tool, a, b, c)
            _add_terrain_tri(surface_tool, a, c, d)
    surface_tool.generate_normals()
    var mesh := surface_tool.commit()
    var body := StaticBody3D.new()
    body.name = "ReadyMITValleyTerrain"
    body.collision_layer = 1
    body.collision_mask = 1
    add_child(body)

    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "TerrainMesh"
    mesh_instance.mesh = mesh
    var terrain_material := _mat("terrain_material", Color(0.30, 0.34, 0.24), 0.92)
    if terrain_material is StandardMaterial3D:
        var standard_material := terrain_material as StandardMaterial3D
        standard_material.vertex_color_use_as_albedo = true
    mesh_instance.material_override = terrain_material
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(mesh.get_faces())
    collision.shape = shape
    body.add_child(collision)

func _add_terrain_tri(surface_tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    surface_tool.set_color(_terrain_color(a.x, a.z, a.y))
    surface_tool.set_uv(Vector2(a.x, a.z) * 0.02)
    surface_tool.add_vertex(a)
    surface_tool.set_color(_terrain_color(b.x, b.z, b.y))
    surface_tool.set_uv(Vector2(b.x, b.z) * 0.02)
    surface_tool.add_vertex(b)
    surface_tool.set_color(_terrain_color(c.x, c.z, c.y))
    surface_tool.set_uv(Vector2(c.x, c.z) * 0.02)
    surface_tool.add_vertex(c)

func _build_lake() -> void:
    var water_body := StaticBody3D.new()
    water_body.name = "LakeSurface"
    water_body.position = Vector3(52.0, WATER_LEVEL + 0.05, -34.0)
    add_child(water_body)

    var mesh_instance := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(82.0, 64.0)
    mesh_instance.mesh = plane
    var water_mat := StandardMaterial3D.new()
    water_mat.albedo_color = Color(0.08, 0.18, 0.22, 1.0)
    water_mat.roughness = 0.2
    mesh_instance.material_override = water_mat
    water_body.add_child(mesh_instance)

func _static_box(node_name: String, world_pos: Vector3, size_value: Vector3, color: Color, collision_layer_value: int = 1) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = world_pos
    body.collision_layer = collision_layer_value
    body.collision_mask = 1
    add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size_value
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _mat(node_name + "_mat", color)
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size_value
    collision.shape = shape
    body.add_child(collision)
    return body

func _build_observatory_compound() -> void:
    var concrete := Color(0.42, 0.43, 0.41)
    var wall := Color(0.50, 0.51, 0.49)
    var trim := Color(0.25, 0.26, 0.26)
    var warm := Color(0.45, 0.37, 0.26)

    _static_box("ObservatoryPad", Vector3(0.0, 0.12, 0.0), Vector3(46.0, 0.22, 34.0), concrete)
    _static_box("MainBuildingFloor", Vector3(0.0, 0.32, 0.0), Vector3(31.0, 0.24, 22.0), Color(0.38, 0.39, 0.38))

    _static_box("BuildingBackWall", Vector3(0.0, 2.05, -11.0), Vector3(31.0, 3.7, 0.55), wall)
    _static_box("BuildingLeftWall", Vector3(-15.5, 2.05, 0.0), Vector3(0.55, 3.7, 22.0), wall)
    _static_box("BuildingRightWall", Vector3(15.5, 2.05, 0.0), Vector3(0.55, 3.7, 22.0), wall)
    _static_box("BuildingFrontLeft", Vector3(-10.0, 2.05, 11.0), Vector3(11.0, 3.7, 0.55), wall)
    _static_box("BuildingFrontRight", Vector3(10.0, 2.05, 11.0), Vector3(11.0, 3.7, 0.55), wall)
    _static_box("EntranceTop", Vector3(0.0, 3.75, 11.0), Vector3(8.0, 0.55, 0.65), trim)
    _static_box("RoofSlab", Vector3(0.0, 4.12, 0.0), Vector3(32.0, 0.35, 23.0), Color(0.28, 0.29, 0.29))

    _static_box("SignalLabDivider", Vector3(-5.0, 1.8, -1.0), Vector3(0.38, 2.8, 16.5), wall)
    _static_box("StorageDivider", Vector3(6.0, 1.8, 4.0), Vector3(0.38, 2.8, 12.0), wall)
    _static_box("StorageBackDivider", Vector3(10.5, 1.8, -2.3), Vector3(9.0, 2.8, 0.38), wall)

    _static_box("ComputerDesk", Vector3(-10.3, 1.02, -7.4), Vector3(7.8, 1.1, 2.1), warm)
    _static_box("CoordinateDesk", Vector3(0.0, 1.02, -7.4), Vector3(8.6, 1.1, 2.1), Color(0.25, 0.26, 0.25))
    _static_box("DetectorDesk", Vector3(9.7, 1.02, -7.4), Vector3(5.8, 1.1, 2.1), Color(0.25, 0.26, 0.26))
    _static_box("StorageShelfA", Vector3(12.8, 1.35, 3.3), Vector3(1.7, 2.3, 5.4), Color(0.27, 0.21, 0.16))
    _static_box("StorageShelfB", Vector3(8.5, 1.35, 9.0), Vector3(5.5, 2.3, 1.2), Color(0.27, 0.21, 0.16))
    _static_box("BedBase", Vector3(-10.2, 0.72, 6.6), Vector3(4.8, 0.78, 2.5), Color(0.18, 0.19, 0.22))
    _static_box("BedMattress", Vector3(-10.2, 1.22, 6.6), Vector3(4.4, 0.34, 2.2), Color(0.60, 0.62, 0.60))

    for i in range(5):
        _static_box("TapeCrate%d" % i, Vector3(9.0 + float(i % 2) * 2.1, 0.78 + (float(i) / 2.0) * 0.7, 5.8 + float(i % 3) * 1.1), Vector3(1.2, 0.65, 0.9), Color(0.20, 0.23, 0.22))

    _add_omni("LabLightA", Vector3(-9.5, 3.45, -4.0), Color(0.86, 0.94, 1.0), 5.2, 10.0)
    _add_omni("LabLightB", Vector3(3.5, 3.45, -4.0), Color(0.86, 0.94, 1.0), 5.2, 10.0)
    _add_omni("LivingWarmLight", Vector3(-10.0, 3.0, 6.0), Color(1.0, 0.76, 0.48), 3.3, 8.0)

func _add_omni(node_name: String, world_pos: Vector3, light_color: Color, energy: float, range_value: float) -> OmniLight3D:
    var light := OmniLight3D.new()
    light.name = node_name
    light.position = world_pos
    light.light_color = light_color
    light.light_energy = energy
    light.omni_range = range_value
    add_child(light)
    return light

func _build_service_road() -> void:
    _static_box("SouthRoad", Vector3(0.0, 0.22, 54.0), Vector3(8.0, 0.18, 94.0), Color(0.23, 0.23, 0.21))
    _static_box("WestServiceRoad", Vector3(-52.0, 0.18, 17.0), Vector3(72.0, 0.16, 7.0), Color(0.24, 0.24, 0.22))
    for i in range(8):
        _static_box("RoadMarker%d" % i, Vector3(0.0, 0.35, 18.0 + float(i) * 10.0), Vector3(0.25, 0.08, 3.0), Color(0.75, 0.68, 0.38))

func _build_satellite_array() -> void:
    var positions := [Vector3(-46.0, 0.7, -44.0), Vector3(-12.0, 0.7, -58.0), Vector3(34.0, 0.7, -40.0)]
    for i in range(positions.size()):
        var p: Vector3 = positions[i]
        _static_box("DishPad%d" % i, Vector3(p.x, 0.22, p.z), Vector3(9.0, 0.25, 9.0), Color(0.40, 0.40, 0.38))
        _static_box("DishMast%d" % i, Vector3(p.x, 2.5, p.z), Vector3(0.62, 4.7, 0.62), Color(0.39, 0.40, 0.39))
        var face := _static_box("DishFace%d" % i, Vector3(p.x, 5.0, p.z - 1.45), Vector3(6.2, 3.6, 0.35), Color(0.62, 0.64, 0.62))
        face.rotation_degrees.x = -20.0
        _static_box("DishCounterweight%d" % i, Vector3(p.x, 3.1, p.z + 1.4), Vector3(1.4, 1.0, 1.0), Color(0.30, 0.31, 0.30))

func _build_radio_tower() -> void:
    _static_box("TowerBase", Vector3(66.0, get_height_at(66.0, -32.0) + 0.25, -32.0), Vector3(6.0, 0.5, 6.0), Color(0.38, 0.38, 0.36))
    for i in range(9):
        _static_box("TowerSegment%d" % i, Vector3(66.0, get_height_at(66.0, -32.0) + 1.2 + float(i) * 1.8, -32.0), Vector3(0.55, 1.55, 0.55), Color(0.45, 0.08, 0.08) if i % 2 == 0 else Color(0.78, 0.78, 0.76))
    _static_box("TowerTopPlatform", Vector3(66.0, get_height_at(66.0, -32.0) + 18.0, -32.0), Vector3(5.0, 0.35, 5.0), Color(0.42, 0.43, 0.42))
    _add_omni("TowerBlink", Vector3(66.0, get_height_at(66.0, -32.0) + 19.0, -32.0), Color(1.0, 0.05, 0.02), 2.2, 18.0)

func _build_cabin_area() -> void:
    var base_y := get_height_at(-68.0, 48.0)
    _static_box("CabinFloor", Vector3(-68.0, base_y + 0.2, 48.0), Vector3(10.5, 0.3, 8.0), Color(0.26, 0.19, 0.13))
    _static_box("CabinBack", Vector3(-68.0, base_y + 2.0, 44.0), Vector3(10.5, 3.5, 0.45), Color(0.34, 0.24, 0.16))
    _static_box("CabinLeft", Vector3(-73.25, base_y + 2.0, 48.0), Vector3(0.45, 3.5, 8.0), Color(0.34, 0.24, 0.16))
    _static_box("CabinRight", Vector3(-62.75, base_y + 2.0, 48.0), Vector3(0.45, 3.5, 8.0), Color(0.34, 0.24, 0.16))
    _static_box("CabinRoof", Vector3(-68.0, base_y + 4.0, 48.0), Vector3(11.5, 0.45, 9.0), Color(0.18, 0.16, 0.14))
    _add_omni("CabinDimLight", Vector3(-68.0, base_y + 2.4, 48.0), Color(1.0, 0.55, 0.22), 1.3, 9.0)

func _build_forest_and_rocks() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 99331
    for i in range(145):
        var x := rng.randf_range(-190.0, 190.0)
        var z := rng.randf_range(-190.0, 190.0)
        if Vector2(x, z).length() < 42.0:
            continue
        if Vector2(x - 52.0, z + 34.0).length() < 48.0:
            continue
        _tree("Tree%d" % i, Vector3(x, get_height_at(x, z), z), rng.randf_range(0.7, 1.55), rng.randf() < 0.42)
    for i in range(80):
        var x := rng.randf_range(-185.0, 185.0)
        var z := rng.randf_range(-185.0, 185.0)
        if Vector2(x, z).length() < 35.0:
            continue
        var rock_size := Vector3(rng.randf_range(0.8, 3.4), rng.randf_range(0.35, 1.45), rng.randf_range(0.8, 3.4))
        _static_box("ValleyRock%d" % i, Vector3(x, get_height_at(x, z) + rock_size.y * 0.5, z), rock_size, Color(0.25, 0.26, 0.25))

func _tree(node_name: String, world_pos: Vector3, scale_value: float, pine: bool) -> void:
    if pine:
        _static_box(node_name + "Trunk", world_pos + Vector3(0.0, 1.8 * scale_value, 0.0), Vector3(0.42 * scale_value, 3.6 * scale_value, 0.42 * scale_value), Color(0.20, 0.12, 0.07))
        _static_box(node_name + "NeedlesA", world_pos + Vector3(0.0, 4.0 * scale_value, 0.0), Vector3(2.4 * scale_value, 2.3 * scale_value, 2.4 * scale_value), Color(0.08, 0.19, 0.11))
        _static_box(node_name + "NeedlesB", world_pos + Vector3(0.0, 5.2 * scale_value, 0.0), Vector3(1.7 * scale_value, 1.8 * scale_value, 1.7 * scale_value), Color(0.07, 0.16, 0.09))
    else:
        _static_box(node_name + "Trunk", world_pos + Vector3(0.0, 1.35 * scale_value, 0.0), Vector3(0.55 * scale_value, 2.7 * scale_value, 0.55 * scale_value), Color(0.22, 0.13, 0.07))
        _static_box(node_name + "CrownA", world_pos + Vector3(0.0, 3.25 * scale_value, 0.0), Vector3(2.8 * scale_value, 2.2 * scale_value, 2.8 * scale_value), Color(0.10, 0.24, 0.12))
        _static_box(node_name + "CrownB", world_pos + Vector3(0.45 * scale_value, 4.1 * scale_value, -0.2 * scale_value), Vector3(2.0 * scale_value, 1.7 * scale_value, 2.0 * scale_value), Color(0.09, 0.20, 0.10))

func _place_equipment() -> void:
    _instance_scene(COMPUTER_SCENE, "MainComputer", Vector3(-10.3, 1.7, -6.45), Vector3(0, 0, 0), Vector3(1.4, 1.0, 0.8))
    _instance_scene(COORDINATE_SCENE, "CoordinatePanel", Vector3(0.0, 1.7, -6.45), Vector3(0, 0, 0), Vector3(1.2, 1.0, 0.8))
    _instance_scene(DETECTOR_SCENE, "Detector", Vector3(9.0, 1.7, -6.45), Vector3(0, 0, 0), Vector3(1.1, 1.0, 0.8))
    _instance_scene(BREAKER_SCENE, "BreakerPanel", Vector3(14.9, 1.8, 5.4), Vector3(0, 90, 0), Vector3(0.7, 1.25, 0.25))
    _instance_scene(BED_SCENE, "BedInteract", Vector3(-10.2, 1.65, 6.6), Vector3(0, 0, 0), Vector3(4.2, 0.4, 2.1))
    _instance_scene(RADIO_SCENE, "Radio", Vector3(-7.2, 1.85, 8.5), Vector3(0, 0, 0), Vector3(0.7, 0.5, 0.5))
    _instance_scene(DISH_SCENE, "DishTerminal", Vector3(-46.0, 1.2, -37.0), Vector3(0, 0, 0), Vector3(1.0, 1.0, 1.0))

func _instance_scene(path: String, node_name: String, world_pos: Vector3, rotation_degrees_value: Vector3, scale_value: Vector3) -> Node3D:
    if not ResourceLoader.exists(path):
        push_warning("Missing scene: %s" % path)
        return null
    var scene := load(path) as PackedScene
    if scene == null:
        return null
    var node := scene.instantiate() as Node3D
    if node == null:
        return null
    node.name = node_name
    node.position = world_pos
    node.rotation_degrees = rotation_degrees_value
    node.scale = scale_value
    add_child(node)
    return node
