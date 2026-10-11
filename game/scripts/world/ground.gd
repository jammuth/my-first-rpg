extends MeshInstance3D

## One large plane that follows the target instead of per-chunk ground meshes: a single draw call,
## and the shader samples world space so the pattern doesn't slide.

@export var target_path: NodePath
@export var snap := 32.0

var _target: Node3D


func _ready() -> void:
	_target = get_node(target_path)
	var biome := BiomeMap.biome_at_cell(GameState.world_seed, Vector2i.ZERO)
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter("color_a", biome.ground_color_a)
	mat.set_shader_parameter("color_b", biome.ground_color_b)


func _process(_delta: float) -> void:
	var p := _target.global_position
	global_position = Vector3(snappedf(p.x, snap), 0.0, snappedf(p.z, snap))
