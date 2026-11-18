extends Node
## Offline-first save system. Writes to user:// with a temp file and a
## backup so an Android process kill mid-write cannot corrupt a save.

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://life_empire_save.json"
const TMP_PATH: String = "user://life_empire_save.tmp.json"
const BACKUP_PATH: String = "user://life_empire_save.bak.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	if not GameState.has_game():
		push_warning("SaveManager: nothing to save")
		return false
	var data: Dictionary = GameState.to_dict()
	data["save_version"] = SAVE_VERSION
	data["saved_at"] = int(Time.get_unix_time_from_system())

	var f: FileAccess = FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot open temp file (%s)" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: cannot open user://")
		return false
	if dir.file_exists("life_empire_save.json"):
		dir.copy(SAVE_PATH, BACKUP_PATH)
		dir.remove(SAVE_PATH)
	var err: int = dir.rename("life_empire_save.tmp.json", "life_empire_save.json")
	if err != OK:
		push_error("SaveManager: rename failed (%s)" % error_string(err))
		return false
	return true

func load_game() -> bool:
	var data: Dictionary = _read(SAVE_PATH)
	if data.is_empty():
		data = _read(BACKUP_PATH)
	if data.is_empty():
		return false
	return GameState.from_dict(data)

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: corrupt save at %s" % path)
		return {}
	var data: Dictionary = parsed
	if int(data.get("save_version", 0)) > SAVE_VERSION:
		push_warning("SaveManager: save from a newer version")
	return data

func delete_save() -> void:
	for p in [SAVE_PATH, TMP_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

## Lightweight summary for a title screen, without loading the whole game.
func peek_summary() -> Dictionary:
	var data: Dictionary = _read(SAVE_PATH)
	if data.is_empty():
		return {}
	var p: Dictionary = data.get("player", {})
	return {
		"name": String(p.get("name", "Player")),
		"age": int(p.get("age", 18)),
		"cash": int(p.get("cash", 0)),
		"saved_at": int(data.get("saved_at", 0)),
		"game_over": bool(data.get("game_over", false)),
	}
