extends Resource
class_name UpgradeData
@export var id:String=""
@export var display_name:String="Upgrade"
@export_multiline var description:String=""
@export var max_level:int=10
@export var base_cost:int=100
@export var cost_multiplier:float=2.0
@export var effect_per_level:Dictionary={}
func cost_for_level(next_level:int)->int:
    return int(round(float(base_cost)*pow(cost_multiplier,float(maxi(0,next_level-1)))))
