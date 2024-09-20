import os
import sys
import shutil

intro = """
"""

items = []
pages = []
for f in os.listdir("tests"):
    if f.endswith(".txt"):
        items.append(f.replace(".txt", ""))
page = []
for item in items:
    page.append(item)
    if len(page) == 3:
        pages.append(page)
        page = []
if page:
    pages.append(page)

pagetexts = []
for i, page in enumerate(pages):
    pagetext = f"label pagelabel{i+1}\n"
    pagetext += f"list page{i+1}\n"
    for item in page:
        pagetext += f"li {item}\n"
    if i>0:
        pagetext += f"li pagelabel{i}\n"
    if i<len(pages)-1:
        pagetext += f"li pagelabel{i+2}\n"
    pagetext += "showlist\n"
    pagetexts.append(pagetext)

intro += "\n".join(pagetexts)
for item in items:
    intro += f"label {item}\n"
    intro += f"script {item}\n"

with open("tests/intro.txt", "w") as f:
    f.write(intro)

shutil.copytree("tests", sys.argv[1], dirs_exist_ok=True)