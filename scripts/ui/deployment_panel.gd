extends Control

## 복제인간 사회 배치 패널 - 카이로소프트 스타일

signal closed()

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var sector_list: VBoxContainer = $Panel/VBox/ScrollContainer/SectorList
@onready var summary_label: Label = $Panel/VBox/SummaryLabel
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var panel: PanelContainer = $Panel

var _deployment_system: Node = null

# 분야별 색상
var _sector_colors: Dictionary = {
	Constants.Sector.MANUFACTURING: Color(0.7, 0.5, 0.2),    # 제조업 - 갈색
	Constants.Sector.MILITARY: Color(0.5, 0.3, 0.3),         # 군대 - 어두운 빨강
	Constants.Sector.MEDICAL: Color(0.3, 0.65, 0.5),         # 의료 - 청록
	Constants.Sector.RESEARCH: Color(0.4, 0.5, 0.75),        # 연구 - 파란
	Constants.Sector.FAMILY: Color(0.75, 0.45, 0.6),         # 출산 장려 - 분홍
	Constants.Sector.POLITICS: Color(0.55, 0.45, 0.65),      # 정치 - 보라
}

# 분야별 아이콘 텍스트
var _sector_icons: Dictionary = {
	Constants.Sector.MANUFACTURING: "⚙",
	Constants.Sector.MILITARY: "⚔",
	Constants.Sector.MEDICAL: "✚",
	Constants.Sector.RESEARCH: "🔬",
	Constants.Sector.FAMILY: "♥",
	Constants.Sector.POLITICS: "★",
}


func _ready() -> void:
	close_button.pressed.connect(_close)
	visible = false


func set_deployment_system(ds: Node) -> void:
	_deployment_system = ds


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
	for child in sector_list.get_children():
		child.queue_free()

	var total_deployed: int = 0
	var available: int = ResourceManager.population - ResourceManager.get_total_deployed()

	for sector in Constants.Sector.values():
		var sector_data: Dictionary = Constants.SECTOR_DATA[sector]
		var current: int = ResourceManager.active_clones.get(sector, 0)
		var sector_color: Color = _sector_colors.get(sector, Color.WHITE)
		var icon_text: String = _sector_icons.get(sector, "●")
		total_deployed += current

		# 카드 컨테이너
		var card := PanelContainer.new()
		var card_style := GameTheme.make_resource_card(sector_color)
		card.add_theme_stylebox_override("panel", card_style)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)
		card.add_child(card_vbox)

		# 상단: 아이콘 + 분야명 + 현재 배치 수
		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 10)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(130, 0)
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", sector_color.darkened(0.15))
		name_label.text = "%s %s" % [icon_text, sector_data["name"]]
		top_row.add_child(name_label)

		var count_label := Label.new()
		count_label.custom_minimum_size = Vector2(90, 0)
		count_label.add_theme_font_size_override("font_size", 14)
		count_label.add_theme_color_override("font_color", GameTheme.TEXT_NORMAL)
		count_label.text = "%s명" % _format_number(current)
		top_row.add_child(count_label)

		# 배치 버튼들
		var amounts: Array[int] = [100, 1000, 10000]
		for amount in amounts:
			var btn := Button.new()
			btn.text = "+%s" % _format_number(amount)
			btn.custom_minimum_size = Vector2(75, 30)
			btn.add_theme_font_size_override("font_size", 11)
			btn.pressed.connect(_on_deploy_pressed.bind(sector, amount))

			var btn_style := GameTheme.make_colored_button(sector_color)
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_color_override("font_color", Color(1, 1, 1))

			if available < amount:
				btn.disabled = true

			top_row.add_child(btn)

		card_vbox.add_child(top_row)

		# 하단: 설명 + 효과
		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", GameTheme.TEXT_LIGHT)
		var effects_text := _get_effects_text(sector_data)
		desc.text = "%s | %s" % [sector_data["description"], effects_text]
		card_vbox.add_child(desc)

		sector_list.add_child(card)

	# 요약
	var total: int = ResourceManager.get_total_deployed()
	summary_label.text = "배치 총원: %s명 | 미배치: %s명 | 총 인구: %s명" % [
		_format_number(total),
		_format_number(ResourceManager.population - total),
		_format_number(ResourceManager.population)
	]
	summary_label.add_theme_color_override("font_color", GameTheme.TEXT_NORMAL)


func _get_effects_text(sector_data: Dictionary) -> String:
	var parts: Array[String] = []
	var budget_bonus: int = sector_data.get("budget_bonus", 0)
	var approval_change: float = sector_data.get("approval_change", 0.0)
	var ethics_change: int = sector_data.get("ethics_change", 0)

	if budget_bonus != 0:
		parts.append("예산 %s%d" % ["+" if budget_bonus > 0 else "", budget_bonus])
	if approval_change != 0.0:
		parts.append("여론 %s%.0f%%" % ["+" if approval_change > 0 else "", approval_change])
	if ethics_change != 0:
		parts.append("윤리 %s%d" % ["+" if ethics_change > 0 else "", ethics_change])

	return " ".join(parts) if parts.size() > 0 else "효과 없음"


func _on_deploy_pressed(sector: int, count: int) -> void:
	if _deployment_system:
		var result: Dictionary = _deployment_system.deploy_clones(sector, count)
		if result.get("success", false):
			_refresh()


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		visible = false
		closed.emit()
	)


func _format_number(num: int) -> String:
	var s := str(absi(num))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
