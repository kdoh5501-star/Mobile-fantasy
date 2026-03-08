extends Control

## 복제인간 사회 배치 패널

signal closed()

@onready var sector_list: VBoxContainer = $Panel/VBox/ScrollContainer/SectorList
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var panel: PanelContainer = $Panel

var _deployment_system: Node = null


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
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.2)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _refresh() -> void:
	for child in sector_list.get_children():
		child.queue_free()

	for sector in Constants.Sector.values():
		var sector_data: Dictionary = Constants.SECTOR_DATA[sector]
		var current: int = ResourceManager.active_clones.get(sector, 0)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)

		# 분야명 + 현재 배치 수
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 15)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(100, 0)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.text = sector_data["name"]
		header.add_child(name_label)

		var count_label := Label.new()
		count_label.custom_minimum_size = Vector2(100, 0)
		count_label.add_theme_font_size_override("font_size", 14)
		count_label.text = "배치: %s명" % _format_number(current)
		header.add_child(count_label)

		# 배치 버튼들
		var amounts: Array[int] = [100, 1000, 10000]
		for amount in amounts:
			var btn := Button.new()
			btn.text = "+%s" % _format_number(amount)
			btn.custom_minimum_size = Vector2(80, 30)
			btn.add_theme_font_size_override("font_size", 12)
			btn.pressed.connect(_on_deploy_pressed.bind(sector, amount))
			header.add_child(btn)

		vbox.add_child(header)

		# 설명
		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		desc.text = sector_data["description"]
		vbox.add_child(desc)

		# 구분선
		var sep := HSeparator.new()
		vbox.add_child(sep)

		sector_list.add_child(vbox)


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
