extends Node
class_name EmailSystem
func inbox()->Array[EmailData]: return EmailManager.get_inbox()
