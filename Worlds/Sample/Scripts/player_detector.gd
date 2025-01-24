extends Area2D


func _ready():
	body_entered.connect(_when_body_entered)
	
func _when_body_entered(body: Node2D):
	print(body.name)
	
