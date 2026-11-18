extends Control
## Screen 1 — who are you? Name, gender, starting age and family background.

var _name_input: LineEdit
var _gender: OptionButton
var _age: OptionButton
var _background: String = "middle"
var _bg_buttons: Dictionary = {}
var _error: Label

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()

	var scroll := UI.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var margin := UI.margins(24, 40, 24, 32)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var col := UI.vbox(18)
	margin.add_child(col)

	col.add_child(UI.label("LIFE EMPIRE", 40, LETheme.GOLD, true))
	col.add_child(LETheme.gold_rule(96))
	col.add_child(UI.muted("Build a life. Build an empire. Every year is a choice.", 17))
	col.add_child(UI.spacer(10))

	# Name
	var name_card := UI.card(LETheme.PRIMARY)
	var ncol := UI.vbox(8)
	name_card.add_child(ncol)
	ncol.add_child(UI.label("Your name", 16, LETheme.MUTED))
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "e.g. Aarav Sharma"
	_name_input.custom_minimum_size = Vector2(0, 56)
	ncol.add_child(_name_input)
	col.add_child(name_card)

	# Gender and age
	var row := UI.hbox(14)
	var gcard := UI.card(LETheme.PURPLE)
	var gcol := UI.vbox(8)
	gcard.add_child(gcol)
	gcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gcol.add_child(UI.label("Gender", 16, LETheme.MUTED))
	_gender = OptionButton.new()
	_gender.add_item("Male", 0)
	_gender.add_item("Female", 1)
	_gender.add_item("Other", 2)
	_gender.custom_minimum_size = Vector2(0, 52)
	gcol.add_child(_gender)
	row.add_child(gcard)

	var acard := UI.card(LETheme.GOLD)
	var acol := UI.vbox(8)
	acard.add_child(acol)
	acol.add_child(UI.label("Starting age", 16, LETheme.MUTED))
	_age = OptionButton.new()
	for a in [18, 20, 22, 25]:
		_age.add_item(str(a), a)
	_age.custom_minimum_size = Vector2(0, 52)
	acol.add_child(_age)
	row.add_child(acard)
	col.add_child(row)

	# Background
	col.add_child(UI.h2("Family background"))
	for id in ["poor", "middle", "rich"]:
		var bg: Dictionary = Database.background(String(id))
		var b := Button.new()
		b.text = "%s\n%s\nStarts with %s" % [String(bg["name"]), String(bg["desc"]), GameState.money_text(int(bg["cash"]))]
		b.custom_minimum_size = Vector2(0, 96)
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_select_background.bind(String(id)))
		col.add_child(b)
		_bg_buttons[String(id)] = b

	_error = UI.label("", 15, LETheme.DANGER)
	col.add_child(_error)

	var start := UI.button("Begin your life", true, 64)
	start.pressed.connect(_on_start)
	col.add_child(start)
	col.add_child(UI.spacer(20))

	_select_background(_background)

func _select_background(id: String) -> void:
	_background = id
	for key in _bg_buttons.keys():
		var b: Button = _bg_buttons[key]
		var active: bool = String(key) == id
		var accent: Color = LETheme.GOLD if active else LETheme.SURFACE_2
		b.add_theme_stylebox_override("normal", LETheme.outlined(LETheme.SURFACE if not active else LETheme.SURFACE_2, accent, 22, 2, 16))
		b.add_theme_color_override("font_color", LETheme.TEXT if active else LETheme.MUTED)

func _on_start() -> void:
	var name_text: String = _name_input.text.strip_edges()
	if name_text == "":
		_error.text = "Enter a name to begin."
		return
	var age: int = 18
	if _age.selected >= 0:
		age = int(_age.get_item_id(_age.selected))
	var gender: String = _gender.get_item_text(_gender.selected)
	GameState.new_game(name_text, gender, age, _background)
	SaveManager.save_game()
	EventBus.screen_requested.emit("dashboard")
