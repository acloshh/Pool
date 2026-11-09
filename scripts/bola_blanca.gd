class_name Bola
extends RigidBody2D

signal primera_bola_contactada(bola_objetivo: Bola)
signal tiro_ejecutado()
signal bola_colocada_en_mesa(posicion_final: Vector2)

enum TipoBola { BLANCA, LISA, RAYADA, NEGRA }

const UMBRAL_MINIMO_ARRASTRE: float = 5.0

@export var tipo_bola: TipoBola = TipoBola.LISA
@export var textura_bola: Texture2D
@export var es_bola_blanca: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var linea_apunte: Line2D = get_node_or_null("LineaApunte")

var esta_apuntando: bool = false
var multiplicador_potencia: float = 15.0
var distancia_maxima_arrastre: float = 200.0
var direccion_apunte_actual: Vector2 = Vector2.ZERO
var distancia_apunte_actual: float = 0.0

var fue_embolsada: bool = false
var posicion_reaparicion: Vector2 = Vector2.INF
var detener_pendiente: bool = false

var monitoreando_primer_contacto: bool = false
var primer_contacto_registrado: bool = false

var en_modo_colocacion: bool = false
var posicion_colocacion_valida: bool = true
var limites_mesa_colocacion: Rect2 = Rect2(354.0, 210.0, 1236.0, 588.0)
var capa_colision_original: int = 2
var mascara_colision_original: int = 3

var radio_mundo: float = 15.44
var forma_barrido: CircleShape2D

# Vectores en espacio global (relativos a global_position, sin rotacion)
var vector_impacto_global: Vector2 = Vector2.ZERO
var normal_impacto_bola: Vector2 = Vector2.ZERO
var centro_bola_objetivo_relativo: Vector2 = Vector2.ZERO
var hay_impacto_proyectado: bool = false
var impacto_es_contra_bola: bool = false
var impacto_bola_es_legal: bool = true

var gestor_ref: GestorJuego = null

func _ready() -> void:
	capa_colision_original = collision_layer
	mascara_colision_original = collision_mask
	
	if textura_bola and sprite:
		sprite.texture = textura_bola
		
	var nodo_colision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if nodo_colision and nodo_colision.shape is CircleShape2D:
		radio_mundo = (nodo_colision.shape as CircleShape2D).radius * nodo_colision.scale.x
		
	forma_barrido = CircleShape2D.new()
	forma_barrido.radius = radio_mundo
	
	if linea_apunte:
		linea_apunte.visible = false
		linea_apunte.top_level = true
		linea_apunte.global_rotation = 0.0
		
	if tipo_bola == TipoBola.BLANCA:
		contact_monitor = true
		max_contacts_reported = 8
		body_entered.connect(_al_colisionar_cuerpo)

func _integrate_forces(estado_fisico: PhysicsDirectBodyState2D) -> void:
	if posicion_reaparicion != Vector2.INF:
		estado_fisico.transform = Transform2D(0.0, posicion_reaparicion)
		estado_fisico.linear_velocity = Vector2.ZERO
		estado_fisico.angular_velocity = 0.0
		posicion_reaparicion = Vector2.INF
		
	if detener_pendiente:
		estado_fisico.linear_velocity = Vector2.ZERO
		estado_fisico.angular_velocity = 0.0
		detener_pendiente = false
		
	if tipo_bola == TipoBola.BLANCA and monitoreando_primer_contacto and not primer_contacto_registrado:
		# Correccion sub-frame de Tiempo de Impacto (TOI) para evitar que la penetracion discreta
		# a alta velocidad desvie la normal del primer choque respecto a la Ghost Ball predicha.
		var velocidad_actual: Vector2 = estado_fisico.linear_velocity
		if velocidad_actual.length_squared() > 25.0:
			var dir_vel: Vector2 = velocidad_actual.normalized()
			var pos_actual: Vector2 = estado_fisico.transform.origin
			var gestor: GestorJuego = _obtener_gestor()
			var bola_mas_temprana: Bola = null
			var mayor_retroceso: float = 0.0
			
			if gestor and gestor.nodo_bolas:
				for nodo in gestor.nodo_bolas.get_children():
					if nodo is Bola:
						var otra: Bola = nodo as Bola
						if otra == self or otra.fue_embolsada:
							continue
						var hacia_otra: Vector2 = otra.global_position - pos_actual
						var radio_comb: float = radio_mundo + otra.radio_mundo
						var dist_cuad: float = hacia_otra.length_squared()
						if dist_cuad < (radio_comb * radio_comb) - 0.01:
							var proyeccion: float = hacia_otra.dot(dir_vel)
							var dist_perp_cuad: float = dist_cuad - (proyeccion * proyeccion)
							var radio_objetivo: float = radio_comb - 0.04
							if dist_perp_cuad < radio_objetivo * radio_objetivo:
								var retroceso: float = sqrt(max(0.0, (radio_objetivo * radio_objetivo) - dist_perp_cuad)) - proyeccion
								if retroceso > mayor_retroceso:
									mayor_retroceso = retroceso
									bola_mas_temprana = otra
									
			if bola_mas_temprana != null and mayor_retroceso > 0.0:
				var pos_contacto_exacto: Vector2 = pos_actual - (dir_vel * mayor_retroceso)
				estado_fisico.transform = Transform2D(0.0, pos_contacto_exacto)
				primer_contacto_registrado = true
				monitoreando_primer_contacto = false
				primera_bola_contactada.emit(bola_mas_temprana)
				return
				
		var cantidad_contactos: int = estado_fisico.get_contact_count()
		for i in range(cantidad_contactos):
			var objeto: Object = estado_fisico.get_contact_collider_object(i)
			if objeto is Bola:
				var otra_bola: Bola = objeto as Bola
				if not otra_bola.fue_embolsada:
					primer_contacto_registrado = true
					monitoreando_primer_contacto = false
					primera_bola_contactada.emit(otra_bola)
					break

func _al_colisionar_cuerpo(cuerpo: Node) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
	if monitoreando_primer_contacto and not primer_contacto_registrado:
		if cuerpo is Bola and not (cuerpo as Bola).fue_embolsada:
			primer_contacto_registrado = true
			monitoreando_primer_contacto = false
			primera_bola_contactada.emit(cuerpo as Bola)

func reubicar(nueva_posicion: Vector2) -> void:
	posicion_reaparicion = nueva_posicion
	fue_embolsada = false
	detener_pendiente = false
	
	collision_layer = capa_colision_original
	collision_mask = mascara_colision_original
	if sprite:
		sprite.modulate = Color.WHITE
		
	global_position = nueva_posicion
	global_rotation = 0.0
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, nueva_posicion))
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	
	set_deferred("freeze", false)
	set_deferred("sleeping", false)
	set_deferred("visible", true)

func detener_completamente() -> void:
	if fue_embolsada:
		return
	detener_pendiente = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)

func limpiar_estados_pendientes() -> void:
	detener_pendiente = false
	posicion_reaparicion = Vector2.INF

func activar_modo_colocacion(limites: Rect2) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
	cancelar_apunte()
	limites_mesa_colocacion = limites
	en_modo_colocacion = true
	fue_embolsada = false
	visible = true
	
	# Desactivar colisiones fisicas mientras se posiciona para no empujar otras bolas
	collision_layer = 0
	collision_mask = 0
	set_deferred("freeze", true)
	queue_redraw()

func cancelar_apunte() -> void:
	esta_apuntando = false
	hay_impacto_proyectado = false
	impacto_es_contra_bola = false
	impacto_bola_es_legal = true
	direccion_apunte_actual = Vector2.ZERO
	distancia_apunte_actual = 0.0
	if linea_apunte:
		linea_apunte.visible = false
		linea_apunte.default_color = Color(1.0, 1.0, 1.0, 0.5176471)
	queue_redraw()

func _unhandled_input(evento: InputEvent) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
		
	var gestor: GestorJuego = _obtener_gestor()
	if not gestor:
		return
		
	# Modo Bola en Mano: clic izquierdo confirma la posicion si no hay solapamiento
	if en_modo_colocacion:
		if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
			var pos_actual: Vector2 = _calcular_posicion_mouse_acotada()
			global_position = pos_actual
			posicion_colocacion_valida = es_posicion_libre(pos_actual)
			if posicion_colocacion_valida:
				en_modo_colocacion = false
				reubicar(pos_actual)
				queue_redraw()
				bola_colocada_en_mesa.emit(pos_actual)
				get_viewport().set_input_as_handled()
		return
		
	if gestor.estado != GestorJuego.EstadoJuego.ESPERANDO_TIRO:
		return
		
	if evento is InputEventMouseButton:
		# Si el jugador tiene Bola en Mano este turno, clic derecho permite volver a levantarla antes de tirar
		if evento.button_index == MOUSE_BUTTON_RIGHT and evento.pressed:
			if gestor.puede_reposicionar_bola_blanca():
				gestor.iniciar_reposicionamiento_manual()
				get_viewport().set_input_as_handled()
				return
				
		if evento.button_index == MOUSE_BUTTON_LEFT:
			if evento.pressed:
				if not gestor.puede_iniciar_apunte():
					return
				if linear_velocity.length() < 5.0:
					esta_apuntando = true
					_actualizar_linea_predictiva()
			else:
				if esta_apuntando:
					disparar()
					cancelar_apunte()

func _physics_process(_delta: float) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
		
	if en_modo_colocacion:
		var pos_acotada: Vector2 = _calcular_posicion_mouse_acotada()
		global_position = pos_acotada
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, pos_acotada))
		posicion_colocacion_valida = es_posicion_libre(pos_acotada)
		if sprite:
			sprite.modulate = Color(0.55, 1.0, 0.55, 0.92) if posicion_colocacion_valida else Color(1.0, 0.35, 0.35, 0.85)
		queue_redraw()
		return
		
	if esta_apuntando and linea_apunte:
		_actualizar_linea_predictiva()

func _calcular_posicion_mouse_acotada() -> Vector2:
	var pos_mouse: Vector2 = get_global_mouse_position()
	return Vector2(
		clamp(pos_mouse.x, limites_mesa_colocacion.position.x, limites_mesa_colocacion.end.x),
		clamp(pos_mouse.y, limites_mesa_colocacion.position.y, limites_mesa_colocacion.end.y)
	)

func _actualizar_linea_predictiva() -> void:
	var pos_mouse: Vector2 = get_global_mouse_position()
	var vector_arrastre: Vector2 = global_position - pos_mouse
	var distancia: float = clamp(vector_arrastre.length(), 0.0, distancia_maxima_arrastre)
	
	if distancia < UMBRAL_MINIMO_ARRASTRE:
		direccion_apunte_actual = Vector2.ZERO
		distancia_apunte_actual = 0.0
		linea_apunte.visible = false
		hay_impacto_proyectado = false
		impacto_es_contra_bola = false
		queue_redraw()
		return
		
	var direccion_apunte: Vector2 = vector_arrastre.normalized()
	direccion_apunte_actual = direccion_apunte
	distancia_apunte_actual = distancia
	var alcance_maximo: float = max(distancia * 4.5, 160.0)
	
	# 1. Calculo analitico exacto contra todas las bolas activas (interseccion rayo-circulo de radio 2*R)
	var distancia_impacto_bola: float = INF
	var bola_impactada: Bola = null
	var gestor: GestorJuego = _obtener_gestor()
	if gestor and gestor.nodo_bolas:
		for nodo in gestor.nodo_bolas.get_children():
			if nodo is Bola:
				var otra: Bola = nodo as Bola
				if otra == self or otra.fue_embolsada:
					continue
				var hacia_bola: Vector2 = otra.global_position - global_position
				var proyeccion: float = hacia_bola.dot(direccion_apunte)
				if proyeccion <= 0.0:
					continue
				var dist_perp_cuadrada: float = hacia_bola.length_squared() - (proyeccion * proyeccion)
				var radio_combinado: float = radio_mundo + otra.radio_mundo
				var radio_comb_cuadrado: float = radio_combinado * radio_combinado
				if dist_perp_cuadrada <= radio_comb_cuadrado:
					var dist_contacto: float = proyeccion - sqrt(max(0.0, radio_comb_cuadrado - dist_perp_cuadrada))
					if dist_contacto >= 0.0 and dist_contacto < distancia_impacto_bola:
						distancia_impacto_bola = dist_contacto
						bola_impactada = otra
						
	# 2. Barrido fisico volumetrico (cast_motion) contra las bandas reales (incluyendo biseles)
	var distancia_impacto_banda: float = _calcular_distancia_a_banda(global_position, direccion_apunte)
	if forma_barrido and get_world_2d():
		var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var parametros_banda: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		parametros_banda.shape = forma_barrido
		parametros_banda.transform = Transform2D(0.0, global_position)
		parametros_banda.motion = direccion_apunte * alcance_maximo
		parametros_banda.collision_mask = 1
		parametros_banda.exclude = [get_rid()]
		var resultado_barrido: PackedFloat32Array = espacio.cast_motion(parametros_banda)
		if resultado_barrido.size() >= 2 and resultado_barrido[0] < 1.0:
			distancia_impacto_banda = min(distancia_impacto_banda, resultado_barrido[0] * alcance_maximo)
	
	var distancia_obstaculo: float = min(distancia_impacto_bola, distancia_impacto_banda)
	var distancia_final: float = min(alcance_maximo, distancia_obstaculo)
	
	vector_impacto_global = direccion_apunte * distancia_final
	hay_impacto_proyectado = distancia_obstaculo <= alcance_maximo
	impacto_es_contra_bola = hay_impacto_proyectado and (distancia_impacto_bola <= distancia_impacto_banda) and (bola_impactada != null)
	impacto_bola_es_legal = true
	
	if impacto_es_contra_bola and bola_impactada:
		var pos_fantasma_mundo: Vector2 = global_position + vector_impacto_global
		normal_impacto_bola = (bola_impactada.global_position - pos_fantasma_mundo).normalized()
		centro_bola_objetivo_relativo = bola_impactada.global_position - global_position
		if gestor:
			impacto_bola_es_legal = gestor.es_bola_objetivo_legal(bola_impactada)
			
	if impacto_es_contra_bola and not impacto_bola_es_legal:
		linea_apunte.default_color = Color(1.0, 0.25, 0.25, 0.72)
	else:
		linea_apunte.default_color = Color(1.0, 1.0, 1.0, 0.5176471)
		
	linea_apunte.global_position = global_position
	linea_apunte.global_rotation = 0.0
	linea_apunte.visible = true
	linea_apunte.clear_points()
	linea_apunte.add_point(Vector2.ZERO)
	linea_apunte.add_point(vector_impacto_global)
	queue_redraw()

func _calcular_distancia_a_banda(origen: Vector2, direccion: Vector2) -> float:
	# Limites exactos de las bandas donde choca el centro de una bola de radio ~15.44
	var min_x: float = limites_mesa_colocacion.position.x
	var max_x: float = limites_mesa_colocacion.end.x
	var min_y: float = limites_mesa_colocacion.position.y
	var max_y: float = limites_mesa_colocacion.end.y
	
	var t_min: float = INF
	if abs(direccion.x) > 0.0001:
		var tx: float = ((max_x if direccion.x > 0.0 else min_x) - origen.x) / direccion.x
		if tx > 0.0:
			t_min = min(t_min, tx)
	if abs(direccion.y) > 0.0001:
		var ty: float = ((max_y if direccion.y > 0.0 else min_y) - origen.y) / direccion.y
		if ty > 0.0:
			t_min = min(t_min, ty)
	return t_min

func _draw() -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
		
	# Contrarrestar la rotacion del RigidBody2D para que el dibujo siempre use ejes globales
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE)
	
	if en_modo_colocacion:
		var color_halo: Color = Color(0.2, 1.0, 0.35, 0.9) if posicion_colocacion_valida else Color(1.0, 0.2, 0.2, 0.9)
		draw_arc(Vector2.ZERO, radio_mundo + 4.0, 0.0, TAU, 32, color_halo, 2.5)
	elif esta_apuntando and hay_impacto_proyectado:
		if impacto_es_contra_bola and not impacto_bola_es_legal:
			# Simbolo de Prohibido sobre la posicion de impacto cuando apunta a una bola ilegal
			var color_prohibido: Color = Color(1.0, 0.18, 0.18, 0.95)
			draw_circle(vector_impacto_global, radio_mundo, Color(0.85, 0.08, 0.08, 0.28))
			draw_arc(vector_impacto_global, radio_mundo, 0.0, TAU, 32, color_prohibido, 3.2)
			var desplazamiento_diag: Vector2 = Vector2(0.70710678, 0.70710678) * (radio_mundo - 1.5)
			draw_line(
				vector_impacto_global - desplazamiento_diag,
				vector_impacto_global + desplazamiento_diag,
				color_prohibido,
				3.2
			)
		else:
			# Silueta exacta de la bola blanca en el momento del impacto (Ghost Ball)
			draw_arc(vector_impacto_global, radio_mundo, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.75), 2.0)
			draw_circle(vector_impacto_global, 2.5, Color(1.0, 1.0, 1.0, 0.85))
			
			# Si impacta contra una bola legal, mostrar la linea de salida de la bola golpeada
			if impacto_es_contra_bola:
				var inicio_guia: Vector2 = centro_bola_objetivo_relativo
				var fin_guia: Vector2 = inicio_guia + (normal_impacto_bola * 55.0)
				draw_line(inicio_guia, fin_guia, Color(1.0, 0.9, 0.3, 0.75), 2.0)

func es_posicion_libre(posicion_evaluar: Vector2) -> bool:
	var gestor: GestorJuego = _obtener_gestor()
	if gestor:
		return gestor.validar_distancia_bolas_y_troneras(posicion_evaluar, radio_mundo, self)
	return true

func disparar() -> void:
	var gestor: GestorJuego = _obtener_gestor()
	if gestor and not gestor.puede_iniciar_apunte():
		return
		
	var direccion_apunte: Vector2 = direccion_apunte_actual
	var distancia: float = distancia_apunte_actual
	if distancia < UMBRAL_MINIMO_ARRASTRE or direccion_apunte == Vector2.ZERO:
		return
		
	limpiar_estados_pendientes()
	primer_contacto_registrado = false
	monitoreando_primer_contacto = true
	sleeping = false
	
	# Garantizar reposo absoluto antes de aplicar el impulso central para evitar desvios residuales
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	
	if gestor:
		gestor.registrar_tiro()
		
	var impulso: Vector2 = direccion_apunte * distancia * multiplicador_potencia
	apply_central_impulse(impulso)
	
	tiro_ejecutado.emit()

func _obtener_gestor() -> GestorJuego:
	if not gestor_ref:
		gestor_ref = get_tree().root.find_child("GestorJuego", true, false) as GestorJuego
	return gestor_ref
