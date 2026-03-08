extends Node

## 게임 전체 흐름을 관리하는 메인 매니저

signal turn_started(year: int, month: int)
signal turn_ended(year: int, month: int, report: Dictionary)
signal game_ended(ending_type: String, ending_data: Dictionary)
signal phase_changed(phase: String)

enum GamePhase { TITLE, PLAYING, EVENT, PAUSED, GAME_OVER, ENDING }

var current_phase: GamePhase = GamePhase.TITLE
var current_turn: int = 0
var current_year: int = Constants.START_YEAR
var current_month: int = 1

# 턴 내 단계
enum TurnPhase { BUDGET, PRODUCTION, DEPLOYMENT, EVENT, REPORT }
var current_turn_phase: TurnPhase = TurnPhase.BUDGET


func _ready() -> void:
	ResourceManager.game_over.connect(_on_game_over)


func start_new_game() -> void:
	current_turn = 0
	current_year = Constants.START_YEAR
	current_month = 1
	current_phase = GamePhase.PLAYING
	current_turn_phase = TurnPhase.BUDGET
	ResourceManager.reset()
	phase_changed.emit("playing")
	start_turn()


func start_turn() -> void:
	current_turn += 1
	turn_started.emit(current_year, current_month)


func process_turn() -> void:
	if current_phase != GamePhase.PLAYING:
		return

	# 1. 월간 자원 변동 적용
	var report: Dictionary = ResourceManager.apply_monthly_changes()

	# 2. 이벤트 체크
	var events := EventSystem.check_events(current_year, current_month, current_turn)
	report["events"] = events

	# 3. 턴 종료
	turn_ended.emit(current_year, current_month, report)

	# 4. 다음 달로
	_advance_month()

	# 5. 게임 종료 체크
	if current_year > Constants.END_YEAR:
		_check_ending()
	else:
		start_turn()


func _advance_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1


func _check_ending() -> void:
	var pop := ResourceManager.population
	var eth := ResourceManager.ethics
	var app := ResourceManager.approval
	var ending: Dictionary = {}

	# 히든 엔딩 체크
	if eth <= 0 and ResourceManager.total_clones_produced >= 100:
		ending = {
			"type": "hidden_revolution",
			"title": "복제인간 혁명",
			"description": "복제인간들이 반란을 일으켜 독립국을 선언했습니다!"
		}
	# S 엔딩
	elif pop >= Constants.ENDING_S_POPULATION and eth >= Constants.ENDING_S_ETHICS and app >= Constants.ENDING_S_APPROVAL:
		ending = {
			"type": "S",
			"title": "신인류 시대",
			"description": "복제인간과 인간이 공존하는 이상적 사회가 실현되었습니다!"
		}
	# A 엔딩
	elif pop >= Constants.ENDING_A_POPULATION and app >= Constants.ENDING_A_APPROVAL:
		ending = {
			"type": "A",
			"title": "그럭저럭 성공",
			"description": "논란은 있지만 인구 위기는 해결했습니다. 차장님 수고하셨습니다."
		}
	# B 엔딩
	elif pop >= Constants.ENDING_B_POPULATION:
		ending = {
			"type": "B",
			"title": "아슬아슬 현상유지",
			"description": "겨우 현상 유지... 미래는 여전히 불투명합니다."
		}
	# C 엔딩
	else:
		ending = {
			"type": "C",
			"title": "프로젝트 실패",
			"description": "인구 위기를 해결하지 못했습니다. 차장은 좌천되었습니다..."
		}

	current_phase = GamePhase.ENDING
	game_ended.emit(ending["type"], ending)


func _on_game_over(reason: String) -> void:
	current_phase = GamePhase.GAME_OVER
	game_ended.emit("game_over", {
		"type": "game_over",
		"title": "게임 오버",
		"description": reason
	})


func get_date_string() -> String:
	return "%d년 %d월" % [current_year, current_month]


func get_progress_percent() -> float:
	return (float(current_turn) / float(Constants.TOTAL_TURNS)) * 100.0
