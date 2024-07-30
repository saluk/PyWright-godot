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
    "mac": "Godot.app/Contents/MacOS/Godot"
}

print(platform.platform())
HOST = "mac" if "mac" in platform.platform().lower() else ("linux" if "linux" in platform.platform().lower() else "unknown")
HOST="linux"
def download_godot():
    if not os.path.exists(binary_by_host[HOST]):
        url, filename = zips_by_host[HOST], zips_by_host[HOST].split("/")[-1]
        print(f"Downloading: {url} as {filename}")
        urlretrieve(url, filename)
        print(f"Unzip {filename}")
        subprocess.run(f"unzip {filename}", shell=True, executable='/bin/bash')


export_configs = {
    "Mac OSX": {"profile_name": "Mac OSX", "output": "export/godotwright.dmg"},
    "HTML5": {
        "profile_name": "HTML5", 
        "output": "export/web/godotwright.html", 
        "rmfolder": "export/web",
        "after": "web_build"
    },
    "Android": {
        "profile_name": "Android", 
        "output": "export/godotwright.apk",
        "after": "android_build"
    },
    "Windows Desktop": {
        "profile_name": "Windows Desktop",
        "output": "export/windows/godotwright.exe",
        "rmfolder": "export/windows",
        "after": 'lambda:upload_zips("win")'
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
def upload_zips(system="win"):
    filename = f"GodotWright_{system}_{current_version}.zip"
    subprocess.run([f"cd export/windows; zip ../{filename} *"], shell=True, executable="/bin/bash")
    subprocess.run(f"scp export/{filename} saluk@kamatera1.tinycrease.com:", shell=True, executable='/bin/bash')
    subprocess.run(
        f'ssh saluk@kamatera1.tinycrease.com "cd /opt/pywright/gdw;sudo cp ~/{filename} {filename};sudo chown www-data:www-data *"',
        shell=True, executable='/bin/bash')

def android_build():
    subprocess.run("adb install -r export/godotwright.apk", shell=True, executable='/bin/bash')

def do_export(profile=None):
    # Download godot binary (for github action)
    download_godot()

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
        if export.get("rmfolder", None):
            if os.path.exists(export["rmfolder"]):
                shutil.rmtree(export["rmfolder"])
            if not os.path.exists(export["rmfolder"]):
                os.mkdir(export["rmfolder"])
        
        subprocess.run([
            binary_by_host[HOST],
            "--no-window",
            "--export",
            export["profile_name"],
            export["output"]
        ])

        if export.get("after", None):
            eval(export["after"])()

    # Restore initial state
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
