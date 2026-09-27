extends ItemBase
class_name Note
@export_multiline var text:=""
func interact(player:Node)->void: UIManager.show_notification(text,"info")
