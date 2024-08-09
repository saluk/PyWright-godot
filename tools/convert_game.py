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
    
def magick_identify(full_file):
    result = subprocess.run(["magick","identify","-format","%f %m %wx%h delay=%T\n",full_file], capture_output=True)
    output = str(result.stdout.strip()).replace(full_file,"").strip()
    output = [line.strip().split(" ") for line in output.split("\\n") if line.strip()]
    return output

def convert_gif(dirpath, filename, extension):
    full_file = f"{dirpath}/{filename}.{extension}"
    output = magick_identify(full_file)
    # If the image passed in is a true PNG or JPG file, leave as is
    if output[0][1] == "PNG":
        return
    # If the image passed in is a GIF:
    if output[0][1] == "GIF":
        # If the extension is not GIF, convert to its format
        if extension != "gif":
            print(f"!Invalid FIle {full_file}")
            subprocess.run(["magick", full_file, full_file])
            return
        #   If the extension is GIF: convert to PNG if neither a JPG or PNG file already exists
        if os.path.exists(f"{dirpath}/{filename}.png"):
            #   Otherwise, delete the file
            print(f"(I) deleting {full_file}")
            os.remove(full_file)
        else:
            if len(output) == 1:
                print(f"(I) convert gif {full_file}")
                subprocess.run(["magick", full_file, f"{dirpath}/{filename}.png"])
            else:
                print(f"!!! - convert full animation {full_file}")
                # TODO get correct frame delays
                frames = len(output)
                subprocess.run(['magick', full_file, "-layers", "coalesce", f"{dirpath}/__tmp__.gif"])
                subprocess.run(["montage", f"{dirpath}/__tmp__.gif", "-tile", "16x", "-geometry", "+0+0", "-alpha", "On", "-background", "rgba(0, 0, 0, 0)", "-quality", "100", f"{dirpath}/{filename}.png"])
                output2 = magick_identify(f"{dirpath}/{filename}.png")
                res1 = [int(p) for p in output[0][2].split("x")]
                res2 = [int(p) for p in output2[0][2].split("x")]
                framedelays = []
                for frame in output:
                    original_delay = int(frame[-1].replace("'","").split("=")[1])
                    framedelays.append((float(original_delay)/100.0)*60.0)
                txtfile = open(f"{dirpath}/{filename}.txt", "w")
                txtfile.write(f"horizontal {int(res2[0]/res1[0])}\nvertical {int(res2[1]/res1[1])}\nlength {frames}\nloops 1\n")
                for i, delay in enumerate(framedelays):
                    txtfile.write(f"framedelay {i} {delay}\n")
                txtfile.close()
                os.remove(f"{dirpath}/__tmp__.gif")

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
            if extension.lower() in ["png","jpeg","jpg","gif"]:
                convert_gif(dirpath, filename_only, extension)
            elif extension.lower() == "backup" and clean:
                clean_backup(dirpath, filename)
            elif extension.lower() == "import":
                remove_import(dirpath, filename)
            elif extension != extension.lower():
                fix_extension(dirpath, filename_only, extension)

if __name__ == "__main__":
    game_folder = sys.argv[1]
    start_conversion(game_folder)
