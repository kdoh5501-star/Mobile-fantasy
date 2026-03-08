extends Control

## 복제인간 생산 패널 - 시설 건설 및 생산 현황

signal closed()

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var facility_list: VBoxContainer = $Panel/VBox/ScrollContainer/FacilityList
@onready var summary_label: Label = $Panel/VBox/SummaryLabel
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var panel: PanelContainer = $Panel

var _clone_production: Node = null


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
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.2)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _refresh() -> void:
	# 기존 항목 제거
	for child in facility_list.get_children():
		child.queue_free()

	# 등급별 시설 현황
	for grade in Constants.CloneGrade.values():
		var grade_data: Dictionary = Constants.CLONE_DATA[grade]
		var current_count: int = ResourceManager.clone_facilities.get(grade, 0)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		# 등급 이름
		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(120, 0)
		name_label.add_theme_font_size_override("font_size", 14)
		var grade_name: String = ["D", "C", "B", "A", "S"][grade]
		name_label.text = "[%s] %s" % [grade_name, grade_data["name"]]
		hbox.add_child(name_label)

		# 현재 시설 수
		var count_label := Label.new()
		count_label.custom_minimum_size = Vector2(60, 0)
		count_label.add_theme_font_size_override("font_size", 14)
		count_label.text = "%d기" % current_count
		hbox.add_child(count_label)

		# 월 생산량
		var output_label := Label.new()
		output_label.custom_minimum_size = Vector2(90, 0)
		output_label.add_theme_font_size_override("font_size", 13)
		output_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
		output_label.text = "월%d명" % (grade_data["output"] * current_count)
		hbox.add_child(output_label)

		# 건설 버튼
		var build_btn := Button.new()
		build_btn.text = "건설 (%d억)" % _get_facility_cost(grade)
		build_btn.custom_minimum_size = Vector2(130, 35)
		build_btn.add_theme_font_size_override("font_size", 13)
		build_btn.pressed.connect(_on_build_pressed.bind(grade))

		# 비용 부족하면 비활성화
		if ResourceManager.budget < _get_facility_cost(grade):
			build_btn.disabled = true
		if current_count >= 10:
			build_btn.disabled = true
			build_btn.text = "최대"

		hbox.add_child(build_btn)

		# 설명
		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		desc.text = "결함률: %.0f%%" % (grade_data["defect_rate"] * 100)
		hbox.add_child(desc)

		facility_list.add_child(hbox)

	# 요약
	var total_output := ResourceManager.get_monthly_clone_output()
	summary_label.text = "월간 총 생산량: %d명 | 월간 자연감소: %d명 | 순변동: %s%d명" % [
		total_output,
		Constants.MONTHLY_NATURAL_DECREASE,
		"+" if total_output >= Constants.MONTHLY_NATURAL_DECREASE else "",
		total_output - Constants.MONTHLY_NATURAL_DECREASE
	]

	if total_output >= Constants.MONTHLY_NATURAL_DECREASE:
		summary_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		summary_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))


func _get_facility_cost(grade: int) -> int:
	var base_costs := {0: 100, 1: 300, 2: 800, 3: 2000, 4: 5000}
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
