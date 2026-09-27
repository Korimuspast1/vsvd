extends CharacterBody3D
class_name EntityBase
@export var entity_id:="entity"
@export var max_health:=100.0
@export var speed:=2.0
@export var invulnerable:=false
@export var behavior:="passive"
var health:=100.0
var target:Node3D
func _ready()->void: health=max_health; add_to_group("entities")
func _physics_process(delta:float)->void:
    if behavior=="chase":
        if target==null: target=get_tree().get_first_node_in_group("player") as Node3D
        if target:
            var dir:=(target.global_position-global_position); dir.y=0
            if dir.length()>0.1: velocity=dir.normalized()*speed
            move_and_slide()
func damage(amount:float)->void:
    if invulnerable: return
    health-=amount
    if health<=0.0: queue_free()
