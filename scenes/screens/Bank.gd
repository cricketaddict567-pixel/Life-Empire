extends Control
## Screen 6 — savings, loans and the simulated market.

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

	col.add_child(UI.h1("Bank"))
	col.add_child(UI.muted("Savings earn 6% a year. Loans cost 11% a year and repay themselves from your cash.", 15))

	var summary := UI.gold_card()
	var s := UI.vbox(8)
	summary.add_child(s)
	s.add_child(UI.label("CASH", 13, LETheme.GOLD))
	s.add_child(UI.label(GameState.money_text(GameState.cash()), 34, LETheme.GOLD_LIGHT, true))
	s.add_child(UI.row("In savings", GameState.money_text(GameState.savings())))
	s.add_child(UI.row("Loan outstanding", GameState.money_text(GameState.loan_total()), LETheme.DANGER if GameState.loan_total() > 0 else LETheme.SUCCESS))
	s.add_child(UI.row("Loan limit", GameState.money_text(GameState.loan_limit())))
	col.add_child(summary)

	# Savings
	var save_card := UI.card(LETheme.SUCCESS)
	var sc := UI.vbox(10)
	save_card.add_child(sc)
	sc.add_child(UI.h2("Savings"))
	var row1 := UI.hbox(10)
	for amount in [50000, 500000]:
		var b := UI.button("Deposit " + GameState.money_text(amount), false, 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = GameState.cash() < amount
		b.pressed.connect(func() -> void: GameState.deposit(amount))
		row1.add_child(b)
	sc.add_child(row1)
	var row2 := UI.hbox(10)
	var dep_all := UI.button("Deposit all cash", false, 50)
	dep_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dep_all.disabled = GameState.cash() <= 0
	dep_all.pressed.connect(func() -> void: GameState.deposit(GameState.cash()))
	row2.add_child(dep_all)
	var wd := UI.button("Withdraw all", false, 50)
	wd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wd.disabled = GameState.savings() <= 0
	wd.pressed.connect(func() -> void: GameState.withdraw(GameState.savings()))
	row2.add_child(wd)
	sc.add_child(row2)
	col.add_child(save_card)

	# Loans
	var loan_card := UI.card(LETheme.DANGER)
	var lc := UI.vbox(10)
	loan_card.add_child(lc)
	lc.add_child(UI.h2("Loans"))
	if GameState.loans.is_empty():
		lc.add_child(UI.muted("No active loans.", 15))
	for i in range(GameState.loans.size()):
		var l: Dictionary = GameState.loans[i]
		lc.add_child(UI.row("Loan %d" % (i + 1), GameState.money_text(int(l["remaining"])), LETheme.DANGER))
	var row3 := UI.hbox(10)
	for amount in [100000, 1000000]:
		var b2 := UI.button("Borrow " + GameState.money_text(amount), false, 50)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.disabled = GameState.loan_total() + amount > GameState.loan_limit()
		b2.pressed.connect(func() -> void: GameState.take_loan(amount))
		row3.add_child(b2)
	lc.add_child(row3)
	if GameState.loan_total() > 0:
		var rep := UI.button("Repay 25% of outstanding", false, 50)
		rep.disabled = GameState.cash() <= 0
		rep.pressed.connect(func() -> void: GameState.repay_loan(int(float(GameState.loan_total()) * 0.25)))
		lc.add_child(rep)
		var rep_all := UI.button("Repay everything possible", false, 50)
		rep_all.disabled = GameState.cash() <= 0
		rep_all.pressed.connect(func() -> void: GameState.repay_loan(mini(GameState.cash(), GameState.loan_total())))
		lc.add_child(rep_all)
	col.add_child(loan_card)
	col.add_child(UI.spacer(16))
