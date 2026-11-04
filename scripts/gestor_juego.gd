class_name GestorJuego
extends Node

signal turno_cambiado(jugador_actual: Jugador, tiene_bola_en_mano: bool)
signal tiempo_turno_actualizado(segundos_restantes: float, tiempo_total: float)
signal facciones_asignadas(faccion_jugador_1: int, faccion_jugador_2: int)
signal conteo_bolas_actualizado(restantes_j1: int, restantes_j2: int)
signal notificacion_juego(mensaje: String)
signal partida_finalizada(ganador: Jugador, motivo: String)

enum Jugador { UNO, DOS }
enum EstadoJuego { COLOCANDO_BOLA_BLANCA, ESPERANDO_TIRO, BOLAS_EN_MOVIMIENTO, FIN_PARTIDA }

const TIEMPO_MAXIMO_TURNO: float = 30.0
const UMBRAL_VELOCIDAD_REPOSO: float = 5.0
const TICKS_CONFIRMACION_REPOSO: int = 12
const LIMITES_MESA_INTERNA: Rect2 = Rect2(354.0, 210.0, 1236.0, 588.0)

var estado: EstadoJuego = EstadoJuego.ESPERANDO_TIRO
var posicion_saque: Vector2 = Vector2.ZERO
var turno_actual: Jugador = Jugador.UNO
var mesa_abierta: bool = true
var es_tiro_saque: bool = true

var faccion_j1: int = -1
var faccion_j2: int = -1

var bolas_caidas_este_turno: Array[Bola.TipoBola] = []
var primera_bola_contactada_tipo: int = -1
var bolas_propias_restantes_al_iniciar_tiro: int = 7

var tiene_bola_en_mano_este_turno: bool = false
var debe_cantar_tronera: bool = false
var tronera_designada: Tronera = null
var tronera_donde_cayo_negra: Tronera = null

var tiempo_restante_turno: float = TIEMPO_MAXIMO_TURNO
var ultimo_aviso_tiempo: int = -1
var ticks_acumulados_reposo: int = 0

var bola_blanca_ref: Bola

@onready var nodo_troneras: Node2D = %Troneras
@onready var nodo_bolas: Node2D = %Bolas

func _ready() -> void:
	for bola in nodo_bolas.get_children():
		if bola is Bola and bola.tipo_bola == Bola.TipoBola.BLANCA:
			posicion_saque = bola.global_position
			bola_blanca_ref = bola
			bola_blanca_ref.primera_bola_contactada.connect(_al_contactar_primera_bola)
			bola_blanca_ref.bola_colocada_en_mesa.connect(_al_colocar_bola_blanca)
			break
			
	for tronera in nodo_troneras.get_children():
		if tronera is Tronera:
			var t: Tronera = tronera as Tronera
			t.bola_embolsada.connect(_on_bola_embolsada)
			t.tronera_elegida.connect(_al_elegir_tronera)
			
	_preparar_inicio_tiro(false)
	_emitir_notificacion("--- PARTIDA INICIADA --- Turno del Jugador 1 (Saque Inicial - Mesa Abierta)")

func _physics_process(delta: float) -> void:
	if estado == EstadoJuego.FIN_PARTIDA:
		return
		
	if estado == EstadoJuego.ESPERANDO_TIRO or estado == EstadoJuego.COLOCANDO_BOLA_BLANCA:
		_actualizar_reloj_turno(delta)
		return
		
	if estado == EstadoJuego.BOLAS_EN_MOVIMIENTO:
		if _todas_las_bolas_bajo_umbral():
			ticks_acumulados_reposo += 1
			if ticks_acumulados_reposo >= TICKS_CONFIRMACION_REPOSO:
				_forzar_parada_total_bolas()
				_evaluar_turno()
		else:
			ticks_acumulados_reposo = 0

func _actualizar_reloj_turno(delta: float) -> void:
	tiempo_restante_turno = max(0.0, tiempo_restante_turno - delta)
	tiempo_turno_actualizado.emit(tiempo_restante_turno, TIEMPO_MAXIMO_TURNO)
	
	var segundos_enteros: int = int(ceil(tiempo_restante_turno))
	if segundos_enteros in [10, 5] and segundos_enteros != ultimo_aviso_tiempo:
		ultimo_aviso_tiempo = segundos_enteros
		print("[Reloj] Quedan ", segundos_enteros, " segundos para disparar.")
		
	if tiempo_restante_turno <= 0.0:
		_procesar_falta_por_tiempo()

func _procesar_falta_por_tiempo() -> void:
	if bola_blanca_ref:
		bola_blanca_ref.cancelar_apunte()
		if estado == EstadoJuego.COLOCANDO_BOLA_BLANCA:
			var pos_segura: Vector2 = _buscar_posicion_libre_cercana(posicion_saque)
			bola_blanca_ref.en_modo_colocacion = false
			bola_blanca_ref.reubicar(pos_segura)
			
	_emitir_notificacion("¡FALTA POR TIEMPO AGOTADO! El reloj de 30s llego a cero.")
	_cambiar_turno(true)

func registrar_tiro() -> void:
	if estado == EstadoJuego.ESPERANDO_TIRO:
		estado = EstadoJuego.BOLAS_EN_MOVIMIENTO
		ticks_acumulados_reposo = 0
		bolas_caidas_este_turno.clear()
		primera_bola_contactada_tipo = -1
		tronera_donde_cayo_negra = null
		_habilitar_seleccion_troneras(false)
		if tronera_designada:
			tronera_designada.establecer_seleccionada(true)

func puede_iniciar_apunte() -> bool:
	if estado != EstadoJuego.ESPERANDO_TIRO:
		return false
	if debe_cantar_tronera and tronera_designada == null:
		_emitir_notificacion("¡Debes cantar la tronera! Haz clic sobre una tronera (se pintara de verde) antes de tirar a la Bola 8.")
		return false
	return true

func puede_reposicionar_bola_blanca() -> bool:
	return tiene_bola_en_mano_este_turno and estado == EstadoJuego.ESPERANDO_TIRO

func iniciar_reposicionamiento_manual() -> void:
	if not bola_blanca_ref or not tiene_bola_en_mano_este_turno:
		return
	estado = EstadoJuego.COLOCANDO_BOLA_BLANCA
	bola_blanca_ref.activar_modo_colocacion(LIMITES_MESA_INTERNA)
	_emitir_notificacion("Bola en Mano: Mueve el mouse y haz clic izquierdo en un lugar libre (verde) para apoyar la bola blanca.")

func validar_distancia_bolas_y_troneras(posicion_evaluar: Vector2, radio_bola: float, ignorar_bola: Bola) -> bool:
	if not LIMITES_MESA_INTERNA.has_point(posicion_evaluar):
		return false
		
	var distancia_minima_bolas: float = (radio_bola * 2.0) + 2.0
	for nodo in nodo_bolas.get_children():
		if nodo is Bola:
			var b: Bola = nodo as Bola
			if b != ignorar_bola and not b.fue_embolsada:
				if b.global_position.distance_to(posicion_evaluar) < distancia_minima_bolas:
					return false
					
	for nodo_t in nodo_troneras.get_children():
		if nodo_t is Tronera:
			var t: Tronera = nodo_t as Tronera
			if t.global_position.distance_to(posicion_evaluar) < (t.radio_tronera + radio_bola * 0.85):
				return false
				
	return true

func _al_colocar_bola_blanca(_posicion_final: Vector2) -> void:
	estado = EstadoJuego.ESPERANDO_TIRO
	_emitir_notificacion("Bola blanca colocada. Puedes apuntar y disparar (o hacer clic derecho para reubicarla).")

func _al_contactar_primera_bola(bola_objetivo: Bola) -> void:
	if primera_bola_contactada_tipo == -1 and bola_objetivo:
		primera_bola_contactada_tipo = bola_objetivo.tipo_bola
		var nombre_tipo: String = _obtener_nombre_tipo_bola(primera_bola_contactada_tipo)
		print("[Contacto] Primera bola impactada: ", nombre_tipo)

func _al_elegir_tronera(tronera: Tronera) -> void:
	if not debe_cantar_tronera:
		return
	if estado != EstadoJuego.ESPERANDO_TIRO and estado != EstadoJuego.COLOCANDO_BOLA_BLANCA:
		return
		
	tronera_designada = tronera
	for nodo_t in nodo_troneras.get_children():
		if nodo_t is Tronera:
			var t: Tronera = nodo_t as Tronera
			t.establecer_seleccionada(t == tronera)
			
	_emitir_notificacion("Tronera cantada en VERDE: " + tronera.name + ". Ya puedes disparar a la Bola 8.")

func _habilitar_seleccion_troneras(activo: bool) -> void:
	for nodo_t in nodo_troneras.get_children():
		if nodo_t is Tronera:
			(nodo_t as Tronera).habilitar_seleccion(activo)

func _todas_las_bolas_bajo_umbral() -> bool:
	for bola in nodo_bolas.get_children():
		if bola is Bola and not bola.fue_embolsada:
			if not bola.sleeping and bola.linear_velocity.length() > UMBRAL_VELOCIDAD_REPOSO:
				return false
	return true

func _forzar_parada_total_bolas() -> void:
	for bola in nodo_bolas.get_children():
		if bola is Bola and not bola.fue_embolsada:
			(bola as Bola).detener_completamente()

func _on_bola_embolsada(bola: Bola, tronera: Tronera) -> void:
	bolas_caidas_este_turno.append(bola.tipo_bola)
	if bola.tipo_bola == Bola.TipoBola.NEGRA:
		tronera_donde_cayo_negra = tronera
	_emitir_conteo_bolas()

func _emitir_conteo_bolas() -> void:
	if mesa_abierta:
		conteo_bolas_actualizado.emit(7, 7)
	else:
		var rest_j1: int = _contar_bolas_restantes(faccion_j1)
		var rest_j2: int = _contar_bolas_restantes(faccion_j2)
		conteo_bolas_actualizado.emit(rest_j1, rest_j2)

func _evaluar_turno() -> void:
	print("--- Fin del tiro ---")
	var motivo_falta: String = _verificar_falta_tiro()
	var hay_falta: bool = motivo_falta != ""
	var cayo_negra: bool = Bola.TipoBola.NEGRA in bolas_caidas_este_turno
	var mantiene_turno: bool = false
	
	# Limpiar resaltado verde de troneras tras terminar el tiro
	_habilitar_seleccion_troneras(false)
	
	if cayo_negra:
		_evaluar_bola_8(motivo_falta)
		return
		
	if hay_falta:
		_emitir_notificacion("¡FALTA! " + motivo_falta)
		mantiene_turno = false
	else:
		if mesa_abierta and bolas_caidas_este_turno.size() > 0:
			mantiene_turno = _evaluar_mesa_abierta()
		elif not mesa_abierta:
			mantiene_turno = _evaluar_mesa_cerrada()
			
	es_tiro_saque = false
	
	if not mantiene_turno:
		_cambiar_turno(hay_falta)
	else:
		var num_jugador: String = "1" if turno_actual == Jugador.UNO else "2"
		_emitir_notificacion("El Jugador " + num_jugador + " mantiene el turno.")
		_preparar_inicio_tiro(false)

func _verificar_falta_tiro() -> String:
	if Bola.TipoBola.BLANCA in bolas_caidas_este_turno:
		return "La bola blanca cayo en la tronera (Scratch)."
		
	if primera_bola_contactada_tipo == -1:
		return "La bola blanca no toco ninguna bola."
		
	if es_tiro_saque:
		return ""
		
	if mesa_abierta:
		if primera_bola_contactada_tipo == Bola.TipoBola.NEGRA:
			return "Con mesa abierta no se puede tocar primero la Bola 8."
		return ""
		
	var mi_faccion: int = _obtener_faccion_actual()
	if bolas_propias_restantes_al_iniciar_tiro == 0:
		if primera_bola_contactada_tipo != Bola.TipoBola.NEGRA:
			return "Solo te queda la Bola 8; debias golpear primero la Bola 8."
	else:
		if primera_bola_contactada_tipo != mi_faccion:
			return "Golpeaste primero una bola que no pertenece a tu faccion."
			
	return ""

func _evaluar_mesa_abierta() -> bool:
	var cayo_lisa: bool = Bola.TipoBola.LISA in bolas_caidas_este_turno
	var cayo_rayada: bool = Bola.TipoBola.RAYADA in bolas_caidas_este_turno
	
	if not cayo_lisa and not cayo_rayada:
		return false
		
	var faccion_elegida: int = -1
	if cayo_lisa and not cayo_rayada:
		faccion_elegida = Bola.TipoBola.LISA
	elif cayo_rayada and not cayo_lisa:
		faccion_elegida = Bola.TipoBola.RAYADA
	else:
		# Caso borde determinista: cayeron ambas facciones en el mismo tiro
		if primera_bola_contactada_tipo == Bola.TipoBola.LISA or primera_bola_contactada_tipo == Bola.TipoBola.RAYADA:
			faccion_elegida = primera_bola_contactada_tipo
		else:
			_emitir_notificacion("Cayeron bolas de ambas facciones tras tocar la 8 en el saque. La mesa sigue abierta y conservas el turno.")
			return true
			
	_asignar_facciones(faccion_elegida)
	return true

func _asignar_facciones(faccion_jugador_activo: int) -> void:
	mesa_abierta = false
	var faccion_opuesta: int = Bola.TipoBola.RAYADA if faccion_jugador_activo == Bola.TipoBola.LISA else Bola.TipoBola.LISA
	
	if turno_actual == Jugador.UNO:
		faccion_j1 = faccion_jugador_activo
		faccion_j2 = faccion_opuesta
	else:
		faccion_j2 = faccion_jugador_activo
		faccion_j1 = faccion_opuesta
		
	var n1: String = "Lisas" if faccion_j1 == Bola.TipoBola.LISA else "Rayadas"
	var n2: String = "Lisas" if faccion_j2 == Bola.TipoBola.LISA else "Rayadas"
	facciones_asignadas.emit(faccion_j1, faccion_j2)
	_emitir_conteo_bolas()
	_emitir_notificacion("¡Mesa cerrada! Jugador 1: " + n1 + " | Jugador 2: " + n2)

func _evaluar_mesa_cerrada() -> bool:
	var mi_faccion: int = _obtener_faccion_actual()
	return mi_faccion in bolas_caidas_este_turno

func _evaluar_bola_8(motivo_falta: String) -> void:
	estado = EstadoJuego.FIN_PARTIDA
	var num_jugador: String = "1" if turno_actual == Jugador.UNO else "2"
	var num_oponente: String = "2" if turno_actual == Jugador.UNO else "1"
	var ganador_oponente: Jugador = Jugador.DOS if turno_actual == Jugador.UNO else Jugador.UNO
	var cayo_blanca: bool = Bola.TipoBola.BLANCA in bolas_caidas_este_turno
	
	# Regla 1: Si se emboca la negra en la primera tirada (saque), cuenta como victoria (salvo scratch)
	if es_tiro_saque:
		if not cayo_blanca:
			var msg_victoria_saque: String = "¡VICTORIA EN EL SAQUE! El Jugador " + num_jugador + " emboco la Bola 8 en la primera tirada."
			_emitir_notificacion(msg_victoria_saque)
			partida_finalizada.emit(turno_actual, msg_victoria_saque)
		else:
			var msg_derrota_saque: String = "¡DERROTA! El Jugador " + num_jugador + " emboco la Bola 8 y la blanca en el saque. Gana Jugador " + num_oponente + "."
			_emitir_notificacion(msg_derrota_saque)
			partida_finalizada.emit(ganador_oponente, msg_derrota_saque)
		return
		
	if mesa_abierta or bolas_propias_restantes_al_iniciar_tiro > 0:
		var msg_prematura: String = "¡DERROTA! Jugador " + num_jugador + " emboco la Bola 8 antes de limpiar su faccion. Gana Jugador " + num_oponente + "."
		_emitir_notificacion(msg_prematura)
		partida_finalizada.emit(ganador_oponente, msg_prematura)
		return
		
	if motivo_falta != "":
		var msg_falta_8: String = "¡DERROTA! Jugador " + num_jugador + " emboco la Bola 8 cometiendo falta (" + motivo_falta + "). Gana Jugador " + num_oponente + "."
		_emitir_notificacion(msg_falta_8)
		partida_finalizada.emit(ganador_oponente, msg_falta_8)
		return
		
	if tronera_designada == null or tronera_donde_cayo_negra != tronera_designada:
		var msg_tronera_erronea: String = "¡DERROTA! Jugador " + num_jugador + " emboco la Bola 8 en una tronera distinta a la cantada en verde. Gana Jugador " + num_oponente + "."
		_emitir_notificacion(msg_tronera_erronea)
		partida_finalizada.emit(ganador_oponente, msg_tronera_erronea)
		return
		
	var msg_victoria: String = "¡VICTORIA! El Jugador " + num_jugador + " limpio su faccion y emboco la Bola 8 en la tronera cantada."
	_emitir_notificacion(msg_victoria)
	partida_finalizada.emit(turno_actual, msg_victoria)

func _cambiar_turno(otorgar_bola_en_mano: bool) -> void:
	turno_actual = Jugador.DOS if turno_actual == Jugador.UNO else Jugador.UNO
	var num_jugador: String = "1" if turno_actual == Jugador.UNO else "2"
	var texto_extra: String = " (Con Bola en Mano)" if otorgar_bola_en_mano else ""
	_emitir_notificacion("--> Cambio de turno: Juega el Jugador " + num_jugador + texto_extra)
	_preparar_inicio_tiro(otorgar_bola_en_mano)
	turno_cambiado.emit(turno_actual, otorgar_bola_en_mano)

func _preparar_inicio_tiro(con_bola_en_mano: bool) -> void:
	tiempo_restante_turno = TIEMPO_MAXIMO_TURNO
	ultimo_aviso_tiempo = -1
	tiene_bola_en_mano_este_turno = con_bola_en_mano
	tronera_designada = null
	tronera_donde_cayo_negra = null
	
	if not mesa_abierta:
		var mi_faccion: int = _obtener_faccion_actual()
		bolas_propias_restantes_al_iniciar_tiro = _contar_bolas_restantes(mi_faccion)
		debe_cantar_tronera = (bolas_propias_restantes_al_iniciar_tiro == 0)
	else:
		bolas_propias_restantes_al_iniciar_tiro = 7
		debe_cantar_tronera = false
		
	_habilitar_seleccion_troneras(debe_cantar_tronera)
	if debe_cantar_tronera:
		_emitir_notificacion("¡Tiro por la Bola 8! Haz clic sobre una tronera para cantarla (se pintara de verde).")
		
	if con_bola_en_mano and bola_blanca_ref:
		if bola_blanca_ref.fue_embolsada:
			bola_blanca_ref.global_position = _buscar_posicion_libre_cercana(posicion_saque)
		estado = EstadoJuego.COLOCANDO_BOLA_BLANCA
		bola_blanca_ref.activar_modo_colocacion(LIMITES_MESA_INTERNA)
		_emitir_notificacion("Bola en Mano activa: Mueve el mouse a una posicion libre (halo verde) y haz clic izquierdo para colocar la blanca.")
	else:
		estado = EstadoJuego.ESPERANDO_TIRO

func _buscar_posicion_libre_cercana(origen: Vector2) -> Vector2:
	var radio_b: float = bola_blanca_ref.radio_mundo if bola_blanca_ref else 15.44
	if validar_distancia_bolas_y_troneras(origen, radio_b, bola_blanca_ref):
		return origen
		
	for paso_radio in range(1, 15):
		var distancia: float = float(paso_radio) * 22.0
		for paso_angulo in range(12):
			var angulo: float = (TAU / 12.0) * float(paso_angulo)
			var candidata: Vector2 = origen + Vector2(cos(angulo), sin(angulo)) * distancia
			if validar_distancia_bolas_y_troneras(candidata, radio_b, bola_blanca_ref):
				return candidata
	return origen

func _contar_bolas_restantes(tipo_faccion: int) -> int:
	var cantidad: int = 0
	for bola in nodo_bolas.get_children():
		if bola is Bola and not bola.fue_embolsada and bola.tipo_bola == tipo_faccion:
			cantidad += 1
	return cantidad

func _obtener_faccion_actual() -> int:
	return faccion_j1 if turno_actual == Jugador.UNO else faccion_j2

func _obtener_nombre_tipo_bola(tipo: int) -> String:
	match tipo:
		Bola.TipoBola.BLANCA:
			return "Blanca"
		Bola.TipoBola.LISA:
			return "Lisa"
		Bola.TipoBola.RAYADA:
			return "Rayada"
		Bola.TipoBola.NEGRA:
			return "Negra (Bola 8)"
		_:
			return "Desconocida"

func _emitir_notificacion(mensaje: String) -> void:
	print(mensaje)
	notificacion_juego.emit(mensaje)
