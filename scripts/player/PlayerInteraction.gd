extends RayCast3D
class_name PlayerInteraction
var current_target:Node
func _ready()->void:
    enabled=true; collide_with_areas=true; collide_with_bodies=true
func _process(delta:float)->void:
    force_raycast_update()
    current_target=get_collider() as Node if is_colliding() else null
    if current_target and current_target.has_method("get_interaction_prompt"):
        UIManager.set_interaction_prompt(current_target.get_interaction_prompt())
    else:
        UIManager.set_interaction_prompt("")
func _unhandled_input(event:InputEvent)->void:
    if event.is_action_pressed("interact") and current_target and current_target.has_method("interact"):
        current_target.interact(get_tree().get_first_node_in_group("player"))
