extends Area3D
class_name InteractableEquipment

@export var interaction_label := "Use"
@export var display_name := "Device"
@export var interaction_priority := 0

func get_interaction_prompt() -> String:
    return "%s %s [%s]" % [interaction_label, display_name, InputManager.get_action_label("interact")]

func interact(player: Node) -> void:
    UIManager.show_notification("%s has no configured action." % display_name, "info")
