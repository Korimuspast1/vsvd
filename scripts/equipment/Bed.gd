extends InteractableEquipment
class_name Bed

func _ready() -> void:
    interaction_label = "Sleep"
    display_name = "Bed"

func interact(player: Node) -> void:
    GameStateManager.sleep_hours(8.0)
    UIManager.show_notification("You slept.", "info")
