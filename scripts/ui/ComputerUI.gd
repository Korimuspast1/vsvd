extends Control
class_name ComputerUI

var content: RichTextLabel
var transient_buttons: Array[Button] = []

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()
    show_main()

func _build() -> void:
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 120
    panel.offset_top = 60
    panel.offset_right = -120
    panel.offset_bottom = -60
    add_child(panel)
    var h := HBoxContainer.new()
    panel.add_child(h)
    var menu := VBoxContainer.new()
    menu.custom_minimum_size = Vector2(220, 0)
    h.add_child(menu)
    _add_menu_button(menu, "Signals", Callable(self, "show_signals"))
    _add_menu_button(menu, "Sell", Callable(self, "show_sale"))
    _add_menu_button(menu, "Email", Callable(self, "show_email"))
    _add_menu_button(menu, "Upgrades", Callable(self, "show_upgrades"))
    _add_menu_button(menu, "Facility", Callable(self, "show_facility"))
    _add_menu_button(menu, "Stats", Callable(self, "show_stats"))
    _add_menu_button(menu, "Logout", Callable(self, "logout"))
    content = RichTextLabel.new()
    content.bbcode_enabled = true
    content.fit_content = false
    content.custom_minimum_size = Vector2(760, 520)
    h.add_child(content)

func _add_menu_button(menu: VBoxContainer, label: String, callable: Callable) -> void:
    var b := Button.new()
    b.text = label
    b.pressed.connect(callable)
    menu.add_child(b)

func _clear_transient() -> void:
    for b in transient_buttons:
        if is_instance_valid(b):
            b.queue_free()
    transient_buttons.clear()

func show_main() -> void:
    _clear_transient()
    content.text = "[center]REMOTE OBSERVATORY TERMINAL[/center]\nSelect a function."

func show_signals() -> void:
    _clear_transient()
    content.clear()
    content.append_text("[b]Tape Drives[/b]\n")
    var row := 0
    for id in GameStateManager.tape_drives.keys():
        content.append_text("%s\n" % GameStateManager.get_tape_display_name(id))
        var b := Button.new()
        b.text = "Process %s" % id
        b.position = Vector2(420, 120 + 28 * row)
        b.pressed.connect(func(tape_id := id):
            GameStateManager.process_tape(tape_id)
            show_signals()
        )
        add_child(b)
        transient_buttons.append(b)
        row += 1

func show_sale() -> void:
    _clear_transient()
    content.clear()
    content.append_text("[b]Sale Queue[/b]\n")
    var row := 0
    for id in GameStateManager.tape_drives.keys():
        var t: Dictionary = GameStateManager.tape_drives[id]
        if str(t.signal_id) != "":
            var price := GameStateManager.calculate_signal_price(str(t.signal_id), int(t.processing_level))
            content.append_text("%s price %d pts\n" % [GameStateManager.get_tape_display_name(id), price])
            var b := Button.new()
            b.text = "Sell %s" % id
            b.position = Vector2(420, 120 + 28 * row)
            b.pressed.connect(func(tape_id := id):
                GameStateManager.sell_tape(tape_id)
                show_sale()
            )
            add_child(b)
            transient_buttons.append(b)
            row += 1

func show_email() -> void:
    _clear_transient()
    content.clear()
    content.append_text("[b]Inbox[/b]\n")
    for e: EmailData in EmailManager.get_inbox():
        content.append_text("[u]%s[/u] — %s\n%s\n\n" % [e.subject, e.sender, e.body])
        EmailManager.mark_as_read(e.id)

func show_upgrades() -> void:
    _clear_transient()
    content.clear()
    content.append_text("[b]Upgrades[/b]\n")
    var ids := ["detector_frequency", "processing_speed", "dish_efficiency", "storage_capacity", "signal_analysis", "power_efficiency", "movement_speed", "stamina_capacity", "hunger_resistance", "sleep_resistance", "health_regeneration"]
    var row := 0
    for id in ids:
        content.append_text("%s L%d\n" % [id, GameStateManager.get_upgrade_level(id)])
        var b := Button.new()
        b.text = "Buy"
        b.position = Vector2(420, 120 + 28 * row)
        b.pressed.connect(func(upgrade_id := id):
            GameStateManager.purchase_upgrade(upgrade_id)
            show_upgrades()
        )
        add_child(b)
        transient_buttons.append(b)
        row += 1

func show_facility() -> void:
    _clear_transient()
    content.text = JSON.stringify(GameStateManager.facility_status, "\t")

func show_stats() -> void:
    _clear_transient()
    content.text = JSON.stringify(StatisticsSystem.stats, "\t")

func logout() -> void:
    UIManager.close_top()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        UIManager.close_top()
