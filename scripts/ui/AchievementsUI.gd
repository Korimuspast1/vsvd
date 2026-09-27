extends Control
class_name AchievementsUI

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.position = Vector2(260, 80)
    panel.size = Vector2(760, 560)
    add_child(panel)
    var root := VBoxContainer.new()
    panel.add_child(root)
    var title := Label.new()
    title.text = "ACHIEVEMENTS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(title)
    var list := ScrollContainer.new()
    list.custom_minimum_size = Vector2(720, 460)
    root.add_child(list)
    var box := VBoxContainer.new()
    list.add_child(box)
    for id in AchievementManager.achievements.keys():
        var data: AchievementData = AchievementManager.achievements[id]
        var label := Label.new()
        var prefix := "[X]" if AchievementManager.is_unlocked(id) else "[ ]"
        label.text = "%s %s — %s" % [prefix, data.display_name, data.description]
        box.add_child(label)
    var back := Button.new()
    back.text = "Back"
    back.pressed.connect(func(): UIManager.close_top())
    root.add_child(back)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
