extends Resource
class_name EventData
@export var id:String=""
@export var display_name:String="Event"
@export_multiline var description:String=""
@export var event_type:String="scripted"
@export var trigger_day:int=1
@export_range(0,1439,1) var trigger_minute:int=0
@export var anomaly_delta:float=0.0
@export var flags_to_set:Dictionary={}
func is_due(day:int, minute:int)->bool:
    return day > trigger_day or (day == trigger_day and minute >= trigger_minute)
