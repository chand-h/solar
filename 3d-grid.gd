extends Node3D

var points = PackedVector3Array()
var spacing = 1.0  # Distance between points
var grid_size = Vector3(16, 16, 16)

@export var gravitational_object_position = Vector3(0, 0, 0)
@export var gravitational_object_mass = 2000000.0
@export var gravitational_constant = 0.0001  # in m^3 kg^-1 s^-2

func create_point_mesh():
	
	var start_x = -grid_size.x / 2
	var end_x = grid_size.x / 2
	var start_y = -grid_size.y / 2
	var end_y = grid_size.y / 2
	var start_z = -grid_size.z / 2
	var end_z = grid_size.z / 2

	# Generate points centered around the Node3D
	for x in range(start_x, end_x + 1, spacing):
		for y in range(start_y, end_y + 1, spacing):
			for z in range(start_z, end_z + 1, spacing):
				points.push_back(Vector3(x, y, z))

	# Apply gravity-induced displacement
	for i in range(points.size()):
		var point = points[i]
		var displacement = calculate_gravitational_displacement(point)
		points[i] = point + displacement

	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = points

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	return mesh

func calculate_gravitational_displacement(point: Vector3) -> Vector3:
	var direction = gravitational_object_position - point
	var distance_squared = direction.length_squared()
	if distance_squared == 0:
		return Vector3.ZERO

	var force_magnitude = gravitational_constant * gravitational_object_mass / distance_squared
	var displacement = direction.normalized() * force_magnitude
	if displacement.length() > direction.length():
		return direction
	return displacement
	
func create_line_segments():
	var lines = []

	for x in range(-grid_size.x / 2, grid_size.x / 2, spacing):
		for y in range(-grid_size.y / 2, grid_size.y / 2, spacing):
			for z in range(-grid_size.z / 2, grid_size.z / 2, spacing):
				var current_point = Vector3(x, y, z)
				var displaced_point = current_point + calculate_gravitational_displacement(current_point)
				if x + spacing < grid_size.x / 2:
					var right_neighbor = Vector3(x + spacing, y, z)
					var displaced_right = right_neighbor + calculate_gravitational_displacement(right_neighbor)
					lines.append(displaced_point)
					lines.append(displaced_right)
				if z + spacing < grid_size.z / 2:
					var forward_neighbor = Vector3(x, y, z + spacing)
					var displaced_forward = forward_neighbor + calculate_gravitational_displacement(forward_neighbor)
					lines.append(displaced_point)
					lines.append(displaced_forward)
				if y + spacing < grid_size.y / 2:
					var up_neighbor = Vector3(x, y + spacing, z)
					var displaced_up = up_neighbor + calculate_gravitational_displacement(up_neighbor)
					lines.append(displaced_point)
					lines.append(displaced_up)
	return lines




func _ready():
	var mesh_instance = MeshInstance3D.new()
	var lines = create_line_segments()

	# Convert lines to PackedVector3Array
	var packed_lines = PackedVector3Array()
	packed_lines.resize(lines.size())
	for i in range(lines.size()):
		packed_lines[i] = lines[i]

	# Create an array for the lines
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = packed_lines

	# Create the mesh
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh_instance.mesh = mesh

	add_child(mesh_instance)

	var material = ShaderMaterial.new()
	material.shader = preload("res://grid.gdshader")

	# Set the color directly in the shader
	material.shader.set("color", Color(1, 1, 1, 1))

	mesh_instance.material_override = material

#func _ready():
	#var mesh_instance = MeshInstance3D.new()
	#mesh_instance.mesh = create_point_mesh()
#
	## Create and assign the shader material
	#var material = ShaderMaterial.new()
	#material.shader = preload("res://grid.gdshader")  # Make sure the shader file exists
	#mesh_instance.material_override = material
#
	#add_child(mesh_instance)
