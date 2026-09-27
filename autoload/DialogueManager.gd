extends Node
signal dialogue_started(id:String)
signal dialogue_line(speaker:String,text:String)
signal dialogue_finished(id:String)
var current:DialogueData
var current_id:=""
var line_index:=0
var active:=false
func start_dialogue(id:String)->bool:
    var path:="res://resources/dialogues/%s.tres"%id
    if not ResourceLoader.exists(path): return false
    current=load(path) as DialogueData
    if current==null: return false
    current_id=id; line_index=0; active=true; dialogue_started.emit(id); _emit_line(); return true
func advance()->void:
    if not active: return
    line_index+=1
    if current==null or line_index>=current.lines.size(): end_dialogue()
    else: _emit_line()
func skip()->void: end_dialogue()
func end_dialogue()->void:
    if not active: return
    var id:=current_id; current=null; current_id=""; line_index=0; active=false; dialogue_finished.emit(id)
func _emit_line()->void:
    if current: dialogue_line.emit(current.speaker,current.lines[line_index])
