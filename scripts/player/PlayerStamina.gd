extends Node
class_name PlayerStamina
func current()->float: return float(GameStateManager.needs.stamina)
func consume(v:float)->void: GameStateManager.add_stamina(-v)
func restore(v:float)->void: GameStateManager.add_stamina(v)
