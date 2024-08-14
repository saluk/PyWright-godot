import sys
import os
import subprocess
import shutil
import platform
from urllib.request import urlretrieve

zips_by_host = {
    "linux": "https://github.com/godotengine/godot-builds/releases/download/3.5.3-stable/Godot_v3.5.3-stable_x11.64.zip",
    "mac": "https://github.com/godotengine/godot-builds/releases/download/3.5.3-stable/Godot_v3.5.3-stable_osx.universal.zip"
}
binary_by_host = {
    "linux": "./Godot_v3.5.3-stable_x11.64",
    "mac": "../Godot-3.53-Mac.app/Contents/MacOS/Godot",
    "win": "../Godot_v3.5.3-stable_win64.exe",
    "docker": "docker run local"
}
shell_by_host = {
    "linux": "/bin/bash",
    "mac": "/bin/bash",
    "docker": "/bin/bash",
    "win": "powershell"
}

print(platform.platform())
HOST = "mac" if "mac" in platform.platform().lower() else None
if not HOST:
    HOST = "linux" if "linux" in platform.platform().lower() else None
if not HOST:
    HOST = "win" if "windows" in platform.platform().lower() else None
if not HOST:
    crash

export_configs = {
    "Mac OSX": {
        "profile_name": "Mac OSX",
        "output": "export/macosx/godotwright.dmg",
        "folder": "export/macosx",
        "zip_tag": "mac"
    },
    "HTML5": {
        "profile_name": "HTML5", 
        "output": "export/web/godotwright.html", 
        "folder": "export/web",
        "after": "web_build"
    },
    "Android": {
        "profile_name": "Android", 
        "output": "export/android/godotwright.apk",
        "folder": "export/android",
        "after": "android_build",
        "zip_tag": "android"
    },
    "Windows Desktop": {
        "profile_name": "Windows Desktop",
        "output": "export/windows/godotwright.exe",
        "folder": "export/windows",
        "zip_tag": "win"
    }
}

def web_build():
    subprocess.run(["cd export/web; zip ../web.zip *"], shell=True, executable='/bin/bash')
    subprocess.run("scp export/web.zip saluk@kamatera1.tinycrease.com:", shell=True, executable='/bin/bash')
    subprocess.run(
        'ssh saluk@kamatera1.tinycrease.com "cd /opt/pywright/gdw;sudo unzip -u ~/web.zip;sudo chown www-data:www-data *"',
        shell=True, executable='/bin/bash')

current_version = "demo_3"

# only does windows
def upload_zips(export):
    filename = f"GodotWright_{export["zip_tag"]}_{current_version}.zip"
    subprocess.run([f"cd {export['folder']}; zip ../{filename} *"], shell=True, executable="/bin/bash")
    subprocess.run(f"scp export/{filename} saluk@kamatera1.tinycrease.com:", shell=True, executable='/bin/bash')
    subprocess.run(
        f'ssh saluk@kamatera1.tinycrease.com "cd /opt/pywright/gdw;sudo cp ~/{filename} {filename};sudo chown www-data:www-data *"',
        shell=True, executable='/bin/bash')

def android_build():
    subprocess.run("adb install -r export/godotwright.apk", shell=True, executable='/bin/bash')

def do_export(profile=None):
    # ensure required folders exist
    if not os.path.exists("export"):
        os.mkdir("export")

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

    configs = export_configs.values()
    if profile:
        configs = [export_configs[profile]]

    for export in configs:
        if export.get("folder", None):
            if os.path.exists(export["folder"]):
                shutil.rmtree(export["folder"])
            if not os.path.exists(export["folder"]):
                os.mkdir(export["folder"])
        
        print("running godot build...")
        subprocess.run([
            binary_by_host[HOST],
            "--no-window",
            "--headless",
            "--verbose",
            "--export",
            export["profile_name"],
            export["output"]]
        )

        if export.get("after", None):
            eval(export["after"])()

        if export.get("zip_tag", None):
            upload_zips(export)

    # Restore initial state
    if os.path.exists("games/"):
        with open("games/.gdignore", "w") as f:
            f.write("")
    shutil.move("project.godot.orig", "project.godot")

if __name__ == "__main__":
    profile = None
    if len(sys.argv) > 1:
        profile = sys.argv[1]
        do_export(profile)
    else:
        print("build.py [profile]")
        for profile in export_configs:
            print(repr(profile))
