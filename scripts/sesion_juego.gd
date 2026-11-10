extends Node

enum ModoJuego { LOCAL_1V1, VS_IA, TORNEO }
enum DificultadIA { FACIL, MEDIO, PROFESIONAL }

const NOMBRES_RIVALES_TORNEO: Array[String] = [
	"CPU Novato",
	"CPU Tactico",
	"CPU Preciso",
	"CPU Maestro",
	"CPUCalculador",
	"CPU Veterano",
	"CPU Leyenda"
]

var modo_actual: ModoJuego = ModoJuego.LOCAL_1V1
var dificultad_actual: DificultadIA = DificultadIA.MEDIO
var mostrar_menu_al_iniciar: bool = true

# Estado del Modo Torneo (Llaves de 8 participantes: Cuartos, Semifinal, Final)
var torneo_en_curso: bool = false
var torneo_eliminado: bool = false
var ronda_torneo: int = 0 # 0: Cuartos, 1: Semifinal, 2: Final, 3: Campeon
var cuartos_torneo: Array[String] = []
var semifinalistas_torneo: Array[String] = ["?", "?", "?", "?"]
var finalistas_torneo: Array[String] = ["?", "?"]
var campeon_torneo: String = ""

func _ready() -> void:
	_inicializar_llaves_torneo()

func _inicializar_llaves_torneo() -> void:
	cuartos_torneo = [
		"JUGADOR 1",
		"IA Bot (Facil)",
		"IA Sombra",
		"IA Titan (Medio)",
		"IA Halcon",
		"IA Viper",
		"IA Kronos",
		"IA Maestro (Pro)"
	]
	semifinalistas_torneo = ["?", "?", "?", "?"]
	finalistas_torneo = ["?", "?"]
	campeon_torneo = ""
	ronda_torneo = 0
	torneo_eliminado = false

func iniciar_partida_local() -> void:
	modo_actual = ModoJuego.LOCAL_1V1
	torneo_en_curso = false
	mostrar_menu_al_iniciar = false

func iniciar_partida_vs_ia(dificultad: DificultadIA) -> void:
	modo_actual = ModoJuego.VS_IA
	dificultad_actual = dificultad
	torneo_en_curso = false
	mostrar_menu_al_iniciar = false

func iniciar_nuevo_torneo() -> void:
	modo_actual = ModoJuego.TORNEO
	torneo_en_curso = true
	_inicializar_llaves_torneo()
	dificultad_actual = DificultadIA.FACIL
	mostrar_menu_al_iniciar = false

func registrar_resultado_torneo(gano_humano: bool) -> void:
	if modo_actual != ModoJuego.TORNEO or not torneo_en_curso:
		return
		
	if ronda_torneo == 0:
		# Cuartos de Final -> Semifinal
		semifinalistas_torneo[0] = cuartos_torneo[0] if gano_humano else cuartos_torneo[1]
		semifinalistas_torneo[1] = cuartos_torneo[3]
		semifinalistas_torneo[2] = cuartos_torneo[4]
		semifinalistas_torneo[3] = cuartos_torneo[7]
		if gano_humano:
			ronda_torneo = 1
			dificultad_actual = DificultadIA.MEDIO
		else:
			torneo_eliminado = true
	elif ronda_torneo == 1:
		# Semifinal -> Final
		finalistas_torneo[0] = semifinalistas_torneo[0] if gano_humano else semifinalistas_torneo[1]
		finalistas_torneo[1] = semifinalistas_torneo[3]
		if gano_humano:
			ronda_torneo = 2
			dificultad_actual = DificultadIA.PROFESIONAL
		else:
			torneo_eliminado = true
	elif ronda_torneo == 2:
		# Final -> Campeon
		if gano_humano:
			campeon_torneo = finalistas_torneo[0]
			ronda_torneo = 3
		else:
			campeon_torneo = finalistas_torneo[1]
			torneo_eliminado = true

func es_rival_ia() -> bool:
	return modo_actual == ModoJuego.VS_IA or modo_actual == ModoJuego.TORNEO

func obtener_dificultad_activa() -> DificultadIA:
	if modo_actual == ModoJuego.TORNEO:
		match ronda_torneo:
			0:
				return DificultadIA.FACIL
			1:
				return DificultadIA.MEDIO
			_:
				return DificultadIA.PROFESIONAL
	return dificultad_actual

func obtener_nombre_jugador_2() -> String:
	if modo_actual == ModoJuego.LOCAL_1V1:
		return "JUGADOR 2"
	elif modo_actual == ModoJuego.TORNEO:
		match ronda_torneo:
			0:
				return cuartos_torneo[1] if cuartos_torneo.size() > 1 else "IA (CUARTOS)"
			1:
				return semifinalistas_torneo[1] if semifinalistas_torneo.size() > 1 else "IA (SEMIFINAL)"
			_:
				return finalistas_torneo[1] if finalistas_torneo.size() > 1 else "IA (FINAL)"
	else:
		match dificultad_actual:
			DificultadIA.FACIL:
				return "IA (FACIL)"
			DificultadIA.MEDIO:
				return "IA (MEDIO)"
			DificultadIA.PROFESIONAL:
				return "IA (PRO)"
	return "JUGADOR 2"

func obtener_titulo_modo() -> String:
	match modo_actual:
		ModoJuego.LOCAL_1V1:
			return "MODO: LOCAL 1v1"
		ModoJuego.VS_IA:
			match dificultad_actual:
				DificultadIA.FACIL:
					return "PARTIDA RAPIDA: VS IA (FACIL)"
				DificultadIA.MEDIO:
					return "PARTIDA RAPIDA: VS IA (MEDIO)"
				DificultadIA.PROFESIONAL:
					return "PARTIDA RAPIDA: VS IA (PROFESIONAL)"
		ModoJuego.TORNEO:
			match ronda_torneo:
				0:
					return "TORNEO: CUARTOS DE FINAL (1/3)"
				1:
					return "TORNEO: SEMIFINAL (2/3)"
				2:
					return "TORNEO: GRAN FINAL (3/3)"
				3:
					return "TORNEO: ¡CAMPEON!"
	return "MODO: LOCAL 1v1"
