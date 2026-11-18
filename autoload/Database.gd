extends Node
## Static game data: backgrounds, degrees, jobs, businesses, properties, events.
## Balance values live here so they can be tuned in one place.

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

## Make the whole simulation reproducible. Used by the headless tests so a
## balance run can be repeated exactly.
func use_seed(s: int) -> void:
	_rng.seed = s

const BACKGROUNDS := {
	"poor": {
		"name": "Working Class Family",
		"desc": "Your parents run a small shop. Every rupee counts.",
		"cash": 5000, "smarts": 40.0, "happiness": 55.0, "reputation": 0.0,
	},
	"middle": {
		"name": "Middle Class Family",
		"desc": "A rented flat, a scooter, and expectations of a stable job.",
		"cash": 50000, "smarts": 55.0, "happiness": 70.0, "reputation": 5.0,
	},
	"rich": {
		"name": "Business Family",
		"desc": "Family money and family pressure. The empire is expected.",
		"cash": 500000, "smarts": 65.0, "happiness": 75.0, "reputation": 20.0,
	},
}

const DEGREES := {
	"class12": {
		"name": "Class 12 (Commerce)",
		"cost": 30000, "years": 1, "smarts": 6.0,
		"desc": "Baseline schooling. Unlocks entry-level work.",
	},
	"bcom": {
		"name": "B.Com (Bachelor of Commerce)",
		"cost": 120000, "years": 3, "smarts": 14.0,
		"desc": "Accounting and finance. Opens banking and office careers.",
	},
	"btech": {
		"name": "B.Tech (Computer Science)",
		"cost": 400000, "years": 4, "smarts": 20.0,
		"desc": "Engineering. The door to software and technology companies.",
	},
	"mba": {
		"name": "MBA (Business Administration)",
		"cost": 1200000, "years": 2, "smarts": 18.0,
		"desc": "Management. Required to lead large business empires.",
	},
	"nda": {
		"name": "NDA (Defence Academy)",
		"cost": 250000, "years": 3, "smarts": 12.0,
		"desc": "Military training. Physical and disciplined.",
	},
	"mbbs": {
		"name": "MBBS (Medicine)",
		"cost": 2500000, "years": 5, "smarts": 25.0,
		"desc": "Medicine. Expensive, long, and the highest earning start.",
	},
}

const JOBS := {
	"delivery": {
		"name": "Delivery Partner", "category": "Private",
		"salary": 180000, "growth": 1.06, "degree": "", "smarts": 0.0, "promote_years": 3,
	},
	"gov_clerk": {
		"name": "Government Clerk", "category": "Government",
		"salary": 300000, "growth": 1.07, "degree": "class12", "smarts": 35.0, "promote_years": 4,
	},
	"bank_po": {
		"name": "Bank Probationary Officer", "category": "Government",
		"salary": 600000, "growth": 1.08, "degree": "bcom", "smarts": 55.0, "promote_years": 4,
	},
	"soldier": {
		"name": "Army Officer", "category": "Military",
		"salary": 720000, "growth": 1.09, "degree": "nda", "smarts": 45.0, "promote_years": 3,
	},
	"software_engineer": {
		"name": "Software Engineer", "category": "Private",
		"salary": 900000, "growth": 1.14, "degree": "btech", "smarts": 60.0, "promote_years": 2,
	},
	"tech_lead": {
		"name": "Engineering Manager", "category": "Private",
		"salary": 2200000, "growth": 1.15, "degree": "btech", "smarts": 75.0, "promote_years": 3,
	},
	"doctor": {
		"name": "Doctor", "category": "Private",
		"salary": 1200000, "growth": 1.12, "degree": "mbbs", "smarts": 80.0, "promote_years": 4,
	},
	"business_head": {
		"name": "Business Unit Head", "category": "Business",
		"salary": 3500000, "growth": 1.18, "degree": "mba", "smarts": 80.0, "promote_years": 3,
	},
}

const BUSINESSES := {
	"chai_stall": {
		"name": "Chai Stall", "category": "Food",
		"cost": 60000, "income": 48000, "cost_exp": 1.45, "max_level": 12,
		"desc": "One stove, one corner, steady cash.",
	},
	"dairy": {
		"name": "Dairy Farm", "category": "Farming",
		"cost": 350000, "income": 220000, "cost_exp": 1.5, "max_level": 12,
		"desc": "Buffaloes, milk routes and a chilling plant.",
	},
	"restaurant": {
		"name": "Restaurant", "category": "Food",
		"cost": 1500000, "income": 780000, "cost_exp": 1.5, "max_level": 12,
		"desc": "Dine-in, delivery and a reputation to protect.",
	},
	"factory": {
		"name": "Factory", "category": "Manufacturing",
		"cost": 8000000, "income": 3400000, "cost_exp": 1.52, "max_level": 12,
		"desc": "Production lines that run while you sleep.",
	},
	"hotel": {
		"name": "Hotel", "category": "Hospitality",
		"cost": 25000000, "income": 9000000, "cost_exp": 1.55, "max_level": 12,
		"desc": "Rooms, banquets and business travellers.",
	},
	"tech_company": {
		"name": "Technology Company", "category": "Technology",
		"cost": 60000000, "income": 24000000, "cost_exp": 1.58, "max_level": 12,
		"desc": "Products, platforms and engineering talent.",
	},
	"bank": {
		"name": "Bank", "category": "Finance",
		"cost": 150000000, "income": 52000000, "cost_exp": 1.6, "max_level": 12,
		"desc": "Deposits, loans and the spread between them.",
	},
	"airline": {
		"name": "Airline", "category": "Aviation",
		"cost": 900000000, "income": 280000000, "cost_exp": 1.62, "max_level": 12,
		"desc": "Aircraft, slots and international routes.",
	},
}

const PROPERTIES := {
	"house_1bhk": {"name": "1 BHK Flat", "cost": 2500000, "happiness": 6.0, "reputation": 2.0},
	"house_villa": {"name": "Villa", "cost": 22000000, "happiness": 14.0, "reputation": 8.0},
	"car_hatch": {"name": "Hatchback", "cost": 700000, "happiness": 5.0, "reputation": 2.0},
	"car_luxury": {"name": "Luxury Sedan", "cost": 9000000, "happiness": 12.0, "reputation": 7.0},
	"yacht": {"name": "Yacht", "cost": 120000000, "happiness": 20.0, "reputation": 18.0},
	"jet": {"name": "Private Jet", "cost": 800000000, "happiness": 28.0, "reputation": 30.0},
}

## Yearly random events. weight drives selection odds; effect keys are
## applied to the player record, "cash" is added (negative = cost).
const EVENTS := [
	{"text": "A quiet year. Nothing much happened.", "weight": 20, "effect": {}},
	{"text": "You fell ill and spent on treatment.", "weight": 10, "effect": {"cash": -40000, "health": -8.0}},
	{"text": "A friend's wedding and a lot of gifts.", "weight": 10, "effect": {"cash": -25000, "happiness": 4.0}},
	{"text": "You picked up a side project that paid well.", "weight": 9, "effect": {"cash": 90000, "happiness": 3.0}},
	{"text": "Festival bonus and sweets at home.", "weight": 9, "effect": {"cash": 35000, "happiness": 6.0}},
	{"text": "You started running every morning.", "weight": 8, "effect": {"fitness": 9.0, "health": 4.0}},
	{"text": "A family dispute left you drained.", "weight": 7, "effect": {"happiness": -9.0}},
	{"text": "You got scammed by a fake investment scheme.", "weight": 5, "effect": {"cash": -150000, "happiness": -10.0}},
	{"text": "An old contact offered you a consulting gig.", "weight": 6, "effect": {"cash": 250000, "reputation": 4.0}},
	{"text": "You won a local business award.", "weight": 4, "effect": {"reputation": 10.0, "happiness": 8.0}},
	{"text": "A relative passed away and left you something.", "weight": 3, "effect": {"cash": 500000, "happiness": -5.0}},
	{"text": "You met someone who changed how you see money.", "weight": 5, "effect": {"smarts": 6.0, "happiness": 5.0}},
]

func background(id: String) -> Dictionary:
	return BACKGROUNDS.get(id, BACKGROUNDS["middle"])

func degree(id: String) -> Dictionary:
	return DEGREES.get(id, {})

func job(id: String) -> Dictionary:
	return JOBS.get(id, {})

func business(id: String) -> Dictionary:
	return BUSINESSES.get(id, {})

func property(id: String) -> Dictionary:
	return PROPERTIES.get(id, {})

## Cost of taking a business from `level` to `level + 1`.
func business_upgrade_cost(id: String, level: int) -> int:
	var b: Dictionary = business(id)
	if b.is_empty():
		return 0
	return int(round(float(b["cost"]) * pow(float(b["cost_exp"]), level)))

## Yearly income of a business at `level`.
func business_income(id: String, level: int) -> int:
	var b: Dictionary = business(id)
	if b.is_empty() or level <= 0:
		return 0
	return int(round(float(b["income"]) * pow(1.35, level - 1)))

## Book value of a business — used for net worth and inheritance.
func business_value(id: String, level: int) -> int:
	var total: int = 0
	for i in range(level):
		total += business_upgrade_cost(id, i)
	return int(total * 0.75)

## Yearly salary for a job at `level`.
func job_salary(id: String, level: int) -> int:
	var j: Dictionary = job(id)
	if j.is_empty():
		return 0
	return int(round(float(j["salary"]) * pow(float(j["growth"]), level)))

func pick_event() -> Dictionary:
	var total: int = 0
	for e in EVENTS:
		total += int(e["weight"])
	var roll: int = _rng.randi_range(1, total)
	var acc: int = 0
	for e in EVENTS:
		acc += int(e["weight"])
		if roll <= acc:
			return e
	return EVENTS[0]
