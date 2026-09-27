extends Node
class_name DialogueSystem
func start(id:String)->bool: return DialogueManager.start_dialogue(id)
