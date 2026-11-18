extends Node
## Global signal hub. The model emits; the UI listens. The model never
## reaches into the UI, and no screen talks to another screen directly.

signal state_changed()
signal money_changed(new_total: int)
signal aged_up(new_age: int)
signal year_report(lines: Array)
signal toast(message: String)
signal screen_requested(screen_name: String)
signal game_over(reason: String)
