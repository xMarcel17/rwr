extends XROrigin3D

@export var move_speed: float = 2.5
@export var deadzone: float = 0.15
@export var snap_turn_angle: float = 45.0

@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var left_ctrl: XRController3D = $LeftController
@onready var right_ctrl: XRController3D = $RightController

# Referencje do teleportu
@onready var teleport_ray: RayCast3D = $RightController/TeleportRay
@onready var teleport_marker: MeshInstance3D = $RightController/TeleportMarker

var snap_turned: bool = false

func _physics_process(delta: float) -> void:
	# --- RUCH PŁYNNY ---
	var dir := Vector3.ZERO
	var fwd := -xr_camera.global_transform.basis.z
	var right := xr_camera.global_transform.basis.x
	fwd.y = 0.0
	fwd = fwd.normalized()
	right.y = 0.0
	right = right.normalized()

	var left_input: Vector2 = left_ctrl.get_vector2("thumbstick")
	if left_input.length() > deadzone:
		dir += fwd * (-left_input.y) + right * (left_input.x)
	if dir.length() > 0.0:
		global_translate(dir.normalized() * move_speed * delta)

	# --- OBRÓT SKOKOWY ---
	var right_input: Vector2 = right_ctrl.get_vector2("thumbstick")
	if abs(right_input.x) > 0.5:
		if not snap_turned:
			rotate_y(deg_to_rad(snap_turn_angle * -sign(right_input.x)))
			snap_turned = true
	else:
		snap_turned = false

	# --- TELEPORTACJA ---
	# Celowanie: Wyświetlamy marker tam, gdzie trafia promień
	if teleport_ray.is_colliding():
		teleport_marker.visible = true
		teleport_marker.global_position = teleport_ray.get_collision_point()
	else:
		teleport_marker.visible = false

# Obsługa przycisku teleportu (Select na prawym kontrolerze)
func _ready() -> void:
	# Łączymy sygnał przycisku z funkcją teleportacji
	right_ctrl.button_pressed.connect(_on_right_controller_button_pressed)

func _on_right_controller_button_pressed(button_name: String) -> void:
	if button_name == "trigger" or button_name == "ax_button":
		if teleport_ray.is_colliding():
			perform_teleport()

func perform_teleport() -> void:
	var target_pos = teleport_ray.get_collision_point()
	
	# Obsługa offsetu głowy
	# Obliczamy różnicę między środkiem XROrigin a kamerą w poziomie (XZ)
	var camera_offset = xr_camera.global_position - global_position
	camera_offset.y = 0 # Ignorujemy wysokość
	
	# Przesuwamy Origin tak, aby kamera wylądowała dokładnie na celu
	global_position = target_pos - camera_offset
