extends Node
class_name PlayerNeeds
func eat(nutrition:float,name:="food")->void: GameStateManager.eat(nutrition,name)
func sleep(hours:float)->void: GameStateManager.sleep_hours(hours)
func damage(amount:float,cause:="damage")->void: GameStateManager.apply_damage(amount,cause)
