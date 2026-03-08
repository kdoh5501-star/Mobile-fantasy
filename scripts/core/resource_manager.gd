extends Node

## 게임 내 모든 자원을 관리하는 싱글톤

signal resource_changed(resource_name: String, new_value: float)
signal population_changed(new_population: int)
signal game_over(reason: String)

# === 자원 ===
var population: int = Constants.INITIAL_POPULATION:
	set(value):
		population = max(0, value)
		population_changed.emit(population)

var budget: float = Constants.INITIAL_MONTHLY_BUDGET:
	set(value):
		budget = max(0.0, value)
		resource_changed.emit("budget", budget)

var approval: float = Constants.INITIAL_APPROVAL:
	set(value):
		approval = clampf(value, 0.0, 100.0)
		resource_changed.emit("approval", approval)
		if approval <= Constants.GAMEOVER_APPROVAL:
			game_over.emit("여론 지지율이 바닥을 쳤습니다! 국민이 신인류청 폐지를 요구합니다.")

var tech_level: int = Constants.INITIAL_TECH_LEVEL:
	set(value):
		tech_level = clampi(value, 1, 10)
		resource_changed.emit("tech_level", tech_level)

var ethics: int = Constants.INITIAL_ETHICS:
	set(value):
		ethics = clampi(value, 0, 100)
		resource_changed.emit("ethics", ethics)
		if ethics <= Constants.GAMEOVER_ETHICS:
			game_over.emit("윤리 게이지가 0이 되었습니다! UN이 대한민국에 국제 제재를 발동합니다.")

var director_mood: int = Constants.INITIAL_DIRECTOR_MOOD:
	set(value):
		director_mood = clampi(value, 0, 100)
		resource_changed.emit("director_mood", director_mood)


# === 복제인간 통계 ===
var total_clones_produced: int = 0
var active_clones: Dictionary = {}  # Sector -> count
var clone_facilities: Dictionary = {}  # CloneGrade -> count


func _ready() -> void:
	_init_facilities()


func _init_facilities() -> void:
	for grade in Constants.CloneGrade.values():
		clone_facilities[grade] = 0

	for sector in Constants.Sector.values():
		active_clones[sector] = 0


func get_director_mood_emoji() -> String:
	if director_mood >= 80:
		return "😊"
	elif director_mood >= 60:
		return "🙂"
	elif director_mood >= 40:
		return "😐"
	elif director_mood >= 20:
		return "😠"
	else:
		return "😡"


func get_monthly_clone_output() -> int:
	var total := 0
	for grade in clone_facilities:
		var count: int = clone_facilities[grade]
		if count > 0:
			var data: Dictionary = Constants.CLONE_DATA[grade]
			total += data["output"] * count
	return total


func get_monthly_budget_income() -> float:
	var base := Constants.INITIAL_MONTHLY_BUDGET
	var clone_income := 0.0
	for sector in active_clones:
		var count: int = active_clones[sector]
		var sector_data: Dictionary = Constants.SECTOR_DATA[sector]
		clone_income += count * sector_data.get("budget_bonus", 0) * 0.01
	return base + clone_income


func apply_monthly_changes() -> Dictionary:
	var report := {}

	# 자연 인구 감소
	var natural_decrease := Constants.MONTHLY_NATURAL_DECREASE
	population -= natural_decrease
	report["natural_decrease"] = natural_decrease

	# 복제인간 생산
	var clone_output := get_monthly_clone_output()
	population += clone_output
	total_clones_produced += clone_output
	report["clone_output"] = clone_output

	# 예산 수입
	var income := get_monthly_budget_income()
	budget += income
	report["budget_income"] = income

	# 인구 순변동
	report["net_change"] = clone_output - natural_decrease

	return report


func reset() -> void:
	population = Constants.INITIAL_POPULATION
	budget = Constants.INITIAL_MONTHLY_BUDGET
	approval = Constants.INITIAL_APPROVAL
	tech_level = Constants.INITIAL_TECH_LEVEL
	ethics = Constants.INITIAL_ETHICS
	director_mood = Constants.INITIAL_DIRECTOR_MOOD
	total_clones_produced = 0
	_init_facilities()
