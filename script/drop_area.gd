extends Area2D

var is_hovered = false

func _on_mouse_entered():
	print("mouse masuk")

func _on_mouse_exited():
	is_hovered = false
