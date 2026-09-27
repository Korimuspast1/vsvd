extends Node

signal bindings_changed()

const DEFAULT_BINDINGS := {
    "move_forward": [KEY_W],
    "move_backward": [KEY_S],
    "move_left": [KEY_A],
    "move_right": [KEY_D],
    "jump": [KEY_SPACE],
    "crouch": [KEY_CTRL],
    "sprint": [KEY_SHIFT],
    "interact": [KEY_E],
    "drop_item": [KEY_G],
    "inspect_item": [KEY_F],
    "inventory": [KEY_TAB, KEY_I],
    "hotbar_1": [KEY_1],
    "hotbar_2": [KEY_2],
    "hotbar_3": [KEY_3],
    "hotbar_4": [KEY_4],
    "hotbar_5": [KEY_5],
    "flashlight": [KEY_L],
    "pause": [KEY_ESCAPE],
    "quick_save": [KEY_F5],
    "quick_load": [KEY_F9],
    "toggle_hud": [KEY_F1],
    "toggle_subtitles": [KEY_F2],
    "toggle_compass": [KEY_F3],
    "toggle_objective_marker": [KEY_F4],
    "screenshot": [KEY_F12],
    "lean_left": [KEY_Q],
    "lean_right": [KEY_E],
    "melee": [KEY_V],
    "gravity_use": [MOUSE_BUTTON_RIGHT],
    "gravity_zoom": [MOUSE_BUTTON_MIDDLE],
}

var mouse_sensitivity := 1.0
var invert_y := false

func _ready() -> void:
    apply_default_bindings(false)

func apply_default_bindings(clear_existing: bool = true) -> void:
    for action in DEFAULT_BINDINGS.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action, 0.5)
        elif clear_existing:
            InputMap.action_erase_events(action)
        if clear_existing or InputMap.action_get_events(action).is_empty():
            for code in DEFAULT_BINDINGS[action]:
                InputMap.action_add_event(action, _event_from_code(int(code)))
    bindings_changed.emit()

func _event_from_code(code: int) -> InputEvent:
    if code >= MOUSE_BUTTON_LEFT and code <= MOUSE_BUTTON_XBUTTON2:
        var e := InputEventMouseButton.new()
        e.button_index = code
        return e
    var k := InputEventKey.new()
    k.physical_keycode = code
    return k

func rebind_action(action: String, event: InputEvent) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, 0.5)
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, event)
    bindings_changed.emit()

func get_action_label(action: String) -> String:
    if not InputMap.has_action(action):
        return "?"
    var events := InputMap.action_get_events(action)
    return "?" if events.is_empty() else events[0].as_text().replace(" (Physical)", "")

func reset_to_defaults() -> void:
    apply_default_bindings(true)
