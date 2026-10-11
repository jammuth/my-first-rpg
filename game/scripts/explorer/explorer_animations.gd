class_name ExplorerAnimations
extends RefCounted

## One shared AnimationLibrary built from the KayKit Rig_Medium packs. Their tracks address
## "Rig_Medium/Skeleton3D:<bone>", which every character option's scene also has.

const IDLE := "Idle_A"
const WALK := "Walking_A"
const RUN := "Running_A"
const INTERACT := "Interact"
const PICK_UP := "PickUp"
const LOOPING: Array[String] = [IDLE, WALK, RUN]
const PACKS: Array[String] = [
	"res://assets/characters/Rig_Medium_General.glb",
	"res://assets/characters/Rig_Medium_MovementBasic.glb",
]

static var _library: AnimationLibrary


static func library() -> AnimationLibrary:
	if _library != null:
		return _library
	_library = AnimationLibrary.new()
	for path in PACKS:
		var pack: Node = (load(path) as PackedScene).instantiate()
		var player := pack.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var source := player.get_animation_library("")
		for anim_name in source.get_animation_list():
			var anim: Animation = source.get_animation(anim_name).duplicate()
			if anim_name in LOOPING:
				anim.loop_mode = Animation.LOOP_LINEAR
			_library.add_animation(anim_name, anim)
		pack.free()
	return _library
