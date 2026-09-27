extends Node

signal event_started(id: String)
signal event_finished(id: String)

var triggered: Dictionary = {}
var active: Dictionary = {}
var schedule: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    schedule = [
        {"id": "meteor_shower", "day": 2, "minute": 17},
        {"id": "base_blackout", "day": 4, "minute": 11},
        {"id": "vent_noise", "day": 5, "minute": 23 * 60 + 28},
        {"id": "visitor_peace_signal", "day": 6, "minute": 23 * 60},
        {"id": "first_visitor_sighting", "day": 10, "minute": 22 * 60},
        {"id": "stag_entity_encounter", "day": 15, "minute": 22 * 60},
        {"id": "null_signal", "day": 20, "minute": 12 * 60},
        {"id": "falling_cabin", "day": 30, "minute": 12 * 60},
        {"id": "final_signal", "day": 40, "minute": 8 * 60},
    ]

func check_due_events() -> void:
    for e in schedule:
        var id := str(e.id)
        if triggered.has(id):
            continue
        var due_day := int(e.day)
        var due_minute := int(e.minute)
        if GameStateManager.current_day > due_day or (GameStateManager.current_day == due_day and GameStateManager.minute_of_day >= due_minute):
            execute_event(id)

func schedule_event(id: String, day: int, minute: int) -> void:
    schedule.append({"id": id, "day": day, "minute": minute})

func execute_event(id: String) -> void:
    if triggered.has(id):
        return
    triggered[id] = true
    active[id] = true
    event_started.emit(id)
    match id:
        "meteor_shower":
            _notify("Meteor shower detected above the ridge.", "info")
            GameStateManager.add_anomaly(0.03)
        "base_blackout":
            _notify("Power surge: breakers tripped.", "warning")
            GameStateManager.facility_status.power = false
            for k in GameStateManager.facility_status.breakers.keys():
                GameStateManager.facility_status.breakers[k] = false
            GameStateManager.add_anomaly(0.05)
        "vent_noise":
            _notify("Scratching echoes from the vents.", "warning")
            GameStateManager.set_flag("vent_access_unlocked", true)
            GameStateManager.add_anomaly(0.04)
        "visitor_peace_signal":
            _notify("A visitor-band signal is ready for download.", "info")
            GameStateManager.set_pending_signal("visitor_peace")
            GameStateManager.add_anomaly(0.05)
        "first_visitor_sighting":
            _notify("A tall silhouette watches from the trees.", "warning")
            GameStateManager.set_flag("visitor_seen", true)
            GameStateManager.add_anomaly(0.05)
        "stag_entity_encounter":
            _notify("The forest has gone silent.", "error")
            GameStateManager.set_flag("stag_entity_active", true)
            GameStateManager.add_anomaly(0.08)
        "null_signal":
            _notify("Null-band interference is overriding the detector.", "error")
            GameStateManager.set_pending_signal("null_whisper")
            GameStateManager.add_anomaly(0.10)
        "falling_cabin":
            _notify("Falling object impacted beyond the ridge.", "warning")
            GameStateManager.set_flag("gravity_tool_available", true)
            GameStateManager.add_anomaly(0.12)
        "final_signal":
            _notify("Final deep-band signal available.", "error")
            GameStateManager.set_pending_signal("null_final")
            GameStateManager.add_anomaly(0.15)
        _:
            _notify("Event: %s" % id, "info")
    event_finished.emit(id)

func trigger_random_anomaly() -> String:
    if rng.randf() > GameStateManager.anomaly_meter:
        return ""
    var pool := ["sound", "visual", "object", "weather", "entity", "gravity"]
    var pick: String = pool[rng.randi_range(0, pool.size() - 1)]
    _notify("Anomaly: %s" % pick, "warning")
    GameStateManager.add_anomaly(0.01)
    return pick

func is_event_active(id: String) -> bool:
    return active.has(id)

func _notify(t: String, k: String) -> void:
    var ui := get_node_or_null("/root/UIManager")
    if ui:
        ui.show_notification(t, k)

func to_dict() -> Dictionary:
    return {"triggered": triggered, "active": active, "schedule": schedule}

func from_dict(data: Dictionary) -> void:
    triggered = data.get("triggered", {}).duplicate(true)
    active = data.get("active", {}).duplicate(true)
    schedule = data.get("schedule", schedule).duplicate(true)
