extends Node

## 복제인간 생산 시스템

signal production_started(grade: int, facility_id: int)
signal production_completed(grade: int, count: int, has_defect: bool)
signal facility_built(grade: int)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## 등급 해금 여부 확인
func is_grade_unlocked(grade: int) -> bool:
	var required_tech: int = Constants.GRADE_TECH_REQUIREMENT.get(grade, 99)
	return ResourceManager.tech_level >= required_tech


## 시설 건설
func build_facility(grade: int) -> Dictionary:
	# 기술 레벨 체크
	if not is_grade_unlocked(grade):
		var required: int = Constants.GRADE_TECH_REQUIREMENT.get(grade, 99)
		return {"success": false, "reason": "기술 레벨이 부족합니다. (필요: Lv.%d, 현재: Lv.%d)" % [required, ResourceManager.tech_level]}

	var current_count: int = ResourceManager.clone_facilities.get(grade, 0)
	if current_count >= Constants.MAX_FACILITIES:
		return {"success": false, "reason": "시설 수 최대치(%d)에 도달했습니다." % Constants.MAX_FACILITIES}

	var cost: float = _get_build_cost(grade)
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


## 시설 건설 비용 (기술 레벨 할인 적용)
func _get_build_cost(grade: int) -> float:
	var base: float = Constants.FACILITY_COST.get(grade, 100)
	# 기술 레벨 3 이상부터 레벨당 3% 할인
	var discount := maxf(0.0, (ResourceManager.tech_level - 2) * 0.03)
	return base * (1.0 - minf(discount, 0.3))  # 최대 30% 할인


## 복제인간 월간 생산
func process_monthly_production() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var tech_multiplier := ResourceManager.get_tech_output_multiplier()
	var defect_reduction := ResourceManager.get_tech_defect_reduction()

	for grade in ResourceManager.clone_facilities:
		var facility_count: int = ResourceManager.clone_facilities[grade]
		if facility_count <= 0:
			continue

		var grade_data: Dictionary = Constants.CLONE_DATA[grade]
		var base_output: int = grade_data["output"]
		var defect_rate: float = grade_data["defect_rate"]

		# 기술 레벨 적용
		var total_output := int(base_output * facility_count * tech_multiplier)
		defect_rate = maxf(0.005, defect_rate - defect_reduction)

		# 월 유지비 (건설비의 10%)
		var maintenance: float = Constants.FACILITY_COST.get(grade, 100) * facility_count * 0.1
		if ResourceManager.budget < maintenance:
			results.append({
				"grade": grade,
				"name": grade_data["name"],
				"produced": 0,
				"defects": 0,
				"reason": "유지비 부족으로 생산 중단 (필요: %.0f억)" % maintenance
			})
			continue

		ResourceManager.budget -= maintenance

		# 결함 체크 (확률 기반, 이항분포 근사)
		var defect_count := int(total_output * defect_rate)
		defect_count += _rng.randi_range(-max(1, defect_count / 5), max(1, defect_count / 5))
		defect_count = clampi(defect_count, 0, total_output)

		var successful := total_output - defect_count

		var result: Dictionary = {
			"grade": grade,
			"name": grade_data["name"],
			"produced": successful,
			"defects": defect_count,
			"maintenance": maintenance,
			"defect_rate": defect_rate,
			"tech_multiplier": tech_multiplier,
		}

		# 결함 발생 시 추가 효과
		if defect_count > 0:
			var severity := float(defect_count) / float(total_output)
			var approval_penalty := severity * 2.0
			var ethics_penalty := int(severity * 3.0)
			ResourceManager.approval -= approval_penalty
			ResourceManager.ethics -= ethics_penalty
			result["approval_penalty"] = approval_penalty
			result["ethics_penalty"] = ethics_penalty

		production_completed.emit(grade, successful, defect_count > 0)
		results.append(result)

	return results


## 생산 현황 요약
func get_production_summary() -> Dictionary:
	var tech_multiplier := ResourceManager.get_tech_output_multiplier()
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
			var output := int(grade_data["output"] * count * tech_multiplier)
			var cost: float = Constants.FACILITY_COST.get(grade, 100) * count * 0.1
			summary["facilities"][grade] = {
				"name": grade_data["name"],
				"count": count,
				"output": output,
				"cost": cost
			}
			summary["monthly_output"] += output
			summary["monthly_cost"] += cost

	return summary
