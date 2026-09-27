extends EntityBase
class_name VisitorAI
func _ready()->void: entity_id="visitor"; max_health=9999; invulnerable=true; behavior="observe"; super()
func _physics_process(delta:float)->void:
    var p:=get_tree().get_first_node_in_group("player") as Node3D
    if p and global_position.distance_to(p.global_position)<6.0: queue_free()
