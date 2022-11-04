extends Reference

# Makes all objects, should be an instance variable on a script and
# objects are made in reference to that script

# Object types:

# Basic: has a single sprite (bg, fg, ev, etc
# PWChar: has multiple sprites that it switches between depending on animation state
# Button: Clickable ui that has two sprites, one for not clicked and one for clicked

# Interfaces: collect multiple buttons


# General factory steps:
#   - load assets needed, maybe store references to each asset in a dictionary
#   	templates can control how different asset types are loaded
#       asset paths are searched according to the script that's creating the object
#   - create base game object and instantiate it in the scene
#   - assign specific properties according to object type
#   - assign standard properties
#   - return object


# TODO - replace Commands.create_object, and some of the initialization in the
#   specialized interface classes.
#   Once we are searching for assets in a standard place we can cache assets better
#   Organize classes to support simplicity and reuse
