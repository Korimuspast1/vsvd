extends Node3D
class_name DemoMapBuilder

const COMPUTER_SCENE := "res://scenes/equipment/MainComputer.tscn"
const COORDINATE_SCENE := "res://scenes/equipment/CoordinatePanel.tscn"
const DETECTOR_SCENE := "res://scenes/equipment/Detector.tscn"
const BREAKER_SCENE := "res://scenes/equipment/BreakerPanel.tscn"
const BED_SCENE := "res://scenes/equipment/Bed.tscn"
const RADIO_SCENE := "res://scenes/equipment/Radio.tscn"
const DISH_SCENE := "res://scenes/equipment/Dish.tscn"

var materials: Dictionary = {}

func _ready() -> void:
    _setup_environment()
    _build_ground()
    _build_observatory()
    _build_exterior_props()
    _build_forest()
    _place_equipment()

func _setup_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.18, 0.23, 0.28)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.45, 0.48, 0.50)
    env.ambient_light_energy = 0.9
    env.fog_enabled = true
    env.fog_density = 0.012
    env.fog_light_color = Color(0.45, 0.50, 0.55)
    world_environment.environment = env
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.name = "MapSun"
    sun.rotation_degrees = Vector3(-45, 35, 0)
    sun.light_energy = 2.2
    sun.shadow_enabled = true
    add_child(sun)

func _mat(id: String, color: Color) -> Material:
    if materials.has(id):
        return materials[id]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    material.metallic = 0.0
    materials[id] = material
    return material

func _static_box(node_name: String, position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = position
    add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _mat(node_name + "_mat", color)
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _decor_box(node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    mesh_instance.position = position
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _mat(node_name + "_mat", color)
    add_child(mesh_instance)
    return mesh_instance

func _build_ground() -> void:
    _static_box("Ground", Vector3(0, -0.12, 0), Vector3(180, 0.2, 180), Color(0.32, 0.36, 0.31))
    _static_box("ConcreteYard", Vector3(0, 0.0, 0), Vector3(44, 0.12, 34), Color(0.47, 0.48, 0.46))
    _static_box("MainPath", Vector3(0, 0.02, 45), Vector3(7, 0.08, 70), Color(0.34, 0.35, 0.33))
    _static_box("ServiceRoad", Vector3(-42, 0.01, 12), Vector3(70, 0.08, 6), Color(0.27, 0.27, 0.25))

func _build_observatory() -> void:
    var wall := Color(0.55, 0.56, 0.54)
    var dark := Color(0.33, 0.34, 0.34)
    var floor := Color(0.43, 0.44, 0.42)

    _static_box("LabFloor", Vector3(0, 0.08, 0), Vector3(30, 0.16, 22), floor)

    # Outer walls with a wide front doorway.
    _static_box("BackWall", Vector3(0, 1.65, -11), Vector3(30, 3.3, 0.45), wall)
    _static_box("FrontWallLeft", Vector3(-10.5, 1.65, 11), Vector3(9, 3.3, 0.45), wall)
    _static_box("FrontWallRight", Vector3(10.5, 1.65, 11), Vector3(9, 3.3, 0.45), wall)
    _static_box("LeftWall", Vector3(-15, 1.65, 0), Vector3(0.45, 3.3, 22), wall)
    _static_box("RightWall", Vector3(15, 1.65, 0), Vector3(0.45, 3.3, 22), wall)

    # Partial roof beams so the interior still has light.
    _static_box("RoofBeamA", Vector3(-7.5, 3.35, 0), Vector3(0.5, 0.35, 22), dark)
    _static_box("RoofBeamB", Vector3(7.5, 3.35, 0), Vector3(0.5, 0.35, 22), dark)
    _static_box("RoofBack", Vector3(0, 3.45, -9.5), Vector3(30, 0.25, 3), dark)

    # Interior partitions: signal lab, living corner, storage corner.
    _static_box("PartitionA", Vector3(-5, 1.35, 1.5), Vector3(0.35, 2.7, 12), wall)
    _static_box("PartitionB", Vector3(6, 1.35, 3.5), Vector3(0.35, 2.7, 9), wall)
    _static_box("StorageDivider", Vector3(10.5, 1.35, -2.5), Vector3(9, 2.7, 0.35), wall)

    # Desks and shelves.
    _static_box("ComputerDesk", Vector3(-9.5, 0.55, -7.2), Vector3(7.5, 1.1, 2.0), Color(0.25, 0.22, 0.18))
    _static_box("ControlDesk", Vector3(1.5, 0.55, -7.2), Vector3(8.0, 1.1, 2.0), Color(0.24, 0.25, 0.24))
    _static_box("DetectorDesk", Vector3(9.8, 0.55, -7.2), Vector3(5.5, 1.1, 2.0), Color(0.25, 0.25, 0.25))
    _static_box("StorageShelfA", Vector3(12.8, 1.0, 2.5), Vector3(1.8, 2.0, 5.5), Color(0.28, 0.25, 0.20))
    _static_box("StorageShelfB", Vector3(8.2, 1.0, 9.0), Vector3(5.5, 2.0, 1.2), Color(0.28, 0.25, 0.20))
    _static_box("BedBase", Vector3(-10.0, 0.35, 6.5), Vector3(4.5, 0.7, 2.4), Color(0.18, 0.20, 0.23))
    _static_box("BedMattress", Vector3(-10.0, 0.85, 6.5), Vector3(4.2, 0.35, 2.1), Color(0.58, 0.60, 0.58))

    # Door frame and visible room labels as simple colored blocks.
    _static_box("EntranceLintel", Vector3(0, 3.0, 11), Vector3(7.0, 0.35, 0.5), dark)
    _decor_box("SignalRoomMarker", Vector3(-9.5, 2.4, -10.7), Vector3(3.0, 0.2, 0.08), Color(0.1, 0.8, 0.35))
    _decor_box("ControlRoomMarker", Vector3(1.5, 2.4, -10.7), Vector3(3.0, 0.2, 0.08), Color(0.1, 0.45, 0.9))

    _add_light("LabLightA", Vector3(-8, 3.0, -3), 5.0, 9.0)
    _add_light("LabLightB", Vector3(5, 3.0, -3), 5.0, 9.0)
    _add_light("LivingLight", Vector3(-10, 2.6, 6), 3.0, 7.0, Color(1.0, 0.82, 0.55))

func _add_light(node_name: String, position: Vector3, energy: float, range_value: float, color: Color = Color.WHITE) -> OmniLight3D:
    var light := OmniLight3D.new()
    light.name = node_name
    light.position = position
    light.light_color = color
    light.light_energy = energy
    light.omni_range = range_value
    add_child(light)
    return light

func _build_exterior_props() -> void:
    var metal := Color(0.42, 0.43, 0.42)
    var concrete := Color(0.43, 0.43, 0.41)

    # Satellite dish pads and simplified dishes.
    for i in range(3):
        var x := -30.0 + float(i) * 30.0
        var z := -34.0 - float(i % 2) * 8.0
        _static_box("DishPad%d" % i, Vector3(x, 0.05, z), Vector3(8, 0.18, 8), concrete)
        _static_box("DishMast%d" % i, Vector3(x, 2.0, z), Vector3(0.55, 4.0, 0.55), metal)
        var dish := _static_box("DishFace%d" % i, Vector3(x, 4.2, z - 1.2), Vector3(5.0, 3.0, 0.35), Color(0.62, 0.64, 0.62))
        dish.rotation_degrees.x = -18

    # Fences around the playable compound.
    _static_box("FenceNorth", Vector3(0, 1.0, -58), Vector3(110, 2.0, 0.35), Color(0.22, 0.24, 0.22))
    _static_box("FenceSouthLeft", Vector3(-34, 1.0, 58), Vector3(42, 2.0, 0.35), Color(0.22, 0.24, 0.22))
    _static_box("FenceSouthRight", Vector3(34, 1.0, 58), Vector3(42, 2.0, 0.35), Color(0.22, 0.24, 0.22))
    _static_box("FenceWest", Vector3(-55, 1.0, 0), Vector3(0.35, 2.0, 116), Color(0.22, 0.24, 0.22))
    _static_box("FenceEast", Vector3(55, 1.0, 0), Vector3(0.35, 2.0, 116), Color(0.22, 0.24, 0.22))

    # Small radio tower made from stacked boxes.
    _static_box("RadioTowerBase", Vector3(42, 0.25, -22), Vector3(5, 0.5, 5), concrete)
    for h in range(6):
        _static_box("RadioTower%d" % h, Vector3(42, 1.0 + float(h) * 1.8, -22), Vector3(0.5, 1.5, 0.5), metal)
    _static_box("TowerTop", Vector3(42, 12.4, -22), Vector3(4.5, 0.35, 4.5), metal)

    # Abandoned cabin blockout.
    _static_box("CabinFloor", Vector3(-42, 0.1, 30), Vector3(9, 0.2, 7), Color(0.26, 0.20, 0.15))
    _static_box("CabinBack", Vector3(-42, 1.5, 26.5), Vector3(9, 3, 0.35), Color(0.35, 0.25, 0.17))
    _static_box("CabinLeft", Vector3(-46.5, 1.5, 30), Vector3(0.35, 3, 7), Color(0.35, 0.25, 0.17))
    _static_box("CabinRight", Vector3(-37.5, 1.5, 30), Vector3(0.35, 3, 7), Color(0.35, 0.25, 0.17))

func _build_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 421337
    for i in range(75):
        var x := rng.randf_range(-82, 82)
        var z := rng.randf_range(-82, 82)
        if absf(x) < 30 and absf(z) < 26:
            continue
        _tree("Tree%d" % i, Vector3(x, 0, z), rng.randf_range(0.8, 1.5))
    for i in range(24):
        var x := rng.randf_range(-70, 70)
        var z := rng.randf_range(-70, 70)
        if absf(x) < 24 and absf(z) < 20:
            continue
        _static_box("Rock%d" % i, Vector3(x, 0.25, z), Vector3(rng.randf_range(0.8, 2.5), rng.randf_range(0.35, 1.1), rng.randf_range(0.8, 2.5)), Color(0.22, 0.23, 0.22))

func _tree(node_name: String, position: Vector3, scale_value: float) -> void:
    _static_box(node_name + "Trunk", position + Vector3(0, 1.4 * scale_value, 0), Vector3(0.55 * scale_value, 2.8 * scale_value, 0.55 * scale_value), Color(0.20, 0.13, 0.08))
    _static_box(node_name + "CrownA", position + Vector3(0, 3.3 * scale_value, 0), Vector3(2.5 * scale_value, 2.3 * scale_value, 2.5 * scale_value), Color(0.11, 0.22, 0.13))
    _static_box(node_name + "CrownB", position + Vector3(0.25 * scale_value, 4.3 * scale_value, -0.2 * scale_value), Vector3(1.8 * scale_value, 1.8 * scale_value, 1.8 * scale_value), Color(0.09, 0.18, 0.10))

func _place_equipment() -> void:
    _instance_scene(COMPUTER_SCENE, "MainComputer", Vector3(-9.5, 1.25, -6.3), Vector3(0, 0, 0), Vector3(1.4, 1.0, 0.8))
    _instance_scene(COORDINATE_SCENE, "CoordinatePanel", Vector3(0.0, 1.25, -6.3), Vector3(0, 0, 0), Vector3(1.2, 1.0, 0.8))
    _instance_scene(DETECTOR_SCENE, "Detector", Vector3(8.8, 1.25, -6.3), Vector3(0, 0, 0), Vector3(1.1, 1.0, 0.8))
    _instance_scene(BREAKER_SCENE, "BreakerPanel", Vector3(14.35, 1.3, 5.4), Vector3(0, 90, 0), Vector3(0.7, 1.2, 0.25))
    _instance_scene(BED_SCENE, "BedInteract", Vector3(-10.0, 1.2, 6.5), Vector3(0, 0, 0), Vector3(4.2, 0.4, 2.1))
    _instance_scene(RADIO_SCENE, "Radio", Vector3(-7.2, 1.45, 8.5), Vector3(0, 0, 0), Vector3(0.7, 0.5, 0.5))
    _instance_scene(DISH_SCENE, "DishTerminal", Vector3(-30, 1.0, -28), Vector3(0, 0, 0), Vector3(1, 1, 1))

func _instance_scene(path: String, node_name: String, position: Vector3, rotation_degrees_value: Vector3, scale_value: Vector3) -> Node3D:
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
    node.position = position
    node.rotation_degrees = rotation_degrees_value
    node.scale = scale_value
    add_child(node)
    return node
