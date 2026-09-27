extends CanvasLayer
class_name HUD

var health: ProgressBar
var hunger: ProgressBar
var sleep_bar: ProgressBar
var stamina: ProgressBar
var points_label: Label
var time_label: Label
var prompt: Label
var notify_box: VBoxContainer
var held_label: Label
var damage_overlay: ColorRect
var damage_alpha := 0.0

func _ready() -> void:
    UIManager.register_hud(self)
    _build()
    GameStateManager.needs_changed.connect(_on_needs)
    GameStateManager.points_changed.connect(func(v: int): points_label.text = "%d pts" % v)
    GameStateManager.time_changed.connect(func(d: int, m: int): time_label.text = GameStateManager.get_day_time_string())
    _on_needs(GameStateManager.needs)
    points_label.text = "%d pts" % GameStateManager.points
    time_label.text = GameStateManager.get_day_time_string()

func _process(delta: float) -> void:
    if damage_alpha > 0.0:
        damage_alpha = maxf(0.0, damage_alpha - delta * 2.0)
        damage_overlay.color = Color(0.9, 0.0, 0.0, damage_alpha)

func _build() -> void:
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    prompt = Label.new()
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.set_anchors_preset(Control.PRESET_CENTER)
    prompt.position = Vector2(-160, 28)
    prompt.size = Vector2(320, 30)
    root.add_child(prompt)
    var needs_box := VBoxContainer.new()
    needs_box.position = Vector2(20, 520)
    needs_box.size = Vector2(220, 70)
    root.add_child(needs_box)
    health = _bar("Health")
    hunger = _bar("Hunger")
    sleep_bar = _bar("Sleep")
    needs_box.add_child(health)
    needs_box.add_child(hunger)
    needs_box.add_child(sleep_bar)
    stamina = _bar("Stamina")
    stamina.position = Vector2(490, 680)
    stamina.size = Vector2(300, 10)
    root.add_child(stamina)
    points_label = Label.new()
    points_label.position = Vector2(1080, 20)
    root.add_child(points_label)
    time_label = Label.new()
    time_label.position = Vector2(1030, 48)
    root.add_child(time_label)
    held_label = Label.new()
    held_label.position = Vector2(1000, 650)
    root.add_child(held_label)
    notify_box = VBoxContainer.new()
    notify_box.position = Vector2(400, 20)
    notify_box.size = Vector2(480, 160)
    root.add_child(notify_box)
    damage_overlay = ColorRect.new()
    damage_overlay.color = Color(0.9, 0.0, 0.0, 0.0)
    damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(damage_overlay)

func _bar(label: String) -> ProgressBar:
    var b := ProgressBar.new()
    b.min_value = 0
    b.max_value = 100
    b.value = 100
    b.show_percentage = false
    b.custom_minimum_size = Vector2(200, 14)
    b.tooltip_text = label
    return b

func _on_needs(n: Dictionary) -> void:
    health.value = float(n.health)
    hunger.value = float(n.hunger)
    sleep_bar.value = float(n.sleep)
    stamina.value = float(n.stamina)
    stamina.visible = float(n.stamina) < 99.0

func set_interaction_prompt(text: String) -> void:
    prompt.text = text

func show_notification(text: String, kind: String = "info") -> void:
    var l := Label.new()
    l.text = text
    l.modulate = {"info": Color.WHITE, "success": Color.GREEN, "warning": Color.YELLOW, "error": Color.RED}.get(kind, Color.WHITE)
    notify_box.add_child(l)
    await get_tree().create_timer(3.0, true).timeout
    if is_instance_valid(l):
        l.queue_free()

func flash_damage(amount: float) -> void:
    damage_alpha = clampf(0.15 + amount / 100.0, 0.2, 0.75)
    damage_overlay.color = Color(0.9, 0.0, 0.0, damage_alpha)
