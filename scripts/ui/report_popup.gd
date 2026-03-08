extends Control

## 월간 보고서 팝업

signal report_closed()

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var report_text: RichTextLabel = $Panel/VBox/ReportText
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var panel: PanelContainer = $Panel


func _ready() -> void:
	close_button.pressed.connect(_close)
	visible = false


func show_report(report: Dictionary) -> void:
	visible = true

	var year: int = report.get("year", 0)
	var month: int = report.get("month", 0)
	title_label.text = "%d년 %d월 보고서" % [year, month]

	var text := ""

	# 인구 변동
	text += "[b]=== 인구 현황 ===[/b]\n"
	var natural_decrease: int = report.get("natural_decrease", 0)
	var clone_output: int = report.get("clone_output", 0)
	var clones_produced: int = report.get("clones_produced", 0)
	var net: int = report.get("net_change", report.get("net_population_change", 0))

	text += "자연감소: [color=red]-%s명[/color]\n" % _format_number(natural_decrease)
	if clone_output > 0 or clones_produced > 0:
		var produced := clone_output if clone_output > 0 else clones_produced
		text += "복제생산: [color=green]+%s명[/color]\n" % _format_number(produced)
	text += "순변동: %s%s명\n" % ["[color=green]+" if net >= 0 else "[color=red]", _format_number(net)]
	if net >= 0:
		text += "[/color]\n"
	else:
		text += "[/color]\n"
	text += "현재 인구: [b]%s명[/b]\n" % _format_number(ResourceManager.population)

	# 예산
	text += "\n[b]=== 예산 ===[/b]\n"
	var income: float = report.get("budget_income", 0)
	text += "이번 달 수입: +%.0f억 원\n" % income
	text += "현재 예산: [b]%.0f억 원[/b]\n" % ResourceManager.budget

	# 현재 자원
	text += "\n[b]=== 종합 현황 ===[/b]\n"
	text += "여론 지지율: %.1f%%\n" % ResourceManager.approval
	text += "윤리 게이지: %d\n" % ResourceManager.ethics
	text += "기술 레벨: Lv.%d\n" % ResourceManager.tech_level
	text += "청장 기분: %s\n" % ResourceManager.get_director_mood_emoji()
	text += "진행률: %.1f%%\n" % GameManager.get_progress_percent()

	# 이벤트
	var events: Array = report.get("events", [])
	if events.size() > 0:
		text += "\n[b]=== 이번 달 이벤트 ===[/b]\n"
		for event in events:
			text += "- %s\n" % event.get("title", "알 수 없는 이벤트")

	# 생산 상세
	var production: Array = report.get("production", [])
	if production.size() > 0:
		text += "\n[b]=== 생산 상세 ===[/b]\n"
		for prod in production:
			text += "%s: %d명 생산" % [prod.get("name", "?"), prod.get("produced", 0)]
			var defects: int = prod.get("defects", 0)
			if defects > 0:
				text += " ([color=red]결함 %d명[/color])" % defects
			text += "\n"

	report_text.text = text

	# 등장 애니메이션
	panel.scale = Vector2(0.9, 0.9)
	panel.modulate.a = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.2)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		visible = false
		report_closed.emit()
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
	if num < 0:
		result = "-" + result
	return result
