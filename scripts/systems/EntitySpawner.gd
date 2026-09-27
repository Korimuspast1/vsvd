extends Node3D
class_name EntitySpawner

func spawn(scene_path: String, pos: Vector3) -> Node3D:
    if not ResourceLoader.exists(scene_path):
        return null
    var n := load(scene_path).instantiate() as Node3D
    add_child(n)
    n.global_position = pos
    return n
