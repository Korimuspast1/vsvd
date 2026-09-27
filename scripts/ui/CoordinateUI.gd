extends Control
class_name CoordinateUI

var altitude := 50
var info: Label

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var box := VBoxContainer.new()
    box.position = Vector2(420, 180)
    box.size = Vector2(440, 300)
    add_child(box)
    var title := Label.new()
    title.text = "Coordinate Scanner"
    box.add_child(title)
    var opt := OptionButton.new()
    for a in [10, 20, 50, 100, 500, 1000]:
        opt.add_item("%d m" % a, a)
    opt.item_selected.connect(func(i: int): altitude = opt.get_item_id(i))
    box.add_child(opt)
    var scan := Button.new()
    scan.text = "Scan"
    scan.pressed.connect(_scan)
    box.add_child(scan)
    info = Label.new()
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART as TextServer.AutowrapMode
    box.add_child(info)

func _scan() -> void:
    info.text = "Scanning..."
    await get_tree().create_timer(1.0, true).timeout
    var data := SignalDatabase.get_random_signal(altitude, GameStateManager.current_day)
    if data:
        GameStateManager.set_pending_signal(data.id)
        info.text = "Detected: %s\nGo to Detector." % data.display_name
    else:
        info.text = "No signal."

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
