class_name HudJuego
extends CanvasLayer

var gestor_juego: GestorJuego = null

var panel_j1: PanelContainer
var panel_j2: PanelContainer
var estilo_panel_j1: StyleBoxFlat
var estilo_panel_j2: StyleBoxFlat
var estilo_avatar_j1: StyleBoxFlat
var estilo_avatar_j2: StyleBoxFlat
var etiqueta_avatar_j1: Label
var etiqueta_avatar_j2: Label

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

var etiqueta_modo_central: Label
var etiqueta_estado_central: Label
var panel_notificacion: PanelContainer
var etiqueta_notificacion: Label
var tween_notificacion: Tween

# Componentes del Menu de Modos, Fin de Partida y Bracket de Torneo
var capa_oscura_menu: ColorRect
var etiqueta_titulo_modal: Label
var etiqueta_subtitulo_modal: Label
var contenedor_bracket_torneo: VBoxContainer
var boton_continuar_torneo: Button
var boton_revancha: Button
var boton_cerrar_modal: Button

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
	
	_sincronizar_encabezado_modo()
	_actualizar_resaltado_turno(gestor_juego.turno_actual, false)
	var vacio: Array[Texture2D] = []
	_al_actualizar_bolas_embolsadas(vacio, vacio, 7, 7)
	
	if SesionJuego.mostrar_menu_al_iniciar:
		_abrir_modal_menu("SELECCIONA EL MODO DE JUEGO", "Elige una modalidad para comenzar la partida.", false)

func _sincronizar_encabezado_modo() -> void:
	etiqueta_nombre_j1.text = "JUGADOR 1"
	etiqueta_nombre_j2.text = SesionJuego.obtener_nombre_jugador_2()
	etiqueta_avatar_j2.text = "IA" if SesionJuego.es_rival_ia() else "J2"
	etiqueta_modo_central.text = SesionJuego.obtener_titulo_modo()

func _construir_interfaz() -> void:
	var contenedor_raiz: Control = Control.new()
	contenedor_raiz.name = "ContenedorHud"
	contenedor_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contenedor_raiz)
	
	# Barra superior posicionada por encima del borde superior de la mesa (y = 10..132)
	var barra_superior: HBoxContainer = HBoxContainer.new()
	barra_superior.name = "BarraSuperior"
	barra_superior.position = Vector2(280.0, 10.0)
	barra_superior.size = Vector2(1384.0, 122.0)
	barra_superior.alignment = BoxContainer.ALIGNMENT_CENTER
	barra_superior.add_theme_constant_override("separation", 20)
	barra_superior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor_raiz.add_child(barra_superior)
	
	# Tarjeta Jugador 1 (Izquierda)
	var datos_j1: Dictionary = _crear_tarjeta_jugador("JUGADOR 1", "J1", false)
	panel_j1 = datos_j1["panel"]
	estilo_panel_j1 = datos_j1["estilo_panel"]
	estilo_avatar_j1 = datos_j1["estilo_avatar"]
	etiqueta_avatar_j1 = datos_j1["etiqueta_avatar"]
	etiqueta_nombre_j1 = datos_j1["etiqueta_nombre"]
	etiqueta_faccion_j1 = datos_j1["etiqueta_faccion"]
	barra_tiempo_j1 = datos_j1["barra_tiempo"]
	estilo_relleno_tiempo_j1 = datos_j1["estilo_tiempo"]
	slots_j1 = datos_j1["slots"]
	iconos_slots_j1 = datos_j1["iconos"]
	barra_superior.add_child(panel_j1)
	
	# Columna Central (Modo, Estado de la Mesa y Boton de Menu)
	var columna_central: VBoxContainer = VBoxContainer.new()
	columna_central.custom_minimum_size = Vector2(360.0, 118.0)
	columna_central.alignment = BoxContainer.ALIGNMENT_CENTER
	columna_central.add_theme_constant_override("separation", 4)
	columna_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_superior.add_child(columna_central)
	
	etiqueta_modo_central = Label.new()
	etiqueta_modo_central.text = "MODO: LOCAL 1v1"
	etiqueta_modo_central.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_modo_central.add_theme_font_size_override("font_size", 14)
	etiqueta_modo_central.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	etiqueta_modo_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna_central.add_child(etiqueta_modo_central)
	
	etiqueta_estado_central = Label.new()
	etiqueta_estado_central.text = "MESA ABIERTA"
	etiqueta_estado_central.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_estado_central.add_theme_font_size_override("font_size", 20)
	etiqueta_estado_central.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75))
	etiqueta_estado_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna_central.add_child(etiqueta_estado_central)
	
	var fila_boton_menu: HBoxContainer = HBoxContainer.new()
	fila_boton_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_boton_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna_central.add_child(fila_boton_menu)
	
	var boton_menu_superior: Button = _crear_boton_estilizado("Modos / Torneo", Color(0.18, 0.24, 0.34, 0.95), Vector2(170.0, 30.0), 14)
	boton_menu_superior.pressed.connect(_al_presionar_boton_menu_superior)
	fila_boton_menu.add_child(boton_menu_superior)
	
	# Tarjeta Jugador 2 (Derecha)
	var datos_j2: Dictionary = _crear_tarjeta_jugador("JUGADOR 2", "J2", true)
	panel_j2 = datos_j2["panel"]
	estilo_panel_j2 = datos_j2["estilo_panel"]
	estilo_avatar_j2 = datos_j2["estilo_avatar"]
	etiqueta_avatar_j2 = datos_j2["etiqueta_avatar"]
	etiqueta_nombre_j2 = datos_j2["etiqueta_nombre"]
	etiqueta_faccion_j2 = datos_j2["etiqueta_faccion"]
	barra_tiempo_j2 = datos_j2["barra_tiempo"]
	estilo_relleno_tiempo_j2 = datos_j2["estilo_tiempo"]
	slots_j2 = datos_j2["slots"]
	iconos_slots_j2 = datos_j2["iconos"]
	barra_superior.add_child(panel_j2)
	
	# Notificacion Flotante Temporal
	panel_notificacion = PanelContainer.new()
	panel_notificacion.name = "PanelNotificacion"
	panel_notificacion.position = Vector2(460.0, 885.0)
	panel_notificacion.custom_minimum_size = Vector2(1000.0, 56.0)
	panel_notificacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_notif: StyleBoxFlat = StyleBoxFlat.new()
	estilo_notif.bg_color = Color(0.08, 0.1, 0.14, 0.90)
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
	
	# Construir Modal de Modos / Torneo / Fin de Partida
	_construir_modal_menu(contenedor_raiz)

func _crear_tarjeta_jugador(titulo: String, siglas_avatar: String, alinear_derecha: bool) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480.0, 118.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_panel: StyleBoxFlat = StyleBoxFlat.new()
	estilo_panel.bg_color = Color(0.11, 0.13, 0.17, 0.92)
	estilo_panel.border_color = Color(0.35, 0.38, 0.45, 0.8)
	estilo_panel.set_border_width_all(3)
	estilo_panel.set_corner_radius_all(12)
	estilo_panel.content_margin_left = 14.0
	estilo_panel.content_margin_right = 14.0
	estilo_panel.content_margin_top = 8.0
	estilo_panel.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", estilo_panel)
	
	var fila_principal: HBoxContainer = HBoxContainer.new()
	fila_principal.add_theme_constant_override("separation", 12)
	fila_principal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fila_principal)
	
	# Marco de Avatar del Jugador / IA
	var panel_avatar: PanelContainer = PanelContainer.new()
	panel_avatar.custom_minimum_size = Vector2(68.0, 68.0)
	panel_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_avatar: StyleBoxFlat = StyleBoxFlat.new()
	estilo_avatar.bg_color = Color(0.16, 0.22, 0.30, 0.95) if not alinear_derecha else Color(0.26, 0.16, 0.24, 0.95)
	estilo_avatar.border_color = Color(0.4, 0.45, 0.55, 0.9)
	estilo_avatar.set_border_width_all(3)
	estilo_avatar.set_corner_radius_all(34)
	panel_avatar.add_theme_stylebox_override("panel", estilo_avatar)
	
	var etq_avatar: Label = Label.new()
	etq_avatar.text = siglas_avatar
	etq_avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etq_avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etq_avatar.add_theme_font_size_override("font_size", 22)
	etq_avatar.add_theme_color_override("font_color", Color.WHITE)
	etq_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_avatar.add_child(etq_avatar)
	
	var caja_vertical: VBoxContainer = VBoxContainer.new()
	caja_vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja_vertical.add_theme_constant_override("separation", 6)
	caja_vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if alinear_derecha:
		fila_principal.add_child(caja_vertical)
		fila_principal.add_child(panel_avatar)
	else:
		fila_principal.add_child(panel_avatar)
		fila_principal.add_child(caja_vertical)
		
	# Fila superior: Nombre y Faccion
	var fila_cabecera: HBoxContainer = HBoxContainer.new()
	fila_cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_vertical.add_child(fila_cabecera)
	
	var etq_nombre: Label = Label.new()
	etq_nombre.text = titulo
	etq_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etq_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if alinear_derecha else HORIZONTAL_ALIGNMENT_LEFT
	etq_nombre.add_theme_font_size_override("font_size", 19)
	etq_nombre.add_theme_color_override("font_color", Color.WHITE)
	etq_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var etq_faccion: Label = Label.new()
	etq_faccion.text = "Sin Faccion"
	etq_faccion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etq_faccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if alinear_derecha else HORIZONTAL_ALIGNMENT_RIGHT
	etq_faccion.add_theme_font_size_override("font_size", 15)
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
	fila_slots.add_theme_constant_override("separation", 8)
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
		"estilo_avatar": estilo_avatar,
		"etiqueta_avatar": etq_avatar,
		"etiqueta_nombre": etq_nombre,
		"etiqueta_faccion": etq_faccion,
		"barra_tiempo": barra_tiempo,
		"estilo_tiempo": estilo_relleno_barra,
		"slots": arreglo_slots,
		"iconos": arreglo_iconos
	}

func _construir_modal_menu(contenedor_raiz: Control) -> void:
	capa_oscura_menu = ColorRect.new()
	capa_oscura_menu.name = "CapaModalMenu"
	capa_oscura_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_oscura_menu.color = Color(0.03, 0.05, 0.08, 0.82)
	capa_oscura_menu.visible = false
	capa_oscura_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	contenedor_raiz.add_child(capa_oscura_menu)
	
	var tarjeta_modal: PanelContainer = PanelContainer.new()
	tarjeta_modal.position = Vector2(410.0, 145.0)
	tarjeta_modal.custom_minimum_size = Vector2(1100.0, 760.0)
	var estilo_modal: StyleBoxFlat = StyleBoxFlat.new()
	estilo_modal.bg_color = Color(0.09, 0.12, 0.16, 0.98)
	estilo_modal.border_color = Color(0.28, 0.82, 0.48, 0.95)
	estilo_modal.set_border_width_all(3)
	estilo_modal.set_corner_radius_all(16)
	estilo_modal.content_margin_left = 32.0
	estilo_modal.content_margin_right = 32.0
	estilo_modal.content_margin_top = 24.0
	estilo_modal.content_margin_bottom = 24.0
	tarjeta_modal.add_theme_stylebox_override("panel", estilo_modal)
	capa_oscura_menu.add_child(tarjeta_modal)
	
	var caja_modal: VBoxContainer = VBoxContainer.new()
	caja_modal.add_theme_constant_override("separation", 16)
	tarjeta_modal.add_child(caja_modal)
	
	etiqueta_titulo_modal = Label.new()
	etiqueta_titulo_modal.text = "BILLAR 2D - BOLA 8"
	etiqueta_titulo_modal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_titulo_modal.add_theme_font_size_override("font_size", 30)
	etiqueta_titulo_modal.add_theme_color_override("font_color", Color(0.3, 0.95, 0.55))
	caja_modal.add_child(etiqueta_titulo_modal)
	
	etiqueta_subtitulo_modal = Label.new()
	etiqueta_subtitulo_modal.text = "Selecciona un modo de juego"
	etiqueta_subtitulo_modal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_subtitulo_modal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_subtitulo_modal.add_theme_font_size_override("font_size", 18)
	etiqueta_subtitulo_modal.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	caja_modal.add_child(etiqueta_subtitulo_modal)
	
	# Fila de Acciones Contextuales (Fin de Partida / Avance de Torneo)
	var fila_acciones_contexto: HBoxContainer = HBoxContainer.new()
	fila_acciones_contexto.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_acciones_contexto.add_theme_constant_override("separation", 18)
	caja_modal.add_child(fila_acciones_contexto)
	
	boton_continuar_torneo = _crear_boton_estilizado("Jugar Siguiente Ronda del Torneo >>", Color(0.16, 0.58, 0.30, 1.0), Vector2(340.0, 46.0), 17)
	boton_continuar_torneo.visible = false
	boton_continuar_torneo.pressed.connect(_al_presionar_continuar_torneo)
	fila_acciones_contexto.add_child(boton_continuar_torneo)
	
	boton_revancha = _crear_boton_estilizado("Reiniciar Partida Actual", Color(0.22, 0.38, 0.58, 1.0), Vector2(260.0, 46.0), 16)
	boton_revancha.pressed.connect(_al_presionar_reiniciar_actual)
	fila_acciones_contexto.add_child(boton_revancha)
	
	boton_cerrar_modal = _crear_boton_estilizado("Volver a la Mesa", Color(0.25, 0.28, 0.35, 1.0), Vector2(200.0, 46.0), 16)
	boton_cerrar_modal.pressed.connect(_cerrar_modal_menu)
	fila_acciones_contexto.add_child(boton_cerrar_modal)
	
	# Seccion de Seleccion de Modos (3 Columnas: Local 1v1 | Vs IA | Modo Torneo)
	var fila_modos: HBoxContainer = HBoxContainer.new()
	fila_modos.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_modos.add_theme_constant_override("separation", 20)
	caja_modal.add_child(fila_modos)
	
	# Tarjeta 1: Local 1v1
	var col_local: PanelContainer = _crear_subpanel_modal(Vector2(310.0, 210.0))
	fila_modos.add_child(col_local)
	var vbox_local: VBoxContainer = VBoxContainer.new()
	vbox_local.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_local.add_theme_constant_override("separation", 12)
	col_local.add_child(vbox_local)
	vbox_local.add_child(_crear_etiqueta_seccion("LOCAL 1v1 (HOTSEAT)", 19, Color(0.95, 0.9, 0.55)))
	vbox_local.add_child(_crear_etiqueta_seccion("Dos jugadores humanos comparten el dispositivo por turnos.", 14, Color(0.75, 0.8, 0.86)))
	var btn_1v1: Button = _crear_boton_estilizado("Jugar Local 1v1", Color(0.20, 0.48, 0.34, 1.0), Vector2(240.0, 44.0), 16)
	btn_1v1.pressed.connect(_al_iniciar_local_1v1)
	vbox_local.add_child(btn_1v1)
	
	# Tarjeta 2: Partida Rapida Vs IA (3 Dificultades)
	var col_ia: PanelContainer = _crear_subpanel_modal(Vector2(360.0, 210.0))
	fila_modos.add_child(col_ia)
	var vbox_ia: VBoxContainer = VBoxContainer.new()
	vbox_ia.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_ia.add_theme_constant_override("separation", 8)
	col_ia.add_child(vbox_ia)
	vbox_ia.add_child(_crear_etiqueta_seccion("PARTIDA RAPIDA VS IA", 19, Color(0.55, 0.88, 1.0)))
	var btn_ia_facil: Button = _crear_boton_estilizado("Vs IA - Dificultad FACIL", Color(0.18, 0.44, 0.28, 1.0), Vector2(280.0, 38.0), 15)
	btn_ia_facil.pressed.connect(func() -> void: _al_iniciar_vs_ia(SesionJuego.DificultadIA.FACIL))
	vbox_ia.add_child(btn_ia_facil)
	var btn_ia_medio: Button = _crear_boton_estilizado("Vs IA - Dificultad MEDIO", Color(0.22, 0.42, 0.58, 1.0), Vector2(280.0, 38.0), 15)
	btn_ia_medio.pressed.connect(func() -> void: _al_iniciar_vs_ia(SesionJuego.DificultadIA.MEDIO))
	vbox_ia.add_child(btn_ia_medio)
	var btn_ia_pro: Button = _crear_boton_estilizado("Vs IA - Dificultad PROFESIONAL", Color(0.52, 0.22, 0.28, 1.0), Vector2(280.0, 38.0), 15)
	btn_ia_pro.pressed.connect(func() -> void: _al_iniciar_vs_ia(SesionJuego.DificultadIA.PROFESIONAL))
	vbox_ia.add_child(btn_ia_pro)
	
	# Tarjeta 3: Modo Torneo (8 Participantes)
	var col_torneo: PanelContainer = _crear_subpanel_modal(Vector2(310.0, 210.0))
	fila_modos.add_child(col_torneo)
	var vbox_torneo: VBoxContainer = VBoxContainer.new()
	vbox_torneo.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_torneo.add_theme_constant_override("separation", 12)
	col_torneo.add_child(vbox_torneo)
	vbox_torneo.add_child(_crear_etiqueta_seccion("MODO TORNEO (8 LLAVES)", 19, Color(1.0, 0.72, 0.35)))
	vbox_torneo.add_child(_crear_etiqueta_seccion("Gana 3 rondas consecutivas (Cuartos, Semifinal y Final) contra la CPU.", 14, Color(0.75, 0.8, 0.86)))
	var btn_torneo: Button = _crear_boton_estilizado("Iniciar Nuevo Torneo", Color(0.58, 0.38, 0.14, 1.0), Vector2(240.0, 44.0), 16)
	btn_torneo.pressed.connect(_al_iniciar_torneo)
	vbox_torneo.add_child(btn_torneo)
	
	# Cuadro de Llaves del Torneo (Bracket Visual de 8 participantes)
	var panel_bracket: PanelContainer = _crear_subpanel_modal(Vector2(1020.0, 285.0))
	caja_modal.add_child(panel_bracket)
	contenedor_bracket_torneo = VBoxContainer.new()
	contenedor_bracket_torneo.add_theme_constant_override("separation", 10)
	panel_bracket.add_child(contenedor_bracket_torneo)
	
	_actualizar_vista_bracket_torneo()

func _actualizar_vista_bracket_torneo() -> void:
	if not contenedor_bracket_torneo:
		return
	for hijo in contenedor_bracket_torneo.get_children():
		hijo.queue_free()
		
	var estado_torneo_txt: String = "CUADRO DEL TORNEO (8 PARTICIPANTES)"
	if SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO:
		if SesionJuego.ronda_torneo == 3:
			estado_torneo_txt = "¡TORNEO COMPLETADO! CAMPEON: " + SesionJuego.campeon_torneo
		elif SesionJuego.torneo_eliminado:
			estado_torneo_txt = "TORNEO FINALIZADO (ELIMINADO EN RONDA " + str(SesionJuego.ronda_torneo + 1) + "/3)"
		else:
			estado_torneo_txt = "TORNEO ACTIVO - RONDA ACTUAL: " + SesionJuego.obtener_titulo_modo()
			
	contenedor_bracket_torneo.add_child(_crear_etiqueta_seccion(estado_torneo_txt, 17, Color(1.0, 0.82, 0.4)))
	
	var columnas_llaves: HBoxContainer = HBoxContainer.new()
	columnas_llaves.alignment = BoxContainer.ALIGNMENT_CENTER
	columnas_llaves.add_theme_constant_override("separation", 28)
	contenedor_bracket_torneo.add_child(columnas_llaves)
	
	# Columna 1: Cuartos de Final (4 cruces)
	var col_cuartos: VBoxContainer = VBoxContainer.new()
	col_cuartos.custom_minimum_size = Vector2(280.0, 0.0)
	col_cuartos.add_theme_constant_override("separation", 6)
	col_cuartos.add_child(_crear_etiqueta_seccion("CUARTOS (IA Facil)", 15, Color(0.65, 0.85, 1.0)))
	var c: Array[String] = SesionJuego.cuartos_torneo
	if c.size() >= 8:
		col_cuartos.add_child(_crear_caja_cruce(c[0] + "  vs  " + c[1], SesionJuego.ronda_torneo == 0 and SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO))
		col_cuartos.add_child(_crear_caja_cruce(c[2] + "  vs  " + c[3], false))
		col_cuartos.add_child(_crear_caja_cruce(c[4] + "  vs  " + c[5], false))
		col_cuartos.add_child(_crear_caja_cruce(c[6] + "  vs  " + c[7], false))
	columnas_llaves.add_child(col_cuartos)
	
	# Columna 2: Semifinales (2 cruces)
	var col_semis: VBoxContainer = VBoxContainer.new()
	col_semis.custom_minimum_size = Vector2(280.0, 0.0)
	col_semis.add_theme_constant_override("separation", 14)
	col_semis.add_child(_crear_etiqueta_seccion("SEMIFINAL (IA Medio)", 15, Color(0.65, 0.85, 1.0)))
	var s: Array[String] = SesionJuego.semifinalistas_torneo
	if s.size() >= 4:
		col_semis.add_child(_crear_caja_cruce(s[0] + "  vs  " + s[1], SesionJuego.ronda_torneo == 1 and SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO and not SesionJuego.torneo_eliminado))
		col_semis.add_child(_crear_caja_cruce(s[2] + "  vs  " + s[3], false))
	columnas_llaves.add_child(col_semis)
	
	# Columna 3: Gran Final y Campeon
	var col_final: VBoxContainer = VBoxContainer.new()
	col_final.custom_minimum_size = Vector2(280.0, 0.0)
	col_final.add_theme_constant_override("separation", 14)
	col_final.add_child(_crear_etiqueta_seccion("GRAN FINAL (IA Pro)", 15, Color(0.65, 0.85, 1.0)))
	var f: Array[String] = SesionJuego.finalistas_torneo
	if f.size() >= 2:
		col_final.add_child(_crear_caja_cruce(f[0] + "  vs  " + f[1], SesionJuego.ronda_torneo == 2 and SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO and not SesionJuego.torneo_eliminado))
	var txt_campeon: String = "CAMPEON: " + (SesionJuego.campeon_torneo if SesionJuego.campeon_torneo != "" else "?")
	col_final.add_child(_crear_caja_cruce(txt_campeon, SesionJuego.ronda_torneo == 3))
	columnas_llaves.add_child(col_final)

func _crear_caja_cruce(texto: String, resaltado: bool) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	var est: StyleBoxFlat = StyleBoxFlat.new()
	est.bg_color = Color(0.14, 0.24, 0.19, 0.95) if resaltado else Color(0.07, 0.09, 0.12, 0.9)
	est.border_color = Color(0.3, 0.95, 0.5, 1.0) if resaltado else Color(0.28, 0.32, 0.4, 0.8)
	est.set_border_width_all(2 if resaltado else 1)
	est.set_corner_radius_all(6)
	est.content_margin_left = 10.0
	est.content_margin_right = 10.0
	est.content_margin_top = 6.0
	est.content_margin_bottom = 6.0
	p.add_theme_stylebox_override("panel", est)
	
	var lbl: Label = Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.WHITE if resaltado else Color(0.82, 0.86, 0.92))
	p.add_child(lbl)
	return p

func _crear_subpanel_modal(tamano_minimo: Vector2) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.custom_minimum_size = tamano_minimo
	var est: StyleBoxFlat = StyleBoxFlat.new()
	est.bg_color = Color(0.12, 0.15, 0.20, 0.95)
	est.border_color = Color(0.28, 0.34, 0.44, 0.9)
	est.set_border_width_all(2)
	est.set_corner_radius_all(10)
	est.content_margin_left = 16.0
	est.content_margin_right = 16.0
	est.content_margin_top = 12.0
	est.content_margin_bottom = 12.0
	p.add_theme_stylebox_override("panel", est)
	return p

func _crear_etiqueta_seccion(texto: String, tamano: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	return l

func _crear_boton_estilizado(texto: String, color_fondo: Color, tamano_min: Vector2, tamano_fuente: int) -> Button:
	var btn: Button = Button.new()
	btn.text = texto
	btn.custom_minimum_size = tamano_min
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", tamano_fuente)
	btn.add_theme_color_override("font_color", Color.WHITE)
	
	var est_normal: StyleBoxFlat = StyleBoxFlat.new()
	est_normal.bg_color = color_fondo
	est_normal.border_color = color_fondo.lightened(0.32)
	est_normal.set_border_width_all(2)
	est_normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", est_normal)
	
	var est_hover: StyleBoxFlat = est_normal.duplicate() as StyleBoxFlat
	est_hover.bg_color = color_fondo.lightened(0.15)
	btn.add_theme_stylebox_override("hover", est_hover)
	
	var est_pressed: StyleBoxFlat = est_normal.duplicate() as StyleBoxFlat
	est_pressed.bg_color = color_fondo.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", est_pressed)
	return btn

func _abrir_modal_menu(titulo: String, subtitulo: String, es_fin_partida: bool) -> void:
	etiqueta_titulo_modal.text = titulo
	etiqueta_subtitulo_modal.text = subtitulo
	_actualizar_vista_bracket_torneo()
	
	var puede_avanzar_torneo: bool = (
		SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO
		and not SesionJuego.torneo_eliminado
		and SesionJuego.ronda_torneo in [1, 2]
		and es_fin_partida
	)
	boton_continuar_torneo.visible = puede_avanzar_torneo
	boton_cerrar_modal.visible = not es_fin_partida and not SesionJuego.mostrar_menu_al_iniciar
	capa_oscura_menu.visible = true
	if gestor_juego:
		gestor_juego.establecer_pausa_menu(true)

func _cerrar_modal_menu() -> void:
	SesionJuego.mostrar_menu_al_iniciar = false
	capa_oscura_menu.visible = false
	_sincronizar_encabezado_modo()
	if gestor_juego:
		gestor_juego.establecer_pausa_menu(false)
		_actualizar_resaltado_turno(gestor_juego.turno_actual, gestor_juego.tiene_bola_en_mano_este_turno)

func _al_presionar_boton_menu_superior() -> void:
	_abrir_modal_menu("MENU DE MODOS Y TORNEO", "Cambia de modo de juego o revisa el cuadro del torneo.", false)

func _al_iniciar_local_1v1() -> void:
	SesionJuego.iniciar_partida_local()
	get_tree().reload_current_scene()

func _al_iniciar_vs_ia(dificultad: int) -> void:
	SesionJuego.iniciar_partida_vs_ia(dificultad as SesionJuego.DificultadIA)
	get_tree().reload_current_scene()

func _al_iniciar_torneo() -> void:
	SesionJuego.iniciar_nuevo_torneo()
	get_tree().reload_current_scene()

func _al_presionar_continuar_torneo() -> void:
	SesionJuego.mostrar_menu_al_iniciar = false
	get_tree().reload_current_scene()

func _al_presionar_reiniciar_actual() -> void:
	if SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO and SesionJuego.torneo_eliminado:
		SesionJuego.iniciar_nuevo_torneo()
	else:
		SesionJuego.mostrar_menu_al_iniciar = false
	get_tree().reload_current_scene()

func _al_cambiar_turno(jugador_actual: GestorJuego.Jugador, tiene_bola_en_mano: bool) -> void:
	_actualizar_resaltado_turno(jugador_actual, tiene_bola_en_mano)

func _actualizar_resaltado_turno(jugador_actual: GestorJuego.Jugador, tiene_bola_en_mano: bool) -> void:
	var es_j1: bool = (jugador_actual == GestorJuego.Jugador.UNO)
	var color_activo: Color = Color(0.25, 0.95, 0.45, 1.0)
	var color_inactivo: Color = Color(0.3, 0.33, 0.4, 0.65)
	
	estilo_panel_j1.border_color = color_activo if es_j1 else color_inactivo
	estilo_panel_j2.border_color = color_activo if not es_j1 else color_inactivo
	estilo_avatar_j1.border_color = color_activo if es_j1 else color_inactivo
	estilo_avatar_j2.border_color = color_activo if not es_j1 else color_inactivo
	
	panel_j1.modulate = Color(1.0, 1.0, 1.0, 1.0) if es_j1 else Color(0.72, 0.72, 0.75, 0.85)
	panel_j2.modulate = Color(1.0, 1.0, 1.0, 1.0) if not es_j1 else Color(0.72, 0.72, 0.75, 0.85)
	
	barra_tiempo_j1.value = 30.0 if es_j1 else 0.0
	barra_tiempo_j2.value = 30.0 if not es_j1 else 0.0
	
	var nombre_turno: String = "JUGADOR 1" if es_j1 else SesionJuego.obtener_nombre_jugador_2()
	var texto_turno: String = "TURNO: " + nombre_turno
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
	panel_notificacion.visible = true
	panel_notificacion.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if tween_notificacion and tween_notificacion.is_valid():
		tween_notificacion.kill()
	tween_notificacion = create_tween()
	tween_notificacion.tween_interval(3.5)
	tween_notificacion.tween_property(panel_notificacion, "modulate:a", 0.0, 0.8)

func _al_finalizar_partida(ganador: GestorJuego.Jugador, motivo: String) -> void:
	var txt_ganador: String = "JUGADOR 1" if ganador == GestorJuego.Jugador.UNO else SesionJuego.obtener_nombre_jugador_2()
	var titulo_fin: String = "¡GANADOR: " + txt_ganador + "!"
	if SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO:
		if SesionJuego.ronda_torneo == 3 and not SesionJuego.torneo_eliminado:
			titulo_fin = "¡¡CAMPEON DEL TORNEO DE BOLA 8!!"
		elif SesionJuego.torneo_eliminado:
			titulo_fin = "ELIMINADO DEL TORNEO - GANA " + txt_ganador
		else:
			titulo_fin = "¡CLASIFICADO A LA SIGUIENTE RONDA!"
			
	etiqueta_estado_central.text = titulo_fin
	_al_recibir_notificacion(motivo)
	if tween_notificacion and tween_notificacion.is_valid():
		tween_notificacion.kill()
	panel_notificacion.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	await get_tree().create_timer(1.4).timeout
	_abrir_modal_menu(titulo_fin, motivo, true)
