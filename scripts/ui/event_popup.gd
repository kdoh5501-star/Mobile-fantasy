extends Control

## 이벤트 팝업 - 카이로소프트 스타일 선택지 표시

signal choice_made(event_data: Dictionary, choice_index: int)
signal closed()

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var description_label: Label = $Panel/VBox/DescriptionLabel
@onready var choices_container: VBoxContainer = $Panel/VBox/ChoicesContainer
@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var panel: PanelContainer = $Panel

var _current_event: Dictionary = {}
var _choice_buttons: Array[Button] = []

# 이벤트 타입별 색상
var _type_colors: Dictionary = {
	"director": Color(0.85, 0.5, 0.2),      # 청장 이벤트 - 주황
	"crisis": Color(0.8, 0.25, 0.25),        # 위기 - 빨강
	"opportunity": Color(0.3, 0.65, 0.35),   # 기회 - 초록
	"random": Color(0.4, 0.55, 0.75),        # 일반 - 파란
	"ending": Color(0.7, 0.5, 0.8),          # 엔딩 - 보라
}


func _ready() -> void:
	close_button.pressed.connect(_close)
	close_button.visible = false
	result_label.visible = false
	visible = false


func show_event(event_data: Dictionary) -> void:
	_current_event = event_data
	visible = true

	# 이벤트 타입 판별
	var event_type: String = event_data.get("type", "random")
	var category: String = event_data.get("category", "")
	var color_key := event_type
	if event_type == "random" and category in ["crisis", "opportunity"]:
		color_key = category

	var title_color: Color = _type_colors.get(color_key, Color(0.4, 0.55, 0.75))
	title_label.add_theme_color_override("font_color", title_color)

	# 타입 뱃지 텍스트
	var badge := ""
	match color_key:
		"director":
			badge = "【청장 지시】"
		"crisis":
			badge = "【긴급 상황】"
		"opportunity":
			badge = "【기회 발생】"
		"ending":
			badge = "【결산】"
		_:
			badge = "【이벤트】"

	title_label.text = "%s %s" % [badge, event_data.get("title", "이벤트")]
	description_label.text = event_data.get("description", "")

	# 선택지 버튼 생성
	_clear_choices()
	var choices: Array = event_data.get("choices", [])
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, choice.get("text", "선택지")]
		btn.custom_minimum_size = Vector2(0, 42)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_choice_selected.bind(i))

		# 선택지 버튼 스타일 - 각 선택지마다 약간 다른 톤
		var btn_hue := title_color.lightened(0.1 + i * 0.05)
		var btn_style := GameTheme.make_colored_button(btn_hue)
		btn.add_theme_stylebox_override("normal", btn_style)

		var hover_style := GameTheme.make_colored_button(btn_hue.lightened(0.15))
		hover_style.border_color = Color(1, 1, 1, 0.4)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))

		choices_container.add_child(btn)
		_choice_buttons.append(btn)

	result_label.visible = false
	close_button.visible = false

	# 등장 애니메이션
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)


func _on_choice_selected(index: int) -> void:
	# 선택지 비활성화 + 애니메이션
	for i in range(_choice_buttons.size()):
		var btn := _choice_buttons[i]
		btn.disabled = true
		if i == index:
			# 선택된 버튼 강조
			btn.add_theme_color_override("font_color", Color(1, 1, 0.3))
			var pulse := create_tween()
			pulse.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
			pulse.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		else:
			# 비선택 버튼 페이드
			var fade := create_tween()
			fade.tween_property(btn, "modulate:a", 0.4, 0.2)

	# 효과 적용
	var choices: Array = _current_event.get("choices", [])
	if index < choices.size():
		var effects: Dictionary = choices[index].get("effects", {})
		EventSystem.apply_effects(effects)

		# 결과 텍스트 생성
		var result_text := _generate_result_text(effects)
		result_label.text = result_text
		result_label.visible = true

		# 결과 애니메이션
		result_label.modulate.a = 0
		var result_tween := create_tween()
		result_tween.tween_property(result_label, "modulate:a", 1.0, 0.3)

	# 확인 버튼 표시
	close_button.visible = true
	close_button.modulate.a = 0
	var close_tween := create_tween()
	close_tween.tween_property(close_button, "modulate:a", 1.0, 0.3).set_delay(0.2)

	choice_made.emit(_current_event, index)


func _generate_result_text(effects: Dictionary) -> String:
	var lines: Array[String] = ["━━━ 결과 ━━━"]

	for key in effects:
		var val = effects[key]
		var val_sign := "+" if val > 0 else ""
		match key:
			"budget":
				lines.append("  예산 %s%s억 원" % [val_sign, str(val)])
			"approval":
				lines.append("  여론 %s%.1f%%" % [val_sign, val])
			"ethics":
				lines.append("  윤리 %s%d" % [val_sign, val])
			"director_mood":
				lines.append("  청장 기분 %s%d" % [val_sign, val])
			"tech_level":
				lines.append("  기술 레벨 %s%d" % [val_sign, val])
			"population":
				lines.append("  인구 %s%d명" % [val_sign, val])

	if lines.size() == 1:
		lines.append("  (변화 없음)")

	return "\n".join(lines)


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		closed.emit()
	)


func _clear_choices() -> void:
	for btn in _choice_buttons:
		btn.queue_free()
	_choice_buttons.clear()
