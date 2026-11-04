class_name Bola
extends RigidBody2D

enum TipoBola { BLANCA, LISA, RAYADA, NEGRA }

@export var tipo_bola: TipoBola = TipoBola.LISA
@export var textura_bola: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var linea_apunte: Line2D = get_node_or_null("LineaApunte")

var is_aiming: bool = false
var power_multiplier: float = 15.0
var max_drag_distance: float = 200.0

var fue_embolsada: bool = false
var posicion_reaparicion: Vector2 = Vector2.INF

func _ready() -> void:
	if textura_bola:
		sprite.texture = textura_bola
	if linea_apunte:
		linea_apunte.visible = false
		linea_apunte.top_level = true

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if posicion_reaparicion != Vector2.INF:
		state.transform.origin = posicion_reaparicion
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		posicion_reaparicion = Vector2.INF

func reubicar(nueva_posicion: Vector2) -> void:
	posicion_reaparicion = nueva_posicion
	fue_embolsada = false
	
	set_deferred("freeze", false)
	set_deferred("sleeping", false)
	set_deferred("visible", true)

func _input(event: InputEvent) -> void:
	if tipo_bola != TipoBola.BLANCA:
		return
		
	# Bloqueo estricto si las bolas siguen rodando
	var gestor: GestorJuego = get_tree().root.find_child("GestorJuego", true, false) as GestorJuego
	if gestor and gestor.estado != GestorJuego.EstadoJuego.ESPERANDO_TIRO:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if linear_velocity.length() < 5.0:
					is_aiming = true
			else:
				if is_aiming:
					shoot()
					is_aiming = false
					if linea_apunte:
						linea_apunte.visible = false

func _process(_delta: float) -> void:
	if is_aiming and linea_apunte:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var drag_vector: Vector2 = global_position - mouse_pos
		var distance: float = clamp(drag_vector.length(), 0.0, max_drag_distance)
		var aim_dir: Vector2 = drag_vector.normalized()
		
		linea_apunte.global_position = global_position
		linea_apunte.visible = true
		linea_apunte.clear_points()
		linea_apunte.add_point(Vector2.ZERO)
		linea_apunte.add_point(aim_dir * distance * 3.0)

func shoot() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var drag_vector: Vector2 = global_position - mouse_pos
	var distance: float = clamp(drag_vector.length(), 0.0, max_drag_distance)
	
	# Descartar clics accidentales sin arrastre
	if distance < 5.0:
		return
		
	var aim_dir: Vector2 = drag_vector.normalized()
	var impulse: Vector2 = aim_dir * distance * power_multiplier
	apply_central_impulse(impulse)
	
	# Notificar explícitamente al GestorJuego para cambiar de estado
	var gestor: GestorJuego = get_tree().root.find_child("GestorJuego", true, false) as GestorJuego
	if gestor:
		gestor.registrar_tiro()
