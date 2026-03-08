extends Control

## 타이틀 화면 - 카이로소프트 스타일 애니메이션

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	# 테마 적용
	theme = GameTheme.create_theme()

	# 버튼 스타일
	_style_button(start_button, Color(0.85, 0.35, 0.25))    # 빨간색 - 시작
	_style_button(continue_button, Color(0.4, 0.6, 0.75))   # 파란색 - 이어하기
	_style_button(quit_button, Color(0.5, 0.5, 0.55))       # 회색 - 종료

	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 초기 상태 - 모든 요소 숨김
	for child in vbox.get_children():
		child.modulate.a = 0
		child.position.y += 20

	# 페이드 인 + 순차적 등장 애니메이션
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.8)

	# 각 요소 순차 등장
	var delay := 0.3
	for child in vbox.get_children():
		var child_tween := create_tween()
		child_tween.set_parallel(true)
		child_tween.tween_property(child, "modulate:a", 1.0, 0.4).set_delay(delay)
		child_tween.tween_property(child, "position:y", child.position.y - 20, 0.4).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		delay += 0.12

	# 타이틀 텍스트 펄스 효과
	_start_title_pulse()


func _start_title_pulse() -> void:
	if not is_instance_valid(subtitle_label):
		return
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(subtitle_label, "theme_override_colors/font_color",
		Color(0.95, 0.3, 0.25, 1), 1.5).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(subtitle_label, "theme_override_colors/font_color",
		Color(0.85, 0.25, 0.2, 1), 1.5).set_ease(Tween.EASE_IN_OUT)


func _style_button(btn: Button, color: Color) -> void:
	var normal := GameTheme.make_colored_button(color)
	var hover := GameTheme.make_colored_button(color.lightened(0.15))
	hover.border_color = Color(1, 1, 1, 0.5)
	var pressed := GameTheme.make_colored_button(color.darkened(0.15))
	pressed.shadow_size = 0

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))


func _on_start_pressed() -> void:
	# 버튼 클릭 피드백
	start_button.disabled = true

	# 페이드 아웃
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
