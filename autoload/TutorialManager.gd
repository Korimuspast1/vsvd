extends Node
signal tutorial_step_changed(index:int,text:String)
signal tutorial_completed(id:String)
var steps=["Wake up and check needs.","Read terminal email.","Scan at the coordinate panel.","Tune the detector above 95% output.","Download to tape.","Process and sell the signal.","Sleep to start the next day."]
var current_step:=-1
var completed:=false
func start_tutorial()->void: current_step=0; completed=false; tutorial_step_changed.emit(current_step,steps[current_step])
func advance_step()->void:
    if completed: return
    current_step+=1
    if current_step >= steps.size():
        completed = true
        tutorial_completed.emit("intro")
        GameStateManager.add_points(100, "tutorial complete")
    else:
        tutorial_step_changed.emit(current_step, steps[current_step])
func skip()->void: completed=true; tutorial_completed.emit("intro")
