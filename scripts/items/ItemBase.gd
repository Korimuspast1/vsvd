extends RigidBody3D
class_name ItemBase
@export var item_id:=""
@export var display_name:="Item"
func get_interaction_prompt()->String: return "Pick Up %s [%s]"%[display_name,InputManager.get_action_label("interact")]
func interact(player:Node)->void:
    if GameStateManager.add_item(item_id): queue_free()
