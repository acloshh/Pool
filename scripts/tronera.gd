class_name Tronera
extends Area2D

signal bola_embolsada(bola: Bola, tronera: Tronera)
signal tronera_elegida(tronera: Tronera)

var seleccion_habilitada: bool = false
var esta_seleccionada: bool = false
var radio_tronera: float = 26.0

func _ready() -> void:
	body_entered.connect(_al_entrar_cuerpo)
	var colision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colision and colision.shape is CircleShape2D:
		radio_tronera = (colision.shape as CircleShape2D).radius

func _input(evento: InputEvent) -> void:
	if not seleccion_habilitada:
		return
		
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		var distancia_mouse: float = get_global_mouse_position().distance_to(global_position)
		if distancia_mouse <= radio_tronera * 1.35:
			tronera_elegida.emit(self)
			get_viewport().set_input_as_handled()

func _draw() -> void:
	if esta_seleccionada:
		draw_circle(Vector2.ZERO, radio_tronera, Color(0.1, 0.85, 0.25, 0.55))
		draw_arc(Vector2.ZERO, radio_tronera, 0.0, TAU, 36, Color(0.2, 1.0, 0.35, 1.0), 4.0)
	elif seleccion_habilitada:
		draw_arc(Vector2.ZERO, radio_tronera, 0.0, TAU, 36, Color(0.2, 1.0, 0.35, 0.28), 2.0)

func habilitar_seleccion(activo: bool) -> void:
	seleccion_habilitada = activo
	if not activo:
		esta_seleccionada = false
	queue_redraw()

func establecer_seleccionada(seleccionada: bool) -> void:
	esta_seleccionada = seleccionada
	queue_redraw()

func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if cuerpo is Bola:
		_manejar_bola_embolsada(cuerpo as Bola)

func _manejar_bola_embolsada(bola: Bola) -> void:
	if bola.fue_embolsada:
		return
		
	bola.fue_embolsada = true
	bola.cancelar_apunte()
	
	bola.set_deferred("freeze", true)
	bola.set_deferred("visible", false)
	
	bola_embolsada.emit(bola, self)
	
	if bola.tipo_bola != Bola.TipoBola.BLANCA:
		bola.queue_free()
