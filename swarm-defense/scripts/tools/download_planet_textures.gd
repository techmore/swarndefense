@tool
extends Control

var _http: HTTPRequest
var _queue: Array[Dictionary] = []
var _active_download: Dictionary = {}
var _total: int = 0
var _completed: int = 0

const TEXTURES_DIR := "res://assets/textures/planets"
const BASE_URL := "https://www.solarsystemscope.com/textures/download"

const TEXTURES := [
	{"file": "2k_mercury.jpg",         "name": "Mercury", "dest": "mercury_albedo.jpg"},
	{"file": "2k_venus_atmosphere.jpg", "name": "Venus",   "dest": "venus_albedo.jpg"},
	{"file": "2k_earth_daymap.jpg",    "name": "Earth",    "dest": "earth_albedo.jpg"},
	{"file": "2k_earth_clouds.jpg",    "name": "Clouds",   "dest": "earth_clouds.jpg"},
	{"file": "2k_mars.jpg",            "name": "Mars",     "dest": "mars_albedo.jpg"},
	{"file": "2k_moon.jpg",            "name": "Moon",     "dest": "moon_albedo.jpg"},
]

func _ready() -> void:
	if Engine.is_editor_hint():
		_http = HTTPRequest.new()
		add_child(_http)
		_http.request_completed.connect(_on_download_completed)
		$DownloadBtn.pressed.connect(_on_download_pressed)

func _on_download_pressed() -> void:
	$DownloadBtn.disabled = true
	$Status.text = "Starting download..."
	start_download()

func start_download() -> void:
	_queue = TEXTURES.duplicate()
	_total = _queue.size()
	_completed = 0
	_active_download = {}
	_next_download()

func _next_download() -> void:
	if _queue.is_empty():
		$Status.text = "Done! %d textures saved to %s" % [_completed, TEXTURES_DIR]
		$DownloadBtn.disabled = false
		return
	_active_download = _queue.pop_front()
	var url = BASE_URL + "/" + _active_download.file
	$Status.text = "Downloading %s..." % _active_download.name
	_http.request(url)

func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("Failed to download %s (HTTP %d)" % [_active_download.name, response_code])
		_next_download()
		return

	var path = TEXTURES_DIR.path_join(_active_download.dest)
	var dir = DirAccess.open("res://")
	if dir:
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_buffer(body)
			file.close()
			_completed += 1
			$Status.text = "  [%d/%d] Saved %s" % [_completed, _total, _active_download.dest]
		else:
			push_error("Failed to write: " + path)
	else:
		push_error("Failed to open textures directory")

	_next_download()
