extends Resource
class_name EntityData
@export var id:String=""
@export var display_name:String="Entity"
@export_multiline var description:String=""
@export var scene_path:String=""
@export var max_health:float=100.0
@export var invulnerable:bool=false
@export var spawn_min_day:int=1
@export var spawn_contexts:Array[String]=[]
@export var behavior:String="passive"
