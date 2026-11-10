class_name ControladorIA
extends Node

const CENTRO_MESA: Vector2 = Vector2(972.0, 504.0)

var generador_azar: RandomNumberGenerator = RandomNumberGenerator.new()
var turno_ia_en_progreso: bool = false

func _ready() -> void:
	generador_azar.randomize()

func cancelar_turno_ia() -> void:
	turno_ia_en_progreso = false

func ejecutar_turno_ia(gestor: GestorJuego) -> void:
	if not gestor or turno_ia_en_progreso:
		return
	turno_ia_en_progreso = true
	_secuencia_turno_ia(gestor)

func _secuencia_turno_ia(gestor: GestorJuego) -> void:
	var dificultad: int = _obtener_dificultad(gestor)
	
	# Pausa breve inicial para que el jugador perciba el inicio del turno de la CPU
	await get_tree().create_timer(0.65).timeout
	if not is_instance_valid(gestor) or not turno_ia_en_progreso or gestor.estado == GestorJuego.EstadoJuego.FIN_PARTIDA:
		turno_ia_en_progreso = false
		return
	if gestor.es_turno_humano():
		turno_ia_en_progreso = false
		return
		
	var bola_blanca: Bola = gestor.bola_blanca_ref
	if not bola_blanca:
		turno_ia_en_progreso = false
		return
		
	# 1. Fase condicional: Si la IA tiene Bola en Mano, elegir posicion optima y colocarla
	if gestor.estado == GestorJuego.EstadoJuego.COLOCANDO_BOLA_BLANCA:
		var pos_elegida: Vector2 = elegir_posicion_bola_en_mano(gestor, dificultad)
		bola_blanca.colocar_automaticamente(pos_elegida)
		await get_tree().create_timer(0.55).timeout
		if not is_instance_valid(gestor) or not turno_ia_en_progreso or gestor.estado != GestorJuego.EstadoJuego.ESPERANDO_TIRO:
			turno_ia_en_progreso = false
			return
			
	# 2. Planificar el mejor tiro segun la dificultad activa
	var plan: Dictionary = planificar_tiro(gestor, dificultad)
	var direccion_tiro: Vector2 = plan.get("direccion", Vector2.LEFT)
	var distancia_arrastre: float = plan.get("distancia_arrastre", 110.0)
	var tronera_cantada: Tronera = plan.get("tronera_objetivo", null)
	
	# 3. Si solo resta la Bola 8, la IA debe cantar tronera (se ilumina en verde)
	if gestor.debe_cantar_tronera:
		if tronera_cantada == null:
			tronera_cantada = _obtener_tronera_mas_cercana_a_negra(gestor)
		if tronera_cantada != null:
			gestor.seleccionar_tronera_directa(tronera_cantada)
			await get_tree().create_timer(0.55).timeout
			if not is_instance_valid(gestor) or not turno_ia_en_progreso or gestor.estado != GestorJuego.EstadoJuego.ESPERANDO_TIRO:
				turno_ia_en_progreso = false
				return
				
	# 4. Mostrar visualmente la linea de apunte de la IA antes de soltar el tiro
	bola_blanca.mostrar_apunte_externo(direccion_tiro, distancia_arrastre)
	await get_tree().create_timer(0.75).timeout
	if not is_instance_valid(gestor) or not turno_ia_en_progreso or gestor.estado != GestorJuego.EstadoJuego.ESPERANDO_TIRO:
		bola_blanca.cancelar_apunte()
		turno_ia_en_progreso = false
		return
		
	# 5. Ejecutar el disparo fisico determinista
	turno_ia_en_progreso = false
	bola_blanca.disparar_con_vector(direccion_tiro, distancia_arrastre)

func elegir_posicion_bola_en_mano(gestor: GestorJuego, dificultad: int) -> Vector2:
	var bola_blanca: Bola = gestor.bola_blanca_ref
	var radio_b: float = bola_blanca.radio_mundo if bola_blanca else 15.44
	
	# En dificultad Facil, coloca la blanca cerca de la posicion de saque con leve variacion
	if dificultad == 0:
		for intento in range(20):
			var offset: Vector2 = Vector2(
				generador_azar.randf_range(-90.0, 90.0),
				generador_azar.randf_range(-120.0, 120.0)
			)
			var candidata: Vector2 = _acotar_a_mesa(gestor.posicion_saque + offset, gestor.LIMITES_MESA_INTERNA, 22.0)
			if gestor.validar_distancia_bolas_y_troneras(candidata, radio_b, bola_blanca):
				return candidata
		return gestor._buscar_posicion_libre_cercana(gestor.posicion_saque)
		
	# En dificultades Medio y Profesional, busca alinearse detras de la mejor bola legal hacia una tronera
	var bolas_legales: Array[Bola] = _obtener_bolas_legales(gestor)
	var troneras: Array[Tronera] = _obtener_troneras(gestor)
	var mejor_pos: Vector2 = Vector2.INF
	var mejor_puntaje: float = -INF
	
	for bola_obj in bolas_legales:
		for tronera in troneras:
			var entrada_tronera: Vector2 = _punto_entrada_tronera(tronera)
			var dir_a_tronera: Vector2 = (entrada_tronera - bola_obj.global_position).normalized()
			var dist_a_tronera: float = bola_obj.global_position.distance_to(entrada_tronera)
			if not _corredor_libre(bola_obj.global_position, entrada_tronera, radio_b * 1.95, [bola_blanca, bola_obj], gestor):
				continue
				
			var pos_fantasma: Vector2 = bola_obj.global_position - (dir_a_tronera * (radio_b * 2.0))
			for dist_detras in [95.0, 140.0, 190.0]:
				var candidata: Vector2 = pos_fantasma - (dir_a_tronera * dist_detras)
				if not gestor.LIMITES_MESA_INTERNA.grow(-18.0).has_point(candidata):
					continue
				if not gestor.validar_distancia_bolas_y_troneras(candidata, radio_b, bola_blanca):
					continue
				if not _corredor_libre(candidata, pos_fantasma, radio_b * 1.98, [bola_blanca, bola_obj], gestor):
					continue
				var puntaje: float = 200.0 - (dist_a_tronera * 0.15) - (dist_detras * 0.1)
				if puntaje > mejor_puntaje:
					mejor_puntaje = puntaje
					mejor_pos = candidata
					
	if mejor_pos != Vector2.INF:
		return mejor_pos
	return gestor._buscar_posicion_libre_cercana(gestor.posicion_saque)

func planificar_tiro(gestor: GestorJuego, dificultad: int) -> Dictionary:
	var bola_blanca: Bola = gestor.bola_blanca_ref
	var pos_blanca: Vector2 = bola_blanca.global_position
	var radio_b: float = bola_blanca.radio_mundo
	var troneras: Array[Tronera] = _obtener_troneras(gestor)
	
	# Caso 1: Saque Inicial (Break)
	if gestor.es_tiro_saque:
		var objetivo_saque: Vector2 = Vector2(602.0, 504.0)
		var bolas_activas: Array[Bola] = _obtener_bolas_legales(gestor)
		if bolas_activas.size() > 0:
			objetivo_saque = bolas_activas[0].global_position
		var dir_saque: Vector2 = (objetivo_saque - pos_blanca).normalized()
		var desvio_saque: float = deg_to_rad(generador_azar.randf_range(-1.8, 1.8))
		return {
			"direccion": dir_saque.rotated(desvio_saque),
			"distancia_arrastre": bola_blanca.distancia_maxima_arrastre * 0.96,
			"tronera_objetivo": troneras[0] if troneras.size() > 0 else null
		}
		
	var bolas_legales: Array[Bola] = _obtener_bolas_legales(gestor)
	var mejor_candidato: Dictionary = {}
	var mejor_puntaje: float = -INF
	
	# Evaluar tiros directos a tronera para cada bola legal
	for bola_obj in bolas_legales:
		for tronera in troneras:
			var entrada_tronera: Vector2 = _punto_entrada_tronera(tronera)
			var hacia_tronera: Vector2 = entrada_tronera - bola_obj.global_position
			var dist_bola_tronera: float = hacia_tronera.length()
			var dir_bola_tronera: Vector2 = hacia_tronera / max(1.0, dist_bola_tronera)
			
			# Posicion exacta de la Ghost Ball
			var pos_fantasma: Vector2 = bola_obj.global_position - (dir_bola_tronera * (radio_b + bola_obj.radio_mundo))
			if not gestor.LIMITES_MESA_INTERNA.grow(4.0).has_point(pos_fantasma):
				continue
				
			var hacia_fantasma: Vector2 = pos_fantasma - pos_blanca
			var dist_blanca_fantasma: float = hacia_fantasma.length()
			if dist_blanca_fantasma < 4.0:
				continue
			var dir_tiro: Vector2 = hacia_fantasma / dist_blanca_fantasma
			
			# Coseno del angulo de corte (1.0 = recto, 0.0 = 90 grados)
			var cos_corte: float = dir_tiro.dot(dir_bola_tronera)
			var umbral_corte: float = 0.14 if dificultad == 2 else (0.22 if dificultad == 1 else 0.30)
			if cos_corte < umbral_corte:
				continue
				
			# Verificar que el corredor blanca -> pos_fantasma y bola_obj -> tronera esten despejados
			if not _corredor_libre(pos_blanca, pos_fantasma, radio_b * 1.96, [bola_blanca, bola_obj], gestor):
				continue
			if not _corredor_libre(bola_obj.global_position, entrada_tronera, radio_b * 1.92, [bola_blanca, bola_obj], gestor):
				continue
				
			var puntaje: float = (cos_corte * 140.0) - (dist_blanca_fantasma * 0.065) - (dist_bola_tronera * 0.11)
			
			# Calculo de potencia requerida segun la distancia total y el corte
			var dist_equivalente: float = (dist_blanca_fantasma * 0.55) + (dist_bola_tronera / max(0.35, cos_corte))
			var arrastre_ideal: float = clamp(42.0 + (dist_equivalente * 0.14), 52.0, bola_blanca.distancia_maxima_arrastre * 0.90)
			
			if dificultad == 2:
				# En modo Profesional: evaluar riesgo de Scratch y posicionamiento residual de la blanca
				var componente_normal: Vector2 = dir_bola_tronera * dir_tiro.dot(dir_bola_tronera)
				var vector_tangente: Vector2 = dir_tiro - componente_normal
				if vector_tangente.length_squared() > 0.001:
					var dir_tangente: Vector2 = vector_tangente.normalized()
					for t_riesgo in troneras:
						var hacia_t: Vector2 = t_riesgo.global_position - pos_fantasma
						if hacia_t.length() < 420.0 and hacia_t.normalized().dot(dir_tangente) > 0.94:
							puntaje -= 65.0
					var pos_residual_estimada: Vector2 = _acotar_a_mesa(
						pos_fantasma + dir_tangente * (arrastre_ideal * 1.4),
						gestor.LIMITES_MESA_INTERNA,
						30.0
					)
					var dist_al_centro: float = pos_residual_estimada.distance_to(CENTRO_MESA)
					puntaje += clamp(35.0 - (dist_al_centro * 0.05), 0.0, 35.0)
			elif dificultad == 0:
				# En modo Facil, agrega ruido a la valoracion para no elegir siempre la opcion optima
				puntaje += generador_azar.randf_range(-25.0, 25.0)
				
			if puntaje > mejor_puntaje:
				mejor_puntaje = puntaje
				mejor_candidato = {
					"direccion": dir_tiro,
					"distancia_arrastre": arrastre_ideal,
					"tronera_objetivo": tronera
				}
				
	# Si en modo Profesional no hay tiro directo, evaluar tiro por banda (Bank Shot)
	if mejor_candidato.is_empty() and dificultad == 2:
		mejor_candidato = _buscar_tiro_con_banda_profesional(gestor, bolas_legales, troneras)
		
	# Si aun no hay tiro de embocada claro, ejecutar tiro de resguardo (Safety) hacia una bola legal visible
	if mejor_candidato.is_empty():
		mejor_candidato = _buscar_tiro_resguardo_legal(gestor, bolas_legales, troneras)
		
	# Aplicar margen de ruido segun la dificultad (GDD Seccion 3.2)
	var dir_final: Vector2 = mejor_candidato.get("direccion", Vector2.LEFT)
	var arrastre_final: float = mejor_candidato.get("distancia_arrastre", 95.0)
	var tronera_final: Tronera = mejor_candidato.get("tronera_objetivo", null)
	
	var error_grados_max: float = 0.0
	var variacion_fuerza: float = 0.0
	match dificultad:
		0: # Facil: alto margen de ruido
			error_grados_max = 6.2
			variacion_fuerza = 0.22
		1: # Medio: ruido moderado
			error_grados_max = 2.1
			variacion_fuerza = 0.10
		2: # Profesional: precision milimetrica
			error_grados_max = 0.18
			variacion_fuerza = 0.02
			
	var desvio_rad: float = deg_to_rad(generador_azar.randf_range(-error_grados_max, error_grados_max))
	dir_final = dir_final.rotated(desvio_rad).normalized()
	arrastre_final = clamp(
		arrastre_final * (1.0 + generador_azar.randf_range(-variacion_fuerza, variacion_fuerza)),
		35.0,
		bola_blanca.distancia_maxima_arrastre
	)
	
	return {
		"direccion": dir_final,
		"distancia_arrastre": arrastre_final,
		"tronera_objetivo": tronera_final
	}

func _buscar_tiro_con_banda_profesional(gestor: GestorJuego, bolas_legales: Array[Bola], troneras: Array[Tronera]) -> Dictionary:
	var bola_blanca: Bola = gestor.bola_blanca_ref
	var pos_blanca: Vector2 = bola_blanca.global_position
	var radio_b: float = bola_blanca.radio_mundo
	var limites: Rect2 = gestor.LIMITES_MESA_INTERNA
	var mejor: Dictionary = {}
	var mejor_puntaje: float = -INF
	
	# Evaluar rebote de la bola objetivo en banda superior o inferior hacia una tronera
	var bandas_y: Array[float] = [limites.position.y, limites.end.y]
	for bola_obj in bolas_legales:
		for tronera in troneras:
			var entrada: Vector2 = _punto_entrada_tronera(tronera)
			for y_banda in bandas_y:
				var pos_espejo: Vector2 = Vector2(entrada.x, (2.0 * y_banda) - entrada.y)
				var dir_rebote: Vector2 = (pos_espejo - bola_obj.global_position).normalized()
				var pos_fantasma: Vector2 = bola_obj.global_position - (dir_rebote * (radio_b * 2.0))
				if not limites.has_point(pos_fantasma):
					continue
				var hacia_fantasma: Vector2 = pos_fantasma - pos_blanca
				var dir_tiro: Vector2 = hacia_fantasma.normalized()
				var cos_corte: float = dir_tiro.dot(dir_rebote)
				if cos_corte < 0.35:
					continue
				if not _corredor_libre(pos_blanca, pos_fantasma, radio_b * 1.96, [bola_blanca, bola_obj], gestor):
					continue
				var puntaje: float = (cos_corte * 85.0) - (hacia_fantasma.length() * 0.08)
				if puntaje > mejor_puntaje:
					mejor_puntaje = puntaje
					mejor = {
						"direccion": dir_tiro,
						"distancia_arrastre": clamp(115.0 + hacia_fantasma.length() * 0.12, 95.0, 175.0),
						"tronera_objetivo": tronera
					}
	return mejor

func _buscar_tiro_resguardo_legal(gestor: GestorJuego, bolas_legales: Array[Bola], troneras: Array[Tronera]) -> Dictionary:
	var bola_blanca: Bola = gestor.bola_blanca_ref
	var pos_blanca: Vector2 = bola_blanca.global_position
	var radio_b: float = bola_blanca.radio_mundo
	var tronera_defecto: Tronera = _obtener_tronera_mas_cercana_a_negra(gestor)
	if tronera_defecto == null and troneras.size() > 0:
		tronera_defecto = troneras[0]
		
	# Intentar golpear directamente cualquier bola legal con linea de vision despejada
	var mejor_bola: Bola = null
	var menor_dist: float = INF
	var mejor_dir: Vector2 = Vector2.LEFT
	
	for bola_obj in bolas_legales:
		var hacia_bola: Vector2 = bola_obj.global_position - pos_blanca
		var dist: float = hacia_bola.length()
		var dir_central: Vector2 = hacia_bola.normalized()
		var normal_lat: Vector2 = Vector2(-dir_central.y, dir_central.x)
		
		for factor_lat in [0.0, 0.45, -0.45, 0.8, -0.8]:
			var punto_objetivo: Vector2 = bola_obj.global_position + (normal_lat * (radio_b * factor_lat)) - (dir_central * (radio_b * 1.85))
			if _corredor_libre(pos_blanca, punto_objetivo, radio_b * 1.92, [bola_blanca, bola_obj], gestor):
				if dist < menor_dist:
					menor_dist = dist
					mejor_bola = bola_obj
					mejor_dir = (punto_objetivo - pos_blanca).normalized()
				break
				
	if mejor_bola != null:
		return {
			"direccion": mejor_dir,
			"distancia_arrastre": clamp(68.0 + menor_dist * 0.08, 60.0, 130.0),
			"tronera_objetivo": tronera_defecto
		}
		
	# Si todas las bolas legales estan tapadas, tirar hacia la mas cercana mediante rebote o directo
	if bolas_legales.size() > 0:
		var dir_emergencia: Vector2 = (bolas_legales[0].global_position - pos_blanca).normalized()
		return {
			"direccion": dir_emergencia,
			"distancia_arrastre": 105.0,
			"tronera_objetivo": tronera_defecto
		}
		
	return {
		"direccion": Vector2.LEFT,
		"distancia_arrastre": 90.0,
		"tronera_objetivo": tronera_defecto
	}

func _corredor_libre(inicio: Vector2, fin: Vector2, radio_corredor: float, ignorar: Array[Bola], gestor: GestorJuego) -> bool:
	var segmento: Vector2 = fin - inicio
	var largo: float = segmento.length()
	if largo <= 1.0:
		return true
	var dir: Vector2 = segmento / largo
	
	for nodo in gestor.nodo_bolas.get_children():
		if nodo is Bola:
			var b: Bola = nodo as Bola
			if b.fue_embolsada or (b in ignorar):
				continue
			var hacia_b: Vector2 = b.global_position - inicio
			var proy: float = hacia_b.dot(dir)
			if proy < -b.radio_mundo or proy > largo + b.radio_mundo:
				continue
			var punto_mas_cercano: Vector2 = inicio + (dir * clamp(proy, 0.0, largo))
			if b.global_position.distance_to(punto_mas_cercano) < radio_corredor:
				return false
	return true

func _obtener_bolas_legales(gestor: GestorJuego) -> Array[Bola]:
	var resultado: Array[Bola] = []
	if not gestor or not gestor.nodo_bolas:
		return resultado
	for nodo in gestor.nodo_bolas.get_children():
		if nodo is Bola:
			var b: Bola = nodo as Bola
			if gestor.es_bola_objetivo_legal(b):
				resultado.append(b)
	return resultado

func _obtener_troneras(gestor: GestorJuego) -> Array[Tronera]:
	var resultado: Array[Tronera] = []
	if not gestor or not gestor.nodo_troneras:
		return resultado
	for nodo in gestor.nodo_troneras.get_children():
		if nodo is Tronera:
			resultado.append(nodo as Tronera)
	return resultado

func _obtener_tronera_mas_cercana_a_negra(gestor: GestorJuego) -> Tronera:
	var troneras: Array[Tronera] = _obtener_troneras(gestor)
	if troneras.is_empty():
		return null
	var bola_negra: Bola = null
	for nodo in gestor.nodo_bolas.get_children():
		if nodo is Bola and not (nodo as Bola).fue_embolsada and (nodo as Bola).tipo_bola == Bola.TipoBola.NEGRA:
			bola_negra = nodo as Bola
			break
	if bola_negra == null:
		return troneras[0]
	var mejor_t: Tronera = troneras[0]
	var menor_d: float = INF
	for t in troneras:
		var d: float = bola_negra.global_position.distance_to(t.global_position)
		if d < menor_d:
			menor_d = d
			mejor_t = t
	return mejor_t

func _punto_entrada_tronera(tronera: Tronera) -> Vector2:
	return tronera.global_position.lerp(CENTRO_MESA, 0.055)

func _acotar_a_mesa(punto: Vector2, limites: Rect2, margen: float) -> Vector2:
	return Vector2(
		clamp(punto.x, limites.position.x + margen, limites.end.x - margen),
		clamp(punto.y, limites.position.y + margen, limites.end.y - margen)
	)

func _obtener_dificultad(gestor: GestorJuego) -> int:
	if gestor:
		return gestor.obtener_dificultad_ia_activa()
	return 1
