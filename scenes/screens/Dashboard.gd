extends Control
## Screen 2 — the life at a glance, and the button that advances a year.

var _busy: bool = false

func _ready() -> void:
	EventBus.state_changed.connect(_on_state_changed)
	_build()

func _on_state_changed() -> void:
	if _busy:
		return
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

	# Header
	var head := UI.hbox(10)
	var hcol := UI.vbox(2)
	hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hcol.add_child(UI.label(String(p["name"]), 28, LETheme.TEXT, true))
	hcol.add_child(UI.muted("%s · Age %d · Level %d" % [String(p["gender"]), int(p["age"]), int(p["level"])], 15))
	head.add_child(hcol)
	head.add_child(UI.pill("Year %d" % int(p.get("year", 1)), LETheme.GOLD))
	col.add_child(head)

	# Net worth
	var worth := UI.gold_card(22)
	var wcol := UI.vbox(6)
	worth.add_child(wcol)
	wcol.add_child(UI.label("NET WORTH", 14, LETheme.GOLD))
	wcol.add_child(UI.label(GameState.money_text(GameState.net_worth()), 40, LETheme.GOLD_LIGHT, true))
	var wrow := UI.hbox(10)
	wrow.add_child(UI.row("Cash", GameState.money_text(GameState.cash())))
	wrow.add_child(UI.row("Savings", GameState.money_text(GameState.savings())))
	wcol.add_child(wrow)
	col.add_child(worth)

	# Stats
	var stats_card := UI.card(LETheme.PRIMARY)
	var scol := UI.vbox(12)
	stats_card.add_child(scol)
	scol.add_child(UI.h2("Wellbeing"))
	scol.add_child(UI.stat_bar("Health", float(p["health"]), LETheme.SUCCESS))
	scol.add_child(UI.stat_bar("Happiness", float(p["happiness"]), LETheme.GOLD))
	scol.add_child(UI.stat_bar("Smarts", float(p["smarts"]), LETheme.PRIMARY))
	scol.add_child(UI.stat_bar("Fitness", float(p["fitness"]), LETheme.PURPLE))
	scol.add_child(UI.stat_bar("Reputation", float(p["reputation"]), LETheme.WARN))
	col.add_child(stats_card)

	# Life summary
	var life_card := UI.card(LETheme.PURPLE)
	var lcol := UI.vbox(8)
	life_card.add_child(lcol)
	lcol.add_child(UI.h2("Life"))
	var job_id: String = String(p.get("job", ""))
	if job_id == "":
		lcol.add_child(UI.row("Career", "Unemployed", LETheme.DANGER))
	else:
		lcol.add_child(UI.row("Career", String(Database.job(job_id).get("name", job_id))))
	lcol.add_child(UI.row("Businesses", str(GameState.businesses.size())))
	lcol.add_child(UI.row("Properties", str(GameState.properties.size())))
	lcol.add_child(UI.row("Degrees", str(p["degrees"].size())))
	lcol.add_child(UI.row("Loans", GameState.money_text(GameState.loan_total()), LETheme.DANGER if GameState.loan_total() > 0 else LETheme.SUCCESS))
	col.add_child(life_card)

	# Advance year
	if GameState.game_over:
		var over := UI.card(LETheme.DANGER)
		var ocol := UI.vbox(8)
		over.add_child(ocol)
		ocol.add_child(UI.h2("Life complete"))
		ocol.add_child(UI.body(GameState.death_reason))
		ocol.add_child(UI.muted("Final net worth: %s" % GameState.money_text(GameState.net_worth())))
		col.add_child(over)
	else:
		var next := UI.button("Next Year  →", true, 68)
		next.pressed.connect(_on_next_year)
		col.add_child(next)
		col.add_child(UI.muted("Age %d of %d expected years" % [int(p["age"]), int(p.get("lifespan", 80))], 14))

	# Recent events
	if not GameState.event_log.is_empty():
		var log_card := UI.card(LETheme.MUTED)
		var gcol := UI.vbox(6)
		log_card.add_child(gcol)
		gcol.add_child(UI.h2("Recent"))
		var start: int = maxi(0, GameState.event_log.size() - 6)
		for i in range(GameState.event_log.size() - 1, start - 1, -1):
			gcol.add_child(UI.muted("• " + String(GameState.event_log[i]), 15))
		col.add_child(log_card)
	col.add_child(UI.spacer(16))

func _on_next_year() -> void:
	_busy = true
	GameState.advance_year()
	SaveManager.save_game()
	_busy = false
	_build()
