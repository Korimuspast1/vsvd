extends InteractableEquipment
class_name Radio

var enabled_audio := false

func _ready() -> void:
    interaction_label = "Toggle"
    display_name = "Radio"

func interact(_player: Node) -> void:
    enabled_audio = not enabled_audio
    UIManager.show_notification("Radio %s" % ("on" if enabled_audio else "off"), "info")
