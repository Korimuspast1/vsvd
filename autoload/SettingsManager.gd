extends Node
signal settings_applied()
const SETTINGS_PATH:="user://settings.cfg"
var settings={"gameplay":{"difficulty":"normal","hud":true,"subtitles":true},"audio":{"Master":1.0,"Music":0.8,"SFX":0.9,"Ambience":0.8,"UI":0.8,"Voice":1.0,"mute_all":false},"video":{"vsync":true,"fps_limit":60,"fov":75.0},"controls":{"mouse_sensitivity":1.0,"invert_y":false},"accessibility":{"ui_scale":1.0,"screen_shake":1.0},"language":{"locale":"en"}}
func _ready()->void: load_settings(); apply_settings()
func get_setting(section:String,key:String,default_value:Variant=null)->Variant: return settings.get(section,{}).get(key,default_value)
func set_setting(section:String,key:String,value:Variant,apply_now:=true)->void:
    if not settings.has(section): settings[section]={}
    settings[section][key]=value
    if apply_now: apply_settings()
func load_settings()->void:
    var cfg:=ConfigFile.new()
    if cfg.load(SETTINGS_PATH)!=OK: return
    for s in settings.keys():
        for k in settings[s].keys(): settings[s][k]=cfg.get_value(s,k,settings[s][k])
func save_settings()->void:
    var cfg:=ConfigFile.new()
    for s in settings.keys():
        for k in settings[s].keys(): cfg.set_value(s,k,settings[s][k])
    cfg.save(SETTINGS_PATH)
func apply_settings()->void:
    GameStateManager.difficulty=str(get_setting("gameplay","difficulty","normal"))
    InputManager.mouse_sensitivity=float(get_setting("controls","mouse_sensitivity",1.0)); InputManager.invert_y=bool(get_setting("controls","invert_y",false))
    for bus in ["Master","Music","SFX","Ambience","UI","Voice"]:
        var v:=0.0 if bool(get_setting("audio","mute_all",false)) else float(get_setting("audio",bus,1.0))
        AudioManager.set_bus_volume(bus,v)
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_setting("video","vsync",true)) else DisplayServer.VSYNC_DISABLED)
    Engine.max_fps=int(get_setting("video","fps_limit",60)); settings_applied.emit()
