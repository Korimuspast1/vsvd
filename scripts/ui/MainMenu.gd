extends Control
class_name MainMenu

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color(0.02, 0.025, 0.03, 1.0)
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var box := VBoxContainer.new()
    box.position = Vector2(470, 170)
    box.size = Vector2(340, 420)
    add_child(box)
    var title := Label.new()
    title.text = "VOID SIGNAL VIGIL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title)
    _button(box, "New Game", _new_game)
    _button(box, "Continue", _continue)
    _button(box, "Load Game", func(): UIManager.open_scene("res://scenes/ui/SaveLoadMenu.tscn", true))
    _button(box, "Settings", func(): UIManager.open_scene("res://scenes/ui/SettingsMenu.tscn", true))
    _button(box, "Achievements", func(): UIManager.open_scene("res://scenes/ui/AchievementsUI.tscn", true))
    _button(box, "Statistics", func(): UIManager.open_scene("res://scenes/ui/StatisticsUI.tscn", true))
    _button(box, "Quit", func(): get_tree().quit())

func _button(parent: VBoxContainer, text: String, action: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(320, 42)
    b.pressed.connect(action)
    parent.add_child(b)

func _new_game() -> void:
    GameStateManager.reset_new_game(true)
    get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _continue() -> void:
    if SaveManager.load_game(0):
        get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
    else:
        UIManager.show_notification("No autosave found", "warning")
