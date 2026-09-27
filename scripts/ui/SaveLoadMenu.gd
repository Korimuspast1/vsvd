extends Control
class_name SaveLoadMenu

@export var load_mode := false
var list_box: VBoxContainer

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()
    refresh()

func _build() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(260, 80)
    panel.size = Vector2(760, 560)
    add_child(panel)
    var root := VBoxContainer.new()
    panel.add_child(root)
    var title := Label.new()
    title.text = "LOAD GAME" if load_mode else "SAVE / LOAD"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(title)
    list_box = VBoxContainer.new()
    list_box.custom_minimum_size = Vector2(720, 460)
    root.add_child(list_box)
    var back := Button.new()
    back.text = "Back"
    back.pressed.connect(func(): UIManager.close_top())
    root.add_child(back)

func refresh() -> void:
    for child in list_box.get_children():
        child.queue_free()
    for info in SaveManager.list_saves():
        var row := HBoxContainer.new()
        list_box.add_child(row)
        var slot := int(info.slot)
        var label := Label.new()
        label.custom_minimum_size = Vector2(420, 32)
        if bool(info.get("empty", false)):
            label.text = "Slot %d — Empty" % slot
        elif bool(info.get("corrupt", false)):
            label.text = "Slot %d — Corrupt" % slot
        else:
            var hour := floori(float(info.minute) / 60.0)
            label.text = "Slot %d — Day %d %02d:%02d — %d pts" % [slot, int(info.day), hour, int(info.minute) % 60, int(info.points)]
        row.add_child(label)
        var save_button := Button.new()
        save_button.text = "Save"
        save_button.disabled = slot == 0
        save_button.pressed.connect(func(s := slot):
            SaveManager.save_game(s)
            refresh()
        )
        row.add_child(save_button)
        var load_button := Button.new()
        load_button.text = "Load"
        load_button.disabled = bool(info.get("empty", false)) or bool(info.get("corrupt", false))
        load_button.pressed.connect(func(s := slot):
            SaveManager.load_game(s)
            UIManager.close_top()
        )
        row.add_child(load_button)
        var delete_button := Button.new()
        delete_button.text = "Delete"
        delete_button.disabled = bool(info.get("empty", false))
        delete_button.pressed.connect(func(s := slot):
            SaveManager.delete_save(s)
            refresh()
        )
        row.add_child(delete_button)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
