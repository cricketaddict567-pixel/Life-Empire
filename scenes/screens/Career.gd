extends Control
## Screen 3 — current job, promotions and the job market.

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

	col.add_child(UI.h1("Career"))
	col.add_child(UI.muted("Age %d · Smarts %d" % [int(p["age"]), int(p["smarts"])], 15))

	var job_id: String = String(p.get("job", ""))
	if job_id != "":
		var j: Dictionary = Database.job(job_id)
		var card := UI.gold_card()
		var c := UI.vbox(10)
		card.add_child(c)
		c.add_child(UI.label("CURRENT JOB", 13, LETheme.GOLD))
		c.add_child(UI.label(String(j.get("name", job_id)), 26, LETheme.TEXT, true))
		c.add_child(UI.pill(String(j.get("category", "")), LETheme.PURPLE))
		c.add_child(UI.row("Salary per year", GameState.money_text(Database.job_salary(job_id, int(p["job_level"])))))
		c.add_child(UI.row("Grade", "Level %d" % (int(p["job_level"]) + 1)))
		c.add_child(UI.row("Years in grade", str(int(p["job_years"]))))
		c.add_child(UI.stat_bar("Performance", float(p["performance"]), LETheme.SUCCESS))
		c.add_child(UI.muted("Promotion needs performance 60+ and %d years in grade." % int(j.get("promote_years", 3)), 14))
		var quit := UI.ghost_button("Resign")
		quit.pressed.connect(func() -> void: GameState.quit_job())
		c.add_child(quit)
		col.add_child(card)
	else:
		var card := UI.card(LETheme.DANGER)
		var c := UI.vbox(6)
		card.add_child(c)
		c.add_child(UI.h2("Unemployed"))
		c.add_child(UI.muted("Apply for a job below, or start a business from the Business tab."))
		col.add_child(card)

	var edu := UI.ghost_button("Education & degrees  →")
	edu.pressed.connect(func() -> void: EventBus.screen_requested.emit("education"))
	col.add_child(edu)

	col.add_child(UI.h2("Job market"))
	for id in Database.JOBS.keys():
		var j: Dictionary = Database.job(String(id))
		var ok: bool = GameState.can_take_job(String(id))
		var card2 := UI.card(LETheme.PRIMARY if ok else LETheme.MUTED)
		var c2 := UI.vbox(8)
		card2.add_child(c2)
		var head := UI.hbox(8)
		var hcol := UI.vbox(2)
		hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hcol.add_child(UI.label(String(j["name"]), 20, LETheme.TEXT, true))
		hcol.add_child(UI.muted(String(j["category"]), 14))
		head.add_child(hcol)
		head.add_child(UI.pill(GameState.money_text(int(j["salary"])) + "/yr", LETheme.GOLD))
		c2.add_child(head)
		var req_degree: String = String(j.get("degree", ""))
		if req_degree != "":
			var d: Dictionary = Database.degree(req_degree)
			c2.add_child(UI.row("Needs degree", String(d.get("name", req_degree)), LETheme.SUCCESS if GameState.has_degree(req_degree) else LETheme.DANGER))
		if float(j.get("smarts", 0.0)) > 0.0:
			c2.add_child(UI.row("Needs smarts", str(int(j["smarts"])), LETheme.SUCCESS if float(p["smarts"]) >= float(j["smarts"]) else LETheme.DANGER))
		if ok:
			var apply := UI.button("Apply", false, 50)
			apply.pressed.connect(func() -> void: GameState.apply_job(String(id)))
			c2.add_child(apply)
		else:
			c2.add_child(UI.muted("Requirements not met.", 14))
		col.add_child(card2)
	col.add_child(UI.spacer(16))
