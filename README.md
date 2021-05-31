# Pinecil Firmware Updater
Application for updating Pine64's Pinecil soldering iron.

## Supported platforms

- [X] Windows 7 - 10 (64-bit)
- [X] MacOS
- [X] Linux

## How to compile (and run)

### Windows, MAC

Download the binaries from the [releases page](https://github.com/pine64/pinecil-firmware-updater/releases)

### Linux

The following steps assume you have the Qt, dfu-util and libusb dependencies
already installed. Depending on your actual Linux distribution these dependencies
might have slightly different names, and can be installed through your favourite
package manager.


```
# Create make file using Qt
qmake
# Build
make
# Link dfu-util symbolically to this folder
ln -s /usr/bin/dfu-util .
# Run the tool
sudo ./pinecil_firmware_updater
```

## Screenshots

![Screenshot 1 - Windows](https://i.imgur.com/WYzyAUE.png)
![Screenshot 2 - Mac](https://i.imgur.com/BmVQINS.png)
![Screenshot 3 - Linux](https://i.imgur.com/FOVMO4P.png)
