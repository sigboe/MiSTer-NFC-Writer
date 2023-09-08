# MiSTer NFC Write

This program is not functional yet! I have written the skeleton for the program
an user interface because I reused code I have from another earler project.
You can see a gif of the UI of the program this program is based on [here](https://github.com/sigboe/pie-galaxy/)

This program is intended to browse games on your MiSTer device,
select a game, and write the path to an NFC tag
so you can boot the game using the [NFC script by Wizzo](https://github.com/wizzomafizzo/mrext/blob/main/docs/nfc.md)

The user interface is more or less finished, I do not have an NFC reader
so I am posting the unfinished script online in case someone wants to
either make Pull Requests to implement the logic to do that, or help me out by
telling me how to write to the tags via the linux command line. Or if
figure it out by reading online / guesswork , or I buy an NFC reader.

If you want to help but dont have programming knowledge, but have an NFC reader/writer
and a linux machine, we can figure it out together.
Or if someone can lend me an NFC reader/writer, I should be able to figure it out.

## TODO

### The logic to write to an NFC tag

I won't say it is as simple as copy pasting in a Linux command to write text to
an NFC tag. But it is more or less the last thing needed to do that.

Probably not but I might need to add some UI stuff to pick types of NFC tags,
I imagine this can be handled automatically.

### The logic to read from an NFC tag

I won't say it is as simple as copy pasting in a Linux command to read text from
an NFC tag. But it is more or less the last thing needed to do that.
This is just if you want to see the path to the game of a tag thats already written.

### Browsing inside zip files

This is just a bit tedious labor, I might not do it before reading and writing
to tags is implemented. This is not a hard step, its just a bit tedious and
requires a bit of work. I have the basic idea of how I will acomplish it in my mind.

### More fluff

I might like to add a bit more flare, like filtering what folders and files you
see when you browse maybe more small things like this.

## Havent tested yet

if I can browse the menu with a gamepad on the MiSTer device. I managed to do that
for the program this UI is based on in RetroPie, so I don't see this as impossible.
