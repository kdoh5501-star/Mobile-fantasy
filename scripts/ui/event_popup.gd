extends Control

## 이벤트 팝업 - 선택지를 표시하고 결과를 반환

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


func _ready() -> void:
	close_button.pressed.connect(_close)
	close_button.visible = false
	result_label.visible = false
	visible = false


func show_event(event_data: Dictionary) -> void:
	_current_event = event_data
	visible = true

	# 이벤트 타입에 따른 타이틀 색상
	match event_data.get("type", ""):
		"director":
			title_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
		"random":
			match event_data.get("category", ""):
				"crisis":
					title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
				"opportunity":
					title_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
				_:
					title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
		_:
			title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))

	title_label.text = event_data.get("title", "이벤트")
	description_label.text = event_data.get("description", "")

	# 선택지 버튼 생성
	_clear_choices()
	var choices: Array = event_data.get("choices", [])
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, choice.get("text", "선택지")]
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(btn)
		_choice_buttons.append(btn)

	result_label.visible = false
	close_button.visible = false

	# 등장 애니메이션
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)


func _on_choice_selected(index: int) -> void:
	# 선택지 비활성화
	for btn in _choice_buttons:
		btn.disabled = true

	# 선택된 버튼 강조
	if index < _choice_buttons.size():
		_choice_buttons[index].add_theme_color_override("font_color", Color(1, 1, 0.3))

	# 효과 적용
	var choices: Array = _current_event.get("choices", [])
	if index < choices.size():
		var effects: Dictionary = choices[index].get("effects", {})
		EventSystem.apply_effects(effects)

		# 결과 텍스트 생성
		var result_text := _generate_result_text(effects)
		result_label.text = result_text
		result_label.visible = true

	close_button.visible = true
	choice_made.emit(_current_event, index)


func _generate_result_text(effects: Dictionary) -> String:
	var lines: Array[String] = ["--- 결과 ---"]

	for key in effects:
		var val = effects[key]
		var sign := "+" if val > 0 else ""
		match key:
			"budget":
				lines.append("예산 %s%s억 원" % [sign, str(val)])
			"approval":
				lines.append("여론 %s%.1f%%" % [sign, val])
			"ethics":
				lines.append("윤리 %s%d" % [sign, val])
			"director_mood":
				lines.append("청장 기분 %s%d" % [sign, val])
			"tech_level":
				lines.append("기술 레벨 %s%d" % [sign, val])
			"population":
				lines.append("인구 %s%d명" % [sign, val])

	if lines.size() == 1:
		lines.append("(변화 없음)")

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
