import sys
import os
import subprocess
import shutil

# Some files are not importing correctly so we ignore them. But we can't ignore
# them while exporting or it skips the folders entirely. Add back at the end
if os.path.exists("games/.gdignore"):
    os.remove("games/.gdignore")

# Because we changed the .gdignore, when godot loads to export, it
# changes the project.godot file. We don't want to mess with that,
# so let's save it (preserving modification time)
shutil.move("project.godot", "project.godot.orig")
shutil.copy("project.godot.orig", "project.godot")

#Godot-3.53-Mac.app/Contents/MacOS/Godot --export "Mac OSX" export/godotwright.dmg

godot_binary = "/Users/patrickm/Projects/Godot/Godot-3.53-Mac.app/Contents/MacOS/Godot"

export_configs = {
    "Mac OSX": {"profile_name": "Mac OSX", "output": "export/godotwright.dmg"}
}

for export in export_configs.values():
    subprocess.run([
        godot_binary,
        "--no-window",
        "--export",
        export["profile_name"],
        export["output"]
    ])

# Restore initial state
with open("games/.gdignore", "w") as f:
    f.write("")
shutil.move("project.godot.orig", "project.godot")