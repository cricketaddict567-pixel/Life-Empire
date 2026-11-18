extends Control
## Screen 4 — degrees. Each degree costs money up front and takes years.

func _ready() -> void:
	EventBus.state_changed.connect(_on_state_changed)
	_build()

func _on_state_changed() -> void:
	call_deferred("_build")

func _build() -> void:
	for c in get_children():
		c.queue_free()
	if not GameState.has_game():
		return
	var p: Dictionary = GameState.player
	var scroll := UI.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin := UI.margins(20, 28, 20, 24)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var col := UI.vbox(16)
	margin.add_child(col)

	var back := UI.ghost_button("←  Back to career")
	back.pressed.connect(func() -> void: EventBus.screen_requested.emit("career"))
	col.add_child(back)

	col.add_child(UI.h1("Education"))
	col.add_child(UI.muted("Cash available: %s" % GameState.money_text(GameState.cash()), 15))

	var studying: String = String(p.get("studying", ""))
	if studying != "":
		var d: Dictionary = Database.degree(studying)
		var card := UI.gold_card()
		var c := UI.vbox(6)
		card.add_child(c)
		c.add_child(UI.label("STUDYING", 13, LETheme.GOLD))
		c.add_child(UI.label(String(d.get("name", studying)), 22, LETheme.TEXT, true))
		c.add_child(UI.row("Years left", str(int(p.get("study_years_left", 0)))))
		col.add_child(card)

	col.add_child(UI.h2("Available courses"))
	for id in Database.DEGREES.keys():
		var d2: Dictionary = Database.degree(String(id))
		var done: bool = GameState.has_degree(String(id))
		var card2 := UI.card(LETheme.SUCCESS if done else LETheme.PRIMARY)
		var c2 := UI.vbox(8)
		card2.add_child(c2)
		c2.add_child(UI.label(String(d2["name"]), 20, LETheme.TEXT, true))
		c2.add_child(UI.muted(String(d2["desc"]), 15))
		c2.add_child(UI.row("Cost", GameState.money_text(int(d2["cost"]))))
		c2.add_child(UI.row("Duration", "%d years" % int(d2["years"])))
		c2.add_child(UI.row("Smarts gained", "+%d" % int(d2["smarts"])))
		if done:
			c2.add_child(UI.pill("Completed", LETheme.SUCCESS))
		elif studying != "":
			c2.add_child(UI.muted("Finish your current course first.", 14))
		else:
			var enroll := UI.button("Enroll", false, 50)
			enroll.disabled = GameState.cash() < int(d2["cost"])
			enroll.pressed.connect(func() -> void: GameState.enroll_degree(String(id)))
			c2.add_child(enroll)
		col.add_child(card2)
	col.add_child(UI.spacer(16))
