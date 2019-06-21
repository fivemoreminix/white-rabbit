The White Rabbit Operating System
=================================
One idea lead to "hey, let's really make this a thing," so we are now neck-deep in making a minimal (and incomplete) operating system in x86 assembly for a game. Information about the game can be found in the section [*The Game*](https://github.com/asmoaesl/white-rabbit#the-game).

## Building
```
make
```
### Dependencies
 - GNU Make
 - NASM assembler

### To Generate an ISO Image:
Make a new directory called `cdiso` and move the `white-rabbit.flp` file into it. Then:
```bash
mkisofs -o white-rabbit.iso -b white-rabbit.flp cdiso/
```

## The Game
Imagine if all you had access to were a very limiting operating system and just the tools that you found on it. What would you do with it? For most, not much. But some could say they aren't satisfied with the mono colors in their text editor, or the efficiency of the file system, and change it.

The operating system you have access to is only a game to begin with, but what you build along the way is real.

When starting, you have the essentials:
 - A command-line interface, with X commands: TK, TK, TK, and TK.
 - A text editor that can read and write files.
 - An included assembler, with a pocket manual.
 - The source code of your operating system on disk.

In this game, there is no goal. The best comparing game is Skyblock from Minecraft; where the player is born into a desolate world of only a tree and some grass blocks, which might be just enough, but curiosity and creativity take over, and players eventually build entire systems from nothing.

## Authors
 - King Shelvacu of Shelvaculandia (shelvacu)
 - Luke I. Wilson (asmoaesl)
 - Imtiaz Ahmed (tiazahmd)
