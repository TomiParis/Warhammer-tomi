## filter_panel.gd - Filtros colapsables por tipo, facción, grieta
extends PanelContainer

var _map = null
var _vbox: VBoxContainer = null
var _type_checks: Dictionary = {} # tipo -> CheckBox
var _lado_checks: Dictionary = {} # "sanctus"/"nihilus" -> CheckBox
var _ctrl_checks: Dictionary = {} # controlador_tipo -> CheckBox
var _scroll: ScrollContainer = null
var _toggle_btn: Button = null
var _minimized: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: lateral izquierdo, compacto
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 5.0
	offset_top = 35.0
	custom_minimum_size = Vector2(150, 0)

	# Estilo: transparente cuando minimizado, con fondo cuando expandido
	_update_style()

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# Botón minimizar/expandir
	_toggle_btn = Button.new()
	_toggle_btn.text = "▼ FILTROS"
	_toggle_btn.flat = true
	_toggle_btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
	_toggle_btn.add_theme_font_size_override("font_size", 11)
	_toggle_btn.pressed.connect(_on_toggle)
	main_vbox.add_child(_toggle_btn)

	# Scroll con contenido (colapsable)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(150, 350)
	main_vbox.add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_vbox)

	_build_filters()

func setup(map_ref: Variant) -> void:
	_map = map_ref

func _on_toggle() -> void:
	_minimized = not _minimized
	_scroll.visible = not _minimized
	_toggle_btn.text = "► FILTROS" if _minimized else "▼ FILTROS"
	_update_style()

func _update_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if _minimized:
		style.bg_color = Color(0.04, 0.04, 0.07, 0.5)
		style.border_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_content_margin_all(2)
	else:
		style.bg_color = Color(0.04, 0.04, 0.07, 0.85)
		style.border_color = Color(0.45, 0.42, 0.3, 0.15)
		style.border_width_right = 1
		style.set_content_margin_all(6)
	style.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", style)

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

	_add_separator()

	# Filtro por controlador/facción
	var ctrl_label: Label = Label.new()
	ctrl_label.text = "Controlador"
	ctrl_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	ctrl_label.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(ctrl_label)

	var ctrl_types: Array = ["gobernador_planetario", "adeptus_mechanicus", "ecclesiarquia",
		"adeptus_astartes", "casa_noble", "rogue_trader", "comandante_militar"]
	for ct_idx: int in ctrl_types.size():
		var ct: String = ctrl_types[ct_idx]
		var ct_name: String = ct
		if FactionData.FACTIONS.has(ct):
			ct_name = str(FactionData.FACTIONS[ct]["nombre"])
		_add_ctrl_check(ct, ct_name)

func _add_type_check(tipo: String, label_text: String) -> void:
	var cb: CheckBox = CheckBox.new()
	cb.text = label_text
	cb.button_pressed = true
	cb.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45))
	cb.add_theme_font_size_override("font_size", 10)
	cb.toggled.connect(func(_pressed: bool) -> void: _apply_filters())
	_type_checks[tipo] = cb
	_vbox.add_child(cb)

func _add_ctrl_check(ctrl_type: String, label_text: String) -> void:
	var cb: CheckBox = CheckBox.new()
	cb.text = label_text
	cb.button_pressed = true
	cb.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45))
	cb.add_theme_font_size_override("font_size", 10)
	cb.toggled.connect(func(_pressed: bool) -> void: _apply_filters())
	_ctrl_checks[ctrl_type] = cb
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

	# Determinar qué controladores están activos
	var active_ctrls: Dictionary = {}
	var has_ctrl_filter: bool = not _ctrl_checks.is_empty()
	for ct: String in _ctrl_checks:
		if _ctrl_checks[ct].button_pressed:
			active_ctrls[ct] = true

	# Marcar planetas que no pasan el filtro
	var planetas: Array = _map.galaxy.get("planetas", [])
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var tipo: String = str(p["tipo"])
		var lado: String = str(p["lado_grieta"])
		var pid: int = int(p["id"])
		var ctrl_tipo: String = str(p.get("controlador", {}).get("tipo", ""))

		var passes: bool = active_types.has(tipo) and active_lados.has(lado)
		if has_ctrl_filter and passes:
			passes = active_ctrls.has(ctrl_tipo) or active_ctrls.is_empty()
		if not passes:
			_map.filter_dimmed_ids[pid] = true

	# Redibujar
	if _map.renderer:
		_map.renderer.queue_redraw()
