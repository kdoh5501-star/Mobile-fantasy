extends Control

## 월간 보고서 팝업 - 카이로소프트 스타일

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
	title_label.text = "📋 %d년 %d월 월간 보고서" % [year, month]

	var text := ""

	# ━━━ 인구 현황 ━━━
	text += "[b]━━━ 인구 현황 ━━━[/b]\n"
	var natural_decrease: int = report.get("natural_decrease", 0)
	var clone_output: int = report.get("clone_output", 0)
	var clones_produced: int = report.get("clones_produced", 0)
	var net: int = report.get("net_change", report.get("net_population_change", 0))

	text += "  자연감소  [color=#cc3333]-%s명[/color]\n" % _format_number(natural_decrease)
	if clone_output > 0 or clones_produced > 0:
		var produced := clone_output if clone_output > 0 else clones_produced
		text += "  복제생산  [color=#33aa33]+%s명[/color]\n" % _format_number(produced)

	if net >= 0:
		text += "  순변동    [color=#33aa33]+%s명[/color]\n" % _format_number(net)
	else:
		text += "  순변동    [color=#cc3333]%s명[/color]\n" % _format_number(net)

	text += "  현재 인구  [b]%s명[/b]\n" % _format_number(ResourceManager.population)

	# ━━━ 예산 ━━━
	text += "\n[b]━━━ 예산 현황 ━━━[/b]\n"
	var income: float = report.get("budget_income", 0)
	text += "  월 수입   [color=#cc9900]+%.0f억 원[/color]\n" % income
	text += "  보유 예산  [b]%s억 원[/b]\n" % _format_number(int(ResourceManager.budget))

	# ━━━ 종합 현황 ━━━
	text += "\n[b]━━━ 종합 현황 ━━━[/b]\n"

	# 여론
	var app := ResourceManager.approval
	var app_color := "#33aa33" if app >= 60 else ("#cc9900" if app >= 40 else "#cc3333")
	text += "  여론 지지  [color=%s]%.1f%%[/color]\n" % [app_color, app]

	# 윤리
	var eth := ResourceManager.ethics
	var eth_color := "#8866bb" if eth >= 60 else ("#cc9900" if eth >= 30 else "#cc3333")
	text += "  윤리 수치  [color=%s]%d[/color]\n" % [eth_color, eth]

	# 기술
	text += "  기술 레벨  [color=#4499bb]Lv.%d[/color]\n" % ResourceManager.tech_level

	# 청장 기분
	var mood := ResourceManager.director_mood
	var mood_text := ""
	if mood >= 80:
		mood_text = "매우 좋음"
	elif mood >= 60:
		mood_text = "좋음"
	elif mood >= 40:
		mood_text = "보통"
	elif mood >= 20:
		mood_text = "불만"
	else:
		mood_text = "격노"
	var mood_color := "#dd8833" if mood >= 40 else "#cc3333"
	text += "  청장 기분  [color=%s]%s[/color]\n" % [mood_color, mood_text]

	# 진행률
	text += "  진행률    [color=#4488aa]%.1f%%[/color]\n" % GameManager.get_progress_percent()

	# ━━━ 이벤트 ━━━
	var events: Array = report.get("events", [])
	if events.size() > 0:
		text += "\n[b]━━━ 이번 달 이벤트 ━━━[/b]\n"
		for event in events:
			text += "  ● %s\n" % event.get("title", "알 수 없는 이벤트")

	# ━━━ 생산 상세 ━━━
	var production: Array = report.get("production", [])
	if production.size() > 0:
		text += "\n[b]━━━ 생산 상세 ━━━[/b]\n"
		for prod in production:
			text += "  %s: %d명 생산" % [prod.get("name", "?"), prod.get("produced", 0)]
			var defects: int = prod.get("defects", 0)
			if defects > 0:
				text += " [color=#cc3333](결함 %d명)[/color]" % defects
			text += "\n"

	report_text.text = text

	# 등장 애니메이션
	panel.scale = Vector2(0.9, 0.9)
	panel.modulate.a = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.25).set_ease(Tween.EASE_OUT)
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
