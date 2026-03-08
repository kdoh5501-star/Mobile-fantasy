extends Node

## 턴 진행 관리 - 매 턴의 단계별 처리를 담당

signal turn_phase_changed(phase: String)
signal monthly_report_ready(report: Dictionary)

@onready var clone_production: Node = $"../CloneProduction" if has_node("../CloneProduction") else null
@onready var deployment: Node = $"../Deployment" if has_node("../Deployment") else null

var _monthly_report: Dictionary = {}


## 턴 전체 처리
func process_full_turn() -> Dictionary:
	_monthly_report = {
		"year": GameManager.current_year,
		"month": GameManager.current_month,
		"turn": GameManager.current_turn,
	}

	# Phase 1: 예산 수입
	_process_budget_phase()

	# Phase 2: 복제인간 생산
	_process_production_phase()

	# Phase 3: 배치 효과 적용
	_process_deployment_phase()

	# Phase 4: 자연인구 감소 + 복제인간 수명 처리
	_process_population_phase()

	# Phase 5: 복제인간 사기/사건 처리
	_process_clone_morale_phase()

	# Phase 6: 이벤트 체크
	_process_event_phase()

	# Phase 7: 게임오버 체크
	_check_population_gameover()

	# 최종 보고서
	_monthly_report["final_stats"] = {
		"natural_population": ResourceManager.natural_population,
		"clone_population": ResourceManager.clone_population,
		"total_population": ResourceManager.get_total_population(),
		"budget": ResourceManager.budget,
		"approval": ResourceManager.approval,
		"ethics": ResourceManager.ethics,
		"tech_level": ResourceManager.tech_level,
		"director_mood": ResourceManager.director_mood,
		"clone_morale": ResourceManager.clone_morale,
	}

	monthly_report_ready.emit(_monthly_report)
	return _monthly_report


func _process_budget_phase() -> void:
	turn_phase_changed.emit("budget")
	var income := ResourceManager.get_monthly_budget_income()
	ResourceManager.budget += income
	_monthly_report["budget_income"] = income


func _process_production_phase() -> void:
	turn_phase_changed.emit("production")
	if clone_production:
		var results: Array[Dictionary] = clone_production.process_monthly_production()
		_monthly_report["production"] = results

		# 생산된 복제인간을 clone_population에 추가
		var total_produced: int = 0
		var total_defects: int = 0
		for result in results:
			total_produced += result.get("produced", 0)
			total_defects += result.get("defects", 0)
		ResourceManager.total_clones_produced += total_produced
		ResourceManager.clone_population += total_produced
		ResourceManager.clone_incidents += total_defects
		_monthly_report["clones_produced"] = total_produced
		_monthly_report["clone_defects"] = total_defects


func _process_deployment_phase() -> void:
	turn_phase_changed.emit("deployment")
	if deployment:
		var results: Array[Dictionary] = deployment.apply_monthly_sector_effects()
		_monthly_report["deployment_effects"] = results


func _process_population_phase() -> void:
	turn_phase_changed.emit("population")
	# 자연인구만 감소 (저출산+고령화)
	var decrease := Constants.MONTHLY_NATURAL_DECREASE
	ResourceManager.natural_population -= decrease
	_monthly_report["natural_decrease"] = decrease

	# 복제인간 수명에 의한 자연사 (간소화: 총 클론의 0.1%가 매월 수명 만료)
	var clone_deaths := int(ResourceManager.clone_population * 0.001)
	if clone_deaths > 0:
		ResourceManager.clone_population -= clone_deaths
		# 배치된 클론에서도 비례 감소
		_reduce_deployed_clones(clone_deaths)
	_monthly_report["clone_deaths"] = clone_deaths

	_monthly_report["net_population_change"] = _monthly_report.get("clones_produced", 0) - decrease - clone_deaths


func _process_clone_morale_phase() -> void:
	# 복제인간 사기는 배치 상황에 따라 변동
	var deployed := ResourceManager.get_total_deployed()
	var total_clones := ResourceManager.clone_population
	if total_clones <= 0:
		return

	var deploy_ratio := float(deployed) / float(total_clones)

	# 과도한 배치(70% 이상)는 사기 감소
	if deploy_ratio > 0.7:
		ResourceManager.clone_morale = clampi(ResourceManager.clone_morale - 2, 0, 100)
	elif deploy_ratio < 0.3 and deployed > 0:
		ResourceManager.clone_morale = clampi(ResourceManager.clone_morale + 1, 0, 100)

	# 윤리가 낮으면 사기 감소
	if ResourceManager.ethics < 30:
		ResourceManager.clone_morale = clampi(ResourceManager.clone_morale - 1, 0, 100)

	# 사기가 낮으면 여론과 윤리에 영향
	if ResourceManager.clone_morale < 20:
		ResourceManager.approval -= 0.5
		ResourceManager.ethics -= 1
		_monthly_report["clone_unrest"] = true

	_monthly_report["clone_morale"] = ResourceManager.clone_morale


func _process_event_phase() -> void:
	turn_phase_changed.emit("events")
	var events := EventSystem.check_events(
		GameManager.current_year,
		GameManager.current_month,
		GameManager.current_turn
	)
	_monthly_report["events"] = events


func _check_population_gameover() -> void:
	var total := ResourceManager.get_total_population()
	if total <= Constants.GAMEOVER_POPULATION:
		ResourceManager.game_over.emit("총 인구가 %d만 명 이하로 떨어졌습니다! 국가 존립이 위태롭습니다." % (total / 10000))


## 배치된 클론에서 사망자를 비례 감소
func _reduce_deployed_clones(deaths: int) -> void:
	var total_deployed := ResourceManager.get_total_deployed()
	if total_deployed <= 0:
		return
	for sector in ResourceManager.active_clones:
		var count: int = ResourceManager.active_clones[sector]
		if count > 0:
			var sector_deaths := int(float(deaths) * float(count) / float(total_deployed))
			ResourceManager.active_clones[sector] = max(0, count - sector_deaths)
