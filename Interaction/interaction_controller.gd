extends Node

@onready var interaction_controller: Node = %InteractionController
@onready var interaction_raycast: RayCast3D = %InteractionRaycast
@onready var player_camera: Camera3D = %Camera3D
@onready var hand: Marker3D = %Hand
@onready var default_reticle: TextureRect = %DefaultReticle
@onready var higlight_reticle: TextureRect = %HiglightReticle
@onready var interacting_reticle: TextureRect = %InteractingReticle



var current_object: Object
var last_potential_object: Object
var interaction_component: Node

func _ready () -> void:
	default_reticle.position.x = get_viewport().size.x / 2 - default_reticle.texture.get_size().x / 2
	default_reticle.position.y = get_viewport().size.y / 2 - default_reticle.texture.get_size().y / 2
	higlight_reticle.position.x = get_viewport().size.x / 2 - higlight_reticle.texture.get_size().x / 2
	higlight_reticle.position.y = get_viewport().size.y / 2 - higlight_reticle.texture.get_size().y / 2
	interacting_reticle.position.x = get_viewport().size.x / 2 - interacting_reticle.texture.get_size().x / 2
	interacting_reticle.position.y = get_viewport().size.y / 2 - interacting_reticle.texture.get_size().y / 2


func _process(delta: float) -> void:
	
	if interaction_component and interaction_component.is_interacting:
		default_reticle.visible = false
		higlight_reticle.visible = false
		interacting_reticle.visible = true
		
	
	#if on the previous frame, we were interacting with and object, lets keep interacting with it
	if current_object:
		if Input.is_action_just_pressed("secondary"):
			if interaction_component:
				interaction_component.auxInteract()
				current_object = null
				_unFocus() 
		elif Input.is_action_pressed("primary"):
			if interaction_component:
				interaction_component.interact()
		else:
			if interaction_component:
				interaction_component.postInteract()
				current_object = null 
				_unFocus()
	else: #we werent interacting with something, let see if we can
		var potential_object: Object = interaction_raycast.get_collider()
		
		if potential_object and potential_object is Node:
			interaction_component = potential_object.get_node_or_null("InteractionComponent")
			if interaction_component:
				if interaction_component.can_interact == false:
					return
					
				last_potential_object = current_object
				_focus()
				if Input.is_action_pressed("primary"):
					current_object = potential_object
					interaction_component.preInteract(hand)
					
					if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
						interaction_component.set_direction(current_object.to_local(interaction_raycast.get_collision_point()))
		else:
			_unFocus()

func isCameraLocked() -> bool:
	if interaction_component:
		if interaction_component.lock_camera and interaction_component.is_interacting:
			return true
	return false
	
func _focus() -> void:
	default_reticle.visible = false
	higlight_reticle.visible = true
	interacting_reticle.visible = false

func _unFocus() -> void:
	default_reticle.visible = true
	higlight_reticle.visible = false
	interacting_reticle.visible = false
	
