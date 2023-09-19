# MiSTer NFC Write

This program is not functional yet! I have written the skeleton for the program
an user interface because I reused code I have from another earler project.
You can see a gif of the UI of the program this program is based on [here](https://github.com/sigboe/pie-galaxy/)

This program is intended to browse games on your MiSTer device,
select a game, and write the path to an NFC tag
so you can boot the game using the [NFC script by Wizzo](https://github.com/wizzomafizzo/mrext/blob/main/docs/nfc.md)

The user interface is more or less finished, I do not have an NFC reader,
but Wizzo and Symm has implemented functions in the nfc tools to help out
this project. It is not far off before it is ready for testing.

## TODO

### The logic to write to an NFC tag

More or less finished. Currently working on more advanced features related to this
like being able to update the mappings database (needed to use amiibos, or reuse
tags for other functions, or testing commands, or some commands that only work
using this feature)

### The logic to read from an NFC tag

More or less finished.

### Browsing inside zip files

This is now more or less finished,
expect there to be some bugs, but currently it works.

### A commands pallate

I want the user to be able to browse from a list of commands to flash to the card
or write to the mappings database. Including just letting you use a keyboard to
type in the command manually. I havent started this yet, but such a feature should
be quite trivial. 

### More fluff

I might like to add a bit more flare, like filtering what folders and files you
see when you browse maybe more small things like this.
I'll also try to just add support for the cool new features Wizzo has added to
his project.

## Havent tested yet

if I can browse the menu with a gamepad on the MiSTer device. I managed to do that
for the program this UI is based on in RetroPie, so I don't see this as impossible.
