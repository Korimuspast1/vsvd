extends Resource
class_name SignalData
@export var id:String=""
@export var display_name:String="Unnamed Signal"
@export var object_type:String="Object"
@export var quality:String="Average"
@export var frequency_band:String="Average"
@export var base_price:int=5
@export var rarity:String="common"
@export var min_day:int=1
@export var unique:bool=false
@export var altitude_bands:Array[int]=[50,100]
@export_range(0.0,1.0,0.001) var target_frequency:float=0.5
@export_range(-1.0,1.0,0.001) var target_polarity:float=0.0
@export var spectrogram_path:String=""
@export var audio_path:String=""
@export_multiline var decoded_text:String=""
@export var lore_tags:Array[String]=[]
func quality_multiplier()->float:
    match quality.to_lower():
        "very low": return 0.4
        "low": return 0.8
        "average": return 1.0
        "good": return 1.2
        "high": return 1.6
        "very high": return 1.8
        "unknown": return 1.25
        _: return 1.0
func processing_multiplier(level:int)->float:
    match clampi(level,0,3):
        0: return 0.4
        1: return 0.6
        2: return 0.8
        _: return 1.0
func estimated_sale_price(level:int)->int:
    return maxi(0,int(round(float(base_price)*quality_multiplier()*processing_multiplier(level))))
func rarity_weight()->float:
    match rarity.to_lower():
        "common": return 60.0
        "uncommon": return 25.0
        "rare": return 10.0
        "very_rare", "very rare": return 4.0
        "legendary": return 1.0
        _: return 5.0
func can_spawn(day:int, altitude:int, seen:Array=[])->bool:
    if day < min_day: return false
    if unique and id in seen: return false
    return altitude_bands.is_empty() or altitude in altitude_bands
