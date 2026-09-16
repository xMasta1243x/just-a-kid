extends CharacterBody3D

#Vars Nodes
@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera_3d: Camera3D = $Head/Eyes/Camera3D
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape
@onready var standing_check: RayCast3D = $StandingCheck
@onready var interaction_controller: Node = %InteractionController

#Movement Variables

const walk_speed: float = 3.0;
const sprint_speed: float = 5.0;
const crouch_speed: float = 1.8;
var current_speed: float = 0.0;
var moving: bool = false;
var input_dir: Vector2 = Vector2.ZERO;
var direction: Vector3 = Vector3.ZERO;
const crouch_depth: float = -0.9;
const jump_velocity: float = 4.0;

var lerp_speed: float = 10.0

#Player Settings
var base_fov: float = 90.0
var mouse_sensitivity: float = 0.2;

#State Machine
enum PlayerState{
	IDLE_STAND,
	IDLE_CROUCH,
	CROUCHING,
	WALKING,
	SPRINTING,
	AIR
}

var player_State: PlayerState = PlayerState.IDLE_STAND

#Headbobbing Vars

const hb_sprint_speed: float = 22.0
const hb_walk_speed: float = 14.0
const hb_crouch_speed: float = 10.0
const hb_sprint_intensity: float = 0.2
const hb_walk_intensity: float = 0.1
const hb_crouch_intensity: float = 0.05
var hb_current_intensity: float = 0.0
var hb_vector: Vector2 = Vector2.ZERO
var hb_index: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	return
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if event is InputEventMouseMotion:
		if not interaction_controller.isCameraLocked():
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
			head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))	 
		

#Movement and Jump
func _physics_process(delta: float) -> void:
	
	updatePlayerState()
	updateCamera(delta)
	
	#Falling
	if not is_on_floor():
		if velocity.y >= 0:
			velocity += get_gravity() * delta
		else:
			velocity += get_gravity() * delta * 2.0	
	else: #Jumping
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	
	#Movement
	
	input_dir = Input.get_vector("left","right","forward","backward")
	print(current_speed)
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
	if direction: 
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	
			
	move_and_slide()	
	
#Updating Player State
func updatePlayerState() -> void:
	moving = (input_dir != Vector2.ZERO)
	if not is_on_floor():
		player_State = PlayerState.AIR
	else:
		if Input.is_action_pressed("crouch"):
			if not moving:
				player_State = PlayerState.IDLE_CROUCH
			else:
				player_State = PlayerState.CROUCHING
		elif !standing_check.is_colliding():
			if not moving:
				player_State = PlayerState.IDLE_STAND
			elif Input.is_action_pressed("sprint"):
				player_State = PlayerState.SPRINTING
			else:
				player_State = PlayerState.WALKING
				
	updatePlayerColShape(player_State)
	updatePlayerSpeed(player_State)
	print(player_State)

#Collision Raycast3D Crouch
func updatePlayerColShape(_player_State: PlayerState) -> void:
	if _player_State == PlayerState.CROUCHING or _player_State == PlayerState.IDLE_CROUCH:
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
	else:
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
	
#Update Player Speed
func updatePlayerSpeed(_player_State: PlayerState) -> void:
	if _player_State == PlayerState.CROUCHING or _player_State == PlayerState.IDLE_CROUCH:
		current_speed = crouch_speed
	elif _player_State == PlayerState.WALKING:
		current_speed = walk_speed
	elif _player_State == PlayerState.SPRINTING:
		current_speed = sprint_speed

#Camera Head Bobbing and Fov		
func updateCamera(delta: float) -> void:
	if player_State == PlayerState.AIR:
		pass
		
	if player_State == PlayerState.CROUCHING or player_State == PlayerState.IDLE_CROUCH:
		head.position.y = lerp(head.position.y, 1.8 + crouch_depth, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*0.95, delta * lerp_speed)
		hb_current_intensity = hb_crouch_intensity
		hb_index += hb_crouch_speed * delta
	elif player_State == PlayerState.IDLE_STAND:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta * lerp_speed)
		hb_current_intensity = hb_walk_intensity
		hb_index += hb_walk_speed * delta
	elif player_State == PlayerState.WALKING:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov, delta * lerp_speed)
		hb_current_intensity = hb_walk_intensity
		hb_index += hb_walk_speed * delta
	elif player_State == PlayerState.SPRINTING:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		camera_3d.fov = lerp(camera_3d.fov, base_fov*1.05, delta * lerp_speed)
		hb_current_intensity = hb_sprint_intensity
		hb_index += hb_sprint_speed * delta
	
	hb_vector.y = sin(hb_index)
	hb_vector.x = (sin(hb_index/2.0)+0.5)
	if moving:
		eyes.position.y = lerp(eyes.position.y, hb_vector.y*(hb_current_intensity/2.0),delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, hb_vector.x*(hb_current_intensity),delta * lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0 ,delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0 ,delta * lerp_speed)
		

   		
	
