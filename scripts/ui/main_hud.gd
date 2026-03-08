extends Control

## 메인 게임 HUD - 상단 자원바 + 하단 메뉴 + 중앙 뉴스 표시

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

	# 초기 표시
	update_all()


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
	date_label.text = GameManager.get_date_string()


func _update_budget() -> void:
	budget_label.text = "예산: %.0f억 원" % ResourceManager.budget


func _update_population() -> void:
	var pop := ResourceManager.population
	if pop >= 10_000_000:
		population_label.text = "인구: %.1f백만" % (pop / 1_000_000.0)
	else:
		population_label.text = "인구: %s명" % _format_number(pop)


func _update_approval() -> void:
	var app := ResourceManager.approval
	approval_label.text = "여론: %.1f%%" % app
	# 색상 변경
	if app >= 60:
		approval_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif app >= 40:
		approval_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	else:
		approval_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))


func _update_ethics() -> void:
	var eth := ResourceManager.ethics
	ethics_label.text = "윤리: %d" % eth
	if eth >= 60:
		ethics_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.9))
	elif eth >= 30:
		ethics_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	else:
		ethics_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))


func _update_tech() -> void:
	tech_label.text = "기술: Lv.%d" % ResourceManager.tech_level


func _update_mood() -> void:
	mood_label.text = "청장: %s" % ResourceManager.get_director_mood_emoji()


func _update_progress() -> void:
	progress_bar.value = GameManager.get_progress_percent()


func set_news(text: String) -> void:
	news_label.text = text


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
