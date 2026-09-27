extends Node
class_name WeatherSystem

signal weather_changed(weather: String)

var current_weather := "cloudy"

func set_weather(w: String) -> void:
    current_weather = w
    weather_changed.emit(w)

func randomize_weather() -> void:
    var options := ["clear", "cloudy", "rain", "fog", "storm", "snow"]
    set_weather(options.pick_random())
