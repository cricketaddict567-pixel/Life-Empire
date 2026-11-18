class_name LETheme
extends RefCounted
## Premium blue / purple / gold theme, built in code so there are no
## binary theme resources to keep in sync and no paid assets.

const BG := Color("0b0a20")
const BG_2 := Color("140f33")
const SURFACE := Color("1b1745")
const SURFACE_2 := Color("241e58")
const PRIMARY := Color("3d6bff")
const PURPLE := Color("7b4dff")
const GOLD := Color("e9b949")
const GOLD_LIGHT := Color("ffe9a8")
const TEXT := Color("f3f1ff")
const MUTED := Color("a8a3d4")
const SUCCESS := Color("35d07f")
const DANGER := Color("ff5c7a")
const WARN := Color("ffb347")

static func rounded(color: Color, radius: int = 24, pad: int = 20) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb

static func outlined(color: Color, border: Color, radius: int = 24, width: int = 2, pad: int = 20) -> StyleBoxFlat:
	var sb := rounded(color, radius, pad)
	sb.border_color = border
	sb.border_width_left = width
	sb.border_width_right = width
	sb.border_width_top = width
	sb.border_width_bottom = width
	return sb

static func gold_button() -> StyleBoxFlat:
	var sb := rounded(GOLD, 26, 18)
	sb.shadow_color = Color(0.91, 0.72, 0.28, 0.35)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 6)
	return sb

static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18

	# Base surfaces
	t.set_stylebox("panel", "PanelContainer", rounded(SURFACE))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "RichTextLabel", TEXT)
	t.set_font_size("font_size", "Label", 18)

	# Cards use PanelContainer; a plain "card" variant is applied per node.
	t.add_type("Card")

	# Buttons
	var normal := rounded(SURFACE_2, 22, 16)
	var hover := rounded(Color("2e2770"), 22, 16)
	var pressed := rounded(Color("1a1540"), 22, 16)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", rounded(Color("171334"), 22, 16))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD_LIGHT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("6a66a0"))
	t.set_font_size("font_size", "Button", 18)

	# Scroll container transparency
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	# Progress bars
	t.set_stylebox("background", "ProgressBar", rounded(Color("0f0c2b"), 8, 0))
	t.set_stylebox("fill", "ProgressBar", rounded(PRIMARY, 8, 0))
	t.set_color("font_color", "ProgressBar", TEXT)

	# Inputs
	t.set_stylebox("normal", "LineEdit", outlined(Color("120f2e"), Color("3a3378"), 18, 2, 16))
	t.set_stylebox("focus", "LineEdit", outlined(Color("120f2e"), GOLD, 18, 2, 16))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", MUTED)
	t.set_font_size("font_size", "LineEdit", 18)

	t.set_stylebox("normal", "OptionButton", rounded(SURFACE_2, 18, 16))
	t.set_stylebox("hover", "OptionButton", rounded(Color("2e2770"), 18, 16))
	t.set_color("font_color", "OptionButton", TEXT)

	return t

## Vertical gradient backdrop for the whole app.
static func backdrop() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, BG)
	g.set_color(1, BG_2)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0.4, 1.0)
	tex.width = 256
	tex.height = 256
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

## Gold rule used under section headings.
static func gold_rule(width: int = 64) -> ColorRect:
	var r := ColorRect.new()
	r.color = GOLD
	r.custom_minimum_size = Vector2(width, 4)
	r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return r
