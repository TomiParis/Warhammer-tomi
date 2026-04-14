## search_panel.gd - Buscador de planetas con autocompletado
extends PanelContainer

var _map = null
var _search_input: LineEdit = null
var _results_list: ItemList = null
var _all_planets: Array = []

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Estilo
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.95)
	style.border_color = Color(0.55, 0.5, 0.3, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	# Posición
	anchor_left = 0.5
	anchor_top = 0.0
	offset_left = -200.0
	offset_top = 50.0
	custom_minimum_size = Vector2(400, 300)

	# Layout
	var vbox: VBoxContainer = VBoxContainer.new()
	add_child(vbox)

	# Campo de búsqueda
	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Buscar planeta, tipo o sector..."
	_search_input.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7))
	_search_input.add_theme_color_override("font_placeholder_color", Color(0.45, 0.42, 0.38))
	var input_style: StyleBoxFlat = StyleBoxFlat.new()
	input_style.bg_color = Color(0.08, 0.08, 0.1)
	input_style.border_color = Color(0.4, 0.38, 0.3, 0.4)
	input_style.set_border_width_all(1)
	input_style.set_corner_radius_all(3)
	input_style.set_content_margin_all(6)
	_search_input.add_theme_stylebox_override("normal", input_style)
	_search_input.text_changed.connect(_on_search_changed)
	vbox.add_child(_search_input)

	# Separador
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	vbox.add_child(sep)

	# Lista de resultados
	_results_list = ItemList.new()
	_results_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results_list.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	_results_list.add_theme_color_override("font_selected_color", Color(0.85, 0.75, 0.35))
	var list_style: StyleBoxFlat = StyleBoxFlat.new()
	list_style.bg_color = Color(0.03, 0.03, 0.05)
	_results_list.add_theme_stylebox_override("panel", list_style)
	_results_list.item_activated.connect(_on_result_selected)
	vbox.add_child(_results_list)

func setup(map_ref: Node2D) -> void:
	_map = map_ref
	if _map and _map.galaxy.has("planetas"):
		_all_planets = _map.galaxy["planetas"]

func focus_search() -> void:
	if _search_input:
		_search_input.grab_focus()
		_search_input.select_all()

func _on_search_changed(query: String) -> void:
	if _results_list == null:
		return
	_results_list.clear()

	if query.length() < 2:
		return

	var q: String = query.to_lower()
	var results: int = 0

	for p_idx: int in _all_planets.size():
		if results >= 20:
			break
		var p: Dictionary = _all_planets[p_idx]
		var nombre: String = str(p["nombre"]).to_lower()
		var tipo_key: String = str(p["tipo"])
		var tipo_name: String = str(GameData.PLANET_TYPES[tipo_key]["nombre"]).to_lower() if GameData.PLANET_TYPES.has(tipo_key) else tipo_key

		if nombre.contains(q) or tipo_name.contains(q) or tipo_key.contains(q):
			var display: String = "%s — %s" % [str(p["nombre"]), str(GameData.PLANET_TYPES[tipo_key]["nombre"]) if GameData.PLANET_TYPES.has(tipo_key) else tipo_key]
			_results_list.add_item(display)
			_results_list.set_item_metadata(_results_list.item_count - 1, p_idx)
			results += 1

func _on_result_selected(idx: int) -> void:
	var planet_idx: int = int(_results_list.get_item_metadata(idx))
	if planet_idx >= 0 and planet_idx < _all_planets.size():
		var planet: Dictionary = _all_planets[planet_idx]
		if _map and _map.has_method("navigate_to_planet"):
			_map.navigate_to_planet(planet)
		visible = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and key.keycode == KEY_ESCAPE:
			visible = false
			get_viewport().set_input_as_handled()
