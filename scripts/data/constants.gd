class_name Constants
extends RefCounted

# === 게임 시간 ===
const START_YEAR := 2045
const END_YEAR := 2080
const TOTAL_TURNS := (END_YEAR - START_YEAR) * 12  # 420턴

# === 시작 수치 ===
const INITIAL_POPULATION := 35_000_000
const INITIAL_BUDGET := 5000  # 억 원 (연간)
const INITIAL_MONTHLY_BUDGET := 420  # 억 원 (월간)
const INITIAL_APPROVAL := 45.0  # 여론 지지율 %
const INITIAL_TECH_LEVEL := 1
const INITIAL_ETHICS := 70
const INITIAL_DIRECTOR_MOOD := 50  # 청장 기분

# === 인구 변동 ===
const MONTHLY_NATURAL_DECREASE := 20000  # 월간 자연감소

# === 게임오버 조건 ===
const GAMEOVER_APPROVAL := 20.0  # 여론 20% 이하
const GAMEOVER_ETHICS := 0       # 윤리 게이지 0

# === 엔딩 조건 ===
const ENDING_S_POPULATION := 50_000_000
const ENDING_S_ETHICS := 80
const ENDING_S_APPROVAL := 80.0
const ENDING_A_POPULATION := 40_000_000
const ENDING_A_APPROVAL := 50.0
const ENDING_B_POPULATION := 35_000_000
const ENDING_C_POPULATION := 30_000_000

# === 복제인간 등급 ===
enum CloneGrade { D, C, B, A, S }

const CLONE_DATA := {
	CloneGrade.D: {
		"name": "급속복제체",
		"cost": 5,        # 억 원
		"duration": 1,    # 개월
		"output": 100,    # 시설당 월 생산량
		"defect_rate": 0.30,
		"description": "수명 짧고 능력치 낮음, 사고 확률 높음"
	},
	CloneGrade.C: {
		"name": "표준복제체",
		"cost": 20,
		"duration": 3,
		"output": 50,
		"defect_rate": 0.15,
		"description": "일반 시민 수준, 단순 노동 가능"
	},
	CloneGrade.B: {
		"name": "강화복제체",
		"cost": 50,
		"duration": 6,
		"output": 20,
		"defect_rate": 0.08,
		"description": "전문직 투입 가능, 학습능력 우수"
	},
	CloneGrade.A: {
		"name": "정밀복제체",
		"cost": 200,
		"duration": 12,
		"output": 5,
		"defect_rate": 0.05,
		"description": "거의 완벽한 인간, 구별 불가"
	},
	CloneGrade.S: {
		"name": "초월복제체",
		"cost": 1000,
		"duration": 24,
		"output": 1,
		"defect_rate": 0.02,
		"description": "인간 이상의 능력, 윤리적 논란 극대화"
	}
}

# === 배치 분야 ===
enum Sector { MANUFACTURING, MILITARY, MEDICAL, RESEARCH, FAMILY, POLITICS }

const SECTOR_DATA := {
	Sector.MANUFACTURING: {
		"name": "제조업",
		"budget_bonus": 10,
		"approval_change": -2.0,
		"ethics_change": 0,
		"description": "경제 성장, 세수 증가 / 노동자 반발"
	},
	Sector.MILITARY: {
		"name": "군대",
		"budget_bonus": 0,
		"approval_change": 3.0,
		"ethics_change": -5,
		"description": "국방력 강화 / 국제 사회 비난"
	},
	Sector.MEDICAL: {
		"name": "의료",
		"budget_bonus": 0,
		"approval_change": 5.0,
		"ethics_change": 2,
		"description": "복지 향상 / 의료 사고 리스크"
	},
	Sector.RESEARCH: {
		"name": "연구",
		"budget_bonus": 0,
		"approval_change": 1.0,
		"ethics_change": -1,
		"tech_bonus": 1,
		"description": "기술 레벨 상승 / 자아각성 리스크"
	},
	Sector.FAMILY: {
		"name": "출산 장려",
		"budget_bonus": 0,
		"approval_change": -1.0,
		"ethics_change": -3,
		"description": "복제인간 가정 구성 / 논란 유발"
	},
	Sector.POLITICS: {
		"name": "정치",
		"budget_bonus": 5,
		"approval_change": -5.0,
		"ethics_change": -5,
		"description": "정책 지지 확보 / 인권 운동 촉발"
	}
}
