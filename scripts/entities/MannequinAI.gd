extends Node3D
class_name MannequinAI

var timer := 0.0

func _process(delta: float) -> void:
    timer += delta
    if timer > 10.0:
        timer = 0.0
        translate(Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)))
