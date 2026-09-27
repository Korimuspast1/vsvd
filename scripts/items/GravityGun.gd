extends ItemBase
class_name GravityGun

@export var pull_range := 10.0
@export var throw_force := 28.0

func _ready() -> void:
    item_id = "gravity_tool"
    display_name = "Gravity Tool"
