extends Node
class_name SignalGenerator
func scan(altitude:int)->SignalData:
    if GameStateManager.pending_signal_id!="": return SignalDatabase.get_signal(GameStateManager.pending_signal_id)
    return SignalDatabase.get_random_signal(altitude,GameStateManager.current_day)
