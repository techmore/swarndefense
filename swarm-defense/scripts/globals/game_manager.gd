extends Node

enum GamePhase { MENU, LOADING, PLAYING, PAUSED, VICTORY, DEFEAT }

var current_phase: GamePhase = GamePhase.MENU

signal phase_changed(from: GamePhase, to: GamePhase)

func _ready() -> void:
    change_phase(GamePhase.MENU)

func change_phase(to: GamePhase) -> void:
    var from = current_phase
    current_phase = to
    phase_changed.emit(from, to)
    match to:
        GamePhase.MENU:
            pass
        GamePhase.LOADING:
            pass
        GamePhase.PLAYING:
            pass
        GamePhase.PAUSED:
            pass
        GamePhase.VICTORY, GamePhase.DEFEAT:
            pass

func start_game() -> void:
    change_phase(GamePhase.LOADING)
    get_tree().change_scene_to_file("res://scenes/core/world.tscn")

func return_to_menu() -> void:
    change_phase(GamePhase.MENU)
    get_tree().change_scene_to_file("res://scenes/core/main_menu.tscn")

func quit_game() -> void:
    get_tree().quit()
