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

	# Phase 4: 인구 자연감소
	_process_population_phase()

	# Phase 5: 이벤트 체크
	_process_event_phase()

	# 최종 보고서
	_monthly_report["final_stats"] = {
		"population": ResourceManager.population,
		"budget": ResourceManager.budget,
		"approval": ResourceManager.approval,
		"ethics": ResourceManager.ethics,
		"tech_level": ResourceManager.tech_level,
		"director_mood": ResourceManager.director_mood
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
		var results: Array = clone_production.process_monthly_production()
		_monthly_report["production"] = results

		# 생산된 복제인간 수 합산
		var total_produced: int = 0
		for result in results:
			total_produced += result.get("produced", 0)
		ResourceManager.total_clones_produced += total_produced
		ResourceManager.population += total_produced
		_monthly_report["clones_produced"] = total_produced


func _process_deployment_phase() -> void:
	turn_phase_changed.emit("deployment")
	if deployment:
		var results: Dictionary = deployment.apply_monthly_sector_effects()
		_monthly_report["deployment_effects"] = results


func _process_population_phase() -> void:
	turn_phase_changed.emit("population")
	var decrease := Constants.MONTHLY_NATURAL_DECREASE
	ResourceManager.population -= decrease
	_monthly_report["natural_decrease"] = decrease
	_monthly_report["net_population_change"] = _monthly_report.get("clones_produced", 0) - decrease


func _process_event_phase() -> void:
	turn_phase_changed.emit("events")
	var events := EventSystem.check_events(
		GameManager.current_year,
		GameManager.current_month,
		GameManager.current_turn
	)
	_monthly_report["events"] = events
