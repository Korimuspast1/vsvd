extends InteractableEquipment
class_name Dish

@export var dish_id := "dish_1"

func _ready() -> void:
    interaction_label = "Inspect"
    display_name = "Satellite Dish"

func interact(_player: Node) -> void:
    UIManager.show_notification("%s: %s" % [dish_id, GameStateManager.facility_status.dishes.get(dish_id, "unknown")], "info")
