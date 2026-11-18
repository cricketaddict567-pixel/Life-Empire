extends Control
## Screen 5 — the empire: buy and upgrade businesses.

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
	var scroll := UI.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin := UI.margins(20, 28, 20, 24)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var col := UI.vbox(16)
	margin.add_child(col)

	col.add_child(UI.h1("Empire"))
	col.add_child(UI.muted("Cash: %s  ·  Businesses owned: %d" % [GameState.money_text(GameState.cash()), GameState.businesses.size()], 15))

	for id in Database.BUSINESSES.keys():
		var b: Dictionary = Database.business(String(id))
		var level: int = GameState.business_level(String(id))
		var accent: Color = LETheme.GOLD if level > 0 else LETheme.PURPLE
		var card := UI.card(accent)
		var c := UI.vbox(8)
		card.add_child(c)
		var head := UI.hbox(8)
		var hcol := UI.vbox(2)
		hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hcol.add_child(UI.label(String(b["name"]), 22, LETheme.TEXT, true))
		hcol.add_child(UI.muted(String(b["desc"]), 14))
		head.add_child(hcol)
		head.add_child(UI.pill(String(b["category"]), accent))
		c.add_child(head)

		if level > 0:
			c.add_child(UI.row("Owned at level", "%d / %d" % [level, int(b["max_level"])], LETheme.GOLD))
			c.add_child(UI.row("Income per year", GameState.money_text(Database.business_income(String(id), level)), LETheme.SUCCESS))
		else:
			c.add_child(UI.row("Income per year at L1", GameState.money_text(Database.business_income(String(id), 1)), LETheme.SUCCESS))

		var cost: int = Database.business_upgrade_cost(String(id), level)
		c.add_child(UI.row("Buy" if level == 0 else "Upgrade cost", GameState.money_text(cost), LETheme.GOLD))
		var maxed: bool = level >= int(b["max_level"])
		var btn := UI.button("Buy business" if level == 0 else "Upgrade to L%d" % (level + 1), false, 52)
		btn.disabled = maxed or GameState.cash() < cost
		if maxed:
			btn.text = "Maximum level"
		if level == 0:
			btn.pressed.connect(func() -> void: GameState.buy_business(String(id)))
		else:
			btn.pressed.connect(func() -> void: GameState.upgrade_business(String(id)))
		c.add_child(btn)
		col.add_child(card)
	col.add_child(UI.spacer(16))
