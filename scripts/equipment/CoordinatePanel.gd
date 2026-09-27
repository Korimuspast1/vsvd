extends InteractableEquipment
class_name CoordinatePanel

func _ready() -> void:
    interaction_label = "Use"
    display_name = "Coordinate Panel"

func interact(player: Node) -> void:
    UIManager.open_scene("res://scenes/ui/CoordinateUI.tscn", true)
