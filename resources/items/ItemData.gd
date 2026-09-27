extends Resource
class_name ItemData
@export var id:String=""
@export var display_name:String="Unnamed Item"
@export_multiline var description:String=""
@export var icon_path:String=""
@export var model_path:String=""
@export var weight_kg:float=0.1
@export var stackable:bool=false
@export var max_stack_size:int=1
@export var category:String="Misc"
@export var use_action:String="none"
@export var special_properties:Dictionary={}
