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
var _news_messages: Array[String] = [
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
	"복제인간들이 노조를 결성하려는 움직임이 있습니다.",
	"오늘의 점심: 구내식당 카레. 복제인간도 같이 먹습니다.",
	"청장님이 출장비로 스테이크를 드셨다는 제보가...",
	"복제인간 축구팀이 K-리그 참가를 신청했습니다!",
	"\"복제인간도 연말정산 하나요?\" - 국세청 문의",
	"복제인간 커뮤니티에서 '원본 따라잡기' 챌린지가 유행 중.",
	"청장님이 복제인간에게 커피 심부름을 시키다 적발.",
	"해외 석학: \"한국의 복제 기술은 50년을 앞섰다\"",
	"복제인간 3호가 대학 수능 만점을 받았습니다!",
	"청장님: \"내 복제인간은 안 만들어도 되나?\" (진지)",
	"경비팀: 오늘도 시위대 0명. 평화로운 하루입니다.",
	"복제인간 카페가 핫플레이스로 등극! 대기 2시간.",
	"기술팀 야근 중... 피자 배달 요청이 들어왔습니다.",
	"민원: \"옆집 복제인간이 노래를 너무 잘해요 (시끄러움)\"",
	"복제인간 유튜버 구독자 100만 돌파! 실버 버튼 수여.",
	"국회의원: \"차장, 이거 합법 맞아?\" / 차장: \"아마도요...\"",
	"복제인간들 사이에서 '나는 몇 번째?' 퀴즈가 유행.",
	"오늘의 전력 소비: 서울시의 3%. 전기세가 무섭습니다.",
	"복제인간 어린이집 개원! 대기 명단 이미 500명.",
	"청장님이 '복제인간과 함께하는 요가' 수업을 개설했습니다.",
]


func _ready() -> void:
	# 테마 적용
	var canvas_layer: CanvasLayer = $CanvasLayer
	for child in canvas_layer.get_children():
		if child is Control:
			child.theme = GameTheme.create_theme()

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
	event_popup.closed.connect(_on_event_popup_closed)

	# 보고서 시그널
	report_popup.report_closed.connect(_on_report_closed)

	# 게임 시그널
	GameManager.turn_ended.connect(_on_turn_ended)
	GameManager.game_ended.connect(_on_game_ended)
	EventSystem.event_triggered.connect(_on_event_triggered)

	# 초기 뉴스
	hud.set_news("🏛 【신인류청 차장 부임】\n환영합니다, 차장님!\n\n자연인구: %s명 (매월 %s명 감소 중)\n복제인간: 0명\n\n▶ '생산' 버튼으로 복제시설을 건설하세요\n▶ '연구' 버튼으로 기술을 올려 상위 등급을 해금하세요" % [
		_format_number(Constants.INITIAL_NATURAL_POPULATION),
		_format_number(Constants.MONTHLY_NATURAL_DECREASE)
	])


func _on_next_turn() -> void:
	var report: Dictionary = turn_manager.process_full_turn()
	_current_report = report

	var events: Array = report.get("events", [])
	_pending_events.clear()
	for event in events:
		_pending_events.append(event)

	if _pending_events.size() > 0:
		_show_next_event()
	else:
		_show_report()

	GameManager.process_turn()


func _on_event_triggered(event_data: Dictionary) -> void:
	pass


func _show_next_event() -> void:
	if _pending_events.size() > 0:
		var event: Dictionary = _pending_events.pop_front()
		event_popup.show_event(event)
	else:
		_show_report()


func _on_event_choice_made(_event_data: Dictionary, _choice_index: int) -> void:
	pass


func _on_event_popup_closed() -> void:
	if _pending_events.size() > 0:
		_show_next_event()
	else:
		_show_report()


func _show_report() -> void:
	report_popup.show_report(_current_report)


func _on_report_closed() -> void:
	if _pending_events.size() > 0:
		_show_next_event()
	else:
		# 랜덤 뉴스 + 현황 요약
		var news: String = _news_messages[randi() % _news_messages.size()]
		var clones := ResourceManager.clone_population
		var available := ResourceManager.get_available_clones()
		var status := "\n\n📊 복제인간: %s명 (배치가능: %s명) | 기술: Lv.%d" % [
			_format_number(clones),
			_format_number(available),
			ResourceManager.tech_level
		]
		hud.set_news(news + status)
		hud.update_all()


func _on_turn_ended(_year: int, _month: int, _report: Dictionary) -> void:
	pass


func _on_game_ended(ending_type: String, ending_data: Dictionary) -> void:
	var ending_event: Dictionary = {
		"id": "ending_%s" % ending_type,
		"type": "ending",
		"title": ending_data.get("title", "게임 종료"),
		"description": ending_data.get("description", ""),
		"choices": [
			{"text": "타이틀로 돌아가기", "effects": {}},
		]
	}
	event_popup.show_event(ending_event)
	event_popup.closed.connect(_return_to_title, CONNECT_ONE_SHOT)


func _return_to_title() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/screens/title_screen.tscn")


func _on_production_pressed() -> void:
	production_panel.show_panel()


func _on_deployment_pressed() -> void:
	if ResourceManager.clone_population <= 0:
		hud.set_news("⚠ 【배치 불가】\n아직 복제인간이 없습니다!\n'생산' 메뉴에서 시설을 건설하고 복제인간을 생산하세요.")
		return
	deployment_panel.show_panel()


func _on_research_pressed() -> void:
	var lv := ResourceManager.tech_level
	if lv >= 10:
		hud.set_news("🔬 【최대 기술 레벨】\n기술 레벨이 이미 최대(Lv.10)입니다!\n모든 복제 등급이 해금되었습니다.")
		return

	var cost := Constants.RESEARCH_BASE_COST + (lv - 1) * Constants.RESEARCH_COST_PER_LEVEL
	if ResourceManager.budget < cost:
		hud.set_news("💸 【예산 부족】\n연구 비용: %s억 원\n보유 예산: %s억 원" % [_format_number(int(cost)), _format_number(int(ResourceManager.budget))])
		return

	ResourceManager.budget -= cost

	# 성공률: 레벨 낮을수록 높음 (Lv1: 60%, Lv9: 20%)
	var success_rate := 0.65 - (lv - 1) * 0.05
	# 연구 분야에 클론 배치 시 보너스
	var research_clones: int = ResourceManager.active_clones.get(Constants.Sector.RESEARCH, 0)
	if research_clones >= 5000:
		success_rate += 0.1
	success_rate = clampf(success_rate, 0.15, 0.80)

	if randf() < success_rate:
		ResourceManager.tech_level += 1
		var new_lv := ResourceManager.tech_level
		var effect: String = Constants.TECH_EFFECTS.get(new_lv, "")
		var unlock_msg := ""
		# 새 등급 해금 체크
		for grade in Constants.CloneGrade.values():
			var req: int = Constants.GRADE_TECH_REQUIREMENT.get(grade, 99)
			if req == new_lv:
				var grade_name: String = Constants.CLONE_DATA[grade]["name"]
				unlock_msg = "\n🎉 새 등급 해금: %s!" % grade_name
		hud.set_news("🔬 【연구 성공!】\n기술 레벨 → Lv.%d\n효과: %s%s\n비용: %s억 원 | 성공률: %.0f%%" % [
			new_lv, effect, unlock_msg, _format_number(int(cost)), success_rate * 100
		])
	else:
		hud.set_news("🔬 【연구 실패...】\n아쉽지만 이번에는 성과가 없었습니다.\n비용: %s억 원 | 현재: Lv.%d | 성공률: %.0f%%\n\n💡 연구 분야에 복제인간 5,000명 이상 배치 시 성공률 +10%%" % [
			_format_number(int(cost)), lv, success_rate * 100
		])
	hud.update_all()


func _on_diplomacy_pressed() -> void:
	var cost := 30.0
	if ResourceManager.budget >= cost:
		ResourceManager.budget -= cost
		var results: Array[String] = []
		# 윤리가 낮으면 효과 증가
		var ethics_gain := 3 + (2 if ResourceManager.ethics < 40 else 0)
		var approval_gain := 2.0 + (2.0 if ResourceManager.approval < 35.0 else 0.0)
		# 복제인간 사기 회복
		var morale_gain := 3
		ResourceManager.ethics += ethics_gain
		ResourceManager.approval += approval_gain
		ResourceManager.clone_morale = clampi(ResourceManager.clone_morale + morale_gain, 0, 100)
		results.append("윤리 +%d" % ethics_gain)
		results.append("여론 +%.0f%%" % approval_gain)
		results.append("클론 사기 +%d" % morale_gain)
		hud.set_news("🌐 【외교 활동 완료】\n국제 사회와 대화를 나눴습니다.\n결과: %s\n비용: %s억 원" % [", ".join(results), _format_number(int(cost))])
	else:
		hud.set_news("💸 【예산 부족】\n외교 비용: %s억 원\n보유 예산: %s억 원" % [_format_number(int(cost)), _format_number(int(ResourceManager.budget))])
	hud.update_all()


func _on_report_pressed() -> void:
	if _current_report.size() > 0:
		report_popup.show_report(_current_report)
	else:
		hud.set_news("📋 아직 보고할 내용이 없습니다.\n첫 턴을 진행해주세요.")


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
