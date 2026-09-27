extends Node

signal interaction_prompt_changed(text: String)
signal notification_queued(text: String, kind: String)
signal damage_flash(amount: float)

var ui_layer: CanvasLayer
var ui_stack: Array[Node] = []
var hud: Node
var hud_visible := true
var current_prompt := ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
    ui_layer = CanvasLayer.new()
    ui_layer.name = "RuntimeUILayer"
    ui_layer.layer = 100
    ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
    add_child(ui_layer)
    set_mouse_capture(true)

func register_hud(n: Node) -> void:
    hud = n

func set_mouse_capture(captured: bool) -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED as Input.MouseMode if captured else Input.MOUSE_MODE_VISIBLE as Input.MouseMode

func open_scene(path: String, pause_game: bool = true) -> Node:
    if not ResourceLoader.exists(path):
        show_notification("Missing UI scene: %s" % path, "error")
        return null
    var scene := load(path) as PackedScene
    if scene == null:
        return null
    var node := scene.instantiate()
    node.process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
    ui_layer.add_child(node)
    ui_stack.append(node)
    if pause_game:
        get_tree().paused = true
    set_mouse_capture(false)
    return node

func close_top() -> void:
    if ui_stack.is_empty():
        return
    var n: Node = ui_stack.pop_back() as Node
    if is_instance_valid(n):
        n.queue_free()
    if ui_stack.is_empty():
        get_tree().paused = false
        set_mouse_capture(true)

func close_all() -> void:
    while not ui_stack.is_empty():
        close_top()

func toggle_pause_menu() -> void:
    if ui_stack.is_empty():
        open_scene("res://scenes/ui/PauseMenu.tscn", true)
    else:
        close_top()

func show_notification(text: String, kind: String = "info") -> void:
    notification_queued.emit(text, kind)
    if hud and hud.has_method("show_notification"):
        hud.show_notification(text, kind)

func set_interaction_prompt(text: String) -> void:
    if text == current_prompt:
        return
    current_prompt = text
    interaction_prompt_changed.emit(text)
    if hud and hud.has_method("set_interaction_prompt"):
        hud.set_interaction_prompt(text)

func flash_damage(amount: float) -> void:
    damage_flash.emit(amount)
    if hud and hud.has_method("flash_damage"):
        hud.flash_damage(amount)

func toggle_hud() -> void:
    hud_visible = not hud_visible
    if hud and hud is CanvasItem:
        hud.visible = hud_visible
