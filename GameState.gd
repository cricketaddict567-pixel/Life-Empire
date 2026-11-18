extends Node
## LIFE EMPIRE — the life-simulation model.
## Holds every number about the player's life and applies the yearly rules.
## It emits signals and never touches the UI.

const SAVE_VERSION: int = 1
const SAVINGS_RATE: float = 0.06
const LOAN_RATE: float = 0.11
const BUSINESS_UPKEEP: float = 0.15
const LIVING_COST: int = 120000

var player: Dictionary = {}
var businesses: Array = []
var properties: Array = []
var loans: Array = []
var achievements: Array = []
var event_log: Array = []
var game_over: bool = false
var death_reason: String = ""

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func has_game() -> bool:
	return not player.is_empty()

# ---------------------------------------------------------------- new game

func new_game(p_name: String, p_gender: String, p_age: int, p_background: String) -> void:
	var clean_name: String = p_name.strip_edges()
	if clean_name == "":
		clean_name = "Player"
	var bg: Dictionary = Database.background(p_background)
	player = {
		"name": clean_name,
		"gender": p_gender,
		"age": p_age,
		"background": p_background,
		"cash": int(bg["cash"]),
		"savings": 0,
		"health": 85.0,
		"happiness": float(bg["happiness"]),
		"smarts": float(bg["smarts"]),
		"fitness": 60.0,
		"reputation": float(bg["reputation"]),
		"degrees": [],
		"studying": "",
		"study_years_left": 0,
		"job": "",
		"job_level": 0,
		"job_years": 0,
		"performance": 50.0,
		"xp": 0,
		"level": 1,
		"lifespan": _rng.randi_range(72, 94),
		"partner": "",
		"children": 0,
		"year": 1,
	}
	businesses = []
	properties = []
	loans = []
	achievements = []
	event_log = []
	game_over = false
	death_reason = ""
	_log("You began your life at age %d with %s." % [p_age, money_text(int(bg["cash"]))])
	EventBus.state_changed.emit()

# ------------------------------------------------------------------ money

func cash() -> int:
	return int(player.get("cash", 0))

func savings() -> int:
	return int(player.get("savings", 0))

func net_worth() -> int:
	var total: int = cash() + savings()
	for b in businesses:
		total += Database.business_value(String(b["id"]), int(b["level"]))
	for pid in properties:
		total += int(float(Database.property(String(pid)).get("cost", 0)) * 0.5)
	for l in loans:
		total -= int(l["remaining"])
	return total

func add_cash(amount: int) -> void:
	player["cash"] = cash() + amount
	EventBus.money_changed.emit(cash())

func spend_cash(amount: int) -> bool:
	if amount < 0 or cash() < amount:
		return false
	player["cash"] = cash() - amount
	EventBus.money_changed.emit(cash())
	return true

static func money_text(amount: int) -> String:
	var neg: bool = amount < 0
	var v: int = absi(amount)
	var out: String
	if v >= 10000000:
		out = "%.2f Cr" % (float(v) / 10000000.0)
	elif v >= 100000:
		out = "%.2f L" % (float(v) / 100000.0)
	elif v >= 1000:
		out = "%.1f K" % (float(v) / 1000.0)
	else:
		out = str(v)
	return ("-" if neg else "") + "₹" + out

# ------------------------------------------------------------- the year

func advance_year() -> Array:
	var report: Array = []
	if game_over or player.is_empty():
		return report
	player["age"] = int(player["age"]) + 1
	player["year"] = int(player.get("year", 1)) + 1
	report.append("You turned %d." % int(player["age"]))

	_resolve_education(report)
	_resolve_job(report)
	_resolve_businesses(report)
	_resolve_finance(report)
	_resolve_living_costs(report)
	_resolve_stats(report)
	_resolve_random_event(report)
	_resolve_achievements(report)
	_resolve_level()
	_check_death(report)

	for line in report:
		_log(String(line))
	EventBus.aged_up.emit(int(player["age"]))
	EventBus.year_report.emit(report)
	EventBus.state_changed.emit()
	return report

func _resolve_education(report: Array) -> void:
	var studying: String = String(player.get("studying", ""))
	if studying == "":
		return
	var years_left: int = int(player.get("study_years_left", 0)) - 1
	player["study_years_left"] = years_left
	if years_left <= 0:
		var d: Dictionary = Database.degree(studying)
		var degs: Array = player["degrees"]
		degs.append(studying)
		player["degrees"] = degs
		player["studying"] = ""
		player["smarts"] = minf(100.0, float(player["smarts"]) + float(d.get("smarts", 0.0)))
		player["happiness"] = minf(100.0, float(player["happiness"]) + 5.0)
		report.append("You completed %s." % String(d.get("name", studying)))
	else:
		report.append("%s: %d year(s) left." % [String(Database.degree(studying).get("name", studying)), years_left])

func _resolve_job(report: Array) -> void:
	var job_id: String = String(player.get("job", ""))
	if job_id == "":
		return
	var level: int = int(player.get("job_level", 0))
	var salary: int = Database.job_salary(job_id, level)
	add_cash(salary)
	report.append("%s paid you %s." % [String(Database.job(job_id).get("name", job_id)), money_text(salary)])

	player["job_years"] = int(player.get("job_years", 0)) + 1
	var perf: float = clampf(float(player.get("performance", 50.0)) + _rng.randf_range(-6.0, 9.0) + float(player.get("smarts", 50.0)) * 0.03, 0.0, 100.0)
	player["performance"] = perf

	var need: int = int(Database.job(job_id).get("promote_years", 3))
	if int(player["job_years"]) >= need and perf >= 60.0:
		player["job_level"] = level + 1
		player["job_years"] = 0
		player["happiness"] = minf(100.0, float(player["happiness"]) + 6.0)
		player["reputation"] = minf(100.0, float(player["reputation"]) + 3.0)
		report.append("Promoted. New salary: %s." % money_text(Database.job_salary(job_id, level + 1)))

func _resolve_businesses(report: Array) -> void:
	if businesses.is_empty():
		return
	var total: int = 0
	for b in businesses:
		var gross: int = Database.business_income(String(b["id"]), int(b["level"]))
		var upkeep: int = int(float(gross) * BUSINESS_UPKEEP)
		total += gross - upkeep
	if total != 0:
		add_cash(total)
		report.append("Your businesses earned %s after upkeep." % money_text(total))

func _resolve_finance(report: Array) -> void:
	if savings() > 0:
		var interest: int = int(float(savings()) * SAVINGS_RATE)
		if interest > 0:
			player["savings"] = savings() + interest
			report.append("Savings interest: %s." % money_text(interest))
	if loans.is_empty():
		return
	var keep: Array = []
	for l in loans:
		var remaining: float = float(l["remaining"]) * (1.0 + LOAN_RATE)
		var pay: float = minf(remaining, maxf(float(cash()) * 0.3, remaining * 0.25))
		if pay > 0.0 and cash() > 0:
			var pay_int: int = int(minf(pay, float(cash())))
			add_cash(-pay_int)
			remaining -= float(pay_int)
			report.append("Loan repayment: %s." % money_text(pay_int))
		if remaining > 1.0:
			l["remaining"] = int(remaining)
			keep.append(l)
		else:
			report.append("A loan is fully repaid.")
	loans = keep

func _resolve_living_costs(report: Array) -> void:
	var cost: int = LIVING_COST
	if not properties.is_empty():
		cost += int(float(properties.size()) * LIVING_COST * 0.35)
	add_cash(-cost)
	report.append("Living costs: %s." % money_text(cost))

func _resolve_stats(report: Array) -> void:
	var age: int = int(player["age"])
	var health: float = float(player["health"]) - (0.5 + maxf(0.0, float(age - 50)) * 0.09)
	var fitness: float = float(player["fitness"]) - 0.6
	var happiness: float = float(player["happiness"])
	happiness += (55.0 - happiness) * 0.06
	if health < 35.0:
		happiness -= 6.0
		report.append("Your health is slipping.")
	player["health"] = clampf(health, 0.0, 100.0)
	player["fitness"] = clampf(fitness, 0.0, 100.0)
	player["happiness"] = clampf(happiness, 0.0, 100.0)

func _resolve_random_event(report: Array) -> void:
	var ev: Dictionary = Database.pick_event()
	report.append(String(ev.get("text", "")))
	var effect: Dictionary = ev.get("effect", {})
	for key in effect.keys():
		var value: float = float(effect[key])
		if key == "cash":
			add_cash(int(value))
		elif player.has(key):
			player[key] = clampf(float(player[key]) + value, 0.0, 100.0)

func _resolve_achievements(report: Array) -> void:
	var checks: Array = [
		{"id": "first_business", "ok": businesses.size() > 0, "text": "First Business"},
		{"id": "lakhpati", "ok": net_worth() >= 1000000, "text": "Lakhpati (₹10 L net worth)"},
		{"id": "crorepati", "ok": net_worth() >= 10000000, "text": "Crorepati (₹1 Cr net worth)"},
		{"id": "educated", "ok": player["degrees"].size() >= 1, "text": "Graduate"},
		{"id": "empire", "ok": businesses.size() >= 3, "text": "Empire Builder (3 businesses)"},
	]
	for c in checks:
		if bool(c["ok"]) and not achievements.has(String(c["id"])):
			achievements.append(String(c["id"]))
			report.append("Achievement unlocked: %s." % String(c["text"]))

func _resolve_level() -> void:
	var xp: int = int(player.get("xp", 0))
	xp += maxi(1, int(float(maxi(0, net_worth())) / 250000.0))
	player["xp"] = xp
	player["level"] = 1 + int(xp / 250)

func _check_death(report: Array) -> void:
	if game_over:
		return
	var age: int = int(player["age"])
	if float(player["health"]) <= 0.0:
		game_over = true
		death_reason = "Your health gave out at age %d." % age
	elif age >= int(player.get("lifespan", 80)):
		game_over = true
		death_reason = "You lived a full life and passed away at age %d." % age
	if game_over:
		report.append(death_reason)
		EventBus.game_over.emit(death_reason)

# ---------------------------------------------------------------- actions

func buy_business(id: String) -> bool:
	var b: Dictionary = Database.business(id)
	if b.is_empty():
		return false
	for owned in businesses:
		if String(owned["id"]) == id:
			return upgrade_business(id)
	var cost: int = Database.business_upgrade_cost(id, 0)
	if not spend_cash(cost):
		return false
	businesses.append({"id": id, "level": 1})
	_log("You bought %s for %s." % [String(b["name"]), money_text(cost)])
	EventBus.state_changed.emit()
	return true

func upgrade_business(id: String) -> bool:
	for owned in businesses:
		if String(owned["id"]) == id:
			var level: int = int(owned["level"])
			var max_level: int = int(Database.business(id).get("max_level", 12))
			if level >= max_level:
				return false
			var cost: int = Database.business_upgrade_cost(id, level)
			if not spend_cash(cost):
				return false
			owned["level"] = level + 1
			_log("You upgraded %s to level %d for %s." % [String(Database.business(id)["name"]), level + 1, money_text(cost)])
			EventBus.state_changed.emit()
			return true
	return false

func business_level(id: String) -> int:
	for owned in businesses:
		if String(owned["id"]) == id:
			return int(owned["level"])
	return 0

func take_loan(amount: int) -> bool:
	if amount <= 0:
		return false
	var limit: int = maxi(100000, int(float(net_worth()) * 0.6))
	var borrowed: int = 0
	for l in loans:
		borrowed += int(l["remaining"])
	if borrowed + amount > limit:
		return false
	loans.append({"remaining": amount})
	add_cash(amount)
	_log("You took a loan of %s." % money_text(amount))
	EventBus.state_changed.emit()
	return true

func loan_total() -> int:
	var total: int = 0
	for l in loans:
		total += int(l["remaining"])
	return total

func loan_limit() -> int:
	return maxi(100000, int(float(net_worth()) * 0.6))

func repay_loan(amount: int) -> bool:
	var total: int = loan_total()
	if total <= 0 or amount <= 0:
		return false
	var pay: int = mini(amount, total)
	if not spend_cash(pay):
		return false
	var left: int = pay
	for l in loans:
		if left <= 0:
			break
		var take: int = mini(left, int(l["remaining"]))
		l["remaining"] = int(l["remaining"]) - take
		left -= take
	var keep: Array = []
	for l in loans:
		if int(l["remaining"]) > 0:
			keep.append(l)
	loans = keep
	_log("You repaid %s of your loan." % money_text(pay))
	EventBus.state_changed.emit()
	return true

func deposit(amount: int) -> bool:
	if not spend_cash(amount):
		return false
	player["savings"] = savings() + amount
	EventBus.state_changed.emit()
	return true

func withdraw(amount: int) -> bool:
	if amount <= 0 or savings() < amount:
		return false
	player["savings"] = savings() - amount
	add_cash(amount)
	EventBus.state_changed.emit()
	return true

func enroll_degree(id: String) -> bool:
	var d: Dictionary = Database.degree(id)
	if d.is_empty() or String(player.get("studying", "")) != "":
		return false
	if has_degree(id):
		return false
	if not spend_cash(int(d["cost"])):
		return false
	player["studying"] = id
	player["study_years_left"] = int(d["years"])
	_log("You enrolled in %s." % String(d["name"]))
	EventBus.state_changed.emit()
	return true

func has_degree(id: String) -> bool:
	return player.get("degrees", []).has(id)

func can_take_job(id: String) -> bool:
	var j: Dictionary = Database.job(id)
	if j.is_empty():
		return false
	var req: String = String(j.get("degree", ""))
	if req != "" and not has_degree(req):
		return false
	return float(player.get("smarts", 0.0)) >= float(j.get("smarts", 0.0))

func apply_job(id: String) -> bool:
	if not can_take_job(id):
		return false
	player["job"] = id
	player["job_level"] = 0
	player["job_years"] = 0
	player["performance"] = 50.0
	_log("You joined as %s." % String(Database.job(id)["name"]))
	EventBus.state_changed.emit()
	return true

func quit_job() -> void:
	if String(player.get("job", "")) == "":
		return
	_log("You left your job.")
	player["job"] = ""
	player["job_level"] = 0
	player["job_years"] = 0
	EventBus.state_changed.emit()

func buy_property(id: String) -> bool:
	var p: Dictionary = Database.property(id)
	if p.is_empty() or properties.has(id):
		return false
	if not spend_cash(int(p["cost"])):
		return false
	properties.append(id)
	player["happiness"] = minf(100.0, float(player["happiness"]) + float(p.get("happiness", 0.0)))
	player["reputation"] = minf(100.0, float(player["reputation"]) + float(p.get("reputation", 0.0)))
	_log("You bought %s." % String(p["name"]))
	EventBus.state_changed.emit()
	return true

func _log(message: String) -> void:
	if message.strip_edges() == "":
		return
	event_log.append("Age %d — %s" % [int(player.get("age", 18)), message])
	while event_log.size() > 40:
		event_log.pop_front()

# ------------------------------------------------------------ serialising

func to_dict() -> Dictionary:
	return {
		"player": player.duplicate(true),
		"businesses": businesses.duplicate(true),
		"properties": properties.duplicate(true),
		"loans": loans.duplicate(true),
		"achievements": achievements.duplicate(true),
		"event_log": event_log.duplicate(true),
		"game_over": game_over,
		"death_reason": death_reason,
	}

func from_dict(data: Dictionary) -> bool:
	if not data.has("player"):
		return false
	var p: Variant = data["player"]
	if typeof(p) != TYPE_DICTIONARY:
		return false
	player = p
	businesses = data.get("businesses", [])
	properties = data.get("properties", [])
	loans = data.get("loans", [])
	achievements = data.get("achievements", [])
	event_log = data.get("event_log", [])
	game_over = bool(data.get("game_over", false))
	death_reason = String(data.get("death_reason", ""))
	# JSON turns typed numbers into floats; normalise the fields the rules rely on.
	player["age"] = int(player.get("age", 18))
	player["cash"] = int(player.get("cash", 0))
	player["savings"] = int(player.get("savings", 0))
	player["job_level"] = int(player.get("job_level", 0))
	player["job_years"] = int(player.get("job_years", 0))
	player["study_years_left"] = int(player.get("study_years_left", 0))
	player["lifespan"] = int(player.get("lifespan", 80))
	player["xp"] = int(player.get("xp", 0))
	player["level"] = int(player.get("level", 1))
	player["year"] = int(player.get("year", 1))
	for b in businesses:
		b["level"] = int(b.get("level", 1))
	for l in loans:
		l["remaining"] = int(l.get("remaining", 0))
	EventBus.state_changed.emit()
	return true
