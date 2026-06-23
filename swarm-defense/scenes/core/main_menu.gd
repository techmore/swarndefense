extends Control

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    $MenuButtons/HostGame.pressed.connect(_on_host_pressed)
    $MenuButtons/JoinGame.pressed.connect(_on_join_pressed)
    $MenuButtons/Settings.pressed.connect(_on_settings_pressed)
    $MenuButtons/Quit.pressed.connect(_on_quit_pressed)

func _on_host_pressed() -> void:
    if NetworkManager.host_game():
        GameManager.start_game()

func _on_join_pressed() -> void:
    pass

func _on_settings_pressed() -> void:
    pass

func _on_quit_pressed() -> void:
    GameManager.quit_game()
