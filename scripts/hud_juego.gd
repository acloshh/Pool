class_name HudJuego
extends CanvasLayer

var gestor_juego: GestorJuego = null

var panel_j1: PanelContainer
var panel_j2: PanelContainer
var estilo_panel_j1: StyleBoxFlat
var estilo_panel_j2: StyleBoxFlat

var etiqueta_nombre_j1: Label
var etiqueta_nombre_j2: Label
var etiqueta_faccion_j1: Label
var etiqueta_faccion_j2: Label

var barra_tiempo_j1: ProgressBar
var barra_tiempo_j2: ProgressBar
var estilo_relleno_tiempo_j1: StyleBoxFlat
var estilo_relleno_tiempo_j2: StyleBoxFlat

var slots_j1: Array[Panel] = []
var slots_j2: Array[Panel] = []
var iconos_slots_j1: Array[TextureRect] = []
var iconos_slots_j2: Array[TextureRect] = []

var etiqueta_estado_central: Label
var panel_notificacion: PanelContainer
var etiqueta_notificacion: Label
var tween_notificacion: Tween

func _ready() -> void:
	_construir_interfaz()
	_conectar_con_gestor.call_deferred()

func _conectar_con_gestor() -> void:
	gestor_juego = get_tree().root.find_child("GestorJuego", true, false) as GestorJuego
	if not gestor_juego:
		return
		
	gestor_juego.turno_cambiado.connect(_al_cambiar_turno)
	gestor_juego.tiempo_turno_actualizado.connect(_al_actualizar_tiempo)
	gestor_juego.facciones_asignadas.connect(_al_asignar_facciones)
	gestor_juego.bolas_embolsadas_actualizadas.connect(_al_actualizar_bolas_embolsadas)
	gestor_juego.notificacion_juego.connect(_al_recibir_notificacion)
	gestor_juego.partida_finalizada.connect(_al_finalizar_partida)
	
	_actualizar_resaltado_turno(gestor_juego.turno_actual, false)
	var vacio: Array[Texture2D] = []
	_al_actualizar_bolas_embolsadas(vacio, vacio, 7, 7)

func _construir_interfaz() -> void:
	var contenedor_raiz: Control = Control.new()
	contenedor_raiz.name = "ContenedorHud"
	contenedor_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contenedor_raiz)
	
	# Barra superior posicionada por encima del borde superior de la mesa (y = 12..130)
	var barra_superior: HBoxContainer = HBoxContainer.new()
	barra_superior.name = "BarraSuperior"
	barra_superior.position = Vector2(324.0, 12.0)
	barra_superior.size = Vector2(1296.0, 122.0)
	barra_superior.alignment = BoxContainer.ALIGNMENT_CENTER
	barra_superior.add_theme_constant_override("separation", 24)
	barra_superior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor_raiz.add_child(barra_superior)
	
	# Tarjeta Jugador 1 (Izquierda)
	var datos_j1: Dictionary = _crear_tarjeta_jugador("JUGADOR 1", false)
	panel_j1 = datos_j1["panel"]
	estilo_panel_j1 = datos_j1["estilo_panel"]
	etiqueta_nombre_j1 = datos_j1["etiqueta_nombre"]
	etiqueta_faccion_j1 = datos_j1["etiqueta_faccion"]
	barra_tiempo_j1 = datos_j1["barra_tiempo"]
	estilo_relleno_tiempo_j1 = datos_j1["estilo_tiempo"]
	slots_j1 = datos_j1["slots"]
	iconos_slots_j1 = datos_j1["iconos"]
	barra_superior.add_child(panel_j1)
	
	# Columna Central (Estado de la Mesa)
	var columna_central: VBoxContainer = VBoxContainer.new()
	columna_central.custom_minimum_size = Vector2(340.0, 114.0)
	columna_central.alignment = BoxContainer.ALIGNMENT_CENTER
	columna_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_superior.add_child(columna_central)
	
	etiqueta_estado_central = Label.new()
	etiqueta_estado_central.text = "MESA ABIERTA"
	etiqueta_estado_central.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_estado_central.add_theme_font_size_override("font_size", 22)
	etiqueta_estado_central.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75))
	etiqueta_estado_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna_central.add_child(etiqueta_estado_central)
	
	# Tarjeta Jugador 2 (Derecha)
	var datos_j2: Dictionary = _crear_tarjeta_jugador("JUGADOR 2", true)
	panel_j2 = datos_j2["panel"]
	estilo_panel_j2 = datos_j2["estilo_panel"]
	etiqueta_nombre_j2 = datos_j2["etiqueta_nombre"]
	etiqueta_faccion_j2 = datos_j2["etiqueta_faccion"]
	barra_tiempo_j2 = datos_j2["barra_tiempo"]
	estilo_relleno_tiempo_j2 = datos_j2["estilo_tiempo"]
	slots_j2 = datos_j2["slots"]
	iconos_slots_j2 = datos_j2["iconos"]
	barra_superior.add_child(panel_j2)
	
	# Notificacion Flotante Central (Debajo de la mesa en el margen inferior y = 885)
	panel_notificacion = PanelContainer.new()
	panel_notificacion.name = "PanelNotificacion"
	panel_notificacion.position = Vector2(460.0, 885.0)
	panel_notificacion.custom_minimum_size = Vector2(1000.0, 56.0)
	panel_notificacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_notif: StyleBoxFlat = StyleBoxFlat.new()
	estilo_notif.bg_color = Color(0.08, 0.1, 0.14, 0.88)
	estilo_notif.border_color = Color(0.3, 0.85, 0.45, 0.9)
	estilo_notif.set_border_width_all(2)
	estilo_notif.set_corner_radius_all(10)
	estilo_notif.content_margin_left = 20.0
	estilo_notif.content_margin_right = 20.0
	estilo_notif.content_margin_top = 10.0
	estilo_notif.content_margin_bottom = 10.0
	panel_notificacion.add_theme_stylebox_override("panel", estilo_notif)
	contenedor_raiz.add_child(panel_notificacion)
	
	etiqueta_notificacion = Label.new()
	etiqueta_notificacion.text = "Partida iniciada"
	etiqueta_notificacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_notificacion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta_notificacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_notificacion.add_theme_font_size_override("font_size", 18)
	etiqueta_notificacion.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	etiqueta_notificacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_notificacion.add_child(etiqueta_notificacion)

func _crear_tarjeta_jugador(titulo: String, alinear_derecha: bool) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440.0, 118.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_panel: StyleBoxFlat = StyleBoxFlat.new()
	estilo_panel.bg_color = Color(0.11, 0.13, 0.17, 0.92)
	estilo_panel.border_color = Color(0.35, 0.38, 0.45, 0.8)
	estilo_panel.set_border_width_all(3)
	estilo_panel.set_corner_radius_all(12)
	estilo_panel.content_margin_left = 16.0
	estilo_panel.content_margin_right = 16.0
	estilo_panel.content_margin_top = 8.0
	estilo_panel.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", estilo_panel)
	
	var caja_vertical: VBoxContainer = VBoxContainer.new()
	caja_vertical.add_theme_constant_override("separation", 6)
	caja_vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(caja_vertical)
	
	# Fila superior: Nombre y Faccion
	var fila_cabecera: HBoxContainer = HBoxContainer.new()
	fila_cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_vertical.add_child(fila_cabecera)
	
	var etq_nombre: Label = Label.new()
	etq_nombre.text = titulo
	etq_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etq_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if alinear_derecha else HORIZONTAL_ALIGNMENT_LEFT
	etq_nombre.add_theme_font_size_override("font_size", 20)
	etq_nombre.add_theme_color_override("font_color", Color.WHITE)
	etq_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var etq_faccion: Label = Label.new()
	etq_faccion.text = "Sin Faccion"
	etq_faccion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etq_faccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if alinear_derecha else HORIZONTAL_ALIGNMENT_RIGHT
	etq_faccion.add_theme_font_size_override("font_size", 16)
	etq_faccion.add_theme_color_override("font_color", Color(0.7, 0.78, 0.88))
	etq_faccion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if alinear_derecha:
		fila_cabecera.add_child(etq_faccion)
		fila_cabecera.add_child(etq_nombre)
	else:
		fila_cabecera.add_child(etq_nombre)
		fila_cabecera.add_child(etq_faccion)
		
	# Fila media: 7 slots que muestran la textura exacta de cada bola embocada
	var fila_slots: HBoxContainer = HBoxContainer.new()
	fila_slots.alignment = BoxContainer.ALIGNMENT_END if alinear_derecha else BoxContainer.ALIGNMENT_BEGIN
	fila_slots.add_theme_constant_override("separation", 10)
	fila_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_vertical.add_child(fila_slots)
	
	var arreglo_slots: Array[Panel] = []
	var arreglo_iconos: Array[TextureRect] = []
	for i in range(7):
		var slot: Panel = Panel.new()
		slot.custom_minimum_size = Vector2(32.0, 32.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var estilo_slot: StyleBoxFlat = StyleBoxFlat.new()
		estilo_slot.bg_color = Color(0.08, 0.1, 0.13, 0.9)
		estilo_slot.border_color = Color(0.35, 0.4, 0.48, 0.75)
		estilo_slot.set_border_width_all(2)
		estilo_slot.set_corner_radius_all(16)
		slot.add_theme_stylebox_override("panel", estilo_slot)
		
		var icono_bola: TextureRect = TextureRect.new()
		icono_bola.set_anchors_preset(Control.PRESET_FULL_RECT)
		icono_bola.offset_left = 1.0
		icono_bola.offset_top = 1.0
		icono_bola.offset_right = -1.0
		icono_bola.offset_bottom = -1.0
		icono_bola.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono_bola.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono_bola.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icono_bola)
		
		fila_slots.add_child(slot)
		arreglo_slots.append(slot)
		arreglo_iconos.append(icono_bola)
		
	# Fila inferior: Barra de progreso del temporizador de turno (30s)
	var barra_tiempo: ProgressBar = ProgressBar.new()
	barra_tiempo.min_value = 0.0
	barra_tiempo.max_value = 30.0
	barra_tiempo.value = 30.0
	barra_tiempo.show_percentage = false
	barra_tiempo.custom_minimum_size = Vector2(0.0, 12.0)
	barra_tiempo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_fondo_barra: StyleBoxFlat = StyleBoxFlat.new()
	estilo_fondo_barra.bg_color = Color(0.06, 0.07, 0.09, 0.9)
	estilo_fondo_barra.set_corner_radius_all(6)
	barra_tiempo.add_theme_stylebox_override("background", estilo_fondo_barra)
	
	var estilo_relleno_barra: StyleBoxFlat = StyleBoxFlat.new()
	estilo_relleno_barra.bg_color = Color(0.2, 0.88, 0.4, 0.95)
	estilo_relleno_barra.set_corner_radius_all(6)
	barra_tiempo.add_theme_stylebox_override("fill", estilo_relleno_barra)
	caja_vertical.add_child(barra_tiempo)
	
	return {
		"panel": panel,
		"estilo_panel": estilo_panel,
		"etiqueta_nombre": etq_nombre,
		"etiqueta_faccion": etq_faccion,
		"barra_tiempo": barra_tiempo,
		"estilo_tiempo": estilo_relleno_barra,
		"slots": arreglo_slots,
		"iconos": arreglo_iconos
	}

func _al_cambiar_turno(jugador_actual: GestorJuego.Jugador, tiene_bola_en_mano: bool) -> void:
	_actualizar_resaltado_turno(jugador_actual, tiene_bola_en_mano)

func _actualizar_resaltado_turno(jugador_actual: GestorJuego.Jugador, tiene_bola_en_mano: bool) -> void:
	var es_j1: bool = (jugador_actual == GestorJuego.Jugador.UNO)
	
	estilo_panel_j1.border_color = Color(0.25, 0.95, 0.45, 1.0) if es_j1 else Color(0.3, 0.33, 0.4, 0.65)
	estilo_panel_j2.border_color = Color(0.25, 0.95, 0.45, 1.0) if not es_j1 else Color(0.3, 0.33, 0.4, 0.65)
	
	panel_j1.modulate = Color(1.0, 1.0, 1.0, 1.0) if es_j1 else Color(0.72, 0.72, 0.75, 0.85)
	panel_j2.modulate = Color(1.0, 1.0, 1.0, 1.0) if not es_j1 else Color(0.72, 0.72, 0.75, 0.85)
	
	barra_tiempo_j1.value = 30.0 if es_j1 else 0.0
	barra_tiempo_j2.value = 30.0 if not es_j1 else 0.0
	
	var texto_turno: String = "TURNO: JUGADOR 1" if es_j1 else "TURNO: JUGADOR 2"
	if tiene_bola_en_mano:
		texto_turno += " (BOLA EN MANO)"
	elif gestor_juego and gestor_juego.debe_cantar_tronera:
		texto_turno += " (CANTAR TRONERA)"
	etiqueta_estado_central.text = texto_turno

func _al_actualizar_tiempo(segundos_restantes: float, tiempo_total: float) -> void:
	if not gestor_juego:
		return
	var es_j1: bool = (gestor_juego.turno_actual == GestorJuego.Jugador.UNO)
	var barra_activa: ProgressBar = barra_tiempo_j1 if es_j1 else barra_tiempo_j2
	var estilo_activo: StyleBoxFlat = estilo_relleno_tiempo_j1 if es_j1 else estilo_relleno_tiempo_j2
	
	barra_activa.max_value = tiempo_total
	barra_activa.value = segundos_restantes
	
	var proporcion: float = segundos_restantes / max(1.0, tiempo_total)
	if proporcion > 0.4:
		estilo_activo.bg_color = Color(0.2, 0.88, 0.4, 0.95)
	elif proporcion > 0.2:
		estilo_activo.bg_color = Color(0.95, 0.78, 0.15, 0.95)
	else:
		estilo_activo.bg_color = Color(0.95, 0.22, 0.22, 0.98)

func _al_asignar_facciones(faccion_j1: int, faccion_j2: int) -> void:
	etiqueta_faccion_j1.text = _texto_faccion(faccion_j1)
	etiqueta_faccion_j2.text = _texto_faccion(faccion_j2)

func _texto_faccion(tipo_faccion: int) -> String:
	if tipo_faccion == Bola.TipoBola.LISA:
		return "Faccion: LISAS (1-7)"
	elif tipo_faccion == Bola.TipoBola.RAYADA:
		return "Faccion: RAYADAS (9-15)"
	return "Sin Faccion"

func _al_actualizar_bolas_embolsadas(texturas_j1: Array[Texture2D], texturas_j2: Array[Texture2D], restantes_j1: int, restantes_j2: int) -> void:
	if gestor_juego and not gestor_juego.mesa_abierta:
		if restantes_j1 == 0:
			etiqueta_faccion_j1.text = "¡POR LA BOLA 8!"
		else:
			etiqueta_faccion_j1.text = _texto_faccion(gestor_juego.faccion_j1)
		if restantes_j2 == 0:
			etiqueta_faccion_j2.text = "¡POR LA BOLA 8!"
		else:
			etiqueta_faccion_j2.text = _texto_faccion(gestor_juego.faccion_j2)
			
	_actualizar_slots_con_texturas(slots_j1, iconos_slots_j1, texturas_j1)
	_actualizar_slots_con_texturas(slots_j2, iconos_slots_j2, texturas_j2)

func _actualizar_slots_con_texturas(arreglo_slots: Array[Panel], arreglo_iconos: Array[TextureRect], texturas: Array[Texture2D]) -> void:
	for i in range(arreglo_slots.size()):
		var estilo: StyleBoxFlat = arreglo_slots[i].get_theme_stylebox("panel") as StyleBoxFlat
		var icono: TextureRect = arreglo_iconos[i]
		if i < texturas.size() and texturas[i] != null:
			icono.texture = texturas[i]
			icono.visible = true
			if estilo:
				estilo.bg_color = Color(0.15, 0.22, 0.18, 0.95)
				estilo.border_color = Color(0.4, 0.95, 0.55, 0.95)
		else:
			icono.texture = null
			icono.visible = false
			if estilo:
				estilo.bg_color = Color(0.08, 0.1, 0.13, 0.9)
				estilo.border_color = Color(0.35, 0.4, 0.48, 0.75)

func _al_recibir_notificacion(mensaje: String) -> void:
	if not etiqueta_notificacion or not panel_notificacion:
		return
	etiqueta_notificacion.text = mensaje
	panel_notificacion.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if tween_notificacion and tween_notificacion.is_valid():
		tween_notificacion.kill()
	tween_notificacion = create_tween()
	tween_notificacion.tween_interval(3.5)
	tween_notificacion.tween_property(panel_notificacion, "modulate:a", 0.35, 0.8)

func _al_finalizar_partida(ganador: GestorJuego.Jugador, motivo: String) -> void:
	var txt_ganador: String = "JUGADOR 1" if ganador == GestorJuego.Jugador.UNO else "JUGADOR 2"
	etiqueta_estado_central.text = "¡GANADOR: " + txt_ganador + "!"
	_al_recibir_notificacion(motivo)
	if tween_notificacion and tween_notificacion.is_valid():
		tween_notificacion.kill()
	panel_notificacion.modulate = Color(1.0, 1.0, 1.0, 1.0)
