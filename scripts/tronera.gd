class_name Tronera
extends Area2D

signal bola_embolsada(bola: Bola)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Bola:
		_manejar_bola_embolsada(body)

func _manejar_bola_embolsada(bola: Bola) -> void:
	if bola.fue_embolsada:
		return
		
	bola.fue_embolsada = true
	
	bola.set_deferred("freeze", true)
	bola.set_deferred("visible", false)
	
	bola_embolsada.emit(bola)
	
	# Usamos el enum para saber si la destruimos o no
	if bola.tipo_bola != Bola.TipoBola.BLANCA:
		bola.queue_free()
