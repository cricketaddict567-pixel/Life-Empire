extends Control
## Screen 7 — property, achievements and save management.

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

	col.add_child(UI.h1("Life"))
	col.add_child(UI.muted("%s · %s · Age %d" % [String(p["name"]), String(p["gender"]), int(p["age"])], 15))

	col.add_child(UI.h2("Property & lifestyle"))
	for id in Database.PROPERTIES.keys():
		var pr: Dictionary = Database.property(String(id))
		var owned: bool = GameState.properties.has(String(id))
		var card := UI.card(LETheme.GOLD if owned else LETheme.PURPLE)
		var c := UI.vbox(8)
		card.add_child(c)
		var head := UI.hbox(8)
		var hcol := UI.vbox(2)
		hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hcol.add_child(UI.label(String(pr["name"]), 20, LETheme.TEXT, true))
		hcol.add_child(UI.muted("Happiness +%d · Reputation +%d" % [int(pr["happiness"]), int(pr["reputation"])], 14))
		head.add_child(hcol)
		head.add_child(UI.pill(GameState.money_text(int(pr["cost"])), LETheme.GOLD))
		c.add_child(head)
		if owned:
			c.add_child(UI.pill("Owned", LETheme.SUCCESS))
		else:
			var buy := UI.button("Buy", false, 48)
			buy.disabled = GameState.cash() < int(pr["cost"])
			buy.pressed.connect(func() -> void: GameState.buy_property(String(id)))
			c.add_child(buy)
		col.add_child(card)

	col.add_child(UI.h2("Achievements"))
	var ach_card := UI.card(LETheme.SUCCESS)
	var ac := UI.vbox(8)
	ach_card.add_child(ac)
	if GameState.achievements.is_empty():
		ac.add_child(UI.muted("None yet. Buy a business or finish a degree.", 15))
	else:
		for a in GameState.achievements:
			ac.add_child(UI.pill(String(a).replace("_", " ").capitalize(), LETheme.GOLD))
	col.add_child(ach_card)

	col.add_child(UI.h2("Game"))
	var save_btn := UI.button("Save now", false, 52)
	save_btn.pressed.connect(func() -> void:
		var ok: bool = SaveManager.save_game()
		EventBus.toast.emit("Saved." if ok else "Save failed."))
	col.add_child(save_btn)
	col.add_child(UI.muted("The game saves automatically at the end of every year.", 14))

	var new_btn := UI.ghost_button("Start a new life (deletes this save)")
	new_btn.pressed.connect(_confirm_new_game)
	col.add_child(new_btn)
	col.add_child(UI.spacer(16))

func _confirm_new_game() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Delete this life and start again? This cannot be undone."
	dlg.title = "Start a new life"
	dlg.confirmed.connect(func() -> void:
		SaveManager.delete_save()
		GameState.player = {}
		GameState.businesses = []
		GameState.properties = []
		GameState.loans = []
		GameState.achievements = []
		GameState.event_log = []
		GameState.game_over = false
		GameState.death_reason = ""
		EventBus.screen_requested.emit("creation"))
	add_child(dlg)
	dlg.popup_centered()
