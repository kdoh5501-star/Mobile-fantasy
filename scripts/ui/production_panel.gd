extends Control

## 복제인간 생산 패널 - 카이로소프트 스타일

signal closed()

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var facility_list: VBoxContainer = $Panel/VBox/ScrollContainer/FacilityList
@onready var summary_label: Label = $Panel/VBox/SummaryLabel
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var panel: PanelContainer = $Panel

var _clone_production: Node = null

# 등급별 색상
var _grade_colors: Array[Color] = [
	Color(0.6, 0.6, 0.6),    # D - 회색
	Color(0.4, 0.7, 0.4),    # C - 초록
	Color(0.3, 0.5, 0.8),    # B - 파란
	Color(0.7, 0.5, 0.8),    # A - 보라
	Color(0.85, 0.65, 0.15), # S - 금색
]


func _ready() -> void:
	close_button.pressed.connect(_close)
	visible = false


func set_clone_production(cp: Node) -> void:
	_clone_production = cp


func show_panel() -> void:
	visible = true
	_refresh()

	panel.scale = Vector2(0.9, 0.9)
	panel.modulate.a = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _refresh() -> void:
	for child in facility_list.get_children():
		child.queue_free()

	for grade in Constants.CloneGrade.values():
		var grade_data: Dictionary = Constants.CLONE_DATA[grade]
		var current_count: int = ResourceManager.clone_facilities.get(grade, 0)
		var grade_color: Color = _grade_colors[grade] if grade < _grade_colors.size() else Color.WHITE

		# 카드 컨테이너
		var card := PanelContainer.new()
		var card_style := GameTheme.make_resource_card(grade_color)
		card.add_theme_stylebox_override("panel", card_style)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)
		card.add_child(card_vbox)

		# 상단: 등급명 + 시설수 + 생산량
		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 12)

		var grade_name: String = ["D", "C", "B", "A", "S"][grade]
		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(140, 0)
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", grade_color.darkened(0.2))
		name_label.text = "[%s] %s" % [grade_name, grade_data["name"]]
		top_row.add_child(name_label)

		var count_label := Label.new()
		count_label.custom_minimum_size = Vector2(50, 0)
		count_label.add_theme_font_size_override("font_size", 14)
		count_label.add_theme_color_override("font_color", GameTheme.TEXT_NORMAL)
		count_label.text = "%d기" % current_count
		top_row.add_child(count_label)

		var output_label := Label.new()
		output_label.custom_minimum_size = Vector2(80, 0)
		output_label.add_theme_font_size_override("font_size", 13)
		output_label.add_theme_color_override("font_color", GameTheme.POSITIVE_GREEN)
		output_label.text = "월 %d명" % (grade_data["output"] * current_count)
		top_row.add_child(output_label)

		# 건설 버튼
		var build_btn := Button.new()
		build_btn.text = "건설 (%d억)" % _get_facility_cost(grade)
		build_btn.custom_minimum_size = Vector2(130, 32)
		build_btn.add_theme_font_size_override("font_size", 12)
		build_btn.pressed.connect(_on_build_pressed.bind(grade))

		var btn_style := GameTheme.make_colored_button(grade_color)
		build_btn.add_theme_stylebox_override("normal", btn_style)
		build_btn.add_theme_color_override("font_color", Color(1, 1, 1))

		if ResourceManager.budget < _get_facility_cost(grade):
			build_btn.disabled = true
		if current_count >= 10:
			build_btn.disabled = true
			build_btn.text = "MAX"

		top_row.add_child(build_btn)
		card_vbox.add_child(top_row)

		# 하단: 설명 + 결함률
		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", GameTheme.TEXT_LIGHT)
		desc.text = "%s | 결함률: %.0f%%" % [grade_data["description"], grade_data["defect_rate"] * 100]
		card_vbox.add_child(desc)

		facility_list.add_child(card)

	# 요약
	var total_output := ResourceManager.get_monthly_clone_output()
	var net := total_output - Constants.MONTHLY_NATURAL_DECREASE
	summary_label.text = "월 생산: %d명 | 자연감소: %d명 | 순변동: %s%d명" % [
		total_output,
		Constants.MONTHLY_NATURAL_DECREASE,
		"+" if net >= 0 else "",
		net
	]

	if net >= 0:
		summary_label.add_theme_color_override("font_color", GameTheme.POSITIVE_GREEN)
	else:
		summary_label.add_theme_color_override("font_color", GameTheme.NEGATIVE_RED)


func _get_facility_cost(grade: int) -> int:
	var base_costs: Dictionary = {0: 100, 1: 300, 2: 800, 3: 2000, 4: 5000}
	var cost: float = base_costs.get(grade, 100)
	var discount := (ResourceManager.tech_level - 1) * 0.05
	return int(cost * (1.0 - discount))


func _on_build_pressed(grade: int) -> void:
	if _clone_production:
		var result: Dictionary = _clone_production.build_facility(grade)
		if result.get("success", false):
			_refresh()


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		visible = false
		closed.emit()
	)
