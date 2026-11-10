class_name HudJuego
extends CanvasLayer

# Sprites reales hechos por artistas humanos: Kenney UI Pack (9-slice) + Kenney Pool Pack
const TEX_PANEL_KENNEY: Texture2D = preload("res://assets/UI/kenney/panel_brown.png")
const TEX_PANEL_INSET_KENNEY: Texture2D = preload("res://assets/UI/kenney/panelInset_brown.png")
const TEX_BOTON_KENNEY: Texture2D = preload("res://assets/UI/kenney/buttonLong_brown.png")
const TEX_BOTON_KENNEY_PRESSED: Texture2D = preload("res://assets/UI/kenney/buttonLong_brown_pressed.png")

const TEX_AVATAR_J1: Texture2D = preload("res://assets/Pool/pool_ball_plain_1.png")
const TEX_AVATAR_J2: Texture2D = preload("res://assets/Pool/pool_ball_plain_9.png")
const TEX_AVATAR_IA_FACIL: Texture2D = preload("res://assets/Pool/snooker_ball_plain_green.png")
const TEX_AVATAR_IA_MEDIO: Texture2D = preload("res://assets/Pool/snooker_ball_plain_blue.png")
const TEX_AVATAR_IA_PRO: Texture2D = preload("res://assets/Pool/snooker_ball_plain_red.png")
const TEX_ICONO_TROFEO: Texture2D = preload("res://assets/Pool/snooker_ball_plain_yellow.png")
const TEX_ICONO_TACOS: Texture2D = preload("res://assets/Pool/pool_ball_plain_8.png")
const TEX_BOLA_8: Texture2D = preload("res://assets/Pool/pool_ball_plain_8.png")

var gestor_juego: GestorJuego = null

var panel_j1: PanelContainer
var panel_j2: PanelContainer
var estilo_panel_j1: StyleBoxTexture
var estilo_panel_j2: StyleBoxTexture
var estilo_avatar_j1: StyleBoxTexture
var estilo_avatar_j2: StyleBoxTexture
var retrato_avatar_j1: TextureRect
var retrato_avatar_j2: TextureRect

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

var icono_modo_central: TextureRect
var etiqueta_modo_central: Label
var etiqueta_estado_central: Label
var panel_notificacion: PanelContainer
var etiqueta_notificacion: Label
var tween_notificacion: Tween
var tween_turno: Tween

# Componentes del Menu de Modos, Fin de Partida y Bracket de Torneo
var capa_oscura_menu: ColorRect
var tarjeta_modal_principal: PanelContainer
var etiqueta_titulo_modal: Label
var etiqueta_subtitulo_modal: Label
var contenedor_bracket_torneo: VBoxContainer
var boton_continuar_torneo: Button
var boton_revancha: Button
var boton_cerrar_modal: Button

func _ready() -> void:
	_construir_fondo_salon()
	_construir_interfaz()
	_conectar_con_gestor.call_deferred()

func _crear_estilo_kenney(textura: Texture2D, mod: Color = Color.WHITE, m_izq: float = 14.0, m_der: float = 14.0, m_arr: float = 12.0, m_aba: float = 12.0) -> StyleBoxTexture:
	var est: StyleBoxTexture = StyleBoxTexture.new()
	est.texture = textura
	est.texture_margin_left = 12.0
	est.texture_margin_right = 12.0
	est.texture_margin_top = 12.0
	est.texture_margin_bottom = 12.0
	est.content_margin_left = m_izq
	est.content_margin_right = m_der
	est.content_margin_top = m_arr
	est.content_margin_bottom = m_aba
	est.modulate_color = mod
	return est

func _construir_fondo_salon() -> void:
	# Capa de fondo detras de la mesa (layer = -10) centrada en 1920x1080
	var capa_fondo: CanvasLayer = CanvasLayer.new()
	capa_fondo.name = "FondoSalonBillar"
	capa_fondo.layer = -10
	add_child(capa_fondo)
	
	var tapiz_salon: Panel = Panel.new()
	tapiz_salon.set_anchors_preset(Control.PRESET_FULL_RECT)
	tapiz_salon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_salon: StyleBoxFlat = StyleBoxFlat.new()
	estilo_salon.bg_color = Color(0.11, 0.07, 0.05, 1.0)
	estilo_salon.border_color = Color(0.75, 0.52, 0.22, 0.45)
	estilo_salon.set_border_width_all(6)
	tapiz_salon.add_theme_stylebox_override("panel", estilo_salon)
	capa_fondo.add_child(tapiz_salon)
	
	# Alfombra verde oscura centrada exactamente en (960, 540) bajo la mesa
	var contenedor_alfombra: CenterContainer = CenterContainer.new()
	contenedor_alfombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_alfombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fondo.add_child(contenedor_alfombra)
	
	var alfombra_mesa: Panel = Panel.new()
	alfombra_mesa.custom_minimum_size = Vector2(1512.0, 728.0)
	alfombra_mesa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_alfombra: StyleBoxFlat = StyleBoxFlat.new()
	estilo_alfombra.bg_color = Color(0.07, 0.16, 0.09, 1.0)
	estilo_alfombra.border_color = Color(0.96, 0.68, 0.26, 0.65)
	estilo_alfombra.set_border_width_all(3)
	estilo_alfombra.set_corner_radius_all(28)
	estilo_alfombra.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	estilo_alfombra.shadow_size = 24
	alfombra_mesa.add_theme_stylebox_override("panel", estilo_alfombra)
	contenedor_alfombra.add_child(alfombra_mesa)

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
		_abrir_modal_menu("CLUB DE BILLAR - BOLA 8", "Selecciona tu modalidad de juego para salir a la mesa.", false)

func _sincronizar_encabezado_modo() -> void:
	etiqueta_nombre_j1.text = "JUGADOR 1"
	etiqueta_nombre_j2.text = SesionJuego.obtener_nombre_jugador_2()
	retrato_avatar_j1.texture = TEX_AVATAR_J1
	retrato_avatar_j2.texture = _obtener_textura_avatar_j2()
	icono_modo_central.texture = TEX_ICONO_TROFEO if SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO else TEX_ICONO_TACOS
	etiqueta_modo_central.text = SesionJuego.obtener_titulo_modo()

func _obtener_textura_avatar_j2() -> Texture2D:
	if not SesionJuego.es_rival_ia():
		return TEX_AVATAR_J2
	match SesionJuego.obtener_dificultad_activa():
		SesionJuego.DificultadIA.FACIL:
			return TEX_AVATAR_IA_FACIL
		SesionJuego.DificultadIA.MEDIO:
			return TEX_AVATAR_IA_MEDIO
		_:
			return TEX_AVATAR_IA_PRO

func _construir_interfaz() -> void:
	var contenedor_raiz: Control = Control.new()
	contenedor_raiz.name = "ContenedorHud"
	contenedor_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contenedor_raiz)
	
	# Contenedor superior centrado horizontalmente en 1920x1080 (y = 12..136)
	var centrador_superior: CenterContainer = CenterContainer.new()
	centrador_superior.name = "CentradorSuperior"
	centrador_superior.set_anchors_preset(Control.PRESET_TOP_WIDE)
	centrador_superior.offset_top = 12.0
	centrador_superior.offset_bottom = 136.0
	centrador_superior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor_raiz.add_child(centrador_superior)
	
	var barra_superior: HBoxContainer = HBoxContainer.new()
	barra_superior.name = "BarraSuperior"
	barra_superior.alignment = BoxContainer.ALIGNMENT_CENTER
	barra_superior.add_theme_constant_override("separation", 18)
	barra_superior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centrador_superior.add_child(barra_superior)
	
	# Tarjeta Jugador 1 (Izquierda)
	var datos_j1: Dictionary = _crear_tarjeta_jugador("JUGADOR 1", TEX_AVATAR_J1, false)
	panel_j1 = datos_j1["panel"]
	estilo_panel_j1 = datos_j1["estilo_panel"]
	estilo_avatar_j1 = datos_j1["estilo_avatar"]
	retrato_avatar_j1 = datos_j1["retrato_avatar"]
	etiqueta_nombre_j1 = datos_j1["etiqueta_nombre"]
	etiqueta_faccion_j1 = datos_j1["etiqueta_faccion"]
	barra_tiempo_j1 = datos_j1["barra_tiempo"]
	estilo_relleno_tiempo_j1 = datos_j1["estilo_tiempo"]
	slots_j1 = datos_j1["slots"]
	iconos_slots_j1 = datos_j1["iconos"]
	barra_superior.add_child(panel_j1)
	
	# Placa Central con textura 9-slice Kenney (panel_brown.png + panelInset_brown.png)
	var panel_central: PanelContainer = PanelContainer.new()
	panel_central.custom_minimum_size = Vector2(390.0, 124.0)
	panel_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_central_ext: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_KENNEY, Color(0.95, 0.88, 0.78, 1.0), 10.0, 10.0, 8.0, 8.0)
	panel_central.add_theme_stylebox_override("panel", estilo_central_ext)
	barra_superior.add_child(panel_central)
	
	var panel_central_inset: PanelContainer = PanelContainer.new()
	panel_central_inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_central_in: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_INSET_KENNEY, Color(0.88, 0.80, 0.70, 1.0), 12.0, 12.0, 8.0, 8.0)
	panel_central_inset.add_theme_stylebox_override("panel", estilo_central_in)
	panel_central.add_child(panel_central_inset)
	
	var columna_central: VBoxContainer = VBoxContainer.new()
	columna_central.alignment = BoxContainer.ALIGNMENT_CENTER
	columna_central.add_theme_constant_override("separation", 3)
	columna_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_central_inset.add_child(columna_central)
	
	var fila_modo: HBoxContainer = HBoxContainer.new()
	fila_modo.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_modo.add_theme_constant_override("separation", 6)
	fila_modo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna_central.add_child(fila_modo)
	
	icono_modo_central = TextureRect.new()
	icono_modo_central.texture = TEX_ICONO_TACOS
	icono_modo_central.custom_minimum_size = Vector2(20.0, 20.0)
	icono_modo_central.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_modo_central.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono_modo_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_modo.add_child(icono_modo_central)
	
	etiqueta_modo_central = Label.new()
	etiqueta_modo_central.text = "MODO: LOCAL 1v1"
	etiqueta_modo_central.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aplicar_estilo_texto_con_sombra(etiqueta_modo_central, 13, Color(1.0, 0.90, 0.52))
	etiqueta_modo_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_modo.add_child(etiqueta_modo_central)
	
	etiqueta_estado_central = Label.new()
	etiqueta_estado_central.text = "MESA ABIERTA"
	etiqueta_estado_central.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aplicar_estilo_texto_con_sombra(etiqueta_estado_central, 17, Color(1.0, 0.98, 0.92))
	etiqueta_estado_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna_central.add_child(etiqueta_estado_central)
	
	var fila_boton_menu: HBoxContainer = HBoxContainer.new()
	fila_boton_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_boton_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna_central.add_child(fila_boton_menu)
	
	var boton_menu_superior: Button = _crear_boton_estilizado("Modos y Torneo", Color(1.0, 0.94, 0.84, 1.0), Vector2(194.0, 34.0), 14, TEX_ICONO_TROFEO)
	boton_menu_superior.pressed.connect(_al_presionar_boton_menu_superior)
	fila_boton_menu.add_child(boton_menu_superior)
	
	# Tarjeta Jugador 2 (Derecha)
	var datos_j2: Dictionary = _crear_tarjeta_jugador("JUGADOR 2", TEX_AVATAR_J2, true)
	panel_j2 = datos_j2["panel"]
	estilo_panel_j2 = datos_j2["estilo_panel"]
	estilo_avatar_j2 = datos_j2["estilo_avatar"]
	retrato_avatar_j2 = datos_j2["retrato_avatar"]
	etiqueta_nombre_j2 = datos_j2["etiqueta_nombre"]
	etiqueta_faccion_j2 = datos_j2["etiqueta_faccion"]
	barra_tiempo_j2 = datos_j2["barra_tiempo"]
	estilo_relleno_tiempo_j2 = datos_j2["estilo_tiempo"]
	slots_j2 = datos_j2["slots"]
	iconos_slots_j2 = datos_j2["iconos"]
	barra_superior.add_child(panel_j2)
	
	# Notificacion Flotante Inferior centrada en 1920x1080 debajo de la mesa (y = 952..1016)
	var centrador_inferior: CenterContainer = CenterContainer.new()
	centrador_inferior.name = "CentradorInferior"
	centrador_inferior.set_anchors_preset(Control.PRESET_TOP_WIDE)
	centrador_inferior.offset_top = 952.0
	centrador_inferior.offset_bottom = 1018.0
	centrador_inferior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor_raiz.add_child(centrador_inferior)
	
	panel_notificacion = PanelContainer.new()
	panel_notificacion.name = "PanelNotificacion"
	panel_notificacion.custom_minimum_size = Vector2(980.0, 62.0)
	panel_notificacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_notif: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_KENNEY, Color(0.94, 0.86, 0.76, 0.98), 22.0, 22.0, 10.0, 10.0)
	panel_notificacion.add_theme_stylebox_override("panel", estilo_notif)
	centrador_inferior.add_child(panel_notificacion)
	
	var fila_notif: HBoxContainer = HBoxContainer.new()
	fila_notif.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_notif.add_theme_constant_override("separation", 14)
	fila_notif.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_notificacion.add_child(fila_notif)
	
	var icono_notif: TextureRect = TextureRect.new()
	icono_notif.texture = TEX_BOLA_8
	icono_notif.custom_minimum_size = Vector2(32.0, 32.0)
	icono_notif.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_notif.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono_notif.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_notif.add_child(icono_notif)
	
	etiqueta_notificacion = Label.new()
	etiqueta_notificacion.text = "Partida iniciada"
	etiqueta_notificacion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta_notificacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_notificacion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta_notificacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aplicar_estilo_texto_con_sombra(etiqueta_notificacion, 18, Color(1.0, 0.97, 0.90))
	etiqueta_notificacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_notif.add_child(etiqueta_notificacion)
	
	# Construir Modal de Modos / Torneo / Fin de Partida
	_construir_modal_menu(contenedor_raiz)

func _crear_tarjeta_jugador(titulo: String, textura_inicial: Texture2D, alinear_derecha: bool) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 124.0)
	panel.pivot_offset = Vector2(250.0, 62.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_panel: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_KENNEY, Color(1.0, 0.95, 0.88, 1.0), 16.0, 16.0, 12.0, 12.0)
	panel.add_theme_stylebox_override("panel", estilo_panel)
	
	var fila_principal: HBoxContainer = HBoxContainer.new()
	fila_principal.add_theme_constant_override("separation", 14)
	fila_principal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fila_principal)
	
	# Marco inset Kenney con insignia de bola real del jugador / IA
	var panel_avatar: PanelContainer = PanelContainer.new()
	panel_avatar.custom_minimum_size = Vector2(84.0, 84.0)
	panel_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var estilo_avatar: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_INSET_KENNEY, Color(0.90, 0.82, 0.72, 1.0), 10.0, 10.0, 10.0, 10.0)
	panel_avatar.add_theme_stylebox_override("panel", estilo_avatar)
	
	var retrato: TextureRect = TextureRect.new()
	retrato.texture = textura_inicial
	retrato.custom_minimum_size = Vector2(58.0, 58.0)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_avatar.add_child(retrato)
	
	var caja_vertical: VBoxContainer = VBoxContainer.new()
	caja_vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja_vertical.alignment = BoxContainer.ALIGNMENT_CENTER
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
	_aplicar_estilo_texto_con_sombra(etq_nombre, 19, Color(1.0, 0.96, 0.86))
	etq_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var etq_faccion: Label = Label.new()
	etq_faccion.text = "Mesa Abierta"
	etq_faccion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etq_faccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if alinear_derecha else HORIZONTAL_ALIGNMENT_RIGHT
	_aplicar_estilo_texto_con_sombra(etq_faccion, 15, Color(0.72, 0.98, 0.58))
	etq_faccion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if alinear_derecha:
		fila_cabecera.add_child(etq_faccion)
		fila_cabecera.add_child(etq_nombre)
	else:
		fila_cabecera.add_child(etq_nombre)
		fila_cabecera.add_child(etq_faccion)
		
	# Fila media: 7 casilleros inset Kenney que muestran el sprite real de cada bola embocada
	var fila_slots: HBoxContainer = HBoxContainer.new()
	fila_slots.alignment = BoxContainer.ALIGNMENT_END if alinear_derecha else BoxContainer.ALIGNMENT_BEGIN
	fila_slots.add_theme_constant_override("separation", 8)
	fila_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_vertical.add_child(fila_slots)
	
	var arreglo_slots: Array[Panel] = []
	var arreglo_iconos: Array[TextureRect] = []
	for i in range(7):
		var slot: Panel = Panel.new()
		slot.custom_minimum_size = Vector2(36.0, 36.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var estilo_slot: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_INSET_KENNEY, Color(0.78, 0.70, 0.60, 0.95), 4.0, 4.0, 4.0, 4.0)
		slot.add_theme_stylebox_override("panel", estilo_slot)
		
		var icono_bola: TextureRect = TextureRect.new()
		icono_bola.set_anchors_preset(Control.PRESET_FULL_RECT)
		icono_bola.offset_left = 3.0
		icono_bola.offset_top = 3.0
		icono_bola.offset_right = -3.0
		icono_bola.offset_bottom = -3.0
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
	estilo_fondo_barra.bg_color = Color(0.16, 0.10, 0.06, 0.95)
	estilo_fondo_barra.border_color = Color(0.45, 0.30, 0.14, 0.90)
	estilo_fondo_barra.set_border_width_all(1)
	estilo_fondo_barra.set_corner_radius_all(5)
	barra_tiempo.add_theme_stylebox_override("background", estilo_fondo_barra)
	
	var estilo_relleno_barra: StyleBoxFlat = StyleBoxFlat.new()
	estilo_relleno_barra.bg_color = Color(0.42, 0.88, 0.25, 0.98)
	estilo_relleno_barra.set_corner_radius_all(5)
	barra_tiempo.add_theme_stylebox_override("fill", estilo_relleno_barra)
	caja_vertical.add_child(barra_tiempo)
	
	return {
		"panel": panel,
		"estilo_panel": estilo_panel,
		"estilo_avatar": estilo_avatar,
		"retrato_avatar": retrato,
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
	capa_oscura_menu.color = Color(0.04, 0.03, 0.02, 0.82)
	capa_oscura_menu.visible = false
	capa_oscura_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	contenedor_raiz.add_child(capa_oscura_menu)
	
	# CenterContainer a pantalla completa para garantizar centrado exacto en 1920x1080
	var centrador_modal: CenterContainer = CenterContainer.new()
	centrador_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_oscura_menu.add_child(centrador_modal)
	
	tarjeta_modal_principal = PanelContainer.new()
	tarjeta_modal_principal.custom_minimum_size = Vector2(1200.0, 840.0)
	tarjeta_modal_principal.pivot_offset = Vector2(600.0, 420.0)
	
	var estilo_modal: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_KENNEY, Color(0.96, 0.90, 0.82, 1.0), 32.0, 32.0, 24.0, 24.0)
	tarjeta_modal_principal.add_theme_stylebox_override("panel", estilo_modal)
	centrador_modal.add_child(tarjeta_modal_principal)
	
	var caja_modal: VBoxContainer = VBoxContainer.new()
	caja_modal.add_theme_constant_override("separation", 14)
	tarjeta_modal_principal.add_child(caja_modal)
	
	# Cabecera con bolas reales de billar Kenney
	var fila_cabecera_modal: HBoxContainer = HBoxContainer.new()
	fila_cabecera_modal.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_cabecera_modal.add_theme_constant_override("separation", 18)
	caja_modal.add_child(fila_cabecera_modal)
	
	var ico_izq: TextureRect = _crear_icono_fijo(TEX_BOLA_8, Vector2(46.0, 46.0))
	fila_cabecera_modal.add_child(ico_izq)
	
	var caja_titulos: VBoxContainer = VBoxContainer.new()
	caja_titulos.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_cabecera_modal.add_child(caja_titulos)
	
	etiqueta_titulo_modal = Label.new()
	etiqueta_titulo_modal.text = "CLUB DE BILLAR - BOLA 8"
	etiqueta_titulo_modal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aplicar_estilo_texto_con_sombra(etiqueta_titulo_modal, 30, Color(1.0, 0.90, 0.48))
	caja_titulos.add_child(etiqueta_titulo_modal)
	
	etiqueta_subtitulo_modal = Label.new()
	etiqueta_subtitulo_modal.text = "Selecciona tu modalidad de juego"
	etiqueta_subtitulo_modal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aplicar_estilo_texto_con_sombra(etiqueta_subtitulo_modal, 17, Color(0.96, 0.94, 0.88))
	caja_titulos.add_child(etiqueta_subtitulo_modal)
	
	var ico_der: TextureRect = _crear_icono_fijo(TEX_ICONO_TROFEO, Vector2(46.0, 46.0))
	fila_cabecera_modal.add_child(ico_der)
	
	# Fila de Acciones Contextuales (Fin de Partida / Avance de Torneo)
	var fila_acciones_contexto: HBoxContainer = HBoxContainer.new()
	fila_acciones_contexto.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_acciones_contexto.add_theme_constant_override("separation", 18)
	caja_modal.add_child(fila_acciones_contexto)
	
	boton_continuar_torneo = _crear_boton_estilizado("Jugar Siguiente Ronda del Torneo >>", Color(0.75, 1.0, 0.75, 1.0), Vector2(350.0, 46.0), 17, TEX_ICONO_TROFEO)
	boton_continuar_torneo.visible = false
	boton_continuar_torneo.pressed.connect(_al_presionar_continuar_torneo)
	fila_acciones_contexto.add_child(boton_continuar_torneo)
	
	boton_revancha = _crear_boton_estilizado("Reiniciar Mesa Actual", Color(1.0, 0.92, 0.80, 1.0), Vector2(250.0, 46.0), 16, TEX_BOLA_8)
	boton_revancha.pressed.connect(_al_presionar_reiniciar_actual)
	fila_acciones_contexto.add_child(boton_revancha)
	
	boton_cerrar_modal = _crear_boton_estilizado("Volver a la Partida", Color(0.86, 0.96, 0.86, 1.0), Vector2(220.0, 46.0), 16)
	boton_cerrar_modal.pressed.connect(_cerrar_modal_menu)
	fila_acciones_contexto.add_child(boton_cerrar_modal)
	
	# Seccion de Seleccion de Modos (3 Subpaneles Inset Kenney: Local 1v1 | Vs IA | Modo Torneo)
	var fila_modos: HBoxContainer = HBoxContainer.new()
	fila_modos.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_modos.add_theme_constant_override("separation", 22)
	caja_modal.add_child(fila_modos)
	
	# Tarjeta 1: Local 1v1
	var col_local: PanelContainer = _crear_subpanel_madera(Vector2(350.0, 275.0))
	fila_modos.add_child(col_local)
	var vbox_local: VBoxContainer = VBoxContainer.new()
	vbox_local.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_local.add_theme_constant_override("separation", 10)
	col_local.add_child(vbox_local)
	
	var fila_av_local: HBoxContainer = HBoxContainer.new()
	fila_av_local.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_av_local.add_theme_constant_override("separation", 14)
	fila_av_local.add_child(_crear_icono_fijo(TEX_AVATAR_J1, Vector2(48.0, 48.0)))
	fila_av_local.add_child(_crear_icono_fijo(TEX_BOLA_8, Vector2(40.0, 40.0)))
	fila_av_local.add_child(_crear_icono_fijo(TEX_AVATAR_J2, Vector2(48.0, 48.0)))
	vbox_local.add_child(fila_av_local)
	
	vbox_local.add_child(_crear_etiqueta_seccion("LOCAL 1v1 (HOTSEAT)", 20, Color(1.0, 0.90, 0.50)))
	vbox_local.add_child(_crear_etiqueta_seccion("Duelo clasico para 2 jugadores humanos compartiendo el mouse por turnos.", 14, Color(0.96, 0.94, 0.90)))
	var btn_1v1: Button = _crear_boton_estilizado("Jugar 1 vs 1 Local", Color(0.82, 1.0, 0.82, 1.0), Vector2(270.0, 46.0), 16, TEX_AVATAR_J1)
	btn_1v1.pressed.connect(_al_iniciar_local_1v1)
	vbox_local.add_child(btn_1v1)
	
	# Tarjeta 2: Partida Rapida Vs IA
	var col_ia: PanelContainer = _crear_subpanel_madera(Vector2(380.0, 275.0))
	fila_modos.add_child(col_ia)
	var vbox_ia: VBoxContainer = VBoxContainer.new()
	vbox_ia.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_ia.add_theme_constant_override("separation", 8)
	col_ia.add_child(vbox_ia)
	vbox_ia.add_child(_crear_etiqueta_seccion("PARTIDA RAPIDA VS CPU", 20, Color(0.72, 0.94, 1.0)))
	
	var btn_ia_facil: Button = _crear_boton_estilizado("Rival FACIL (Club Amateur)", Color(0.82, 0.98, 0.86, 1.0), Vector2(320.0, 44.0), 15, TEX_AVATAR_IA_FACIL)
	btn_ia_facil.pressed.connect(func() -> void: _al_iniciar_vs_ia(SesionJuego.DificultadIA.FACIL))
	vbox_ia.add_child(btn_ia_facil)
	
	var btn_ia_medio: Button = _crear_boton_estilizado("Rival MEDIO (Tactico)", Color(0.82, 0.92, 1.0, 1.0), Vector2(320.0, 44.0), 15, TEX_AVATAR_IA_MEDIO)
	btn_ia_medio.pressed.connect(func() -> void: _al_iniciar_vs_ia(SesionJuego.DificultadIA.MEDIO))
	vbox_ia.add_child(btn_ia_medio)
	
	var btn_ia_pro: Button = _crear_boton_estilizado("Rival PROFESIONAL (Maestro)", Color(1.0, 0.82, 0.82, 1.0), Vector2(320.0, 44.0), 15, TEX_AVATAR_IA_PRO)
	btn_ia_pro.pressed.connect(func() -> void: _al_iniciar_vs_ia(SesionJuego.DificultadIA.PROFESIONAL))
	vbox_ia.add_child(btn_ia_pro)
	
	# Tarjeta 3: Modo Torneo
	var col_torneo: PanelContainer = _crear_subpanel_madera(Vector2(350.0, 275.0))
	fila_modos.add_child(col_torneo)
	var vbox_torneo: VBoxContainer = VBoxContainer.new()
	vbox_torneo.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_torneo.add_theme_constant_override("separation", 10)
	col_torneo.add_child(vbox_torneo)
	
	var fila_av_torneo: HBoxContainer = HBoxContainer.new()
	fila_av_torneo.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_av_torneo.add_theme_constant_override("separation", 14)
	fila_av_torneo.add_child(_crear_icono_fijo(TEX_AVATAR_J1, Vector2(46.0, 46.0)))
	fila_av_torneo.add_child(_crear_icono_fijo(TEX_ICONO_TROFEO, Vector2(54.0, 54.0)))
	fila_av_torneo.add_child(_crear_icono_fijo(TEX_AVATAR_IA_PRO, Vector2(46.0, 46.0)))
	vbox_torneo.add_child(fila_av_torneo)
	
	vbox_torneo.add_child(_crear_etiqueta_seccion("COPA TORNEO (8 LLAVES)", 20, Color(1.0, 0.88, 0.45)))
	vbox_torneo.add_child(_crear_etiqueta_seccion("Supera Cuartos, Semifinal y Gran Final contra rivales de dificultad creciente.", 14, Color(0.96, 0.94, 0.90)))
	var btn_torneo: Button = _crear_boton_estilizado("Iniciar Nuevo Torneo", Color(1.0, 0.92, 0.76, 1.0), Vector2(270.0, 46.0), 16, TEX_ICONO_TROFEO)
	btn_torneo.pressed.connect(_al_iniciar_torneo)
	vbox_torneo.add_child(btn_torneo)
	
	# Cuadro de Llaves del Torneo (Bracket Visual de 8 participantes)
	var panel_bracket: PanelContainer = _crear_subpanel_madera(Vector2(1120.0, 305.0))
	caja_modal.add_child(panel_bracket)
	contenedor_bracket_torneo = VBoxContainer.new()
	contenedor_bracket_torneo.add_theme_constant_override("separation", 10)
	panel_bracket.add_child(contenedor_bracket_torneo)
	
	_actualizar_vista_bracket_torneo()

func _crear_icono_fijo(tex: Texture2D, tamano: Vector2) -> TextureRect:
	var icono_rect: TextureRect = TextureRect.new()
	icono_rect.texture = tex
	icono_rect.custom_minimum_size = tamano
	icono_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icono_rect

func _actualizar_vista_bracket_torneo() -> void:
	if not contenedor_bracket_torneo:
		return
	for hijo in contenedor_bracket_torneo.get_children():
		hijo.queue_free()
		
	var estado_torneo_txt: String = "CUADRO DE LA COPA DE BILLAR (8 PARTICIPANTES)"
	if SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO:
		if SesionJuego.ronda_torneo == 3:
			estado_torneo_txt = "¡TORNEO COMPLETADO! CAMPEON: " + SesionJuego.campeon_torneo
		elif SesionJuego.torneo_eliminado:
			estado_torneo_txt = "TORNEO FINALIZADO (ELIMINADO EN RONDA " + str(SesionJuego.ronda_torneo + 1) + "/3)"
		else:
			estado_torneo_txt = "COPA EN CURSO - " + SesionJuego.obtener_titulo_modo()
			
	contenedor_bracket_torneo.add_child(_crear_etiqueta_seccion(estado_torneo_txt, 17, Color(1.0, 0.90, 0.48)))
	
	var columnas_llaves: HBoxContainer = HBoxContainer.new()
	columnas_llaves.alignment = BoxContainer.ALIGNMENT_CENTER
	columnas_llaves.add_theme_constant_override("separation", 32)
	contenedor_bracket_torneo.add_child(columnas_llaves)
	
	# Columna 1: Cuartos de Final (4 cruces)
	var col_cuartos: VBoxContainer = VBoxContainer.new()
	col_cuartos.custom_minimum_size = Vector2(310.0, 0.0)
	col_cuartos.add_theme_constant_override("separation", 6)
	col_cuartos.add_child(_crear_etiqueta_seccion("CUARTOS DE FINAL (Amateur)", 15, Color(0.75, 0.98, 0.68)))
	var c: Array[String] = SesionJuego.cuartos_torneo
	if c.size() >= 8:
		col_cuartos.add_child(_crear_caja_cruce(c[0] + "  vs  " + c[1], SesionJuego.ronda_torneo == 0 and SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO))
		col_cuartos.add_child(_crear_caja_cruce(c[2] + "  vs  " + c[3], false))
		col_cuartos.add_child(_crear_caja_cruce(c[4] + "  vs  " + c[5], false))
		col_cuartos.add_child(_crear_caja_cruce(c[6] + "  vs  " + c[7], false))
	columnas_llaves.add_child(col_cuartos)
	
	# Columna 2: Semifinales (2 cruces)
	var col_semis: VBoxContainer = VBoxContainer.new()
	col_semis.custom_minimum_size = Vector2(310.0, 0.0)
	col_semis.add_theme_constant_override("separation", 14)
	col_semis.add_child(_crear_etiqueta_seccion("SEMIFINALES (Tactico)", 15, Color(0.70, 0.92, 1.0)))
	var s: Array[String] = SesionJuego.semifinalistas_torneo
	if s.size() >= 4:
		col_semis.add_child(_crear_caja_cruce(s[0] + "  vs  " + s[1], SesionJuego.ronda_torneo == 1 and SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO and not SesionJuego.torneo_eliminado))
		col_semis.add_child(_crear_caja_cruce(s[2] + "  vs  " + s[3], false))
	columnas_llaves.add_child(col_semis)
	
	# Columna 3: Gran Final y Campeon
	var col_final: VBoxContainer = VBoxContainer.new()
	col_final.custom_minimum_size = Vector2(310.0, 0.0)
	col_final.add_theme_constant_override("separation", 14)
	col_final.add_child(_crear_etiqueta_seccion("GRAN FINAL (Maestro)", 15, Color(1.0, 0.86, 0.50)))
	var f: Array[String] = SesionJuego.finalistas_torneo
	if f.size() >= 2:
		col_final.add_child(_crear_caja_cruce(f[0] + "  vs  " + f[1], SesionJuego.ronda_torneo == 2 and SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO and not SesionJuego.torneo_eliminado))
	var txt_campeon: String = "CAMPEON: " + (SesionJuego.campeon_torneo if SesionJuego.campeon_torneo != "" else "?")
	col_final.add_child(_crear_caja_cruce(txt_campeon, SesionJuego.ronda_torneo == 3))
	columnas_llaves.add_child(col_final)

func _crear_caja_cruce(texto: String, resaltado: bool) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	var mod_cruce: Color = Color(0.82, 1.0, 0.80, 1.0) if resaltado else Color(0.92, 0.86, 0.78, 0.95)
	var est: StyleBoxTexture = _crear_estilo_kenney(TEX_BOTON_KENNEY if resaltado else TEX_PANEL_KENNEY, mod_cruce, 12.0, 12.0, 6.0, 6.0)
	p.add_theme_stylebox_override("panel", est)
	
	var lbl: Label = Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aplicar_estilo_texto_con_sombra(lbl, 14, Color(1.0, 0.98, 0.86) if resaltado else Color(0.92, 0.90, 0.86))
	p.add_child(lbl)
	return p

func _crear_subpanel_madera(tamano_minimo: Vector2) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.custom_minimum_size = tamano_minimo
	var est: StyleBoxTexture = _crear_estilo_kenney(TEX_PANEL_INSET_KENNEY, Color(0.86, 0.78, 0.68, 1.0), 18.0, 18.0, 14.0, 14.0)
	p.add_theme_stylebox_override("panel", est)
	return p

func _crear_etiqueta_seccion(texto: String, tamano: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aplicar_estilo_texto_con_sombra(l, tamano, color)
	return l

func _aplicar_estilo_texto_con_sombra(etiqueta: Label, tamano: int, color_texto: Color) -> void:
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color_texto)
	etiqueta.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	etiqueta.add_theme_constant_override("shadow_offset_x", 1)
	etiqueta.add_theme_constant_override("shadow_offset_y", 2)
	etiqueta.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02, 0.90))
	etiqueta.add_theme_constant_override("outline_size", 3)

func _crear_boton_estilizado(texto: String, color_mod: Color, tamano_min: Vector2, tamano_fuente: int, icono: Texture2D = null) -> Button:
	var btn: Button = Button.new()
	btn.text = "  " + texto if icono != null else texto
	btn.custom_minimum_size = tamano_min
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if icono != null:
		btn.icon = icono
		btn.expand_icon = true
		
	btn.add_theme_font_size_override("font_size", tamano_fuente)
	btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.90, 0.80))
	btn.add_theme_color_override("font_outline_color", Color(0.14, 0.07, 0.02, 0.92))
	btn.add_theme_constant_override("outline_size", 3)
	
	var est_normal: StyleBoxTexture = _crear_estilo_kenney(TEX_BOTON_KENNEY, color_mod, 14.0, 14.0, 6.0, 8.0)
	btn.add_theme_stylebox_override("normal", est_normal)
	
	var est_hover: StyleBoxTexture = _crear_estilo_kenney(TEX_BOTON_KENNEY, color_mod.lightened(0.12), 14.0, 14.0, 6.0, 8.0)
	btn.add_theme_stylebox_override("hover", est_hover)
	
	var est_pressed: StyleBoxTexture = _crear_estilo_kenney(TEX_BOTON_KENNEY_PRESSED, color_mod.darkened(0.08), 14.0, 14.0, 8.0, 6.0)
	btn.add_theme_stylebox_override("pressed", est_pressed)
	
	var est_focus: StyleBoxEmpty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", est_focus)
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
	
	if tarjeta_modal_principal:
		tarjeta_modal_principal.scale = Vector2(0.92, 0.92)
		var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(tarjeta_modal_principal, "scale", Vector2.ONE, 0.26)
		
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
	_abrir_modal_menu("SALON DE BILLAR - MODOS Y COPA", "Elige un modo de juego o consulta las llaves del campeonato.", false)

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
	var mod_activo: Color = Color(1.0, 0.97, 0.90, 1.0)
	var mod_inactivo: Color = Color(0.76, 0.72, 0.68, 0.88)
	
	estilo_panel_j1.modulate_color = mod_activo if es_j1 else mod_inactivo
	estilo_panel_j2.modulate_color = mod_activo if not es_j1 else mod_inactivo
	estilo_avatar_j1.modulate_color = Color(0.85, 1.0, 0.82, 1.0) if es_j1 else Color(0.80, 0.74, 0.66, 0.90)
	estilo_avatar_j2.modulate_color = Color(0.85, 1.0, 0.82, 1.0) if not es_j1 else Color(0.80, 0.74, 0.66, 0.90)
	
	panel_j1.modulate = Color(1.0, 1.0, 1.0, 1.0) if es_j1 else Color(0.82, 0.80, 0.76, 0.90)
	panel_j2.modulate = Color(1.0, 1.0, 1.0, 1.0) if not es_j1 else Color(0.82, 0.80, 0.76, 0.90)
	
	var tarjeta_activa: PanelContainer = panel_j1 if es_j1 else panel_j2
	var tarjeta_inactiva: PanelContainer = panel_j2 if es_j1 else panel_j1
	tarjeta_inactiva.scale = Vector2.ONE
	if tween_turno and tween_turno.is_valid():
		tween_turno.kill()
	tween_turno = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tarjeta_activa.scale = Vector2(1.03, 1.03)
	tween_turno.tween_property(tarjeta_activa, "scale", Vector2.ONE, 0.28)
	
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
		estilo_activo.bg_color = Color(0.42, 0.88, 0.25, 0.98)
	elif proporcion > 0.2:
		estilo_activo.bg_color = Color(0.98, 0.76, 0.18, 0.98)
	else:
		estilo_activo.bg_color = Color(0.95, 0.24, 0.20, 0.98)

func _al_asignar_facciones(faccion_j1: int, faccion_j2: int) -> void:
	etiqueta_faccion_j1.text = _texto_faccion(faccion_j1)
	etiqueta_faccion_j2.text = _texto_faccion(faccion_j2)

func _texto_faccion(tipo_faccion: int) -> String:
	if tipo_faccion == Bola.TipoBola.LISA:
		return "Lisas (1-7)"
	elif tipo_faccion == Bola.TipoBola.RAYADA:
		return "Rayadas (9-15)"
	return "Mesa Abierta"

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
		var estilo: StyleBoxTexture = arreglo_slots[i].get_theme_stylebox("panel") as StyleBoxTexture
		var icono: TextureRect = arreglo_iconos[i]
		if i < texturas.size() and texturas[i] != null:
			icono.texture = texturas[i]
			icono.visible = true
			if estilo:
				estilo.modulate_color = Color(0.96, 0.90, 0.80, 1.0)
		else:
			icono.texture = null
			icono.visible = false
			if estilo:
				estilo.modulate_color = Color(0.74, 0.66, 0.56, 0.92)

func _al_recibir_notificacion(mensaje: String) -> void:
	if not etiqueta_notificacion or not panel_notificacion:
		return
	etiqueta_notificacion.text = mensaje
	panel_notificacion.visible = true
	panel_notificacion.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if tween_notificacion and tween_notificacion.is_valid():
		tween_notificacion.kill()
	tween_notificacion = create_tween()
	tween_notificacion.tween_interval(3.6)
	tween_notificacion.tween_property(panel_notificacion, "modulate:a", 0.0, 0.8)

func _al_finalizar_partida(ganador: GestorJuego.Jugador, motivo: String) -> void:
	var txt_ganador: String = "JUGADOR 1" if ganador == GestorJuego.Jugador.UNO else SesionJuego.obtener_nombre_jugador_2()
	var titulo_fin: String = "¡GANADOR: " + txt_ganador + "!"
	if SesionJuego.modo_actual == SesionJuego.ModoJuego.TORNEO:
		if SesionJuego.ronda_torneo == 3 and not SesionJuego.torneo_eliminado:
			titulo_fin = "¡¡CAMPEON DE LA COPA DE BOLA 8!!"
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
