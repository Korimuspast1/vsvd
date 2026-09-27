extends Node
class_name PowerSystem
func restore_all()->void:
    GameStateManager.facility_status.power=true
    for k in GameStateManager.facility_status.breakers.keys(): GameStateManager.facility_status.breakers[k]=true
func trip_breaker(id:String)->void:
    if GameStateManager.facility_status.breakers.has(id): GameStateManager.facility_status.breakers[id]=false
    GameStateManager.facility_status.power=false
