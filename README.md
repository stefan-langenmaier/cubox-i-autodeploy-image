# Autodeply image for the Cubox-i

These scripts are used to create a minimal image that can be flashed to a sd-card which can be used in turn to install a complete system remotely and unattended

## Usage

$ bash create-autodeploy-image.sh

$ dd if=output/autodeploy.img of=/dev/sdX

Afterwards the image can be mounted (ext2) and the autodeploy-source-url can be configured to reference a remote (http(s)) file that should executed to run the deployment

You can also place additional files in the config folder but the space is quite limited an should be reserved for sensitive information like keys and passwords.
