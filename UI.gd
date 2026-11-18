class_name UI
extends RefCounted
## Small widget factory. Every screen is built from these, so the look stays
## consistent and there is no .tscn per screen to maintain.

static func money(amount: int) -> String:
	return GameState.money_text(amount)

static func label(text: String, size: int = 18, color: Color = LETheme.TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 2)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func h1(text: String) -> Label:
	return label(text, 34, LETheme.TEXT, true)

static func h2(text: String) -> Label:
	return label(text, 24, LETheme.GOLD_LIGHT, true)

static func body(text: String) -> Label:
	return label(text, 18, LETheme.TEXT)

static func muted(text: String, size: int = 16) -> Label:
	return label(text, size, LETheme.MUTED)

static func spacer(height: int = 16) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

static func card(accent: Color = LETheme.PRIMARY, pad: int = 20) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", LETheme.outlined(LETheme.SURFACE, Color(accent.r, accent.g, accent.b, 0.28), 26, 2, pad))
	return p

static func gold_card(pad: int = 20) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", LETheme.outlined(LETheme.SURFACE_2, Color(0.91, 0.72, 0.28, 0.55), 26, 2, pad))
	return p

static func button(text: String, gold: bool = false, height: int = 56) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.focus_mode = Control.FOCUS_NONE
	if gold:
		b.add_theme_stylebox_override("normal", LETheme.gold_button())
		b.add_theme_stylebox_override("hover", LETheme.gold_button())
		b.add_theme_color_override("font_color", Color("1a1430"))
		b.add_theme_color_override("font_hover_color", Color("1a1430"))
		b.add_theme_color_override("font_pressed_color", Color("1a1430"))
		b.add_theme_font_size_override("font_size", 20)
	return b

static func ghost_button(text: String, height: int = 48) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", LETheme.outlined(Color(0, 0, 0, 0), LETheme.PRIMARY, 20, 2, 12))
	b.add_theme_color_override("font_color", LETheme.PRIMARY)
	return b

static func stat_bar(title: String, value: float, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	var name_label := muted(title, 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	head.add_child(label("%d" % int(value), 15, color, true))
	box.add_child(head)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.add_theme_stylebox_override("background", LETheme.rounded(Color("0f0c2b"), 6, 0))
	bar.add_theme_stylebox_override("fill", LETheme.rounded(color, 6, 0))
	box.add_child(bar)
	return box

static func row(title: String, value: String, value_color: Color = LETheme.GOLD_LIGHT) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var t := muted(title, 16)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(label(value, 17, value_color, true))
	return h

static func pill(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", LETheme.rounded(Color(color.r, color.g, color.b, 0.16), 14, 8))
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.add_child(label(text, 14, color, true))
	return p

static func scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return s

static func vbox(separation: int = 14) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v

static func hbox(separation: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return h

static func margins(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", left)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_right", right)
	m.add_theme_constant_override("margin_bottom", bottom)
	return m

static func divider() -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(1, 1, 1, 0.07)
	c.custom_minimum_size = Vector2(0, 1)
	return c
