extends MeshInstance
class_name ClickMesh

var original_mesh
var click_uv = preload("res://System/Graphics/click_uv.shader")

var textures = []

func _init(original_mesh):
	self.original_mesh = original_mesh
	self.mesh = original_mesh.mesh.duplicate()
	self.scale = self.original_mesh.scale
	self.original_mesh.click_mesh = self
	#self.material_override = ShaderMaterial.new()
	#self.material_override.shader = click_uv
	._init()
func _process(dt):
	transform = original_mesh.transform

func make_click_mesh():
	for surf in range(mesh.get_surface_count()):
		var mat = mesh.surface_get_material(surf)
		var shader_mat
		if not mat is ShaderMaterial:
			mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
			if mat.albedo_texture and not mat.albedo_texture in textures:
				textures.append(mat.albedo_texture)
			shader_mat = ShaderMaterial.new()
			shader_mat.shader = click_uv
			shader_mat.set_shader_param("albedo_texture", mat.albedo_texture)
			shader_mat.set_shader_param("texture_width", mat.albedo_texture.get_width())
			shader_mat.set_shader_param("texture_height", mat.albedo_texture.get_height())
		else:
			shader_mat = mat
		for i in range(original_mesh.regions.size()):
			shader_mat.set_shader_param("region"+str(i+1), original_mesh.regions[i])
		shader_mat.set_shader_param("region_max", original_mesh.regions.size())
		mesh.surface_set_material(surf, shader_mat)

func get_clicked_region(red_value):
	for i in range(original_mesh.region_colors.size()):
		if abs(original_mesh.region_colors[i]-red_value) < 0.02:
			return original_mesh.region_labels[i]
	return null
