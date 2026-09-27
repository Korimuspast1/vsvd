extends Node3D
class_name HallucinationAI

@export var lifetime := 4.0

func _process(delta: float) -> void:
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()
