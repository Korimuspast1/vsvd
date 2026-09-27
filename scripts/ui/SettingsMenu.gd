extends Control
class_name SettingsMenu

var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var sens_slider: HSlider
var fov_slider: HSlider
var invert_check: CheckButton
var vsync_check: CheckButton
var difficulty_option: OptionButton

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()
    _load_values()

func _build() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(360, 90)
    panel.size = Vector2(560, 540)
    add_child(panel)
    var root := VBoxContainer.new()
    panel.add_child(root)
    var title := Label.new()
    title.text = "SETTINGS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(title)
    difficulty_option = OptionButton.new()
    for d in ["easy", "normal", "hard", "nightmare"]:
        difficulty_option.add_item(d.capitalize())
    root.add_child(_labeled("Difficulty", difficulty_option))
    master_slider = _slider()
    music_slider = _slider()
    sfx_slider = _slider()
    sens_slider = _slider(0.1, 4.0, 0.05)
    fov_slider = _slider(60.0, 110.0, 1.0)
    root.add_child(_labeled("Master Volume", master_slider))
    root.add_child(_labeled("Music Volume", music_slider))
    root.add_child(_labeled("SFX Volume", sfx_slider))
    root.add_child(_labeled("Mouse Sensitivity", sens_slider))
    root.add_child(_labeled("FOV", fov_slider))
    invert_check = CheckButton.new()
    invert_check.text = "Invert Y"
    root.add_child(invert_check)
    vsync_check = CheckButton.new()
    vsync_check.text = "V-Sync"
    root.add_child(vsync_check)
    var buttons := HBoxContainer.new()
    root.add_child(buttons)
    var apply := Button.new()
    apply.text = "Apply"
    apply.pressed.connect(_apply)
    buttons.add_child(apply)
    var back := Button.new()
    back.text = "Back"
    back.pressed.connect(func(): UIManager.close_top())
    buttons.add_child(back)

func _slider(min_value: float = 0.0, max_value: float = 1.0, step: float = 0.01) -> HSlider:
    var s := HSlider.new()
    s.min_value = min_value
    s.max_value = max_value
    s.step = step
    s.custom_minimum_size = Vector2(300, 24)
    return s

func _labeled(label: String, control: Control) -> HBoxContainer:
    var row := HBoxContainer.new()
    var l := Label.new()
    l.text = label
    l.custom_minimum_size = Vector2(180, 24)
    row.add_child(l)
    row.add_child(control)
    return row

func _load_values() -> void:
    var difficulties := ["easy", "normal", "hard", "nightmare"]
    difficulty_option.selected = maxi(0, difficulties.find(str(SettingsManager.get_setting("gameplay", "difficulty", "normal"))))
    master_slider.value = float(SettingsManager.get_setting("audio", "Master", 1.0))
    music_slider.value = float(SettingsManager.get_setting("audio", "Music", 0.8))
    sfx_slider.value = float(SettingsManager.get_setting("audio", "SFX", 0.9))
    sens_slider.value = float(SettingsManager.get_setting("controls", "mouse_sensitivity", 1.0))
    fov_slider.value = float(SettingsManager.get_setting("video", "fov", 75.0))
    invert_check.button_pressed = bool(SettingsManager.get_setting("controls", "invert_y", false))
    vsync_check.button_pressed = bool(SettingsManager.get_setting("video", "vsync", true))

func _apply() -> void:
    var difficulties := ["easy", "normal", "hard", "nightmare"]
    SettingsManager.set_setting("gameplay", "difficulty", difficulties[difficulty_option.selected], false)
    SettingsManager.set_setting("audio", "Master", float(master_slider.value), false)
    SettingsManager.set_setting("audio", "Music", float(music_slider.value), false)
    SettingsManager.set_setting("audio", "SFX", float(sfx_slider.value), false)
    SettingsManager.set_setting("controls", "mouse_sensitivity", float(sens_slider.value), false)
    SettingsManager.set_setting("controls", "invert_y", invert_check.button_pressed, false)
    SettingsManager.set_setting("video", "fov", float(fov_slider.value), false)
    SettingsManager.set_setting("video", "vsync", vsync_check.button_pressed, false)
    SettingsManager.apply_settings()
    SettingsManager.save_settings()
    UIManager.show_notification("Settings applied", "success")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
