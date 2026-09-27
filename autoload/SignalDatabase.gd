extends Node

signal signals_loaded(count: int)

const SIGNAL_DIR := "res://resources/signals/signals"
var signals: Dictionary = {}
var by_type: Dictionary = {}
var by_quality: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    load_signals()

func load_signals() -> void:
    signals.clear()
    by_type.clear()
    by_quality.clear()
    _load_dir(SIGNAL_DIR)
    signals_loaded.emit(signals.size())

func _load_dir(path: String) -> void:
    var d := DirAccess.open(path)
    if d == null:
        return
    d.list_dir_begin()
    var f := d.get_next()
    while f != "":
        if not f.begins_with("."):
            var p := "%s/%s" % [path, f]
            if d.current_is_dir():
                _load_dir(p)
            elif f.ends_with(".tres"):
                var s := load(p)
                if s is SignalData and s.id != "":
                    register_signal(s)
        f = d.get_next()
    d.list_dir_end()

func register_signal(s: SignalData) -> void:
    signals[s.id] = s
    if not by_type.has(s.object_type):
        by_type[s.object_type] = []
    if not by_quality.has(s.quality):
        by_quality[s.quality] = []
    by_type[s.object_type].append(s)
    by_quality[s.quality].append(s)

func get_signal(id: String) -> SignalData:
    return signals.get(id, null)

func filter_by_type(t: String) -> Array:
    return by_type.get(t, [])

func filter_by_quality(q: String) -> Array:
    return by_quality.get(q, [])

func get_random_signal(altitude: int, day: int = -1) -> SignalData:
    if day < 0:
        day = GameStateManager.current_day
    var seen: Array = []
    for e in GameStateManager.signal_log:
        seen.append(str(e.signal_id))
    var candidates: Array[SignalData] = []
    var total := 0.0
    for s: SignalData in signals.values():
        if s.can_spawn(day, altitude, seen):
            candidates.append(s)
            total += s.rarity_weight()
    if candidates.is_empty():
        return null
    var pick := rng.randf_range(0.0, total)
    var cur := 0.0
    for s: SignalData in candidates:
        cur += s.rarity_weight()
        if pick <= cur:
            return s
    return candidates.back()
