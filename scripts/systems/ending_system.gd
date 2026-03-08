extends Node

## 엔딩 판정 시스템

signal ending_determined(ending: Dictionary)

# 히든 엔딩 추적용
var director_ignored_count: int = 0
var natural_births: int = 0
var special_event_chain: int = 0


## 최종 엔딩 판정
func determine_ending() -> Dictionary:
	var total_pop := ResourceManager.get_total_population()
	var nat_pop := ResourceManager.natural_population
	var clone_pop := ResourceManager.clone_population
	var eth := ResourceManager.ethics
	var app := ResourceManager.approval
	var total_clones := ResourceManager.total_clones_produced
	var clone_ratio := float(clone_pop) / float(max(total_pop, 1))

	# === 히든 엔딩 체크 (우선) ===

	# 1. 복제인간 혁명 (윤리 바닥 + 대량 복제)
	if eth <= 5 and total_clones >= 1_000_000:
		return _make_ending(
			"hidden_revolution",
			"🔥 복제인간 혁명",
			"윤리를 무시한 대가를 치르게 되었습니다.\n" +
			"수백만 복제인간들이 연대하여 '신인류 독립국'을 선언!\n" +
			"대한민국은 사실상 두 개의 나라로 분열되었습니다.\n\n" +
			"최종 인구: 자연인 %s명 + 복제인 %s명\n\n" % [_format_number(nat_pop), _format_number(clone_pop)] +
			"...차장님, 어느 쪽에 설 건가요?",
			"hidden"
		)

	# 2. 청장 탄핵 → 차장 승진
	if director_ignored_count >= 20:
		return _make_ending(
			"hidden_director_impeached",
			"👔 청장 탄핵, 차장 승진",
			"끊임없이 무시당한 청장이 결국 비리가 터져 탄핵되었습니다.\n" +
			"그리고 실질적으로 모든 일을 해왔던 차장이 신임 청장으로 임명!\n\n" +
			"축하합니다. 이제 당신이 골프를 칠 차례입니다.",
			"hidden"
		)

	# 3. 자연회복 엔딩 (가정 분야 배치로 자연출산 증가)
	if natural_births >= 50_000:
		return _make_ending(
			"hidden_natural_recovery",
			"🌱 자연회복",
			"놀라운 일이 벌어졌습니다.\n" +
			"복제인간 가정에서 자연출산이 폭발적으로 증가!\n" +
			"출산율이 자연스럽게 회복되면서 복제 프로젝트는 종료되었습니다.\n\n" +
			"결국... 사랑이 답이었던 걸까요?",
			"hidden"
		)

	# 4. 복제인간 지배 엔딩 (클론이 인구의 80% 이상)
	if clone_ratio >= 0.8 and total_pop >= Constants.ENDING_A_POPULATION:
		return _make_ending(
			"hidden_clone_dominance",
			"🤖 신인류의 시대",
			"자연인 %s명, 복제인 %s명.\n\n" % [_format_number(nat_pop), _format_number(clone_pop)] +
			"인구의 %.0f%%가 복제인간인 세상.\n" % (clone_ratio * 100) +
			"그들은 더 이상 '복제'인간이 아닙니다.\n" +
			"그들이 새로운 주류이며, 자연인간이 소수자가 되었습니다.\n\n" +
			"이것이... 당신이 원했던 미래인가요?",
			"hidden"
		)

	# 5. 외계인 엔딩 (이스터에그)
	if special_event_chain >= 5:
		return _make_ending(
			"hidden_alien",
			"👽 ???",
			"복제 기술이 극한에 도달한 그 순간,\n" +
			"하늘에서 빛이 내려왔습니다.\n\n" +
			"\"드디어 너희도 이 단계에 왔구나.\"\n" +
			"\"우리도 처음엔 복제로 시작했다.\"\n\n" +
			"...인류는 혼자가 아니었습니다.",
			"hidden"
		)

	# === 일반 엔딩 ===

	# S 엔딩
	if total_pop >= Constants.ENDING_S_POPULATION and eth >= Constants.ENDING_S_ETHICS and app >= Constants.ENDING_S_APPROVAL:
		return _make_ending(
			"S",
			"⭐ 신인류 시대 (S랭크)",
			"총 인구 %s명! (자연인 %s + 복제인 %s)\n" % [_format_number(total_pop), _format_number(nat_pop), _format_number(clone_pop)] +
			"윤리 %d, 여론 %.1f%%! 완벽한 성과!\n\n" % [eth, app] +
			"복제인간과 자연인간이 완벽하게 공존하는 사회.\n" +
			"대한민국은 세계 최초의 '통합 인류 국가'로 선언되었습니다.\n" +
			"차장님, 당신은 역사에 이름을 남겼습니다.\n\n" +
			"...청장님은 자서전에서 자기 공이라고 하겠지만요.",
			"normal"
		)

	# A 엔딩
	if total_pop >= Constants.ENDING_A_POPULATION and app >= Constants.ENDING_A_APPROVAL:
		return _make_ending(
			"A",
			"🏆 그럭저럭 성공 (A랭크)",
			"총 인구 %s명. 목표를 달성했습니다!\n\n" % _format_number(total_pop) +
			"논란은 여전하지만, 인구 위기는 해결.\n" +
			"신인류청은 정식 정부 부처로 승격되었습니다.\n" +
			"차장님은... 여전히 차장입니다. 승진은 아직.\n\n" +
			"\"수고했어, 차장. 내일 골프 같이 갈래?\" - 청장",
			"normal"
		)

	# B 엔딩
	if total_pop >= Constants.ENDING_B_POPULATION:
		return _make_ending(
			"B",
			"📊 아슬아슬 현상유지 (B랭크)",
			"총 인구 %s명. 겨우 현상 유지입니다.\n\n" % _format_number(total_pop) +
			"더 나빠지진 않았지만 더 나아지지도 않았습니다.\n" +
			"신인류청의 미래는 여전히 불투명합니다.\n\n" +
			"차장님, 퇴근은 하고 계신 거죠...?",
			"normal"
		)

	# C 엔딩 (실패)
	return _make_ending(
		"C",
		"💀 프로젝트 실패 (C랭크)",
		"총 인구 %s명. 인구 위기를 해결하지 못했습니다.\n\n" % _format_number(total_pop) +
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
			"natural_population": ResourceManager.natural_population,
			"clone_population": ResourceManager.clone_population,
			"total_population": ResourceManager.get_total_population(),
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
