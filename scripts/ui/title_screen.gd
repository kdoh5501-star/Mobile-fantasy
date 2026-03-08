extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 페이드 인
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.5)


func _on_start_pressed() -> void:
	# 페이드 아웃 후 게임 시작
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.8)
	tween.tween_callback(_start_game)


func _start_game() -> void:
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/main/main_game.tscn")


func _on_continue_pressed() -> void:
	# TODO: 세이브 로드
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
