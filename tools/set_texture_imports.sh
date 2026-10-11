#!/usr/bin/env bash
# Switches every texture .import in a folder to 3D settings (VRAM compression + mipmaps); headless
# imports otherwise default to uncompressed, mipmap-less 2D settings. Files named *nor*/*normal*
# are flagged as normal maps. Re-run `godot --import` afterwards.
set -euo pipefail
for f in "$1"/*.import; do
	sed -i 's/^compress\/mode=0/compress\/mode=2/; s/^mipmaps\/generate=false/mipmaps\/generate=true/; s/^detect_3d\/compress_to=1/detect_3d\/compress_to=0/' "$f"
	case "$(basename "$f")" in *nor*|*normal*) sed -i 's/^compress\/normal_map=0/compress\/normal_map=1/' "$f";; esac
done
