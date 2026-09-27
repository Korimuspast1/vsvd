extends ItemBase
class_name FoodItem

@export var nutrition := 25.0

func interact(_player: Node) -> void:
    GameStateManager.eat(nutrition, display_name)
    queue_free()
