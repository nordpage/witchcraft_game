extends MultiMeshInstance3D

@export var terrain: Node3D  # Ссылка на HTerrain
@export var bush_mesh: Mesh  # `.tres` файл куста
@export var bush_count: int = 200  # Количество кустов

func _ready():
	regenerate_multimesh()

func regenerate_multimesh():
	if not bush_mesh:
		print("Ошибка: Меш куста не задан!")
		return

	var multimesh = MultiMesh.new()
	multimesh.mesh = bush_mesh
	multimesh.instance_count = bush_count
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	self.multimesh = multimesh

	for i in range(bush_count):
		var x = randf_range(-100, 100)
		var z = randf_range(-100, 100)

		# ✅ Используем get_normal_and_height() вместо get_height_at()
		var height_data = terrain.get_normal_and_height(Vector3(x, 0, z))
		var y = height_data.y  # Высота поверхности в точке

		var transform = Transform3D()
		transform.origin = Vector3(x, y, z)
		transform.basis = Basis().rotated(Vector3.UP, randf_range(0, TAU))
		multimesh.set_instance_transform(i, transform)

	print("Кусты успешно сгенерированы на HTerrain")
