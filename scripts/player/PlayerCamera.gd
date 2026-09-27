extends Camera3D
class_name PlayerCamera
@export var base_fov := 75.0
func set_panic(intensity: float) -> void:
    fov = base_fov + intensity * 4.0
