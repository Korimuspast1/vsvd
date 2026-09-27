extends Control
class_name StatisticsUI

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.position = Vector2(360, 100)
    panel.size = Vector2(560, 520)
    add_child(panel)
    var root := VBoxContainer.new()
    panel.add_child(root)
    var title := Label.new()
    title.text = "STATISTICS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(title)
    var list := ScrollContainer.new()
    list.custom_minimum_size = Vector2(520, 400)
    root.add_child(list)
    var box := VBoxContainer.new()
    list.add_child(box)
    for key in StatisticsSystem.stats.keys():
        var label := Label.new()
        label.text = "%s: %s" % [str(key).capitalize(), str(StatisticsSystem.stats[key])]
        box.add_child(label)
    var back := Button.new()
    back.text = "Back"
    back.pressed.connect(func(): UIManager.close_top())
    root.add_child(back)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
