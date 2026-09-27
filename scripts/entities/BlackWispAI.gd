extends Node3D
class_name BlackWispAI
func _process(delta:float)->void:
    var p:=get_tree().get_first_node_in_group("player") as Node3D
    if p: global_position=global_position.lerp(p.global_position+Vector3(2,1.5,2),delta*0.25)
