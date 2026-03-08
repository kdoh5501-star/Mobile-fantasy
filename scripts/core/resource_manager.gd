extends Node

## 게임 내 모든 자원을 관리하는 싱글톤

signal resource_changed(resource_name: String, new_value: float)
signal population_changed(new_population: int)
signal game_over(reason: String)

# === 인구 (자연인간 / 복제인간 분리) ===
var natural_population: int = Constants.INITIAL_NATURAL_POPULATION:
	set(value):
		natural_population = max(0, value)
		population_changed.emit(get_total_population())

var clone_population: int = Constants.INITIAL_CLONE_POPULATION:
	set(value):
		clone_population = max(0, value)
		population_changed.emit(get_total_population())

# 하위 호환용 + 총 인구 접근
var population: int:
	get:
		return get_total_population()
	set(value):
		# 레거시 코드 호환: population 설정 시 clone_population에 차이를 반영
		var diff := value - get_total_population()
		if diff > 0:
			clone_population += diff
		elif diff < 0:
			natural_population += diff  # 감소는 자연인구에서

var budget: float = Constants.INITIAL_MONTHLY_BUDGET:
	set(value):
		budget = maxf(-1000.0, value)  # 약간의 적자 허용
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
var active_clones: Dictionary = {}  # Sector -> count (배치된 복제인간만)
var clone_facilities: Dictionary = {}  # CloneGrade -> count

# === 복제인간 행복도/사회 지표 ===
var clone_morale: int = 50  # 복제인간 사기 (0-100)
var clone_incidents: int = 0  # 누적 사건사고 수


func _ready() -> void:
	_init_facilities()


func _init_facilities() -> void:
	for grade in Constants.CloneGrade.values():
		clone_facilities[grade] = 0
	for sector in Constants.Sector.values():
		active_clones[sector] = 0


func get_total_population() -> int:
	return natural_population + clone_population


func get_total_deployed() -> int:
	var total := 0
	for sector in active_clones:
		total += active_clones[sector] as int
	return total


## 배치 가능한 복제인간 수 (미배치 클론)
func get_available_clones() -> int:
	return clone_population - get_total_deployed()


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


## 기술 레벨에 따른 생산량 보너스 배율
func get_tech_output_multiplier() -> float:
	var bonus := 1.0
	if tech_level >= 3:
		bonus += 0.1  # Lv3: +10%
	if tech_level >= 5:
		bonus += 0.1  # Lv5: +10%
	if tech_level >= 7:
		bonus += 0.2  # Lv7: +20%
	if tech_level >= 9:
		bonus += 0.3  # Lv9: +30%
	if tech_level >= 10:
		bonus += 0.5  # Lv10: +50% (total 2.2x)
	return bonus


## 기술 레벨에 따른 결함률 감소
func get_tech_defect_reduction() -> float:
	var reduction := 0.0
	if tech_level >= 3:
		reduction += 0.05
	if tech_level >= 5:
		reduction += 0.05
	if tech_level >= 7:
		reduction += 0.05
	if tech_level >= 10:
		reduction += 0.10  # Lv10은 결함률 반감 효과
	return reduction


func get_monthly_clone_output() -> int:
	var total := 0
	var multiplier := get_tech_output_multiplier()
	for grade in clone_facilities:
		var count: int = clone_facilities[grade]
		if count > 0:
			var data: Dictionary = Constants.CLONE_DATA[grade]
			total += int(data["output"] * count * multiplier)
	return total


func get_monthly_budget_income() -> float:
	# 기본 예산 (자연인구 기반 세금)
	var base := float(Constants.INITIAL_MONTHLY_BUDGET) * (float(natural_population) / float(Constants.INITIAL_NATURAL_POPULATION))
	# 배치된 복제인간으로부터의 수입
	var clone_income := 0.0
	for sector in active_clones:
		var count: int = active_clones[sector]
		if count <= 0:
			continue
		var sector_data: Dictionary = Constants.SECTOR_DATA[sector]
		var bonus: float = sector_data.get("budget_bonus", 0)
		# 1만명당 bonus 억원
		clone_income += (count / 10000.0) * bonus
	return base + clone_income


## 이 함수는 turn_manager에서 호출하지 않음 (레거시)
func apply_monthly_changes() -> Dictionary:
	return {}


func reset() -> void:
	natural_population = Constants.INITIAL_NATURAL_POPULATION
	clone_population = Constants.INITIAL_CLONE_POPULATION
	budget = Constants.INITIAL_MONTHLY_BUDGET
	approval = Constants.INITIAL_APPROVAL
	tech_level = Constants.INITIAL_TECH_LEVEL
	ethics = Constants.INITIAL_ETHICS
	director_mood = Constants.INITIAL_DIRECTOR_MOOD
	total_clones_produced = 0
	clone_morale = 50
	clone_incidents = 0
	_init_facilities()
