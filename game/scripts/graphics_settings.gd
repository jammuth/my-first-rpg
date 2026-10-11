extends Node

## Graphics presets (autoload "GraphicsSettings"). "deck" is picked automatically on a Steam Deck;
## --graphics=<name> overrides it, and the cycle_graphics action switches at runtime.

signal changed

const PRESETS := {
	"high": {
		"render_scale": 1.0,
		"shadow_distance": 140.0,
		"shadow_atlas": 4096,
		"terrain_radius": 4,
		"view_distance": 500.0,
		"prop_density": 1.0,
		"prop_view_scale": 1.0,
		"particles": 1.0,
		"small_prop_shadows": true,
	},
	"deck": {
		# FSR 1 upscaling from 85% of the Deck's 1280x800 keeps edges sharp while saving fill rate.
		"render_scale": 0.85,
		"shadow_distance": 90.0,
		"shadow_atlas": 2048,
		"terrain_radius": 3,
		"view_distance": 380.0,
		"prop_density": 0.65,
		"prop_view_scale": 0.75,
		"particles": 0.6,
		"small_prop_shadows": false,
	},
}
const ORDER := ["high", "deck"]

var preset_name := "high"


func _ready() -> void:
	var chosen := detect_preset(OS.get_environment("SteamDeck"), RenderingServer.get_video_adapter_name(),
		OS.get_processor_name())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--graphics=") and PRESETS.has(arg.trim_prefix("--graphics=")):
			chosen = arg.trim_prefix("--graphics=")
	preset_name = chosen


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_graphics"):
		set_preset(ORDER[(ORDER.find(preset_name) + 1) % ORDER.size()])


func get_value(key: String) -> Variant:
	return PRESETS[preset_name][key]


func set_preset(preset: String) -> void:
	if PRESETS.has(preset) and preset != preset_name:
		preset_name = preset
		changed.emit()


## Steam sets SteamDeck=1 on the Deck; the APU/GPU names cover running outside Steam.
static func detect_preset(steam_deck_env: String, gpu_name: String, cpu_name: String) -> String:
	if steam_deck_env == "1":
		return "deck"
	var names := (gpu_name + " " + cpu_name).to_lower()
	for marker in ["van gogh", "sephiroth", "custom gpu 0405", "custom gpu 0932", "custom apu 0405", "custom apu 0932"]:
		if names.contains(marker):
			return "deck"
	return "high"


## Deterministic thinning of decorative props: the same instances survive every time for a given
## density, so thinning never makes props pop in and out.
static func keep_prop(position: Vector3, density: float) -> bool:
	if density >= 1.0:
		return true
	var h := WorldHash.hash3(0x51ED, int(floor(position.x * 4.0)), int(floor(position.z * 4.0)))
	return float(h % 10000) / 10000.0 < density
