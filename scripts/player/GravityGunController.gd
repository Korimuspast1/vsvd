extends RayCast3D
class_name GravityGunController

@export var hold_distance := 3.0
@export var max_mass := 100.0
@export var throw_impulse := 26.0
@export var pull_strength := 18.0

var held_body: RigidBody3D

func _ready() -> void:
    enabled = true
    target_position = Vector3(0, 0, -10)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("gravity_use"):
        if held_body:
            _throw()
        else:
            _try_pickup()
    if event.is_action_pressed("drop_item") and held_body:
        _drop()

func _physics_process(delta: float) -> void:
    if held_body:
        var target := global_transform.origin + -global_transform.basis.z * hold_distance
        var delta_vec := target - held_body.global_position
        held_body.linear_velocity = held_body.linear_velocity.lerp(delta_vec * pull_strength, delta * 8.0)

func _can_use() -> bool:
    return GameStateManager.has_item("gravity_tool") or bool(GameStateManager.get_flag("gravity_tool_available", false))

func _try_pickup() -> void:
    if not _can_use():
        return
    force_raycast_update()
    if not is_colliding():
        return
    var body := get_collider() as RigidBody3D
    if body == null:
        return
    if body.mass > max_mass:
        UIManager.show_notification("Object too heavy", "warning")
        return
    held_body = body
    held_body.gravity_scale = 0.0
    UIManager.show_notification("Object grabbed", "info")

func _throw() -> void:
    if held_body == null:
        return
    var forward := -global_transform.basis.z
    held_body.gravity_scale = 1.0
    held_body.apply_central_impulse(forward * throw_impulse * held_body.mass)
    held_body = null

func _drop() -> void:
    if held_body:
        held_body.gravity_scale = 1.0
        held_body = null
