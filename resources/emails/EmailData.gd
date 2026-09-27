extends Resource
class_name EmailData
@export var id:String=""
@export var sender:String="HQ"
@export var subject:String="No Subject"
@export var category:String="Story"
@export var delivery_day:int=1
@export_range(0,1439,1) var delivery_minute:int=480
@export_multiline var body:String=""
@export var attachments:Array[String]=[]
func is_due(day:int, minute:int)->bool:
    return day > delivery_day or (day == delivery_day and minute >= delivery_minute)
func timestamp_string()->String:
    return "Day %d %02d:%02d" % [delivery_day, int(delivery_minute/60), delivery_minute%60]
