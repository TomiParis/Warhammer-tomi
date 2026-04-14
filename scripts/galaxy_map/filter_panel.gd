## filter_panel.gd - Filtros colapsables por tipo, facción, grieta
extends PanelContainer

var _map = null
var _vbox: VBoxContainer = null
var _type_checks: Dictionary = {} # tipo -> CheckBox
var _lado_checks: Dictionary = {} # "sanctus"/"nihilus" -> CheckBox

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Estilo
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.88)
	style.border_color = Color(0.45, 0.42, 0.3, 0.2)
	style.border_width_right = 1
	style.set_corner_radius_all(0)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	# Posición: lateral izquierdo
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 45.0
	offset_bottom = -10.0
	custom_minimum_size = Vector2(200, 0)

	# Scroll
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_vbox)

	_build_filters()

func setup(map_ref: Node2D) -> void:
	_map = map_ref

func _build_filters() -> void:
	# Título
	var title: Label = Label.new()
	title.text = "FILTROS"
	title.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
	title.add_theme_font_size_override("font_size", 12)
	_vbox.add_child(title)

	_add_separator()

	# Filtro por lado de la Grieta
	var lado_label: Label = Label.new()
	lado_label.text = "Lado de la Grieta"
	lado_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	lado_label.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(lado_label)

	_add_lado_check("sanctus", "Imperium Sanctus")
	_add_lado_check("nihilus", "Imperium Nihilus")

	_add_separator()

	# Filtro por tipo de planeta
	var type_label: Label = Label.new()
	type_label.text = "Tipo de Mundo"
	type_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	type_label.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(type_label)

	# Ordenar tipos por nombre
	var type_keys: Array = PlanetTypes.TYPES.keys()
	for t_idx: int in type_keys.size():
		var tipo: String = str(type_keys[t_idx])
		var nombre: String = str(PlanetTypes.TYPES[tipo]["nombre"])
		_add_type_check(tipo, nombre)

func _add_type_check(tipo: String, label_text: String) -> void:
	var cb: CheckBox = CheckBox.new()
	cb.text = label_text
	cb.button_pressed = true
	cb.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45))
	cb.add_theme_font_size_override("font_size", 10)
	cb.toggled.connect(func(_pressed: bool) -> void: _apply_filters())
	_type_checks[tipo] = cb
	_vbox.add_child(cb)

func _add_lado_check(lado: String, label_text: String) -> void:
	var cb: CheckBox = CheckBox.new()
	cb.text = label_text
	cb.button_pressed = true
	cb.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45))
	cb.add_theme_font_size_override("font_size", 10)
	cb.toggled.connect(func(_pressed: bool) -> void: _apply_filters())
	_lado_checks[lado] = cb
	_vbox.add_child(cb)

func _add_separator() -> void:
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	_vbox.add_child(sep)

func _apply_filters() -> void:
	if _map == null:
		return

	_map.filter_dimmed_ids.clear()

	# Determinar qué tipos están desactivados
	var active_types: Dictionary = {}
	for tipo: String in _type_checks:
		if _type_checks[tipo].button_pressed:
			active_types[tipo] = true

	# Determinar qué lados están desactivados
	var active_lados: Dictionary = {}
	for lado: String in _lado_checks:
		if _lado_checks[lado].button_pressed:
			active_lados[lado] = true

	# Marcar planetas que no pasan el filtro
	var planetas: Array = _map.galaxy.get("planetas", [])
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var tipo: String = str(p["tipo"])
		var lado: String = str(p["lado_grieta"])
		var pid: int = int(p["id"])

		var passes: bool = active_types.has(tipo) and active_lados.has(lado)
		if not passes:
			_map.filter_dimmed_ids[pid] = true

	# Redibujar
	if _map.renderer:
		_map.renderer.queue_redraw()
