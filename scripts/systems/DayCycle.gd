extends Node3D
class_name DayCycle
@export var sun_path:NodePath
@export var moon_path:NodePath
func _process(delta:float)->void:
    var t:=float(GameStateManager.minute_of_day)/1440.0
    if has_node(sun_path): get_node(sun_path).rotation_degrees.x=lerpf(-90,270,t)
    if has_node(moon_path): get_node(moon_path).rotation_degrees.x=lerpf(90,450,t)
