import sys
import os
import subprocess
import shutil

def convert_wave(dirpath, filename, extension):
    print(f"convert '{dirpath}' '{filename}' '{extension}'")
    print(os.path.exists(f'{dirpath}/{filename}.{extension}'))
    subprocess.run([
        f'ffmpeg','-i',
        f'{dirpath}/{filename}.{extension}',
        f'{dirpath}/{filename}.ogg'
    ])
    shutil.move(
        f'{dirpath}/{filename}.{extension}',
        f'{dirpath}/{filename}.{extension}.BACKUP')

def clean_backup(directory, filename):
    os.remove(f"{directory}/{filename}")

def remove_import(directory, filename):
    os.remove(f"{directory}/{filename}")

def fix_extension(dirpath, filename, extension):
    print(f"to lowercase: {filename}.{extension}")
    shutil.move(
        f'{dirpath}/{filename}.{extension}',
        f'{dirpath}/{filename}.{extension.lower()}'
    )

def get_extension(filename):
    if "." in filename:
        return filename.rsplit(".", 1)
    return filename, ""

def start_conversion(game_folder, clean=True):
    for dirpath, dirnames, filenames in os.walk(game_folder):
        for filename in filenames:
            filename_only, extension = get_extension(filename)
            if extension.lower() == "wav":
                convert_wave(dirpath, filename_only, extension)
            elif extension.lower() == "backup" and clean:
                clean_backup(dirpath, filename)
            elif extension.lower() == "import":
                remove_import(dirpath, filename)
            elif extension != extension.lower():
                fix_extension(dirpath, filename_only, extension)

if __name__ == "__main__":
    game_folder = sys.argv[1]
    start_conversion(game_folder)