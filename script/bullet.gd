extends Area2D

@export var speed = 0.0
@export var damage = 0.0
@export var rotation_speed = 5.0  # semakin tinggi, semakin cepat belok
var target: Node2D = null
@export var freeze_duration = 0.0
@export var blind_duration = 0.0


func _process(delta):
	if not is_instance_valid(target):
		queue_free()
		return
	var dir = (target.global_position - global_position).normalized()
	var desired_angle = dir.angle()
	rotation = lerp_angle(rotation, desired_angle, rotation_speed * delta)
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_freeze"):
			body.apply_freeze(freeze_duration)
		if body.has_method("apply_blind"):  # EFEK BARU
			body.apply_blind(blind_duration)
		queue_free()

func set_blind_duration(duration: float):
	blind_duration = duration
	
func reverse_direction():
	rotation += PI  # Balik arah 180 derajat

# Method untuk increase damage
func increase_damage(new_damage: float):
	damage = new_damage
