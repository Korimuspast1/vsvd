extends Control
class_name DetectorUI

var freq: HSlider
var pol: HSlider
var output: Label
var data: SignalData

func _ready() -> void:
    data = SignalDatabase.get_signal(GameStateManager.pending_signal_id)
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var box := VBoxContainer.new()
    box.position = Vector2(420, 160)
    box.size = Vector2(440, 360)
    add_child(box)
    var title := Label.new()
    title.text = "Detector — %s" % (data.display_name if data else "No Signal")
    box.add_child(title)
    var f_label := Label.new()
    f_label.text = "Frequency"
    box.add_child(f_label)
    freq = HSlider.new()
    freq.min_value = 0.0
    freq.max_value = 1.0
    freq.step = 0.001
    box.add_child(freq)
    var p_label := Label.new()
    p_label.text = "Polarity"
    box.add_child(p_label)
    pol = HSlider.new()
    pol.min_value = -1.0
    pol.max_value = 1.0
    pol.step = 0.001
    box.add_child(pol)
    output = Label.new()
    box.add_child(output)
    var dl := Button.new()
    dl.text = "Download"
    dl.pressed.connect(_download)
    box.add_child(dl)

func _process(delta: float) -> void:
    output.text = "Output Data: %.1f%%" % _score()

func _score() -> float:
    return SignalTuner.calculate_output(data, float(freq.value), float(pol.value), GameStateManager.get_upgrade_level("detector_frequency"))

func _download() -> void:
    if _score() < 95.0:
        UIManager.show_notification("Output must exceed 95%", "warning")
        return
    var id := GameStateManager.download_pending_signal_to_tape(_score())
    UIManager.show_notification("Downloaded to %s" % id, "success")
    UIManager.close_top()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
