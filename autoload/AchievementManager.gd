extends Node

signal achievement_unlocked(id: String)

const ACH_DIR := "res://resources/achievements/achievements"
var achievements: Dictionary = {}
var unlocked: Dictionary = {}

func _ready() -> void:
    load_achievements()

func load_achievements() -> void:
    achievements.clear()
    var d := DirAccess.open(ACH_DIR)
    if d == null:
        return
    d.list_dir_begin()
    var f := d.get_next()
    while f != "":
        if f.ends_with(".tres"):
            var a := load("%s/%s" % [ACH_DIR, f]) as AchievementData
            if a and a.id != "":
                achievements[a.id] = a
        f = d.get_next()
    d.list_dir_end()

func unlock(id: String) -> void:
    if unlocked.has(id):
        return
    unlocked[id] = Time.get_unix_time_from_system()
    achievement_unlocked.emit(id)
    if UIManager:
        var label: String = id
        if achievements.has(id):
            var data: AchievementData = achievements[id] as AchievementData
            if data:
                label = data.display_name
        UIManager.show_notification("Achievement: %s" % label, "success")

func is_unlocked(id: String) -> bool:
    return unlocked.has(id)

func to_dict() -> Dictionary:
    return {"unlocked": unlocked}

func from_dict(data: Dictionary) -> void:
    unlocked = data.get("unlocked", {}).duplicate(true)
