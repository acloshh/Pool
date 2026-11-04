class_name GestorJuego
extends Node

enum Jugador { UNO, DOS }
enum EstadoJuego { ESPERANDO_TIRO, BOLAS_EN_MOVIMIENTO, FIN_PARTIDA }

var estado: EstadoJuego = EstadoJuego.ESPERANDO_TIRO
var posicion_saque: Vector2 = Vector2.ZERO
var turno_actual: Jugador = Jugador.UNO
var mesa_abierta: bool = true

var faccion_j1: int = -1
var faccion_j2: int = -1

var bolas_caidas_este_turno: Array[Bola.TipoBola] = []
var bola_blanca_ref: Bola

@onready var nodo_troneras: Node2D = %Troneras
@onready var nodo_bolas: Node2D = %Bolas

func _ready() -> void:
	for bola in nodo_bolas.get_children():
		if bola is Bola and bola.tipo_bola == Bola.TipoBola.BLANCA:
			posicion_saque = bola.global_position
			bola_blanca_ref = bola
			break
			
	for tronera in nodo_troneras.get_children():
		if tronera is Tronera:
			tronera.bola_embolsada.connect(_on_bola_embolsada)
			
	print("--- PARTIDA INICIADA ---")
	print("Turno del Jugador 1 - Mesa Abierta")

func _process(_delta: float) -> void:
	if estado == EstadoJuego.FIN_PARTIDA:
		return
		
	# Espera únicamente cuando el tiro ya fue disparado formalmente
	if estado == EstadoJuego.BOLAS_EN_MOVIMIENTO:
		if _todas_las_bolas_quietas():
			_evaluar_turno()

func registrar_tiro() -> void:
	if estado == EstadoJuego.ESPERANDO_TIRO:
		estado = EstadoJuego.BOLAS_EN_MOVIMIENTO
		bolas_caidas_este_turno.clear()

func _todas_las_bolas_quietas() -> bool:
	for bola in nodo_bolas.get_children():
		if bola is Bola and not bola.fue_embolsada:
			# Umbral seguro y verificación de reposo nativo (sleeping)
			if not bola.sleeping and bola.linear_velocity.length() > 5.0:
				return false
	return true

func _on_bola_embolsada(bola: Bola) -> void:
	bolas_caidas_este_turno.append(bola.tipo_bola)

func _evaluar_turno() -> void:
	estado = EstadoJuego.ESPERANDO_TIRO
	print("--- Fin del tiro ---")
	
	var falta: bool = Bola.TipoBola.BLANCA in bolas_caidas_este_turno
	var cayo_negra: bool = Bola.TipoBola.NEGRA in bolas_caidas_este_turno
	var mantiene_turno: bool = false
	
	if cayo_negra:
		_evaluar_bola_8(falta)
		return
		
	if falta:
		print("¡Falta! La bola blanca cayó.")
		bola_blanca_ref.reubicar(posicion_saque)
		mantiene_turno = false
	else:
		if mesa_abierta and bolas_caidas_este_turno.size() > 0:
			mantiene_turno = _evaluar_mesa_abierta()
		elif not mesa_abierta:
			mantiene_turno = _evaluar_mesa_cerrada()
	
	if not mantiene_turno:
		_cambiar_turno()
	else:
		var num_jugador: String = "1" if turno_actual == Jugador.UNO else "2"
		print("El Jugador ", num_jugador, " mantiene el turno.")

func _evaluar_mesa_abierta() -> bool:
	for tipo in bolas_caidas_este_turno:
		if tipo == Bola.TipoBola.LISA or tipo == Bola.TipoBola.RAYADA:
			mesa_abierta = false
			if turno_actual == Jugador.UNO:
				faccion_j1 = tipo
				faccion_j2 = Bola.TipoBola.RAYADA if tipo == Bola.TipoBola.LISA else Bola.TipoBola.LISA
			else:
				faccion_j2 = tipo
				faccion_j1 = Bola.TipoBola.RAYADA if tipo == Bola.TipoBola.LISA else Bola.TipoBola.LISA
			
			var n1: String = "Lisas" if faccion_j1 == Bola.TipoBola.LISA else "Rayadas"
			var n2: String = "Lisas" if faccion_j2 == Bola.TipoBola.LISA else "Rayadas"
			print("¡Mesa cerrada! J1: ", n1, " | J2: ", n2)
			return true
	return false

func _evaluar_mesa_cerrada() -> bool:
	var mi_faccion: int = faccion_j1 if turno_actual == Jugador.UNO else faccion_j2
	return mi_faccion in bolas_caidas_este_turno

func _evaluar_bola_8(con_falta: bool) -> void:
	estado = EstadoJuego.FIN_PARTIDA
	var num_jugador: String = "1" if turno_actual == Jugador.UNO else "2"
	var oponente: String = "2" if turno_actual == Jugador.UNO else "1"
	
	var mi_faccion: int = faccion_j1 if turno_actual == Jugador.UNO else faccion_j2
	var bolas_restantes: int = 0
	
	for bola in nodo_bolas.get_children():
		if bola is Bola and not bola.fue_embolsada and bola.tipo_bola == mi_faccion:
			bolas_restantes += 1
			
	if con_falta or bolas_restantes > 0 or mesa_abierta:
		print("¡DERROTA! Jugador ", num_jugador, " metió la 8 prematuramente o con falta. Gana J", oponente)
	else:
		print("¡VICTORIA! El Jugador ", num_jugador, " limpió la mesa y embocó la 8 limpiamente.")

func _cambiar_turno() -> void:
	turno_actual = Jugador.DOS if turno_actual == Jugador.UNO else Jugador.UNO
	var num_jugador: String = "1" if turno_actual == Jugador.UNO else "2"
	print("--> Cambio de turno: Juega el Jugador ", num_jugador)
