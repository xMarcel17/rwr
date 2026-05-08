extends XROrigin3D

@export var move_speed: float = 2.5
@export var deadzone: float = 0.15
@export var snap_turn_angle: float = 45.0  # Kąt obrotu

@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var left_ctrl: XRController3D = $LeftController
@onready var right_ctrl: XRController3D = $RightController

# Zmienna do blokady ciągłego obrotu (wymóg na 4.5)
var snap_turned: bool = false

func _physics_process(delta: float) -> void:
	# --- RUCH PŁYNNY (Lewy Joystick - 4.0) ---
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

	# --- OBRÓT SKOKOWY (Prawy Joystick - 4.5) ---
	var right_input: Vector2 = right_ctrl.get_vector2("thumbstick")

	# Sprawdzamy wychylenie poziome prawego joysticka
	if abs(right_input.x) > 0.5:
		if not snap_turned:
			# Obliczamy kierunek obrotu (lewo/prawo)
			var turn_sign = -sign(right_input.x)
			# Wykonujemy natychmiastowy obrót o 45 stopni
			rotate_y(deg_to_rad(snap_turn_angle * turn_sign))
			# Blokujemy możliwość dalszego obrotu do czasu puszczenia gałki
			snap_turned = true
	else:
		# Gracz puścił gałkę (wróciła do środka) - zdejmujemy blokadę
		snap_turned = false
