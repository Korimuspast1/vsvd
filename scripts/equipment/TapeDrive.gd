extends InteractableEquipment
class_name TapeDriveEquipment

@export var tape_id := ""

func _ready() -> void:
    interaction_label = "Pick Up"
    display_name = "Tape Drive"

func interact(_player: Node) -> void:
    GameStateManager.add_item("tape_drive_empty", 1, {"tape_id": tape_id})
    queue_free()
