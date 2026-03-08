extends Node2D

## 메인 게임 씬 - 모든 UI와 시스템을 연결

@onready var hud: Control = $CanvasLayer/MainHUD
@onready var event_popup: Control = $CanvasLayer/EventPopup
@onready var report_popup: Control = $CanvasLayer/ReportPopup
@onready var production_panel: Control = $CanvasLayer/ProductionPanel
@onready var deployment_panel: Control = $CanvasLayer/DeploymentPanel
@onready var clone_production: Node = $Systems/CloneProduction
@onready var deployment_system: Node = $Systems/Deployment
@onready var turn_manager: Node = $Systems/TurnManager
@onready var ending_system: Node = $Systems/EndingSystem

var _pending_events: Array[Dictionary] = []
var _current_report: Dictionary = {}

# 뉴스 메시지 풀
var _news_messages := [
	"차장님, 오늘도 힘내세요!",
	"청장님이 또 골프를 치러 가셨습니다...",
	"복제인간 1호가 첫 출근했습니다!",
	"시민단체에서 항의 서한이 왔습니다.",
	"기술팀에서 새로운 발견을 보고했습니다.",
	"예산 심의가 다음 주로 예정되어 있습니다.",
	"복제인간들이 동호회를 만들었답니다.",
	"해외 언론에서 취재 요청이 왔습니다.",
	"청장님: \"오늘 저녁 회식이다!\"",
	"인사과에서 차장님 야근 수당을 문의합니다... (없음)",
]


func _ready() -> void:
	# 시스템 연결
	production_panel.set_clone_production(clone_production)
	deployment_panel.set_deployment_system(deployment_system)

	# HUD 시그널 연결
	hud.production_pressed.connect(_on_production_pressed)
	hud.deployment_pressed.connect(_on_deployment_pressed)
	hud.research_pressed.connect(_on_research_pressed)
	hud.diplomacy_pressed.connect(_on_diplomacy_pressed)
	hud.report_pressed.connect(_on_report_pressed)
	hud.next_turn_pressed.connect(_on_next_turn)

	# 이벤트 팝업 시그널
	event_popup.choice_made.connect(_on_event_choice_made)

	# 보고서 시그널
	report_popup.report_closed.connect(_on_report_closed)

	# 게임 시그널
	GameManager.turn_ended.connect(_on_turn_ended)
	GameManager.game_ended.connect(_on_game_ended)
	EventSystem.event_triggered.connect(_on_event_triggered)

	# 초기 뉴스
	hud.set_news("신인류청에 오신 것을 환영합니다, 차장님.\n대한민국의 미래가 당신의 손에 달렸습니다.")


func _on_next_turn() -> void:
	# 턴 처리
	var report := turn_manager.process_full_turn()
	_current_report = report

	# 이벤트가 있으면 먼저 처리
	var events: Array = report.get("events", [])
	_pending_events.clear()
	for event in events:
		_pending_events.append(event)

	if _pending_events.size() > 0:
		_show_next_event()
	else:
		_show_report()

	# 턴 진행
	GameManager.process_turn()


func _on_event_triggered(event_data: Dictionary) -> void:
	# 이벤트 시스템에서 직접 트리거된 이벤트
	pass


func _show_next_event() -> void:
	if _pending_events.size() > 0:
		var event := _pending_events.pop_front()
		event_popup.show_event(event)
	else:
		_show_report()


func _on_event_choice_made(_event_data: Dictionary, _choice_index: int) -> void:
	# 선택지 처리 후 다음 이벤트 또는 보고서
	# 잠시 대기 후 다음으로
	await get_tree().create_timer(0.5).timeout
	if event_popup.visible:
		# close_button을 누를 때까지 대기
		pass


func _show_report() -> void:
	report_popup.show_report(_current_report)


func _on_report_closed() -> void:
	# 보고서 닫은 후 다음 이벤트가 있으면 표시
	if _pending_events.size() > 0:
		_show_next_event()
	else:
		# 랜덤 뉴스 표시
		var news := _news_messages[randi() % _news_messages.size()]
		hud.set_news(news)
		hud.update_all()


func _on_turn_ended(_year: int, _month: int, _report: Dictionary) -> void:
	pass


func _on_game_ended(ending_type: String, ending_data: Dictionary) -> void:
	# 엔딩 또는 게임오버 처리
	var ending_event := {
		"id": "ending_%s" % ending_type,
		"type": "ending",
		"title": ending_data.get("title", "게임 종료"),
		"description": ending_data.get("description", ""),
		"choices": [
			{"text": "타이틀로 돌아가기", "effects": {}},
		]
	}
	event_popup.show_event(ending_event)
	# 타이틀로 돌아가는 처리
	event_popup.choice_made.connect(func(_ed: Dictionary, _ci: int):
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scenes/screens/title_screen.tscn")
	, CONNECT_ONE_SHOT)


func _on_production_pressed() -> void:
	production_panel.show_panel()


func _on_deployment_pressed() -> void:
	deployment_panel.show_panel()


func _on_research_pressed() -> void:
	# 간단한 연구 투자 (추후 별도 패널로 확장 가능)
	if ResourceManager.budget >= 50:
		ResourceManager.budget -= 50
		if randf() < 0.4:
			ResourceManager.tech_level += 1
			hud.set_news("연구 투자 성공! 기술 레벨이 올랐습니다! (Lv.%d)" % ResourceManager.tech_level)
		else:
			hud.set_news("연구 투자 진행 중... 아직 성과는 없습니다. (-50억 원)")
	else:
		hud.set_news("예산이 부족합니다! (연구 투자 비용: 50억 원)")


func _on_diplomacy_pressed() -> void:
	# 외교 행동 (추후 확장)
	if ResourceManager.budget >= 30:
		ResourceManager.budget -= 30
		ResourceManager.ethics += 3
		ResourceManager.approval += 2
		hud.set_news("외교 활동을 수행했습니다. 국제 사회의 시선이 조금 누그러졌습니다. (-30억 원)")
	else:
		hud.set_news("예산이 부족합니다! (외교 비용: 30억 원)")


func _on_report_pressed() -> void:
	if _current_report.size() > 0:
		report_popup.show_report(_current_report)
	else:
		hud.set_news("아직 보고할 내용이 없습니다. 첫 턴을 진행해주세요.")
