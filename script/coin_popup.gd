extends Node2D  # Ganti dari Label ke Node2D

@onready var label: Label = $Label  # Referensi ke child Label

var move_speed: float = 50.0
var fade_speed: float = 0.5
var life_time: float = 1.0

func setup(coin_amount: int):
	if label:
		label.text = "+" + str(coin_amount)
		
		# Warna berdasarkan jumlah coin
		if coin_amount >= 50:
			label.add_theme_color_override("font_color", Color.GOLD)
			label.add_theme_font_size_override("font_size", 32)
		elif coin_amount >= 25:
			label.add_theme_color_override("font_color", Color.YELLOW)
			label.add_theme_font_size_override("font_size", 28)
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_font_size_override("font_size", 24)
		
		# Outline untuk visibility
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color.BLACK)

func _ready():
	# Animasi muncul
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Bergerak ke atas
	tween.tween_property(self, "position:y", position.y - 50, life_time)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, life_time)
	
	# Hapus setelah animasi selesai
	await tween.finished
	queue_free()
