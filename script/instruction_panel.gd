extends Panel

signal instruction_completed
signal skip_instructions

@onready var continue_button: Button = $ContinueButton
@onready var skip_button: Button = $SkipButton
@onready var page1: Panel = $Page1
@onready var page2: Panel = $Page2

func _ready():
	page1.visible = true
	page2.visible = false
	GameSpeedManager.set_game_speed(0.0)

func _on_continue_pressed():
	if page1.visible:
		# Pindah ke page 2
		page1.visible = false
		page2.visible = true
	else:
		GameSpeedManager.set_game_speed(1.0)
		instruction_completed.emit()

func _on_skip_pressed():
	GameSpeedManager.set_game_speed(1.0)
	skip_instructions.emit()
