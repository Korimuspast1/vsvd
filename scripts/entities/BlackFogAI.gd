extends Node3D
class_name BlackFogAI
func _process(delta:float)->void: translate(Vector3(sin(Time.get_ticks_msec()*0.001),0,cos(Time.get_ticks_msec()*0.001))*delta*0.25)
