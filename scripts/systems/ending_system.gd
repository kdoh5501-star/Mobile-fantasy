extends Node

## 엔딩 판정 시스템

signal ending_determined(ending: Dictionary)

# 히든 엔딩 추적용
var director_ignored_count: int = 0  # 청장 무시 횟수
var natural_births: int = 0          # 복제인간 자연출산 수
var special_event_chain: int = 0     # 특수 이벤트 연쇄


## 최종 엔딩 판정
func determine_ending() -> Dictionary:
	var pop := ResourceManager.population
	var eth := ResourceManager.ethics
	var app := ResourceManager.approval
	var total_clones := ResourceManager.total_clones_produced

	# === 히든 엔딩 체크 (우선) ===

	# 1. 복제인간 혁명
	if eth <= 5 and total_clones >= 1_000_000:
		return _make_ending(
			"hidden_revolution",
			"복제인간 혁명",
			"윤리를 무시한 대가를 치르게 되었습니다.\n" +
			"수백만 복제인간들이 연대하여 '신인류 독립국'을 선언!\n" +
			"대한민국은 사실상 두 개의 나라로 분열되었습니다.\n\n" +
			"...차장님, 어느 쪽에 설 건가요?",
			"hidden"
		)

	# 2. 청장 탄핵 → 차장 승진
	if director_ignored_count >= 20:
		return _make_ending(
			"hidden_director_impeached",
			"청장 탄핵, 차장 승진",
			"끊임없이 무시당한 청장이 결국 비리가 터져 탄핵되었습니다.\n" +
			"그리고 실질적으로 모든 일을 해왔던 차장이 신임 청장으로 임명!\n\n" +
			"축하합니다. 이제 당신이 골프를 칠 차례입니다.",
			"hidden"
		)

	# 3. 자연회복 엔딩
	if natural_births >= 100_000:
		return _make_ending(
			"hidden_natural_recovery",
			"자연회복",
			"놀라운 일이 벌어졌습니다.\n" +
			"복제인간 가정에서 자연출산이 폭발적으로 증가!\n" +
			"출산율이 자연스럽게 회복되면서 복제 프로젝트는 종료되었습니다.\n\n" +
			"결국... 사랑이 답이었던 걸까요?",
			"hidden"
		)

	# 4. 외계인 엔딩 (이스터에그)
	if special_event_chain >= 5:
		return _make_ending(
			"hidden_alien",
			"???",
			"복제 기술이 극한에 도달한 그 순간,\n" +
			"하늘에서 빛이 내려왔습니다.\n\n" +
			"\"드디어 너희도 이 단계에 왔구나.\"\n" +
			"\"우리도 처음엔 복제로 시작했다.\"\n\n" +
			"...인류는 혼자가 아니었습니다.",
			"hidden"
		)

	# === 일반 엔딩 ===

	# S 엔딩
	if pop >= Constants.ENDING_S_POPULATION and eth >= Constants.ENDING_S_ETHICS and app >= Constants.ENDING_S_APPROVAL:
		return _make_ending(
			"S",
			"신인류 시대",
			"인구 %s명! 윤리와 여론 모두 최상!\n\n" % _format_number(pop) +
			"복제인간과 자연인간이 완벽하게 공존하는 사회.\n" +
			"대한민국은 세계 최초의 '통합 인류 국가'로 선언되었습니다.\n" +
			"차장님, 당신은 역사에 이름을 남겼습니다.\n\n" +
			"...청장님은 자서전에서 자기 공이라고 하겠지만요.",
			"normal"
		)

	# A 엔딩
	if pop >= Constants.ENDING_A_POPULATION and app >= Constants.ENDING_A_APPROVAL:
		return _make_ending(
			"A",
			"그럭저럭 성공",
			"인구 %s명. 목표를 달성했습니다!\n\n" % _format_number(pop) +
			"논란은 여전하지만, 인구 위기는 해결.\n" +
			"신인류청은 정식 정부 부처로 승격되었습니다.\n" +
			"차장님은... 여전히 차장입니다. 승진은 아직.\n\n" +
			"\"수고했어, 차장. 내일 골프 같이 갈래?\" - 청장",
			"normal"
		)

	# B 엔딩
	if pop >= Constants.ENDING_B_POPULATION:
		return _make_ending(
			"B",
			"아슬아슬 현상유지",
			"인구 %s명. 겨우 현상 유지입니다.\n\n" % _format_number(pop) +
			"더 나빠지진 않았지만 더 나아지지도 않았습니다.\n" +
			"신인류청의 미래는 여전히 불투명합니다.\n\n" +
			"차장님, 퇴근은 하고 계신 거죠...?",
			"normal"
		)

	# C 엔딩 (실패)
	return _make_ending(
		"C",
		"프로젝트 실패",
		"인구 %s명. 인구 위기를 해결하지 못했습니다.\n\n" % _format_number(pop) +
		"신인류청은 폐지되었고, 차장은 지방 우체국으로 좌천.\n" +
		"청장님은 어딘가에서 골프를 치고 있겠죠.\n\n" +
		"\"다음엔 로봇으로 해보는 건 어떨까...\" - 누군가의 한마디",
		"normal"
	)


func _make_ending(type: String, title: String, description: String, category: String) -> Dictionary:
	var ending: Dictionary = {
		"type": type,
		"title": title,
		"description": description,
		"category": category,
		"final_stats": {
			"population": ResourceManager.population,
			"approval": ResourceManager.approval,
			"ethics": ResourceManager.ethics,
			"tech_level": ResourceManager.tech_level,
			"total_clones": ResourceManager.total_clones_produced,
			"budget": ResourceManager.budget,
			"turns_played": GameManager.current_turn
		}
	}
	ending_determined.emit(ending)
	return ending


func track_director_ignore() -> void:
	director_ignored_count += 1


func track_natural_birth(count: int) -> void:
	natural_births += count


func track_special_event() -> void:
	special_event_chain += 1


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
