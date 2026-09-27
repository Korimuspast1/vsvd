extends InteractableEquipment
class_name Hook

func _ready() -> void:
    interaction_label = "Use"
    display_name = "Hook"

func interact(player: Node) -> void:
    UIManager.show_notification("Hook point secured.", "info")
