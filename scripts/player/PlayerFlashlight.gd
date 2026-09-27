extends SpotLight3D
class_name PlayerFlashlight

@export var battery_seconds := 600.0
var remaining := 600.0

func _ready() -> void:
    remaining = battery_seconds
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("flashlight") and remaining > 0.0:
        visible = not visible

func _process(delta: float) -> void:
    if visible:
        remaining = maxf(0.0, remaining - delta)
        visible = remaining > 0.0
