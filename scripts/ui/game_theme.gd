class_name GameTheme
extends RefCounted

## 카이로소프트 스타일 밝고 귀여운 게임 테마


# === 컬러 팔레트 (카이로소프트 감성) ===
# 밝고 따뜻한 색상 기반

const BG_CREAM := Color(0.96, 0.93, 0.88)          # 크림색 배경
const BG_WARM := Color(0.92, 0.88, 0.82)            # 따뜻한 배경
const BG_PANEL := Color(1.0, 0.98, 0.94)            # 패널 배경 (밝은 아이보리)
const BG_HEADER := Color(0.25, 0.45, 0.7)           # 헤더 파란색
const BG_HEADER_GREEN := Color(0.3, 0.6, 0.35)      # 헤더 초록색
const BG_HEADER_RED := Color(0.7, 0.25, 0.25)       # 헤더 빨간색
const BG_HEADER_ORANGE := Color(0.8, 0.5, 0.15)     # 헤더 주황색
const BG_HEADER_PURPLE := Color(0.5, 0.3, 0.65)     # 헤더 보라색

const BTN_BLUE := Color(0.3, 0.5, 0.78)             # 버튼 파란색
const BTN_BLUE_HOVER := Color(0.4, 0.6, 0.88)       # 버튼 호버
const BTN_BLUE_PRESSED := Color(0.2, 0.4, 0.68)     # 버튼 누름
const BTN_GREEN := Color(0.35, 0.65, 0.35)          # 초록 버튼
const BTN_ORANGE := Color(0.85, 0.55, 0.2)          # 주황 버튼
const BTN_RED := Color(0.75, 0.3, 0.3)              # 빨간 버튼

const TEXT_DARK := Color(0.2, 0.2, 0.25)             # 어두운 텍스트
const TEXT_NORMAL := Color(0.3, 0.3, 0.35)           # 일반 텍스트
const TEXT_LIGHT := Color(0.5, 0.5, 0.55)            # 밝은 텍스트
const TEXT_WHITE := Color(1.0, 1.0, 1.0)             # 흰색 텍스트
const TEXT_GOLD := Color(0.85, 0.65, 0.1)            # 골드 텍스트

const BORDER_LIGHT := Color(0.8, 0.75, 0.68)        # 밝은 테두리
const BORDER_MEDIUM := Color(0.6, 0.55, 0.5)        # 중간 테두리
const BORDER_DARK := Color(0.4, 0.38, 0.35)         # 어두운 테두리

const POSITIVE_GREEN := Color(0.2, 0.65, 0.25)      # 양수/긍정
const NEGATIVE_RED := Color(0.8, 0.2, 0.2)           # 음수/부정
const WARNING_YELLOW := Color(0.85, 0.7, 0.1)       # 경고

# === 자원별 색상 ===
const COLOR_POPULATION := Color(0.3, 0.55, 0.8)     # 인구 - 파란색
const COLOR_BUDGET := Color(0.85, 0.65, 0.1)        # 예산 - 금색
const COLOR_APPROVAL := Color(0.4, 0.7, 0.35)       # 여론 - 초록
const COLOR_ETHICS := Color(0.6, 0.4, 0.75)         # 윤리 - 보라
const COLOR_TECH := Color(0.3, 0.7, 0.8)            # 기술 - 시안
const COLOR_MOOD := Color(0.85, 0.5, 0.3)           # 청장 기분 - 주황


static func create_theme() -> Theme:
	var theme := Theme.new()

	# === Button 스타일 ===
	var btn_normal := _make_panel(BTN_BLUE, BORDER_DARK, 2, 8)
	btn_normal.set_content_margin_all(8)
	btn_normal.shadow_color = Color(0, 0, 0, 0.2)
	btn_normal.shadow_size = 2
	btn_normal.shadow_offset = Vector2(1, 2)

	var btn_hover := _make_panel(BTN_BLUE_HOVER, Color(0.5, 0.7, 0.95), 2, 8)
	btn_hover.set_content_margin_all(8)
	btn_hover.shadow_color = Color(0, 0, 0, 0.25)
	btn_hover.shadow_size = 3
	btn_hover.shadow_offset = Vector2(1, 2)

	var btn_pressed := _make_panel(BTN_BLUE_PRESSED, BORDER_DARK, 2, 8)
	btn_pressed.set_content_margin_all(8)
	btn_pressed.shadow_size = 0

	var btn_disabled := _make_panel(Color(0.7, 0.68, 0.65), Color(0.6, 0.58, 0.55), 1, 8)
	btn_disabled.set_content_margin_all(8)

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_color", "Button", TEXT_WHITE)
	theme.set_color("font_hover_color", "Button", Color(1.0, 1.0, 0.9))
	theme.set_color("font_pressed_color", "Button", Color(0.9, 0.9, 0.8))
	theme.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.45))
	theme.set_font_size("font_size", "Button", 14)

	# === Label ===
	theme.set_color("font_color", "Label", TEXT_DARK)
	theme.set_font_size("font_size", "Label", 14)

	# === PanelContainer ===
	var panel_style := _make_panel(BG_PANEL, BORDER_MEDIUM, 2, 10)
	panel_style.set_content_margin_all(12)
	panel_style.shadow_color = Color(0, 0, 0, 0.15)
	panel_style.shadow_size = 4
	panel_style.shadow_offset = Vector2(2, 3)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# === ProgressBar ===
	var pb_bg := _make_panel(Color(0.82, 0.78, 0.72), BORDER_MEDIUM, 1, 6)
	pb_bg.set_content_margin_all(0)

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.35, 0.7, 0.4)
	pb_fill.set_corner_radius_all(5)
	pb_fill.set_content_margin_all(0)

	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	theme.set_color("font_color", "ProgressBar", TEXT_DARK)

	# === HSeparator ===
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = BORDER_LIGHT
	sep_style.set_content_margin_all(0)
	sep_style.content_margin_top = 3
	sep_style.content_margin_bottom = 3
	theme.set_stylebox("separator", "HSeparator", sep_style)
	theme.set_constant("separation", "HSeparator", 6)

	# === RichTextLabel ===
	theme.set_color("default_color", "RichTextLabel", TEXT_DARK)
	theme.set_font_size("normal_font_size", "RichTextLabel", 13)

	return theme


# === 헬퍼 함수 ===

static func _make_panel(bg: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style


## 헤더 스타일 패널 생성 (카이로소프트의 색 띠 헤더)
static func make_header_panel(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.set_content_margin_all(8)
	style.content_margin_left = 12
	return style


## 카드 스타일 패널 (자원 표시용)
static func make_resource_card(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_PANEL
	style.border_color = accent_color
	style.set_border_width_all(0)
	style.border_width_left = 4
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	style.content_margin_left = 12
	style.shadow_color = Color(0, 0, 0, 0.1)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1, 1)
	return style


## 색상 버튼 스타일 생성
static func make_colored_button(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1, 2)
	return style


## 상태 뱃지 스타일 (작은 둥근 뱃지)
static func make_badge(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.set_content_margin_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


## 구분선 스타일
static func make_separator(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(0)
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


## 뉴스 티커 스타일 패널
static func make_news_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.98, 0.92, 0.95)
	style.border_color = Color(0.85, 0.75, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.08)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style
