extends Control
## App shell: theme, screen routing and the bottom navigation bar.

const SCREEN_SCRIPTS := {
	"creation": "res://scenes/screens/CharacterCreation.gd",
	"dashboard": "res://scenes/screens/Dashboard.gd",
	"career": "res://scenes/screens/Career.gd",
	"education": "res://scenes/screens/Education.gd",
	"business": "res://scenes/screens/Business.gd",
	"bank": "res://scenes/screens/Bank.gd",
	"life": "res://scenes/screens/Life.gd",
}

const TABS := [
	{"id": "dashboard", "label": "Home"},
	{"id": "career", "label": "Career"},
	{"id": "business", "label": "Business"},
	{"id": "bank", "label": "Bank"},
	{"id": "life", "label": "Life"},
]

var _content: Control
var _nav_panel: PanelContainer
var _nav: HBoxContainer
var _nav_buttons: Dictionary = {}
var _screen: Control = null
var _current: String = ""

func _ready() -> void:
	theme = LETheme.build()
	_build_layout()
	EventBus.screen_requested.connect(show_screen)
	if SaveManager.has_save() and SaveManager.load_game():
		show_screen("dashboard")
	else:
		show_screen("creation")

func _build_layout() -> void:
	add_child(LETheme.backdrop())

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)

	_nav_panel = PanelContainer.new()
	_nav_panel.add_theme_stylebox_override("panel", LETheme.rounded(LETheme.BG_2, 0, 8))
	_nav_panel.custom_minimum_size = Vector2(0, 84)
	root.add_child(_nav_panel)

	_nav = HBoxContainer.new()
	_nav.add_theme_constant_override("separation", 0)
	_nav_panel.add_child(_nav)

	for tab in TABS:
		var b := Button.new()
		b.text = String(tab["label"])
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 76)
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(_on_tab_pressed.bind(String(tab["id"])))
		_nav.add_child(b)
		_nav_buttons[String(tab["id"])] = b

func _on_tab_pressed(id: String) -> void:
	show_screen(id)

func show_screen(screen_name: String) -> void:
	if not SCREEN_SCRIPTS.has(screen_name):
		push_warning("Unknown screen: %s" % screen_name)
		return
	if _screen != null and is_instance_valid(_screen):
		_screen.queue_free()
		_screen = null
	var script: GDScript = load(String(SCREEN_SCRIPTS[screen_name]))
	if script == null:
		push_error("Missing screen script for %s" % screen_name)
		return
	_screen = script.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(_screen)
	_current = screen_name
	_nav_panel.visible = screen_name != "creation"
	_update_nav()

func _update_nav() -> void:
	for id in _nav_buttons.keys():
		var b: Button = _nav_buttons[id]
		var active: bool = String(id) == _current
		b.add_theme_color_override("font_color", LETheme.GOLD if active else LETheme.MUTED)
		b.add_theme_color_override("font_hover_color", LETheme.GOLD_LIGHT)
		b.add_theme_color_override("font_pressed_color", LETheme.GOLD)
