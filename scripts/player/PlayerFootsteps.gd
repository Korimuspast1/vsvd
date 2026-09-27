extends Node
class_name PlayerFootsteps
@export var step_interval:=0.45
var timer:=0.0
func _physics_process(delta:float)->void:
    var p:=get_parent() as CharacterBody3D
    if not p: return
    var speed:=Vector2(p.velocity.x,p.velocity.z).length()
    if p.is_on_floor() and speed>0.2:
        timer-=delta
        if timer<=0.0:
            timer=step_interval/maxf(0.5,speed/3.5)
            # Hook for surface-aware footstep SFX.
    else: timer=0.0
