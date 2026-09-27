extends Control
class_name PauseMenu

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var overlay := ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.45)
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(overlay)
    var box := VBoxContainer.new()
    box.position = Vector2(520, 190)
    box.size = Vector2(240, 360)
    add_child(box)
    _button(box, "Resume", func(): UIManager.close_top())
    _button(box, "Save", func(): SaveManager.save_game(1))
    _button(box, "Save / Load", func(): UIManager.open_scene("res://scenes/ui/SaveLoadMenu.tscn", true))
    _button(box, "Settings", func(): UIManager.open_scene("res://scenes/ui/SettingsMenu.tscn", true))
    _button(box, "Main Menu", _main_menu)
    _button(box, "Quit", func(): get_tree().quit())

func _button(parent: VBoxContainer, text: String, action: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(240, 42)
    b.pressed.connect(action)
    parent.add_child(b)

func _main_menu() -> void:
    UIManager.close_all()
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
