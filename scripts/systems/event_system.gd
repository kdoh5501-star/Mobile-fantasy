extends Node

## 이벤트 발생 및 처리 시스템

signal event_triggered(event_data: Dictionary)
signal event_resolved(event_id: String, choice_index: int, result: Dictionary)

var _event_history: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func check_events(year: int, month: int, turn: int) -> Array[Dictionary]:
	var triggered_events: Array[Dictionary] = []

	# 분기별 정기 이벤트 (3, 6, 9, 12월)
	if month % 3 == 0:
		var quarterly := _get_quarterly_event(year, month)
		if quarterly:
			triggered_events.append(quarterly)

	# 랜덤 이벤트 (매턴 30% 확률)
	if _rng.randf() < 0.30:
		var random_event := _get_random_event(year, month)
		if random_event:
			triggered_events.append(random_event)

	# 청장 돌발 이벤트 (매턴 15% 확률, 청장 기분 낮으면 증가)
	var director_chance := 0.15
	if ResourceManager.director_mood < 30:
		director_chance = 0.30
	if _rng.randf() < director_chance:
		var director_event := _get_director_event()
		if director_event:
			triggered_events.append(director_event)

	for event in triggered_events:
		event_triggered.emit(event)
		_event_history.append(event["id"])

	return triggered_events


func resolve_event(event_id: String, choice_index: int) -> Dictionary:
	var result := _apply_event_choice(event_id, choice_index)
	event_resolved.emit(event_id, choice_index, result)
	return result


# === 정기 이벤트 ===

func _get_quarterly_event(year: int, month: int) -> Dictionary:
	match month:
		3, 9:
			return {
				"id": "audit_%d_%d" % [year, month],
				"type": "quarterly",
				"title": "국정감사",
				"description": "국회에서 신인류청의 성과를 보고하라고 합니다.\n현재 인구: %s명\n여론 지지율: %.1f%%" % [_format_number(ResourceManager.population), ResourceManager.approval],
				"choices": [
					{"text": "성과를 과장해서 보고한다", "effects": {"approval": 5, "ethics": -3, "director_mood": 10}},
					{"text": "솔직하게 보고한다", "effects": {"approval": -2, "ethics": 5, "director_mood": -5}},
					{"text": "청장님께 보고를 맡긴다", "effects": {"approval": -5, "director_mood": 15, "ethics": 0}},
					{"text": "자료를 꼼꼼히 준비해 논리적으로 보고한다", "effects": {"approval": 3, "ethics": 2, "budget": 50}}
				]
			}
		6:
			return {
				"id": "press_%d" % year,
				"type": "quarterly",
				"title": "청장 기자회견",
				"description": "청장님이 기자회견에서 또 말실수를 했습니다.\n\"복제인간은 그냥 고급 로봇 아닌가요?\" 라고 발언!",
				"choices": [
					{"text": "즉시 해명 보도자료를 낸다", "effects": {"approval": -3, "ethics": 2, "director_mood": -10}},
					{"text": "청장 발언을 '유머'로 포장한다", "effects": {"approval": 2, "ethics": -5, "director_mood": 5}},
					{"text": "복제인간 대표를 불러 공동 기자회견을 연다", "effects": {"approval": 5, "ethics": 5, "director_mood": -15}},
					{"text": "언론에 다른 이슈를 흘려 묻어버린다", "effects": {"approval": 0, "ethics": -8, "director_mood": 10}}
				]
			}
		12:
			return {
				"id": "annual_%d" % year,
				"type": "quarterly",
				"title": "연말 실적 보고",
				"description": "올해의 성과를 정리할 시간입니다.\n올해 복제인간 생산: %d명\n인구 변동: %s명" % [ResourceManager.total_clones_produced, _format_number(ResourceManager.population - Constants.INITIAL_POPULATION)],
				"choices": [
					{"text": "내년 예산 증액을 요청한다", "effects": {"budget": 100, "director_mood": -5}},
					{"text": "기술 R&D 투자를 건의한다", "effects": {"tech_level": 1, "budget": -30}},
					{"text": "조용히 보고서만 제출한다", "effects": {"director_mood": 5}},
					{"text": "성과 발표회를 대대적으로 연다", "effects": {"approval": 5, "budget": -20, "director_mood": 10}}
				]
			}
	return {}


# === 랜덤 이벤트 ===

func _get_random_event(_year: int, _month: int) -> Dictionary:
	var events := _get_all_random_events()

	# 여론이 낮으면 위기 이벤트 확률 증가
	var weighted_events: Array[Dictionary] = []
	for event in events:
		if ResourceManager.approval < 40 and event.get("category") == "crisis":
			weighted_events.append(event)
			weighted_events.append(event)  # 가중치 2배
		else:
			weighted_events.append(event)

	if weighted_events.is_empty():
		return {}

	return weighted_events[_rng.randi() % weighted_events.size()]


func _get_all_random_events() -> Array[Dictionary]:
	return [
		# 위기 이벤트
		{
			"id": "protest",
			"type": "random",
			"category": "crisis",
			"title": "반복제 시위대",
			"description": "\"복제인간 반대! 자연출산 지원하라!\"\n시민단체가 청사 앞에서 시위를 시작했습니다.\n참가자: 약 5,000명",
			"choices": [
				{"text": "대화로 해결하자", "effects": {"approval": 3, "ethics": 2, "director_mood": -5}},
				{"text": "경찰에 요청하자", "effects": {"approval": -8, "ethics": -5, "director_mood": 5}},
				{"text": "청장님을 내보내자", "effects": {"approval": -3, "ethics": 0, "director_mood": -20}},
				{"text": "무시하고 업무 보자", "effects": {"approval": -5, "ethics": -2}}
			]
		},
		{
			"id": "clone_escape",
			"type": "random",
			"category": "crisis",
			"title": "복제인간 탈주",
			"description": "D등급 복제체 30명이 시설에서 집단 탈출했습니다!\n시민들 사이에서 공포가 확산되고 있습니다.",
			"choices": [
				{"text": "추적팀을 파견한다", "effects": {"budget": -20, "approval": -2, "ethics": -3}},
				{"text": "언론을 통제한다", "effects": {"approval": 0, "ethics": -10, "director_mood": 5}},
				{"text": "자진 귀환을 유도한다", "effects": {"approval": 2, "ethics": 5, "budget": -5}},
				{"text": "탈주 복제인간의 사연을 다큐로 만든다", "effects": {"approval": 8, "ethics": 3, "budget": -10}}
			]
		},
		{
			"id": "ethics_investigation",
			"type": "random",
			"category": "crisis",
			"title": "윤리위원회 감사",
			"description": "국가윤리위원회에서 신인류청에 대한 특별 감사를 실시합니다.\n서류가 좀... 깨끗하지 않은 부분이 있습니다.",
			"choices": [
				{"text": "투명하게 공개한다", "effects": {"ethics": 10, "approval": 5, "budget": -15}},
				{"text": "서류를 좀 정리(조작)한다", "effects": {"ethics": -15, "director_mood": 10}},
				{"text": "청장한테 떠넘긴다", "effects": {"director_mood": -25, "ethics": 0}},
				{"text": "윤리위원에게 로비한다", "effects": {"budget": -30, "ethics": -8, "director_mood": 5}}
			]
		},
		{
			"id": "clone_awakening",
			"type": "random",
			"category": "crisis",
			"title": "복제인간 자아각성",
			"description": "A등급 복제인간 '김복제'씨가 기자회견을 열었습니다.\n\"저는 누구인가요? 저도 인간인가요?\"\n전국이 술렁이고 있습니다.",
			"choices": [
				{"text": "복제인간 인권을 인정한다", "effects": {"ethics": 15, "approval": -5, "budget": -20}},
				{"text": "기억을 리셋한다", "effects": {"ethics": -20, "approval": 3}},
				{"text": "철학 상담사를 배치한다", "effects": {"ethics": 5, "budget": -10, "approval": 2}},
				{"text": "복제인간 인권위원회를 신설한다", "effects": {"ethics": 10, "budget": -25, "approval": 5}}
			]
		},
		{
			"id": "un_sanctions",
			"type": "random",
			"category": "crisis",
			"title": "UN 경고장",
			"description": "유엔 인권이사회에서 대한민국에 경고장을 보냈습니다.\n\"복제인간 프로그램을 즉시 중단하라\"\n국제 사회의 압력이 거세지고 있습니다.",
			"choices": [
				{"text": "외교적으로 해결한다", "effects": {"budget": -50, "ethics": 5, "approval": 3}},
				{"text": "무시한다", "effects": {"ethics": -10, "approval": -5}},
				{"text": "로비를 한다", "effects": {"budget": -80, "ethics": -5, "director_mood": 10}},
				{"text": "프로그램을 일부 축소한다", "effects": {"ethics": 8, "approval": -3}}
			]
		},
		# 일상 이벤트
		{
			"id": "clone_romance",
			"type": "random",
			"category": "daily",
			"title": "복제인간 연애",
			"description": "C등급 복제인간 두 명이 연애를 시작했습니다!\nSNS에서 \"#복제커플\" 해시태그가 트렌딩 1위입니다.\n반응이 호불호가 갈리고 있습니다.",
			"choices": [
				{"text": "축하 메시지를 보낸다", "effects": {"approval": 3, "ethics": 2}},
				{"text": "모른 척 한다", "effects": {}},
				{"text": "연애를 금지한다", "effects": {"ethics": -10, "approval": -5}},
				{"text": "복제인간 결혼 제도를 만든다", "effects": {"ethics": 5, "approval": 5, "budget": -10}}
			]
		},
		{
			"id": "clone_idol",
			"type": "random",
			"category": "daily",
			"title": "복제인간 아이돌 데뷔",
			"description": "S등급 복제인간이 아이돌 오디션에 합격했습니다!\n완벽한 외모와 실력에 팬들이 열광하고 있습니다.\n\"이건 공정한 건가?\" 논란도 일고 있습니다.",
			"choices": [
				{"text": "적극 홍보한다", "effects": {"approval": 10, "ethics": -5, "director_mood": 10}},
				{"text": "조용히 지켜본다", "effects": {"approval": 3}},
				{"text": "연예계 진출을 제한한다", "effects": {"approval": -5, "ethics": 3}},
				{"text": "복제인간 전용 리그를 만든다", "effects": {"approval": 5, "ethics": -3, "budget": -15}}
			]
		},
		{
			"id": "holiday_controversy",
			"type": "random",
			"category": "daily",
			"title": "명절 논란",
			"description": "추석 특집 뉴스:\n\"복제인간도 세뱃돈을 받나요?\"\n\"복제인간의 고향은 어디인가요?\"\n전국민적 토론이 벌어지고 있습니다.",
			"choices": [
				{"text": "복제인간 명절 가이드라인을 발표한다", "effects": {"approval": 3, "ethics": 2, "budget": -5}},
				{"text": "\"모두가 가족입니다\" 캠페인을 한다", "effects": {"approval": 5, "ethics": 5, "budget": -10}},
				{"text": "논란을 피해 묵묵히 일한다", "effects": {"director_mood": 5}},
				{"text": "복제인간 전용 명절을 제정한다", "effects": {"approval": -3, "ethics": -5}}
			]
		},
		# 기회 이벤트
		{
			"id": "genius_clone",
			"type": "random",
			"category": "opportunity",
			"title": "천재 복제인간 탄생",
			"description": "S등급 복제인간 중 IQ 200의 천재가 탄생했습니다!\n이미 양자역학 논문을 3편 발표했습니다.\n전 세계가 주목하고 있습니다.",
			"choices": [
				{"text": "연구팀에 배치한다", "effects": {"tech_level": 2, "approval": 5}},
				{"text": "자유를 준다", "effects": {"ethics": 10, "approval": 8}},
				{"text": "홍보대사로 활용한다", "effects": {"approval": 10, "director_mood": 15}},
				{"text": "비밀리에 추가 복제한다", "effects": {"tech_level": 3, "ethics": -15}}
			]
		},
		{
			"id": "foreign_deal",
			"type": "random",
			"category": "opportunity",
			"title": "해외 기술 거래 제안",
			"description": "일본에서 복제 기술 공유를 제안했습니다.\n그들도 인구 문제가 심각한 상황입니다.\n기술료 500억 원을 제안합니다.",
			"choices": [
				{"text": "거래를 수락한다", "effects": {"budget": 500, "ethics": -5, "approval": -3}},
				{"text": "거절한다", "effects": {"ethics": 3, "approval": 2}},
				{"text": "공동 연구를 제안한다", "effects": {"tech_level": 1, "budget": 200, "ethics": 0}},
				{"text": "청장님한테 결정을 맡긴다", "effects": {"director_mood": 10, "budget": 300, "ethics": -3}}
			]
		}
	]


# === 청장 돌발 이벤트 ===

func _get_director_event() -> Dictionary:
	var events: Array[Dictionary] = [
		{
			"id": "director_million",
			"type": "director",
			"title": "청장의 야심찬 목표",
			"description": "청장님이 회의실에 들어오시며 외칩니다.\n\"복제인간 100만 명! 올해 안에 가능하지?!\"\n(현재 월 생산량으로는 절대 불가능합니다)",
			"choices": [
				{"text": "\"네, 노력하겠습니다!\" (거짓말)", "effects": {"director_mood": 20, "ethics": -3}},
				{"text": "\"현실적으로 불가능합니다\"", "effects": {"director_mood": -15, "ethics": 3}},
				{"text": "\"예산을 10배로 늘려주시면요\"", "effects": {"director_mood": -5, "budget": 50}},
				{"text": "\"...네?\" (못 들은 척)", "effects": {"director_mood": -3}}
			]
		},
		{
			"id": "director_dog",
			"type": "director",
			"title": "청장의 사적 요청",
			"description": "청장님이 슬픈 눈으로 다가옵니다.\n\"우리 뽀삐가 늙어서... 복제 좀 해줘.\"\n(국가 시설을 사적으로 이용하려 합니다)",
			"choices": [
				{"text": "몰래 해준다", "effects": {"director_mood": 25, "ethics": -10}},
				{"text": "단호하게 거절한다", "effects": {"director_mood": -20, "ethics": 5}},
				{"text": "반려동물 복제 사업을 제안한다", "effects": {"budget": 30, "director_mood": 15, "approval": -3}},
				{"text": "동물병원을 추천해드린다", "effects": {"director_mood": -10, "ethics": 2}}
			]
		},
		{
			"id": "director_credit",
			"type": "director",
			"title": "공 가로채기",
			"description": "이번 분기 성과가 좋았습니다.\n청장님이 기자회견에서 말합니다.\n\"이 모든 것은 제 리더십 덕분입니다!\"\n(당신이 밤새 일한 건데...)",
			"choices": [
				{"text": "참고 넘어간다", "effects": {"director_mood": 10, "ethics": 0}},
				{"text": "뒤에서 기자에게 진실을 흘린다", "effects": {"director_mood": -15, "approval": 3}},
				{"text": "회의에서 정정한다", "effects": {"director_mood": -25, "approval": 5, "ethics": 3}},
				{"text": "\"네, 청장님 덕분입니다~\"", "effects": {"director_mood": 20, "ethics": -2}}
			]
		},
		{
			"id": "director_remodel",
			"type": "director",
			"title": "청사 리모델링",
			"description": "청장님이 인테리어 카탈로그를 들고 옵니다.\n\"우리 청사 좀 고급지게 바꾸자. 예산 200억 정도?\"\n(복제인간 연구비가 부족한 상황인데...)",
			"choices": [
				{"text": "승인한다", "effects": {"budget": -200, "director_mood": 25}},
				{"text": "거절한다", "effects": {"director_mood": -20}},
				{"text": "규모를 줄여서 제안한다", "effects": {"budget": -50, "director_mood": 5}},
				{"text": "\"감사원에서 문제 삼을 수 있습니다\"", "effects": {"director_mood": -10, "ethics": 3}}
			]
		},
		{
			"id": "director_hawaii",
			"type": "director",
			"title": "해외 출장 (하와이)",
			"description": "청장님이 \"국제 컨퍼런스 참석\"을 명목으로\n하와이 출장을 떠나셨습니다.\n3개월간 부재 예정입니다.\n(그 사이 결재가 필요한 서류가 산더미...)",
			"choices": [
				{"text": "전결 처리한다 (불법이지만 효율적)", "effects": {"ethics": -5, "director_mood": 5}},
				{"text": "청장님한테 메일을 보낸다", "effects": {"director_mood": -10}},
				{"text": "결재 없이 할 수 있는 일만 한다", "effects": {"ethics": 3, "approval": -3}},
				{"text": "이 기회에 내 마음대로 한다", "effects": {"ethics": -3, "budget": 30, "approval": 5}}
			]
		}
	]

	return events[_rng.randi() % events.size()]


func _apply_event_choice(event_id: String, choice_index: int) -> Dictionary:
	# 이 함수는 실제 이벤트 데이터에서 선택지의 effects를 적용
	# 현재는 UI에서 호출할 때 event_data를 같이 전달받아 처리
	return {"applied": true, "event_id": event_id, "choice": choice_index}


func apply_effects(effects: Dictionary) -> void:
	if effects.has("budget"):
		ResourceManager.budget += effects["budget"]
	if effects.has("approval"):
		ResourceManager.approval += effects["approval"]
	if effects.has("ethics"):
		ResourceManager.ethics += effects["ethics"]
	if effects.has("director_mood"):
		ResourceManager.director_mood += effects["director_mood"]
	if effects.has("tech_level"):
		ResourceManager.tech_level += effects["tech_level"]
	if effects.has("population"):
		ResourceManager.population += effects["population"]


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
