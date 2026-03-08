class_name GameTheme
extends RefCounted

## 게임 전체 테마를 코드로 생성 - 다크 사이버펑크 스타일


static func create_theme() -> Theme:
	var theme := Theme.new()

	# === 색상 팔레트 ===
	var bg_dark := Color(0.06, 0.06, 0.12)
	var bg_panel := Color(0.1, 0.1, 0.2, 0.95)
	var bg_button := Color(0.15, 0.15, 0.3)
	var bg_button_hover := Color(0.2, 0.2, 0.4)
	var bg_button_pressed := Color(0.1, 0.1, 0.25)
	var accent_cyan := Color(0.3, 0.85, 1.0)
	var accent_gold := Color(1.0, 0.85, 0.3)
	var accent_red := Color(1.0, 0.35, 0.35)
	var text_normal := Color(0.85, 0.85, 0.92)
	var text_dim := Color(0.55, 0.55, 0.65)
	var border_color := Color(0.25, 0.25, 0.5)
	var border_highlight := Color(0.4, 0.4, 0.8)

	# === Button ===
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = bg_button
	btn_normal.border_color = border_color
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(6)
	btn_normal.set_content_margin_all(10)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = bg_button_hover
	btn_hover.border_color = accent_cyan
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(6)
	btn_hover.set_content_margin_all(10)

	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = bg_button_pressed
	btn_pressed.border_color = accent_gold
	btn_pressed.set_border_width_all(2)
	btn_pressed.set_corner_radius_all(6)
	btn_pressed.set_content_margin_all(10)

	var btn_disabled := StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.1, 0.1, 0.15)
	btn_disabled.border_color = Color(0.2, 0.2, 0.25)
	btn_disabled.set_border_width_all(1)
	btn_disabled.set_corner_radius_all(6)
	btn_disabled.set_content_margin_all(10)

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_color", "Button", text_normal)
	theme.set_color("font_hover_color", "Button", accent_cyan)
	theme.set_color("font_pressed_color", "Button", accent_gold)
	theme.set_color("font_disabled_color", "Button", text_dim)
	theme.set_font_size("font_size", "Button", 15)

	# === Label ===
	theme.set_color("font_color", "Label", text_normal)
	theme.set_font_size("font_size", "Label", 15)

	# === PanelContainer ===
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = bg_panel
	panel_style.border_color = border_color
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(16)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# === ProgressBar ===
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.1, 0.1, 0.2)
	pb_bg.border_color = border_color
	pb_bg.set_border_width_all(1)
	pb_bg.set_corner_radius_all(4)
	pb_bg.set_content_margin_all(0)

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = accent_cyan
	pb_fill.set_corner_radius_all(3)
	pb_fill.set_content_margin_all(0)

	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	theme.set_color("font_color", "ProgressBar", text_normal)

	# === HSeparator ===
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = border_color
	sep_style.set_content_margin_all(0)
	sep_style.content_margin_top = 4
	sep_style.content_margin_bottom = 4
	theme.set_stylebox("separator", "HSeparator", sep_style)
	theme.set_constant("separation", "HSeparator", 8)

	# === ScrollContainer ===
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.05, 0.05, 0.1, 0.5)
	scroll_bg.set_corner_radius_all(4)

	# === RichTextLabel ===
	theme.set_color("default_color", "RichTextLabel", text_normal)
	theme.set_font_size("normal_font_size", "RichTextLabel", 14)

	return theme
