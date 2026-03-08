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
	var nat := ResourceManager.natural_population
	var clones := ResourceManager.clone_population
	var total := nat + clones

	text += "  자연인구  [color=#5588cc]%s명[/color]\n" % _format_number(nat)
	text += "  복제인간  [color=#cc8833]%s명[/color]\n" % _format_number(clones)
	text += "  총 인구   [b]%s명[/b]\n" % _format_number(total)

	var natural_decrease: int = report.get("natural_decrease", 0)
	var clones_produced: int = report.get("clones_produced", 0)
	var clone_deaths: int = report.get("clone_deaths", 0)
	var net: int = report.get("net_population_change", 0)

	text += "\n  자연감소  [color=#cc3333]-%s명[/color] (저출산·고령화)\n" % _format_number(natural_decrease)
	if clones_produced > 0:
		text += "  복제생산  [color=#33aa33]+%s명[/color]\n" % _format_number(clones_produced)
	if clone_deaths > 0:
		text += "  클론사망  [color=#cc6633]-%s명[/color] (수명만료)\n" % _format_number(clone_deaths)

	if net >= 0:
		text += "  순변동    [color=#33aa33]+%s명[/color]\n" % _format_number(net)
	else:
		text += "  순변동    [color=#cc3333]%s명[/color]\n" % _format_number(net)

	# ━━━ 예산 ━━━
	text += "\n[b]━━━ 예산 현황 ━━━[/b]\n"
	var income: float = report.get("budget_income", 0)
	text += "  월 수입   [color=#cc9900]+%.0f억 원[/color]\n" % income
	text += "  보유 예산  [b]%s억 원[/b]\n" % _format_number(int(ResourceManager.budget))

	# ━━━ 종합 현황 ━━━
	text += "\n[b]━━━ 종합 현황 ━━━[/b]\n"

	var app := ResourceManager.approval
	var app_color := "#33aa33" if app >= 60 else ("#cc9900" if app >= 40 else "#cc3333")
	text += "  여론 지지  [color=%s]%.1f%%[/color]\n" % [app_color, app]

	var eth := ResourceManager.ethics
	var eth_color := "#8866bb" if eth >= 60 else ("#cc9900" if eth >= 30 else "#cc3333")
	text += "  윤리 수치  [color=%s]%d[/color]\n" % [eth_color, eth]

	text += "  기술 레벨  [color=#4499bb]Lv.%d[/color]" % ResourceManager.tech_level
	var tech_effect: String = Constants.TECH_EFFECTS.get(ResourceManager.tech_level, "")
	if tech_effect != "":
		text += " (%s)" % tech_effect
	text += "\n"

	var mood := ResourceManager.director_mood
	var mood_text := "매우 좋음" if mood >= 80 else ("좋음" if mood >= 60 else ("보통" if mood >= 40 else ("불만" if mood >= 20 else "격노")))
	var mood_color := "#dd8833" if mood >= 40 else "#cc3333"
	text += "  청장 기분  [color=%s]%s[/color]\n" % [mood_color, mood_text]

	# 복제인간 사기
	var morale: int = report.get("clone_morale", ResourceManager.clone_morale)
	var morale_color := "#33aa33" if morale >= 60 else ("#cc9900" if morale >= 30 else "#cc3333")
	if clones > 0:
		text += "  클론 사기  [color=%s]%d[/color]\n" % [morale_color, morale]

	if report.get("clone_unrest", false):
		text += "  [color=#cc3333]⚠ 복제인간 불만 폭발! 여론·윤리 하락 중[/color]\n"

	# 배치 현황
	var deployed := ResourceManager.get_total_deployed()
	if deployed > 0:
		text += "\n  배치 현황  %s명 / %s명 복제인간\n" % [_format_number(deployed), _format_number(clones)]

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
			var reason: String = prod.get("reason", "")
			if reason != "":
				text += "  %s: [color=#cc3333]%s[/color]\n" % [prod.get("name", "?"), reason]
			else:
				text += "  %s: %s명 생산" % [prod.get("name", "?"), _format_number(prod.get("produced", 0))]
				var defects: int = prod.get("defects", 0)
				if defects > 0:
					text += " [color=#cc3333](결함 %s명)[/color]" % _format_number(defects)
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
