extends InteractableEquipment
class_name Detector

func _ready() -> void:
    interaction_label = "Use"
    display_name = "Detector"

func interact(_player: Node) -> void:
    UIManager.open_scene("res://scenes/ui/DetectorUI.tscn", true)
