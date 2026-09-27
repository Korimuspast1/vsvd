extends Control
class_name InventoryUI
func _ready()->void: set_anchors_preset(Control.PRESET_FULL_RECT); _build()
func _build()->void:
    var box:=GridContainer.new(); box.columns=8; box.position=Vector2(280,120); box.size=Vector2(720,420); add_child(box)
    for i in range(40):
        var b:=Button.new(); b.custom_minimum_size=Vector2(84,64); b.text=""
        if i<GameStateManager.inventory.size(): b.text="%s x%d"%[GameStateManager.inventory[i].id,int(GameStateManager.inventory[i].get("count",1))]
        box.add_child(b)
func _unhandled_input(event:InputEvent)->void:
    if event.is_action_pressed("inventory") or event.is_action_pressed("pause"): UIManager.close_top()
