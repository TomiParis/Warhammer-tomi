## breadcrumb.gd - Navegación breadcrumb: Galaxia > Segmentum > Sector
extends HBoxContainer

var _map = null

func setup(map_ref: Node2D) -> void:
	_map = map_ref

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 15.0
	offset_top = 10.0
	mouse_filter = Control.MOUSE_FILTER_STOP

func update_path(state: int, seg_key: String, sec_key: String, galaxy: Dictionary) -> void:
	# Limpiar hijos existentes
	for child: Node in get_children():
		child.queue_free()

	# Siempre mostrar "Galaxia"
	_add_crumb("GALAXIA", func() -> void:
		if _map: _map.navigate_to_galaxy()
	, state == 0) # 0 = GALAXY

	if seg_key != "" and galaxy["segmentae"].has(seg_key):
		_add_separator()
		var seg_name: String = str(galaxy["segmentae"][seg_key]["nombre"])
		_add_crumb(seg_name, func() -> void:
			if _map: _map.navigate_to_segmentum(seg_key)
		, state == 1 and sec_key == "")

		if sec_key != "":
			var parts: PackedStringArray = sec_key.split(".")
			if parts.size() >= 2:
				var sk: String = parts[1]
				var seg: Dictionary = galaxy["segmentae"][seg_key]
				if seg["sectores"].has(sk):
					_add_separator()
					var sec_name: String = str(seg["sectores"][sk]["nombre"])
					_add_crumb(sec_name, Callable(), true) # Último, no clickeable

func _add_crumb(text: String, on_click: Callable, is_current: bool) -> void:
	var btn: Button = Button.new()
	btn.text = text
	btn.flat = true

	if is_current:
		btn.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35))
		btn.add_theme_font_size_override("font_size", 13)
	else:
		btn.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45))
		btn.add_theme_color_override("font_hover_color", Color(0.8, 0.75, 0.6))
		btn.add_theme_font_size_override("font_size", 13)
		if on_click.is_valid():
			btn.pressed.connect(on_click)

	add_child(btn)

func _add_separator() -> void:
	var lbl: Label = Label.new()
	lbl.text = "  ›  "
	lbl.add_theme_color_override("font_color", Color(0.4, 0.38, 0.32))
	lbl.add_theme_font_size_override("font_size", 13)
	add_child(lbl)
