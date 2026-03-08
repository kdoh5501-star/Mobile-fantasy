extends Node

## 복제인간 사회 배치 시스템

signal clone_deployed(sector: int, count: int)
signal sector_effect_applied(sector: int, effects: Dictionary)

# 분야별 최대 배치 수
const MAX_PER_SECTOR := 5_000_000

# 배치 비용 (1명당, 억 원)
const DEPLOY_COST_PER_CLONE := 0.001  # 100만 원


## 복제인간 배치
func deploy_clones(sector: int, count: int) -> Dictionary:
	var current: int = ResourceManager.active_clones.get(sector, 0)

	if current + count > MAX_PER_SECTOR:
		return {
			"success": false,
			"reason": "해당 분야의 최대 배치 인원(%s명)을 초과합니다." % _format_number(MAX_PER_SECTOR)
		}

	var cost := count * DEPLOY_COST_PER_CLONE
	if ResourceManager.budget < cost:
		return {
			"success": false,
			"reason": "예산이 부족합니다. (필요: %.1f억 원)" % cost
		}

	ResourceManager.budget -= cost
	ResourceManager.active_clones[sector] = current + count

	clone_deployed.emit(sector, count)

	var sector_data: Dictionary = Constants.SECTOR_DATA[sector]
	return {
		"success": true,
		"sector": sector,
		"sector_name": sector_data["name"],
		"deployed": count,
		"total_in_sector": current + count,
		"cost": cost
	}


## 매월 배치 효과 적용
func apply_monthly_sector_effects() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for sector in ResourceManager.active_clones:
		var count: int = ResourceManager.active_clones[sector]
		if count <= 0:
			continue

		var sector_data: Dictionary = Constants.SECTOR_DATA[sector]
		var scale := count / 10000.0  # 1만 명 단위로 효과 스케일링

		var effects := {}

		# 예산 효과
		var budget_bonus: float = sector_data.get("budget_bonus", 0) * scale
		if budget_bonus != 0:
			ResourceManager.budget += budget_bonus
			effects["budget"] = budget_bonus

		# 여론 효과 (배치 규모에 따라 감쇠)
		var approval_change: float = sector_data.get("approval_change", 0.0) * minf(scale, 5.0) * 0.1
		if approval_change != 0:
			ResourceManager.approval += approval_change
			effects["approval"] = approval_change

		# 윤리 효과
		var ethics_change: int = int(sector_data.get("ethics_change", 0) * minf(scale, 3.0) * 0.1)
		if ethics_change != 0:
			ResourceManager.ethics += ethics_change
			effects["ethics"] = ethics_change

		# 기술 효과 (연구 분야)
		if sector_data.has("tech_bonus") and count >= 10000:
			var tech_chance := minf(scale * 0.01, 0.1)  # 최대 10% 확률
			if randf() < tech_chance:
				ResourceManager.tech_level += 1
				effects["tech_level"] = 1

		var result := {
			"sector": sector,
			"sector_name": sector_data["name"],
			"clone_count": count,
			"effects": effects
		}

		sector_effect_applied.emit(sector, effects)
		results.append(result)

	return results


## 배치 현황 요약
func get_deployment_summary() -> Dictionary:
	var summary := {
		"total_deployed": 0,
		"sectors": {}
	}

	for sector in ResourceManager.active_clones:
		var count: int = ResourceManager.active_clones[sector]
		if count > 0:
			var sector_data: Dictionary = Constants.SECTOR_DATA[sector]
			summary["sectors"][sector] = {
				"name": sector_data["name"],
				"count": count,
				"description": sector_data["description"]
			}
			summary["total_deployed"] += count

	return summary


func _format_number(num: int) -> String:
	var s := str(absi(num))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
