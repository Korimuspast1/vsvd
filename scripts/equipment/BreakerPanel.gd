extends InteractableEquipment
class_name BreakerPanel

func _ready() -> void:
    interaction_label = "Use"
    display_name = "Breaker Panel"

func interact(player: Node) -> void:
    GameStateManager.facility_status.power = true
    for k in GameStateManager.facility_status.breakers.keys():
        GameStateManager.facility_status.breakers[k] = true
    UIManager.show_notification("Breakers restored", "success")
