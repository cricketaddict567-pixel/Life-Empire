extends Node
## Headless soak test. Run with:
##   godot --headless --path . res://tools/TestSim.tscn
## Exits with code 0 on success, 1 on failure.

var failures: Array = []

func _ready() -> void:
	print("=== LIFE EMPIRE soak test ===")
	_test_new_game()
	_test_progression()
	_test_save_round_trip()
	await _test_screens()
	print("")
	if failures.is_empty():
		print("RESULT: PASS — all checks passed")
		get_tree().quit(0)
	else:
		print("RESULT: FAIL — %d problem(s)" % failures.size())
		for f in failures:
			print("  ! " + String(f))
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		print("  FAIL: " + message)

func _test_new_game() -> void:
	print("-- new game")
	GameState.new_game("Test Player", "Male", 18, "middle")
	_check(GameState.has_game(), "new_game should create a player")
	_check(int(GameState.player["age"]) == 18, "starting age should be 18")
	_check(GameState.cash() == 50000, "middle class should start with 50000, got %d" % GameState.cash())
	_check(GameState.net_worth() == 50000, "net worth should equal starting cash")

func _test_progression() -> void:
	print("-- 40 year progression with automated choices")
	var bought: bool = false
	for year in range(40):
		var age: int = int(GameState.player["age"])
		# Study early if we can afford it
		if age == 19 and String(GameState.player["studying"]) == "":
			GameState.enroll_degree("bcom")
		# Take any job we qualify for
		if String(GameState.player["job"]) == "":
			for job_id in Database.JOBS.keys():
				if GameState.can_take_job(String(job_id)):
					GameState.apply_job(String(job_id))
					break
		# Buy the first business once affordable
		if not bought and GameState.cash() > 90000:
			bought = GameState.buy_business("chai_stall")
		# Grow the business when rich
		if bought and GameState.cash() > 400000:
			GameState.upgrade_business("chai_stall")
		GameState.advance_year()
		if int(GameState.player["age"]) % 10 == 0:
			print("   age %3d  cash %14s  net %14s  job %-18s  biz %d" % [
				int(GameState.player["age"]),
				GameState.money_text(GameState.cash()),
				GameState.money_text(GameState.net_worth()),
				String(GameState.player["job"]),
				GameState.businesses.size(),
			])
	_check(int(GameState.player["age"]) == 58, "age should advance 40 years, got %d" % int(GameState.player["age"]))
	_check(GameState.event_log.size() > 0, "events should be logged")
	_check(GameState.net_worth() > 0, "net worth should be positive after 40 years, got %d" % GameState.net_worth())
	_check(GameState.player["degrees"].size() >= 1, "automated study should have produced a degree")
	_check(GameState.businesses.size() >= 1, "automated buying should have produced a business")
	print("   final: age %d, net worth %s, level %d, achievements %d" % [
		int(GameState.player["age"]), GameState.money_text(GameState.net_worth()),
		int(GameState.player["level"]), GameState.achievements.size()])

func _test_save_round_trip() -> void:
	print("-- save / load round trip")
	var before_worth: int = GameState.net_worth()
	var before_age: int = int(GameState.player["age"])
	var before_biz: int = GameState.businesses.size()
	var saved: bool = SaveManager.save_game()
	_check(saved, "save_game should succeed")
	_check(SaveManager.has_save(), "save file should exist after saving")

	GameState.player = {}
	GameState.businesses = []
	GameState.loans = []
	var loaded: bool = SaveManager.load_game()
	_check(loaded, "load_game should succeed")
	_check(GameState.has_game(), "player should exist after load")
	_check(int(GameState.player["age"]) == before_age, "age should survive save/load")
	_check(GameState.net_worth() == before_worth, "net worth should survive save/load (%d vs %d)" % [GameState.net_worth(), before_worth])
	_check(GameState.businesses.size() == before_biz, "businesses should survive save/load")

	var summary: Dictionary = SaveManager.peek_summary()
	_check(not summary.is_empty(), "peek_summary should return a summary")
	_check(String(summary.get("name", "")) == "Test Player", "summary should carry the player name")

func _test_screens() -> void:
	print("-- screen construction")
	var screens: Array = ["CharacterCreation", "Dashboard", "Career", "Education", "Business", "Bank", "Life"]
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	for name in screens:
		var path: String = "res://scenes/screens/%s.gd" % name
		var script: GDScript = load(path)
		_check(script != null, "screen script missing: %s" % path)
		if script == null:
			continue
		var inst: Control = script.new()
		holder.add_child(inst)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(inst.get_child_count() > 0, "%s built no UI" % name)
		inst.queue_free()
		await get_tree().process_frame
	holder.queue_free()
