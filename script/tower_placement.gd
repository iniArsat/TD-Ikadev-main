extends Area2D

var is_occupied = false
var current_tower = null

func _on_body_entered(body: Node2D):
	if body.is_in_group("tower") and not is_occupied:
		is_occupied = true
		current_tower = body
		print("Tower placed in area")

func _on_body_exited(body: Node2D):
	if body == current_tower:
		is_occupied = false
		current_tower = null
		print("Tower removed from area")

func is_available() -> bool:
	return not is_occupied
