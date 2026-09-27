extends InteractableEquipment
class_name Hook

func _ready() -> void:
    interaction_label = "Use"
    display_name = "Hook"

func interact(_player: Node) -> void:
    UIManager.show_notification("Hook point secured.", "info")
