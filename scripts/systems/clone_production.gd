extends Node

## 복제인간 생산 시스템

signal production_started(grade: int, facility_id: int)
signal production_completed(grade: int, count: int, has_defect: bool)
signal facility_built(grade: int)

var _rng := RandomNumberGenerator.new()

# 진행 중인 생산 큐 [{grade, remaining_turns, facility_id}]
var _production_queue: Array[Dictionary] = []

# 시설 건설 비용 (등급별)
const FACILITY_COST: Dictionary = {
	Constants.CloneGrade.D: 100,   # 억 원
	Constants.CloneGrade.C: 300,
	Constants.CloneGrade.B: 800,
	Constants.CloneGrade.A: 2000,
	Constants.CloneGrade.S: 5000,
}

# 시설 최대 수
const MAX_FACILITIES_PER_GRADE := 10


func _ready() -> void:
	_rng.randomize()


## 시설 건설
func build_facility(grade: int) -> Dictionary:
	var current_count: int = ResourceManager.clone_facilities.get(grade, 0)

	if current_count >= MAX_FACILITIES_PER_GRADE:
		return {"success": false, "reason": "시설 수 최대치(%d)에 도달했습니다." % MAX_FACILITIES_PER_GRADE}

	var cost: float = FACILITY_COST[grade]

	# 기술 레벨에 따른 할인
	var discount := (ResourceManager.tech_level - 1) * 0.05
	cost *= (1.0 - discount)

	if ResourceManager.budget < cost:
		return {"success": false, "reason": "예산이 부족합니다. (필요: %.0f억 원, 보유: %.0f억 원)" % [cost, ResourceManager.budget]}

	ResourceManager.budget -= cost
	ResourceManager.clone_facilities[grade] = current_count + 1

	facility_built.emit(grade)

	var grade_data: Dictionary = Constants.CLONE_DATA[grade]
	return {
		"success": true,
		"grade": grade,
		"name": grade_data["name"],
		"cost": cost,
		"total_facilities": current_count + 1
	}


## 복제인간 생산 시작 (시설이 있으면 자동으로 매턴 생산)
func process_monthly_production() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for grade in ResourceManager.clone_facilities:
		var facility_count: int = ResourceManager.clone_facilities[grade]
		if facility_count <= 0:
			continue

		var grade_data: Dictionary = Constants.CLONE_DATA[grade]
		var output_per_facility: int = grade_data["output"]
		var defect_rate: float = grade_data["defect_rate"]

		# 기술 레벨에 따른 결함률 감소
		var tech_reduction := (ResourceManager.tech_level - 1) * 0.02
		defect_rate = maxf(0.01, defect_rate - tech_reduction)

		var total_output := output_per_facility * facility_count
		var production_cost: float = grade_data["cost"] * facility_count * 0.3  # 월 유지비 (건설비의 30%)

		if ResourceManager.budget < production_cost:
			results.append({
				"grade": grade,
				"name": grade_data["name"],
				"produced": 0,
				"defects": 0,
				"reason": "유지비 부족으로 생산 중단"
			})
			continue

		ResourceManager.budget -= production_cost

		# 결함 체크
		var defect_count := 0
		for i in range(total_output):
			if _rng.randf() < defect_rate:
				defect_count += 1

		var successful := total_output - defect_count

		var result: Dictionary = {
			"grade": grade,
			"name": grade_data["name"],
			"produced": successful,
			"defects": defect_count,
			"cost": production_cost,
			"defect_rate": defect_rate
		}

		# 결함 발생 시 추가 효과
		if defect_count > 0:
			var approval_penalty := defect_count * 0.1
			var ethics_penalty := defect_count * 0.05
			ResourceManager.approval -= approval_penalty
			ResourceManager.ethics -= int(ethics_penalty)
			result["approval_penalty"] = approval_penalty
			result["ethics_penalty"] = ethics_penalty

		production_completed.emit(grade, successful, defect_count > 0)
		results.append(result)

	return results


## 생산 현황 요약
func get_production_summary() -> Dictionary:
	var summary: Dictionary = {
		"facilities": {},
		"monthly_output": 0,
		"monthly_cost": 0.0,
		"total_produced": ResourceManager.total_clones_produced
	}

	for grade in ResourceManager.clone_facilities:
		var count: int = ResourceManager.clone_facilities[grade]
		if count > 0:
			var grade_data: Dictionary = Constants.CLONE_DATA[grade]
			summary["facilities"][grade] = {
				"name": grade_data["name"],
				"count": count,
				"output": grade_data["output"] * count,
				"cost": grade_data["cost"] * count * 0.3
			}
			summary["monthly_output"] += grade_data["output"] * count
			summary["monthly_cost"] += grade_data["cost"] * count * 0.3

	return summary
