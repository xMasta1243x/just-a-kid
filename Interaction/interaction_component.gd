extends Node

#This is define for individual objects in the game

enum InteractionType {
	DEFAULT,
	DOOR,
	SWITCH,
	WHEEL,
	ITEM
}

@export var object_ref: Node3D
@export var interaction_type: InteractionType = InteractionType.DEFAULT
@export var maximum_rotation: float = 90
@export var pivot_point: Node3D
@export var nodes_to_affect: Array[Node] 


var can_interact: bool = true
var is_interacting: bool = false
var lock_camera: bool = false
var starting_rotation: float 
var is_front: bool
var camera: Camera3D
var previous_mouse_position: Vector2
var wheel_rotation: float = 0.0 

var player_hand: Marker3D

#Signals

signal item_collected(item: Node)


func _ready() -> void:
	match interaction_type:
		InteractionType.DOOR:
			starting_rotation = pivot_point.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
		InteractionType.SWITCH:
			starting_rotation = object_ref.rotation.z
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
		InteractionType.WHEEL:
			starting_rotation = object_ref.rotation.z
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
			camera = get_tree().get_current_scene().find_child("Camera3D", true, false)
		
			
	
	
#Run once, when the player first click a object to interact with	
func preInteract(hand: Marker3D) -> void: 
	is_interacting = true
	match interaction_type:
		InteractionType.DEFAULT:
			player_hand = hand
		InteractionType.DOOR:
			lock_camera = true
		InteractionType.SWITCH:
			lock_camera = true
		InteractionType.WHEEL:
			lock_camera = true
			previous_mouse_position = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			wheel_rotation = object_ref.rotation.z 

#Run every frame, perform some logic on this object	
func interact() -> void:
	if not can_interact:
		return
		
	match interaction_type:
		InteractionType.DEFAULT:
			_default_interact()
		InteractionType.ITEM:
			_collect_item()
	

func auxInteract() -> void:
	if not can_interact:
		return
		
	match interaction_type:
		InteractionType.DEFAULT:
			_default_throw()			
	
#Runs once, when the player last interacts with an object	
func postInteract() -> void:
	is_interacting = false
	lock_camera = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	
func _input(event: InputEvent) -> void:
	if is_interacting:
		match interaction_type:
			InteractionType.DOOR:
				if event is InputEventMouseMotion:
					if is_front:
						pivot_point.rotate_y(-event.relative.y * .001)
					else:
						pivot_point.rotate_y(event.relative.y * .001)
						
						
					pivot_point.rotation.y = clamp(pivot_point.rotation.y, starting_rotation, maximum_rotation)
			InteractionType.SWITCH:
				if event is InputEventMouseMotion:
					var percentage: float 
					
					object_ref.rotate_x(event.relative.y * .001)
					object_ref.rotation.x = clamp(object_ref.rotation.x, starting_rotation, maximum_rotation)
					percentage = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
					
					notify_nodes(percentage)
			InteractionType.WHEEL:
				if event is InputEventMouseMotion:
					var center_position = camera.unproject_position(object_ref.global_transform.origin)
					var vector_to_previous = previous_mouse_position - center_position
					var vector_to_current = event.position - center_position
					
					var prev_angle = atan2(vector_to_previous.y, vector_to_previous.x)
					var curr_angle = atan2(vector_to_current.y, vector_to_current.x)
					var angle_delta = curr_angle - prev_angle
					
					if angle_delta > PI:
						angle_delta -= TAU
					elif angle_delta < -PI:
						angle_delta += TAU
					
					wheel_rotation += angle_delta
					wheel_rotation = clamp(wheel_rotation, starting_rotation, maximum_rotation)
					
					object_ref.rotation.z = wheel_rotation
					
					var percentage = (object_ref.rotation.z - starting_rotation) / (maximum_rotation - starting_rotation)
					
					previous_mouse_position = event.position
					notify_nodes(percentage)
					
func _default_interact() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position-object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		rigid_body_3d.set_linear_velocity((object_distance)*(5/rigid_body_3d.mass))
		
func _default_throw() -> void:
	
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position-object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		var throw_direction: Vector3 = -player_hand.global_transform.basis.z.normalized()
		var throw_strength: float = (20.0/rigid_body_3d.mass)
		rigid_body_3d.set_linear_velocity(throw_direction*throw_strength)
		
		can_interact = false
		await get_tree().create_timer(2.0).timeout
		can_interact = true
	
func set_direction(_normal: Vector3) -> void:
	if _normal.z > 0:
		is_front = true
	else:
		is_front = false	
		
func notify_nodes(percentage: float ) -> void:
	for node in nodes_to_affect:
		if node.has_method("execute"):
			node.call("execute", percentage)
			
func calculate_cross_product(_mouse_position: Vector2) -> float:
	var center_position = camera.unproject_position(object_ref.global_transform.origin)
	var vector_to_previous = previous_mouse_position - center_position
	var vector_to_current = _mouse_position - center_position
	var cross_product = vector_to_current.x * vector_to_previous.y - vector_to_previous.y * vector_to_previous.x
	return cross_product
	
func _collect_item() -> void:
	emit_signal("item_collected", )
	
	
	
	
	
	
	
	
	
	
	
	
