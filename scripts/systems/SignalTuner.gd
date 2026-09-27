extends RefCounted
class_name SignalTuner
static func tolerance_for_band(band:String)->float:
    match band.to_lower():
        "very low", "low": return 0.10
        "below average", "average": return 0.05
        "above average", "high": return 0.02
        "very high": return 0.01
        _: return 0.03
static func calculate_output(signal_data:SignalData, frequency:float, polarity:float, upgrade_level:int=0)->float:
    if signal_data==null: return 0.0
    var tol:=tolerance_for_band(signal_data.frequency_band)*(1.0+upgrade_level*0.08)
    var f_error:=abs(signal_data.target_frequency-frequency)
    var p_error:=abs(signal_data.target_polarity-polarity)/2.0
    var score:=1.0-clampf((f_error+p_error)/(tol*2.0),0.0,1.0)
    return clampf(score*100.0,0.0,100.0)
