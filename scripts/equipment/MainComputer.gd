extends InteractableEquipment
class_name MainComputer

func _ready() -> void:
    interaction_label = "Use"
    display_name = "Terminal"

func interact(player: Node) -> void:
    UIManager.open_scene("res://scenes/ui/ComputerUI.tscn", true)
