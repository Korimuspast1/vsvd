extends Node

signal anomaly_effect_changed(level: float, effects: Dictionary)

var anomaly_level := 0.0
var active_effects := {"vignette": 0.0, "chromatic_aberration": 0.0, "film_grain": 0.05, "glitch": 0.0, "audio_static": 0.0}
var timer := 0.0

func _process(delta: float) -> void:
    if get_tree().paused:
        return
    timer += delta
    if timer >= 30.0:
        timer = 0.0
        if anomaly_level > 0.15 and EventManager:
            EventManager.trigger_random_anomaly()

func set_level(value: float) -> void:
    anomaly_level = clampf(value, 0.0, 1.0)
    active_effects.vignette = anomaly_level
    active_effects.chromatic_aberration = maxf(0.0, anomaly_level - 0.35)
    active_effects.film_grain = 0.05 + anomaly_level * 0.35
    active_effects.glitch = maxf(0.0, anomaly_level - 0.65)
    active_effects.audio_static = maxf(0.0, anomaly_level - 0.5)
    anomaly_effect_changed.emit(anomaly_level, active_effects.duplicate(true))

func get_effect_intensity(effect_name: String) -> float:
    return float(active_effects.get(effect_name, 0.0))
