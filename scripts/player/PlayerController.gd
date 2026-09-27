extends CharacterBody3D
class_name PlayerController
@export var walk_speed:=3.5
@export var sprint_speed:=6.0
@export var crouch_speed:=1.5
@export var acceleration:=10.0
@export var deceleration:=12.0
@export var air_control:=0.3
@export var jump_velocity:=4.5
@export var gravity:=9.8
@export var standing_height:=1.6
@export var crouch_height:=1.0
@export var mouse_sensitivity:=0.0025
var yaw:=0.0
var pitch:=0.0
var crouching:=false
var sprinting:=false
var stamina_regen_delay:=0.0
var head:Node3D
var camera:Camera3D
var collision_shape:CollisionShape3D
var bob_time:=0.0
func _ready()->void:
    add_to_group("player")
    head=$Head; camera=$Head/Camera3D; collision_shape=$CollisionShape3D
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _unhandled_input(event:InputEvent)->void:
    if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x*mouse_sensitivity*InputManager.mouse_sensitivity
        var inv:=-1.0 if InputManager.invert_y else 1.0
        pitch -= event.relative.y*mouse_sensitivity*InputManager.mouse_sensitivity*inv
        pitch=clampf(pitch,deg_to_rad(-90),deg_to_rad(90))
        rotation.y=yaw; head.rotation.x=pitch
    if event.is_action_pressed("pause"): UIManager.toggle_pause_menu()
    if event.is_action_pressed("inventory"): UIManager.open_scene("res://scenes/ui/InventoryUI.tscn",true)
    if event.is_action_pressed("toggle_hud"): UIManager.toggle_hud()
    if event.is_action_pressed("quick_save"): SaveManager.save_game(1)
    if event.is_action_pressed("quick_load"): SaveManager.load_game(1)
func _physics_process(delta:float)->void:
    var input_vec:=Input.get_vector("move_left","move_right","move_forward","move_backward")
    var forward:=-global_transform.basis.z
    var right:=global_transform.basis.x
    var wish:=(right*input_vec.x + forward*(-input_vec.y))
    if wish.length()>0.001: wish=wish.normalized()
    crouching=Input.is_action_pressed("crouch")
    sprinting=Input.is_action_pressed("sprint") and not crouching and input_vec.length()>0.1 and GameStateManager.can_sprint()
    var speed:=walk_speed*(1.0+GameStateManager.get_upgrade_level("movement_speed")*0.02)
    if sprinting: speed=sprint_speed*(1.0+GameStateManager.get_upgrade_level("movement_speed")*0.02)
    if crouching: speed=crouch_speed
    var horizontal:=Vector3(velocity.x,0,velocity.z)
    var target:=wish*speed
    var accel:=acceleration if wish.length()>0.0 else deceleration
    if not is_on_floor(): accel*=air_control
    horizontal=horizontal.move_toward(target,accel*delta)
    velocity.x=horizontal.x; velocity.z=horizontal.z
    if is_on_floor():
        if Input.is_action_just_pressed("jump") and float(GameStateManager.needs.stamina)>=10.0:
            velocity.y=jump_velocity; GameStateManager.add_stamina(-10.0); stamina_regen_delay=1.5
    else:
        velocity.y -= gravity*delta
    if sprinting:
        GameStateManager.add_stamina(-15.0*delta); stamina_regen_delay=1.5
    else:
        stamina_regen_delay=maxf(0.0,stamina_regen_delay-delta)
        if stamina_regen_delay<=0.0: GameStateManager.add_stamina(8.0*delta)
    _update_crouch(delta); _update_camera(delta,input_vec.length())
    move_and_slide()
func _update_crouch(delta:float)->void:
    var target_h:=crouch_height if crouching else standing_height
    head.position.y=lerpf(head.position.y,target_h,delta/0.3)
    if collision_shape and collision_shape.shape is CapsuleShape3D:
        var c:=collision_shape.shape as CapsuleShape3D
        c.height=lerpf(c.height,1.0 if crouching else 1.8,delta/0.3)
func _update_camera(delta:float,move_amount:float)->void:
    var target_fov:=82.0 if sprinting else (70.0 if crouching else 75.0)
    camera.fov=lerpf(camera.fov,target_fov,delta*5.0)
    if is_on_floor() and move_amount>0.05:
        bob_time+=delta*(14.0 if sprinting else 10.0)
        camera.position.y=sin(bob_time)*0.05*(0.4 if crouching else 1.0)
    else:
        camera.position.y=lerpf(camera.position.y,0.0,delta*8.0)
