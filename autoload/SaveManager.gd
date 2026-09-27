extends Node

signal saved(slot: int)
signal loaded(slot: int)
signal save_failed(message: String)

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 10

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_path(slot: int) -> String:
    return "%s/slot_%d.save" % [SAVE_DIR, clampi(slot, 0, SLOT_COUNT - 1)]

func save_game(slot: int = 1) -> bool:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    var data := {
        "saved_at_unix": Time.get_unix_time_from_system(),
        "game": GameStateManager.to_dict(),
        "player": _capture_player_state(),
        "emails": EmailManager.to_dict() if EmailManager.has_method("to_dict") else {},
        "events": EventManager.to_dict() if EventManager.has_method("to_dict") else {},
        "achievements": AchievementManager.to_dict() if AchievementManager.has_method("to_dict") else {},
        "statistics": StatisticsSystem.to_dict() if StatisticsSystem.has_method("to_dict") else {},
    }
    var f := FileAccess.open(save_path(slot), FileAccess.WRITE)
    if f == null:
        save_failed.emit("Could not write save")
        return false
    f.store_string(JSON.stringify(data, "\t"))
    saved.emit(slot)
    if UIManager:
        UIManager.show_notification("Saved slot %d" % slot, "success")
    return true

func autosave() -> bool:
    return save_game(0)

func load_game(slot: int = 1) -> bool:
    var p := save_path(slot)
    if not FileAccess.file_exists(p):
        save_failed.emit("Empty save slot")
        return false
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
    if typeof(parsed) != TYPE_DICTIONARY:
        save_failed.emit("Corrupt save")
        return false
    GameStateManager.from_dict(parsed.get("game", {}))
    if EmailManager.has_method("from_dict"):
        EmailManager.from_dict(parsed.get("emails", {}))
    if EventManager.has_method("from_dict"):
        EventManager.from_dict(parsed.get("events", {}))
    if AchievementManager.has_method("from_dict"):
        AchievementManager.from_dict(parsed.get("achievements", {}))
    if StatisticsSystem.has_method("from_dict"):
        StatisticsSystem.from_dict(parsed.get("statistics", {}))
    _restore_player_state(parsed.get("player", {}))
    loaded.emit(slot)
    if UIManager:
        UIManager.show_notification("Loaded slot %d" % slot, "success")
    return true

func delete_save(slot: int) -> bool:
    if FileAccess.file_exists(save_path(slot)):
        DirAccess.remove_absolute(save_path(slot))
    return true

func get_save_info(slot: int) -> Dictionary:
    var p := save_path(slot)
    if not FileAccess.file_exists(p):
        return {"slot": slot, "empty": true}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
    if typeof(parsed) != TYPE_DICTIONARY:
        return {"slot": slot, "empty": false, "corrupt": true}
    var g: Dictionary = parsed.get("game", {})
    return {
        "slot": slot,
        "empty": false,
        "day": int(g.get("current_day", 1)),
        "minute": int(g.get("minute_of_day", 0)),
        "points": int(g.get("points", 0)),
        "playtime_seconds": float(g.get("playtime_seconds", 0.0)),
        "saved_at_unix": int(parsed.get("saved_at_unix", 0)),
    }

func list_saves() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for i in range(SLOT_COUNT):
        out.append(get_save_info(i))
    return out

func _capture_player_state() -> Dictionary:
    var p := get_tree().get_first_node_in_group("player")
    if p and p is Node3D:
        return {"position": var_to_str(p.global_position), "rotation": var_to_str(p.global_rotation)}
    return {}

func _restore_player_state(d: Dictionary) -> void:
    var p := get_tree().get_first_node_in_group("player")
    if p and p is Node3D:
        if d.has("position"):
            p.global_position = str_to_var(str(d.position))
        if d.has("rotation"):
            p.global_rotation = str_to_var(str(d.rotation))
