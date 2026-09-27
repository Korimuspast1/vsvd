extends Node3D
class_name PlayerHands
@export var sway_amount:=0.02
func _process(_delta:float)->void: position.x=sin(Time.get_ticks_msec()*0.004)*sway_amount
