extends Node

const BUS_NAMES := ["Master", "Music", "SFX", "Ambience", "UI", "Voice"]
var current_music: AudioStreamPlayer
var current_ambience: AudioStreamPlayer

func _ready() -> void:
    for b in BUS_NAMES:
        if AudioServer.get_bus_index(b) == -1:
            var index := AudioServer.bus_count
            AudioServer.add_bus(index)
            AudioServer.set_bus_name(index, b)

func play_music(path: String, fade: float = 1.0) -> void:
    if current_music:
        current_music.queue_free()
    current_music = AudioStreamPlayer.new()
    current_music.bus = "Music"
    current_music.stream = load(path) if ResourceLoader.exists(path) else null
    add_child(current_music)
    if current_music.stream:
        current_music.play()

func stop_music(fade: float = 1.0) -> void:
    if current_music:
        current_music.queue_free()
        current_music = null

func play_sfx(path: String, volume_db: float = 0.0) -> AudioStreamPlayer:
    var p := AudioStreamPlayer.new()
    p.bus = "SFX"
    p.volume_db = volume_db
    p.stream = load(path) if ResourceLoader.exists(path) else null
    add_child(p)
    if p.stream:
        p.play()
    p.finished.connect(func(): p.queue_free())
    return p

func play_sfx_at(path: String, pos: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D:
    var p := AudioStreamPlayer3D.new()
    p.bus = "SFX"
    p.volume_db = volume_db
    p.global_position = pos
    p.stream = load(path) if ResourceLoader.exists(path) else null
    get_tree().root.add_child(p)
    if p.stream:
        p.play()
    p.finished.connect(func(): p.queue_free())
    return p

func set_bus_volume(bus: String, linear: float) -> void:
    var i := AudioServer.get_bus_index(bus)
    if i != -1:
        AudioServer.set_bus_volume_db(i, linear_to_db(clampf(linear, 0.0, 1.0)))

func get_bus_volume(bus: String) -> float:
    var i := AudioServer.get_bus_index(bus)
    return db_to_linear(AudioServer.get_bus_volume_db(i)) if i != -1 else 1.0
