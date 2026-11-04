class_name Bola
extends RigidBody2D

signal primera_bola_contactada(bola_objetivo: Bola)
signal tiro_ejecutado()
signal bola_colocada_en_mesa(posicion_final: Vector2)

enum TipoBola { BLANCA, LISA, RAYADA, NEGRA }

const UMBRAL_MINIMO_ARRASTRE: float = 5.0
const DISTANCIA_BASE_PROYECCION: float = 900.0

@export var tipo_bola: TipoBola = TipoBola.LISA
@export var textura_bola: Texture2D
@export var es_bola_blanca: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var linea_apunte: Line2D = get_node_or_null("LineaApunte")

var esta_apuntando: bool = false
var multiplicador_potencia: float = 15.0
var distancia_maxima_arrastre: float = 200.0

var fue_embolsada: bool = false
var posicion_reaparicion: Vector2 = Vector2.INF
var detener_pendiente: bool = false

var monitoreando_primer_contacto: bool = false
var primer_contacto_registrado: bool = false

var en_modo_colocacion: bool = false
var posicion_colocacion_valida: bool = true
var limites_mesa_colocacion: Rect2 = Rect2(350.0, 205.0, 1244.0, 598.0)
var capa_colision_original: int = 2
var mascara_colision_original: int = 3

var radio_mundo: float = 15.44
var forma_barrido: CircleShape2D
var punto_impacto_local: Vector2 = Vector2.ZERO
var hay_impacto_proyectado: bool = false

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
		
	if tipo_bola == TipoBola.BLANCA:
		contact_monitor = true
		max_contacts_reported = 8
		body_entered.connect(_al_colisionar_cuerpo)

func _integrate_forces(estado_fisico: PhysicsDirectBodyState2D) -> void:
	if posicion_reaparicion != Vector2.INF:
		estado_fisico.transform.origin = posicion_reaparicion
		estado_fisico.linear_velocity = Vector2.ZERO
		estado_fisico.angular_velocity = 0.0
		posicion_reaparicion = Vector2.INF
		
	if detener_pendiente:
		estado_fisico.linear_velocity = Vector2.ZERO
		estado_fisico.angular_velocity = 0.0
		detener_pendiente = false
		
	if tipo_bola == TipoBola.BLANCA and monitoreando_primer_contacto and not primer_contacto_registrado:
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
		
	set_deferred("freeze", false)
	set_deferred("sleeping", false)
	set_deferred("visible", true)

func detener_completamente() -> void:
	if not fue_embolsada:
		detener_pendiente = true

func activar_modo_colocacion(limites: Rect2) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
	cancelar_apunte()
	limites_mesa_colocacion = limites
	en_modo_colocacion = true
	fue_embolsada = false
	visible = true
	
	# Desactivar colisiones fisicas mientras se arrastra para no empujar otras bolas
	collision_layer = 0
	collision_mask = 0
	set_deferred("freeze", true)
	queue_redraw()

func cancelar_apunte() -> void:
	esta_apuntando = false
	hay_impacto_proyectado = false
	if linea_apunte:
		linea_apunte.visible = false
	queue_redraw()

func _unhandled_input(evento: InputEvent) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
		
	var gestor: GestorJuego = _obtener_gestor()
	if not gestor:
		return
		
	# Modo Bola en Mano: clic izquierdo confirma la posicion si es libre de solapamientos
	if en_modo_colocacion:
		if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
			if posicion_colocacion_valida:
				en_modo_colocacion = false
				var pos_confirmada: Vector2 = global_position
				reubicar(pos_confirmada)
				queue_redraw()
				bola_colocada_en_mesa.emit(pos_confirmada)
				get_viewport().set_input_as_handled()
		return
		
	if gestor.estado != GestorJuego.EstadoJuego.ESPERANDO_TIRO:
		return
		
	if evento is InputEventMouseButton:
		# Si el jugador tiene derecho a Bola en Mano este turno, clic derecho permite volver a moverla
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
			else:
				if esta_apuntando:
					disparar()
					cancelar_apunte()

func _physics_process(_delta: float) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
		
	if en_modo_colocacion:
		var pos_mouse: Vector2 = get_global_mouse_position()
		var pos_acotada: Vector2 = Vector2(
			clamp(pos_mouse.x, limites_mesa_colocacion.position.x, limites_mesa_colocacion.end.x),
			clamp(pos_mouse.y, limites_mesa_colocacion.position.y, limites_mesa_colocacion.end.y)
		)
		global_position = pos_acotada
		posicion_colocacion_valida = es_posicion_libre(pos_acotada)
		if sprite:
			sprite.modulate = Color(0.55, 1.0, 0.55, 0.9) if posicion_colocacion_valida else Color(1.0, 0.35, 0.35, 0.8)
		queue_redraw()
		return
		
	if esta_apuntando and linea_apunte:
		_actualizar_linea_predictiva()

func _actualizar_linea_predictiva() -> void:
	var pos_mouse: Vector2 = get_global_mouse_position()
	var vector_arrastre: Vector2 = global_position - pos_mouse
	var distancia: float = clamp(vector_arrastre.length(), 0.0, distancia_maxima_arrastre)
	
	if distancia < UMBRAL_MINIMO_ARRASTRE:
		linea_apunte.visible = false
		hay_impacto_proyectado = false
		queue_redraw()
		return
		
	var direccion_apunte: Vector2 = vector_arrastre.normalized()
	var alcance_maximo: float = max(distancia * 4.0, 120.0)
	var desplazamiento_objetivo: Vector2 = direccion_apunte * alcance_maximo
	
	var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var parametros: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	parametros.shape = forma_barrido
	parametros.transform = Transform2D(0.0, global_position)
	parametros.motion = desplazamiento_objetivo
	parametros.collision_mask = 1 | 2
	parametros.exclude = [get_rid()]
	
	var resultado: PackedFloat32Array = espacio.cast_motion(parametros)
	var fraccion_segura: float = 1.0
	if resultado.size() >= 1:
		fraccion_segura = resultado[0]
		
	var vector_final: Vector2 = desplazamiento_objetivo * fraccion_segura
	punto_impacto_local = vector_final
	hay_impacto_proyectado = fraccion_segura < 0.999
	
	linea_apunte.global_position = global_position
	linea_apunte.visible = true
	linea_apunte.clear_points()
	linea_apunte.add_point(Vector2.ZERO)
	linea_apunte.add_point(vector_final)
	queue_redraw()

func _draw() -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
	if en_modo_colocacion:
		var color_halo: Color = Color(0.2, 1.0, 0.3, 0.85) if posicion_colocacion_valida else Color(1.0, 0.2, 0.2, 0.85)
		draw_arc(Vector2.ZERO, radio_mundo + 4.0, 0.0, TAU, 32, color_halo, 2.5)
	elif esta_apuntando and hay_impacto_proyectado:
		# Dibuja la "Ghost Ball" (silueta del radio real en el punto de impacto)
		draw_arc(punto_impacto_local, radio_mundo, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.45), 1.8)

func es_posicion_libre(posicion_evaluar: Vector2) -> bool:
	var gestor: GestorJuego = _obtener_gestor()
	if gestor:
		if not gestor.validar_distancia_bolas_y_troneras(posicion_evaluar, radio_mundo, self):
			return false
			
	var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var parametros: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	parametros.shape = forma_barrido
	parametros.transform = Transform2D(0.0, posicion_evaluar)
	parametros.collision_mask = 1 | 2 | 4
	parametros.collide_with_areas = true
	parametros.collide_with_bodies = true
	parametros.exclude = [get_rid()]
	
	var colisiones: Array[Dictionary] = espacio.intersect_shape(parametros, 4)
	return colisiones.is_empty()

func disparar() -> void:
	var gestor: GestorJuego = _obtener_gestor()
	if gestor and not gestor.puede_iniciar_apunte():
		return
		
	var pos_mouse: Vector2 = get_global_mouse_position()
	var vector_arrastre: Vector2 = global_position - pos_mouse
	var distancia: float = clamp(vector_arrastre.length(), 0.0, distancia_maxima_arrastre)
	
	if distancia < UMBRAL_MINIMO_ARRASTRE:
		return
		
	primer_contacto_registrado = false
	monitoreando_primer_contacto = true
	
	var direccion_apunte: Vector2 = vector_arrastre.normalized()
	var impulso: Vector2 = direccion_apunte * distancia * multiplicador_potencia
	apply_central_impulse(impulso)
	
	tiro_ejecutado.emit()
	if gestor:
		gestor.registrar_tiro()

func _obtener_gestor() -> GestorJuego:
	if not gestor_ref:
		gestor_ref = get_tree().root.find_child("GestorJuego", true, false) as GestorJuego
	return gestor_ref
