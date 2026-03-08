extends Control

## 메인 게임 HUD - 카이로소프트 스타일 UI

signal production_pressed()
signal deployment_pressed()
signal research_pressed()
signal diplomacy_pressed()
signal report_pressed()
signal next_turn_pressed()

# 상단 자원 표시
@onready var date_label: Label = $TopBar/DateLabel
@onready var budget_label: Label = $TopBar/BudgetLabel
@onready var population_label: Label = $ResourcePanel/PopulationLabel
@onready var approval_label: Label = $ResourcePanel/ApprovalLabel
@onready var ethics_label: Label = $ResourcePanel/EthicsLabel
@onready var tech_label: Label = $ResourcePanel/TechLabel
@onready var mood_label: Label = $ResourcePanel/MoodLabel

# 하단 버튼
@onready var production_btn: Button = $BottomBar/ProductionBtn
@onready var deployment_btn: Button = $BottomBar/DeploymentBtn
@onready var research_btn: Button = $BottomBar/ResearchBtn
@onready var diplomacy_btn: Button = $BottomBar/DiplomacyBtn
@onready var report_btn: Button = $BottomBar/ReportBtn
@onready var next_turn_btn: Button = $BottomBar/NextTurnBtn

# 중앙 뉴스
@onready var news_label: Label = $CenterArea/NewsLabel

# 진행률 바
@onready var progress_bar: ProgressBar = $TopBar/ProgressBar


func _ready() -> void:
	# 버튼 연결
	production_btn.pressed.connect(func(): production_pressed.emit())
	deployment_btn.pressed.connect(func(): deployment_pressed.emit())
	research_btn.pressed.connect(func(): research_pressed.emit())
	diplomacy_btn.pressed.connect(func(): diplomacy_pressed.emit())
	report_btn.pressed.connect(func(): report_pressed.emit())
	next_turn_btn.pressed.connect(func(): next_turn_pressed.emit())

	# 자원 변경 시 업데이트
	ResourceManager.resource_changed.connect(_on_resource_changed)
	ResourceManager.population_changed.connect(_on_population_changed)
	GameManager.turn_started.connect(_on_turn_started)

	# 카이로소프트 스타일 버튼 색상 적용
	_apply_button_styles()

	# 초기 표시
	update_all()


func _apply_button_styles() -> void:
	# 각 버튼에 고유 색상 + 아이콘 적용
	_style_button(production_btn, Color(0.35, 0.55, 0.8), "⚙ 생산")
	_style_button(deployment_btn, Color(0.4, 0.7, 0.4), "👥 배치")
	_style_button(research_btn, Color(0.55, 0.45, 0.75), "🔬 연구")
	_style_button(diplomacy_btn, Color(0.3, 0.65, 0.7), "🌐 외교")
	_style_button(report_btn, Color(0.7, 0.55, 0.35), "📋 보고")
	_style_button(next_turn_btn, Color(0.85, 0.45, 0.25), "▶ 다음 턴")


func _style_button(btn: Button, color: Color, label_text: String) -> void:
	btn.text = label_text
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
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.8))


func update_all() -> void:
	_update_date()
	_update_budget()
	_update_population()
	_update_approval()
	_update_ethics()
	_update_tech()
	_update_mood()
	_update_progress()


func _update_date() -> void:
	date_label.text = "📅 %s" % GameManager.get_date_string()


func _update_budget() -> void:
	budget_label.text = "💰 예산: %s억 원" % _format_number(int(ResourceManager.budget))


func _update_population() -> void:
	var pop := ResourceManager.population
	if pop >= 10_000_000:
		population_label.text = "👤 인구  %.1f백만" % (pop / 1_000_000.0)
	else:
		population_label.text = "👤 인구  %s명" % _format_number(pop)
	population_label.add_theme_color_override("font_color", GameTheme.COLOR_POPULATION)


func _update_approval() -> void:
	var app := ResourceManager.approval
	approval_label.text = "📊 여론  %.1f%%" % app
	if app >= 60:
		approval_label.add_theme_color_override("font_color", GameTheme.POSITIVE_GREEN)
	elif app >= 40:
		approval_label.add_theme_color_override("font_color", GameTheme.COLOR_APPROVAL)
	else:
		approval_label.add_theme_color_override("font_color", GameTheme.NEGATIVE_RED)


func _update_ethics() -> void:
	var eth := ResourceManager.ethics
	ethics_label.text = "⚖ 윤리  %d" % eth
	if eth >= 60:
		ethics_label.add_theme_color_override("font_color", GameTheme.COLOR_ETHICS)
	elif eth >= 30:
		ethics_label.add_theme_color_override("font_color", GameTheme.WARNING_YELLOW)
	else:
		ethics_label.add_theme_color_override("font_color", GameTheme.NEGATIVE_RED)


func _update_tech() -> void:
	tech_label.text = "🔧 기술  Lv.%d" % ResourceManager.tech_level
	tech_label.add_theme_color_override("font_color", GameTheme.COLOR_TECH)


func _update_mood() -> void:
	var mood := ResourceManager.director_mood
	var mood_text := ""
	var mood_icon := ""
	if mood >= 80:
		mood_text = "매우 좋음"
		mood_icon = "😊"
	elif mood >= 60:
		mood_text = "좋음"
		mood_icon = "🙂"
	elif mood >= 40:
		mood_text = "보통"
		mood_icon = "😐"
	elif mood >= 20:
		mood_text = "불만"
		mood_icon = "😠"
	else:
		mood_text = "격노"
		mood_icon = "😡"
	mood_label.text = "%s 청장  %s" % [mood_icon, mood_text]

	if mood >= 60:
		mood_label.add_theme_color_override("font_color", GameTheme.COLOR_MOOD)
	elif mood >= 30:
		mood_label.add_theme_color_override("font_color", GameTheme.WARNING_YELLOW)
	else:
		mood_label.add_theme_color_override("font_color", GameTheme.NEGATIVE_RED)


func _update_progress() -> void:
	progress_bar.value = GameManager.get_progress_percent()


func set_news(text: String) -> void:
	news_label.text = text
	# 뉴스 변경 시 페이드 인 효과
	news_label.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(news_label, "modulate:a", 1.0, 0.3)


func _on_resource_changed(resource_name: String, _new_value: float) -> void:
	match resource_name:
		"budget":
			_update_budget()
		"approval":
			_update_approval()
		"ethics":
			_update_ethics()
		"tech_level":
			_update_tech()
		"director_mood":
			_update_mood()


func _on_population_changed(_new_pop: int) -> void:
	_update_population()


func _on_turn_started(_year: int, _month: int) -> void:
	update_all()


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
