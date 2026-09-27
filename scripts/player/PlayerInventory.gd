extends Node
class_name PlayerInventory
func add_item(id:String,count:=1)->bool: return GameStateManager.add_item(id,count)
func remove_item(id:String,count:=1)->bool: return GameStateManager.remove_item(id,count)
func has_item(id:String,count:=1)->bool: return GameStateManager.has_item(id,count)
