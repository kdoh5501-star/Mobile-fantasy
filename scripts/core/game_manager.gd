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

	# 자원 변동은 TurnManager.process_full_turn()에서 처리됨
	# 여기서는 턴 진행(날짜, 엔딩 체크)만 담당

	# 다음 달로
	_advance_month()

	turn_ended.emit(current_year, current_month, {})

	# 게임 종료 체크
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
	# EndingSystem에 엔딩 판정을 위임
	var ending_system: Node = Engine.get_main_loop().root.get_node_or_null("MainGame/Systems/EndingSystem")
	if ending_system and ending_system.has_method("determine_ending"):
		var ending: Dictionary = ending_system.determine_ending()
		current_phase = GamePhase.ENDING
		game_ended.emit(ending.get("type", "C"), ending)
	else:
		# 폴백: EndingSystem이 없을 때 기본 엔딩
		var pop: int = ResourceManager.get_total_population()
		var ending: Dictionary = {}
		if pop >= Constants.ENDING_S_POPULATION:
			ending = {"type": "S", "title": "신인류 시대", "description": "인류의 새 시대가 열렸습니다!"}
		elif pop >= Constants.ENDING_A_POPULATION:
			ending = {"type": "A", "title": "그럭저럭 성공", "description": "인구 위기를 해결했습니다."}
		elif pop >= Constants.ENDING_B_POPULATION:
			ending = {"type": "B", "title": "현상유지", "description": "겨우 현상 유지입니다."}
		else:
			ending = {"type": "C", "title": "프로젝트 실패", "description": "인구 위기를 해결하지 못했습니다."}
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
