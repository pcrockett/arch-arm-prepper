## Arch ARM Prepper

[This is the script](run.sh) I use to automate the [Arch ARM installation instructions for Raspberry Pi 4][arch-arm].
On top of those instructions, it also verifies the PGP signature for the OS image. Its only real dependency besides
standard CLI tools on Linux is [fzf][fzf].

Once `fzf` is installed,

1. Plug the microSD card that you're going to use into your computer
2. Run `sudo ./run.sh` and answer one or two questions

Wait until the script finishes, and your microSD card should be ready to pop into the Raspberry Pi.

[arch-arm]: https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
[fzf]: https://github.com/junegunn/fzf
