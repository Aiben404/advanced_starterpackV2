Put your vehicle preview image in this folder.

Example:  web/img/vehicle.png

Then set it in config.lua under Config.Vehicle:
    image = 'img/vehicle.png'

Supported by the manifest: .png, .jpg, .jpeg, .webp
You can also use a full https URL instead of a local file, e.g.:
    image = 'https://i.imgur.com/xxxxxxx.png'

If the image is missing or fails to load, the UI automatically falls
back to the built-in stylised car silhouette.
