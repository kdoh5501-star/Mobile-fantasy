class_name Constants
extends RefCounted

# === 게임 시간 ===
const START_YEAR := 2045
const END_YEAR := 2080
const TOTAL_TURNS := (END_YEAR - START_YEAR) * 12  # 420턴

# === 시작 수치 ===
const INITIAL_NATURAL_POPULATION := 35_000_000
const INITIAL_CLONE_POPULATION := 0
const INITIAL_BUDGET := 5000  # 억 원 (연간)
const INITIAL_MONTHLY_BUDGET := 420  # 억 원 (월간)
const INITIAL_APPROVAL := 45.0  # 여론 지지율 %
const INITIAL_TECH_LEVEL := 1
const INITIAL_ETHICS := 70
const INITIAL_DIRECTOR_MOOD := 50  # 청장 기분

# === 인구 변동 ===
const MONTHLY_NATURAL_DECREASE := 25000  # 월간 자연인구 감소 (저출산+고령화)

# === 게임오버 조건 ===
const GAMEOVER_APPROVAL := 15.0  # 여론 15% 이하
const GAMEOVER_ETHICS := 0       # 윤리 게이지 0
const GAMEOVER_POPULATION := 20_000_000  # 총 인구 2천만 이하

# === 엔딩 조건 (총 인구 = 자연인구 + 복제인구) ===
const ENDING_S_POPULATION := 50_000_000
const ENDING_S_ETHICS := 70
const ENDING_S_APPROVAL := 70.0
const ENDING_A_POPULATION := 42_000_000
const ENDING_A_APPROVAL := 50.0
const ENDING_B_POPULATION := 35_000_000
const ENDING_C_POPULATION := 28_000_000

# === 복제인간 등급 ===
enum CloneGrade { D, C, B, A, S }

# 등급별 필요 기술 레벨
const GRADE_TECH_REQUIREMENT: Dictionary = {
	CloneGrade.D: 1,
	CloneGrade.C: 2,
	CloneGrade.B: 4,
	CloneGrade.A: 6,
	CloneGrade.S: 8,
}

const CLONE_DATA: Dictionary = {
	CloneGrade.D: {
		"name": "급속복제체",
		"cost": 3,        # 억 원 (시설 유지비 기준)
		"duration": 1,    # 개월
		"output": 500,    # 시설당 월 생산량
		"defect_rate": 0.25,
		"efficiency": 0.5,   # 배치 효율 (1명당 노동력)
		"lifespan": 36,      # 수명 (개월)
		"description": "수명 3년, 단순노동만 가능. 사고 위험 높음"
	},
	CloneGrade.C: {
		"name": "표준복제체",
		"cost": 10,
		"duration": 3,
		"output": 200,
		"defect_rate": 0.12,
		"efficiency": 0.8,
		"lifespan": 120,
		"description": "일반 시민 수준. 단순 노동~사무직 가능"
	},
	CloneGrade.B: {
		"name": "강화복제체",
		"cost": 30,
		"duration": 6,
		"output": 80,
		"defect_rate": 0.06,
		"efficiency": 1.2,
		"lifespan": 240,
		"description": "전문직 투입 가능. 학습능력 우수"
	},
	CloneGrade.A: {
		"name": "정밀복제체",
		"cost": 100,
		"duration": 12,
		"output": 30,
		"defect_rate": 0.03,
		"efficiency": 1.8,
		"lifespan": 480,
		"description": "거의 완벽한 인간. 구별 불가, 고급 전문직"
	},
	CloneGrade.S: {
		"name": "초월복제체",
		"cost": 500,
		"duration": 24,
		"output": 10,
		"defect_rate": 0.01,
		"efficiency": 3.0,
		"lifespan": 960,
		"description": "인간 이상의 능력. 윤리 논란 극대화"
	}
}

# 시설 건설비 (등급별)
const FACILITY_COST: Dictionary = {
	CloneGrade.D: 50,     # 억 원
	CloneGrade.C: 150,
	CloneGrade.B: 500,
	CloneGrade.A: 2000,
	CloneGrade.S: 8000,
}

# 시설 최대 수 (등급별)
const MAX_FACILITIES: int = 50

# === 배치 분야 ===
enum Sector { MANUFACTURING, MILITARY, MEDICAL, RESEARCH, FAMILY, POLITICS }

const SECTOR_DATA: Dictionary = {
	Sector.MANUFACTURING: {
		"name": "제조업",
		"budget_bonus": 15,
		"approval_change": -1.5,
		"ethics_change": -1,
		"description": "경제 성장, 세수 증가 / 일자리 논란"
	},
	Sector.MILITARY: {
		"name": "군대",
		"budget_bonus": 0,
		"approval_change": 2.0,
		"ethics_change": -3,
		"description": "국방력 강화, 안보 지지 / 국제 비난"
	},
	Sector.MEDICAL: {
		"name": "의료",
		"budget_bonus": -2,
		"approval_change": 4.0,
		"ethics_change": 3,
		"description": "복지 향상, 윤리 개선 / 비용 소모"
	},
	Sector.RESEARCH: {
		"name": "연구",
		"budget_bonus": 0,
		"approval_change": 1.0,
		"ethics_change": -1,
		"tech_bonus": 1,
		"description": "기술 레벨 상승 확률 / 자아각성 리스크"
	},
	Sector.FAMILY: {
		"name": "가정·돌봄",
		"budget_bonus": -1,
		"approval_change": -2.0,
		"ethics_change": -4,
		"birth_bonus": true,
		"description": "자연출산 촉진 / 심각한 윤리 논란"
	},
	Sector.POLITICS: {
		"name": "행정·정치",
		"budget_bonus": 8,
		"approval_change": -3.0,
		"ethics_change": -3,
		"description": "정책 효율화, 예산 절감 / 인권 논란"
	}
}

# === 연구 시스템 ===
const RESEARCH_BASE_COST := 30.0  # 기본 연구 비용 (억 원)
const RESEARCH_COST_PER_LEVEL := 15.0  # 레벨당 추가 비용

# 기술 레벨별 효과 설명
const TECH_EFFECTS: Dictionary = {
	1: "D등급 복제 가능",
	2: "C등급 복제 해금",
	3: "결함률 -5%, 생산량 +10%",
	4: "B등급 복제 해금",
	5: "결함률 -5%, 생산량 +10%",
	6: "A등급 복제 해금",
	7: "결함률 -5%, 생산량 +20%",
	8: "S등급 복제 해금",
	9: "전체 효율 +30%",
	10: "궁극의 기술: 결함률 반감, 생산량 2배",
}
