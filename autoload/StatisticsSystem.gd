extends Node
signal stat_changed(key:String,value:Variant)
var stats:Dictionary={"total_playtime":0.0,"days_survived":1,"signals_processed":0,"signals_sold":0,"points_earned":0,"points_spent":0,"upgrades_purchased":0,"entities_encountered":0,"deaths":0,"saves_loaded":0,"emails_read":0,"items_picked_up":0,"food_eaten":0,"hours_slept":0.0}
func _process(delta:float)->void:
    if not get_tree().paused: stats.total_playtime=float(stats.total_playtime)+delta
func increment(key:String,amount:Variant=1)->void:
    stats[key]=stats.get(key,0)+amount; stat_changed.emit(key,stats[key]); _check_achievements(key)
func set_stat(key:String,value:Variant)->void: stats[key]=value; stat_changed.emit(key,value)
func get_stat(key:String,default_value:Variant=0)->Variant: return stats.get(key,default_value)
func _check_achievements(key: String) -> void:
    if key == "signals_processed" and int(stats[key]) >= 10:
        AchievementManager.unlock("signal_collector")
    if key == "points_earned" and int(stats[key]) >= 10000:
        AchievementManager.unlock("mogul")

func to_dict() -> Dictionary:
    return {"stats": stats}

func from_dict(data: Dictionary) -> void:
    stats = data.get("stats", stats).duplicate(true)
