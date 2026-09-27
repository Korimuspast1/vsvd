extends Node
class_name PlayerNeeds

func eat(nutrition: float, item_label: String = "food") -> void:
    GameStateManager.eat(nutrition, item_label)

func sleep(hours: float) -> void:
    GameStateManager.sleep_hours(hours)

func damage(amount: float, cause: String = "damage") -> void:
    GameStateManager.apply_damage(amount, cause)
