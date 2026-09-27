extends Node
signal quest_started(id:String)
signal quest_completed(id:String)
var active_quests:Dictionary={}
var completed_quests:Array[String]=[]
func start_quest(id:String,description:="")->void:
    if id in completed_quests: return
    active_quests[id]={"description":description,"progress":{},"started_day":GameStateManager.current_day}; quest_started.emit(id)
func update_progress(id:String,key:String,value:Variant)->void:
    if active_quests.has(id): active_quests[id].progress[key]=value
func complete_quest(id:String)->void:
    if not active_quests.has(id): return
    active_quests.erase(id)
    if not id in completed_quests: completed_quests.append(id)
    quest_completed.emit(id)
