extends Node

signal day_changed(day:int)
signal time_changed(day:int, minute:int)
signal points_changed(points:int)
signal needs_changed(needs:Dictionary)
signal anomaly_changed(value:float)
signal pending_signal_changed(signal_id:String)
signal inventory_changed()
signal upgrades_changed()
signal game_over(cause:String)

const SAVE_VERSION:=1
const DAY_MINUTES:=1440
const START_MINUTE:=480
const MAX_INVENTORY_SLOTS:=40
const DEFAULT_TAPES:=3
const DIFFICULTY_RULES:={
    "easy":{"needs_decay":0.65,"points":1.35,"anomaly":0.65,"permadeath":false},
    "normal":{"needs_decay":1.0,"points":1.0,"anomaly":1.0,"permadeath":false},
    "hard":{"needs_decay":1.35,"points":0.75,"anomaly":1.35,"permadeath":false},
    "nightmare":{"needs_decay":1.75,"points":0.55,"anomaly":2.0,"permadeath":true},
}

var game_started:=true
var difficulty:="normal"
var current_day:=1
var minute_of_day:=START_MINUTE
var minute_accumulator:=0.0
var time_scale:=1.0
var points:=100
var playtime_seconds:=0.0
var needs:={"health":100.0,"hunger":100.0,"sleep":100.0,"stamina":100.0,"temperature":37.0}
var facility_status:={"power":true,"breakers":{"main":true,"lab":true,"dish":true,"living":true},"dishes":{"dish_1":"operational","dish_2":"operational","dish_3":"operational"},"computer":"operational","detector":"operational"}
var anomaly_meter:=0.0
var flags:Dictionary={}
var upgrades:Dictionary={}
var inventory:Array[Dictionary]=[]
var hotbar:Array=[]
var signal_log:Array[Dictionary]=[]
var pending_signal_id:=""
var dream_state:={"active":false,"dream_id":""}
var tape_drives:Dictionary={}

func _ready()->void:
    reset_new_game(false)

func _process(delta:float)->void:
    if not game_started or get_tree().paused: return
    playtime_seconds += delta
    advance_time(delta*time_scale)

func reset_new_game(emit_events:=true)->void:
    current_day=1
    minute_of_day=START_MINUTE
    minute_accumulator=0.0
    points=100
    playtime_seconds=0.0
    needs={"health":100.0,"hunger":100.0,"sleep":100.0,"stamina":100.0,"temperature":37.0}
    facility_status={"power":true,"breakers":{"main":true,"lab":true,"dish":true,"living":true},"dishes":{"dish_1":"operational","dish_2":"operational","dish_3":"operational"},"computer":"operational","detector":"operational"}
    anomaly_meter=0.0
    flags={}
    upgrades={}
    inventory=[]
    hotbar=[]
    signal_log=[]
    pending_signal_id=""
    dream_state={"active":false,"dream_id":""}
    tape_drives={}
    for i in range(DEFAULT_TAPES):
        var id:="TAPE-%03d" % (i+1)
        tape_drives[id]=_empty_tape(id)
    if emit_events:
        day_changed.emit(current_day)
        time_changed.emit(current_day,minute_of_day)
        points_changed.emit(points)
        needs_changed.emit(needs.duplicate(true))
        anomaly_changed.emit(anomaly_meter)
        inventory_changed.emit()
        upgrades_changed.emit()

func _empty_tape(id:String)->Dictionary:
    return {"id":id,"signal_id":"","processing_level":0,"output_data":0.0,"duplicate":false,"downloaded_day":0,"sold":false}

func difficulty_rule(key:String, fallback:Variant)->Variant:
    return DIFFICULTY_RULES.get(difficulty,DIFFICULTY_RULES["normal"]).get(key,fallback)

func advance_time(game_minutes_delta:float)->void:
    minute_accumulator += game_minutes_delta
    var whole:=int(floor(minute_accumulator))
    if whole<=0: return
    minute_accumulator -= float(whole)
    _apply_needs_decay(float(whole)/60.0)
    minute_of_day += whole
    while minute_of_day>=DAY_MINUTES:
        minute_of_day -= DAY_MINUTES
        start_new_day()
    time_changed.emit(current_day,minute_of_day)
    var email:=get_node_or_null("/root/EmailManager")
    if email: email.refresh_due_emails()
    var events:=get_node_or_null("/root/EventManager")
    if events: events.check_due_events()

func _apply_needs_decay(hours:float)->void:
    var decay:=float(difficulty_rule("needs_decay",1.0))
    needs.hunger=clampf(float(needs.hunger)-hours*decay,0.0,100.0)
    needs.sleep=clampf(float(needs.sleep)-hours*1.5*decay,0.0,100.0)
    if float(needs.hunger)<=0.0: apply_damage(hours,"starvation")
    if float(needs.sleep)<=0.0: apply_damage(hours*0.5,"sleep deprivation")
    if float(needs.hunger)>50.0 and float(needs.sleep)>50.0 and float(needs.health)>0.0:
        needs.health=clampf(float(needs.health)+hours*0.1*(1.0+get_upgrade_level("health_regeneration")*0.05),0.0,100.0)
    needs_changed.emit(needs.duplicate(true))

func start_new_day()->void:
    current_day += 1
    add_anomaly(0.01*float(difficulty_rule("anomaly",1.0)))
    day_changed.emit(current_day)
    var save:=get_node_or_null("/root/SaveManager")
    if save: save.autosave()

func get_time_string()->String: return "%02d:%02d" % [int(minute_of_day/60), minute_of_day%60]
func get_day_time_string()->String: return "Day %d — %s" % [current_day,get_time_string()]

func add_points(amount:int, reason:="")->void:
    points=maxi(0,points+amount)
    points_changed.emit(points)
    var stats:=get_node_or_null("/root/StatisticsSystem")
    if stats and amount>0: stats.increment("points_earned",amount)
    var ui:=get_node_or_null("/root/UIManager")
    if ui and reason!="": ui.show_notification("%+d pts — %s" % [amount,reason], "success" if amount>=0 else "warning")

func spend_points(amount:int, reason:="")->bool:
    if amount<=0: return true
    if points<amount:
        var ui:=get_node_or_null("/root/UIManager")
        if ui: ui.show_notification("Insufficient points","error")
        return false
    points-=amount
    points_changed.emit(points)
    var stats:=get_node_or_null("/root/StatisticsSystem")
    if stats: stats.increment("points_spent",amount)
    return true

func set_need(name:String,value:float)->void:
    if not needs.has(name): return
    needs[name]=value if name=="temperature" else clampf(value,0.0,100.0)
    needs_changed.emit(needs.duplicate(true))
func add_stamina(delta:float)->void: set_need("stamina",float(needs.stamina)+delta)
func can_sprint()->bool: return float(needs.stamina)>10.0 and get_inventory_weight()<=get_weight_limit()

func apply_damage(amount:float,cause:="damage")->void:
    if amount<=0.0: return
    needs.health=clampf(float(needs.health)-amount,0.0,100.0)
    needs_changed.emit(needs.duplicate(true))
    var ui:=get_node_or_null("/root/UIManager")
    if ui: ui.flash_damage(amount)
    if float(needs.health)<=0.0: die(cause)
func heal(amount:float)->void: set_need("health",float(needs.health)+amount)
func eat(nutrition:float,item_name:="food")->void: set_need("hunger",float(needs.hunger)+nutrition)
func sleep_hours(hours:float)->void:
    set_need("sleep",float(needs.sleep)+hours*12.5)
    advance_time(hours*60.0)
    if float(needs.sleep)<20.0 or anomaly_meter>0.55: flags.last_sleep_had_nightmare=true
func die(cause:String)->void:
    game_started=false
    game_over.emit(cause)

func add_anomaly(amount:float)->void: set_anomaly(anomaly_meter+amount)
func set_anomaly(value:float)->void:
    anomaly_meter=clampf(value,0.0,1.0)
    anomaly_changed.emit(anomaly_meter)
    var a:=get_node_or_null("/root/AnomalyManager")
    if a: a.set_level(anomaly_meter)
func set_flag(key:String,value:Variant=true)->void: flags[key]=value
func get_flag(key:String, default_value:Variant=false)->Variant: return flags.get(key,default_value)

func add_item(item_id:String,count:int=1,metadata:Dictionary={})->bool:
    if inventory.size()>=MAX_INVENTORY_SLOTS:
        var ui:=get_node_or_null("/root/UIManager")
        if ui: ui.show_notification("Inventory full","warning")
        return false
    inventory.append({"id":item_id,"count":count,"metadata":metadata.duplicate(true)})
    inventory_changed.emit()
    return true
func remove_item(item_id:String,count:int=1)->bool:
    for i in range(inventory.size()):
        if inventory[i].id==item_id:
            inventory.remove_at(i)
            inventory_changed.emit()
            return true
    return false
func has_item(item_id:String,count:int=1)->bool:
    var total:=0
    for slot in inventory:
        if slot.id==item_id: total += int(slot.get("count",1))
    return total>=count
func get_inventory_weight()->float:
    var total:=0.0
    for slot in inventory:
        var data:=_get_item_data(str(slot.id))
        if data: total += data.weight_kg*float(slot.get("count",1))
    return total
func get_weight_limit()->float: return 50.0
func _get_item_data(item_id:String)->ItemData:
    var path:="res://resources/items/items/%s.tres" % item_id
    return load(path) as ItemData if ResourceLoader.exists(path) else null

func get_upgrade_level(id:String)->int: return int(upgrades.get(id,0))
func purchase_upgrade(id:String)->bool:
    var path:="res://resources/upgrades/upgrades/%s.tres" % id
    if not ResourceLoader.exists(path): return false
    var data:=load(path) as UpgradeData
    var next:=get_upgrade_level(id)+1
    if next>data.max_level: return false
    if not spend_points(data.cost_for_level(next),"upgrade"): return false
    upgrades[id]=next
    upgrades_changed.emit()
    return true

func set_pending_signal(signal_id:String)->void:
    pending_signal_id=signal_id
    pending_signal_changed.emit(signal_id)
func has_signal_seen(signal_id:String)->bool:
    for e in signal_log:
        if e.signal_id==signal_id: return true
    for t in tape_drives.values():
        if t.signal_id==signal_id: return true
    return false
func get_empty_tape_id()->String:
    for id in tape_drives.keys():
        if str(tape_drives[id].signal_id)=="": return id
    var id:="TAPE-%03d" % (tape_drives.size()+1)
    tape_drives[id]=_empty_tape(id)
    return id
func download_pending_signal_to_tape(output_data:float)->String:
    if pending_signal_id=="": return ""
    var id:=get_empty_tape_id()
    tape_drives[id]={"id":id,"signal_id":pending_signal_id,"processing_level":0,"output_data":clampf(output_data,0.0,100.0),"duplicate":has_signal_seen(pending_signal_id),"downloaded_day":current_day,"sold":false}
    pending_signal_id=""
    pending_signal_changed.emit("")
    return id
func process_tape(id:String)->bool:
    if not tape_drives.has(id): return false
    var t:Dictionary=tape_drives[id]
    if str(t.signal_id)=="" or int(t.processing_level)>=3: return false
    t.processing_level=int(t.processing_level)+1
    tape_drives[id]=t
    var ach:=get_node_or_null("/root/AchievementManager")
    if ach: ach.unlock("first_signal")
    return true
func calculate_signal_price(signal_id:String, level:int)->int:
    var db:=get_node_or_null("/root/SignalDatabase")
    var data:SignalData=db.get_signal(signal_id) if db else null
    return data.estimated_sale_price(level) if data else 0
func sell_tape(id:String)->int:
    if not tape_drives.has(id): return -1
    var t:Dictionary=tape_drives[id]
    if str(t.signal_id)=="": return -1
    var price:=0 if bool(t.duplicate) else calculate_signal_price(str(t.signal_id),int(t.processing_level))
    price=int(round(float(price)*float(difficulty_rule("points",1.0))))
    signal_log.append({"signal_id":str(t.signal_id),"day":current_day,"level":int(t.processing_level),"output_data":float(t.output_data),"price":price})
    tape_drives[id]=_empty_tape(id)
    add_points(price,"signal sold")
    return price
func get_tape_display_name(id:String)->String:
    var t:Dictionary=tape_drives.get(id,{})
    if t.is_empty() or str(t.get("signal_id",""))=="": return "%s — Empty" % id
    return "%s — %s L%d %.0f%%" % [id,str(t.signal_id),int(t.processing_level),float(t.output_data)]

func to_dict()->Dictionary:
    return {"version":SAVE_VERSION,"difficulty":difficulty,"current_day":current_day,"minute_of_day":minute_of_day,"time_scale":time_scale,"points":points,"playtime_seconds":playtime_seconds,"needs":needs,"facility_status":facility_status,"anomaly_meter":anomaly_meter,"flags":flags,"upgrades":upgrades,"inventory":inventory,"hotbar":hotbar,"signal_log":signal_log,"pending_signal_id":pending_signal_id,"dream_state":dream_state,"tape_drives":tape_drives}
func from_dict(data:Dictionary)->void:
    difficulty=str(data.get("difficulty",difficulty))
    current_day=int(data.get("current_day",current_day))
    minute_of_day=int(data.get("minute_of_day",minute_of_day))
    time_scale=float(data.get("time_scale",time_scale))
    points=int(data.get("points",points))
    playtime_seconds=float(data.get("playtime_seconds",playtime_seconds))
    needs=data.get("needs",needs).duplicate(true)
    facility_status=data.get("facility_status",facility_status).duplicate(true)
    anomaly_meter=float(data.get("anomaly_meter",anomaly_meter))
    flags=data.get("flags",flags).duplicate(true)
    upgrades=data.get("upgrades",upgrades).duplicate(true)
    inventory=data.get("inventory",inventory).duplicate(true)
    hotbar=data.get("hotbar",hotbar).duplicate(true)
    signal_log=data.get("signal_log",signal_log).duplicate(true)
    pending_signal_id=str(data.get("pending_signal_id",pending_signal_id))
    dream_state=data.get("dream_state",dream_state).duplicate(true)
    tape_drives=data.get("tape_drives",tape_drives).duplicate(true)
    day_changed.emit(current_day)
    time_changed.emit(current_day,minute_of_day)
    points_changed.emit(points)
    needs_changed.emit(needs.duplicate(true))
    anomaly_changed.emit(anomaly_meter)
    pending_signal_changed.emit(pending_signal_id)
    inventory_changed.emit()
    upgrades_changed.emit()
