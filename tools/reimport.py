import os,shutil
folders = ["."]
while folders:
    folder = folders.pop(0)
    print(f"Scanning: {folder}")
    for filename in os.listdir(folder):
        full_filename = folder + "/" + filename
        if filename == ".import" or filename.endswith(".import"):
            print(f"remove {full_filename}")
            if os.path.isdir(full_filename):
                shutil.rmtree(full_filename)
            else:
                os.remove(full_filename)
            continue
        if filename not in [".."] and not (filename.startswith(".") and not filename == "."):
            if os.path.isdir(full_filename):
                folders.append(full_filename)
