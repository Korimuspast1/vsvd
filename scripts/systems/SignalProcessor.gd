extends Node
class_name SignalProcessor
func processing_time_seconds()->float: return maxf(2.0,10.0-GameStateManager.get_upgrade_level("processing_speed")*0.8)
func process(tape_id:String)->bool: return GameStateManager.process_tape(tape_id)
