# 🍊 CitrusOS

A tiny hobby operating system that boots from a **single 512-byte boot sector**,
paints a pulpy orange wallpaper in VGA Mode 13h, and renders its name with a
custom 5×8 bitmap font — no BIOS text routines, no second stage.

![status](https://img.shields.io/badge/stage-boot%20sector-orange)
![size](https://img.shields.io/badge/boot%20sector-512%20bytes-orange)
![mode](https://img.shields.io/badge/display-VGA%20Mode%2013h-orange)

---

## What it does

On boot, CitrusOS:

1. Switches the display into **VGA Mode 13h** (320×200, 256 colors).
2. Loads a **custom orange palette** through the VGA DAC (`0x3C8` / `0x3C9`).
3. Fills the screen with a **procedural pulp pattern** using a cheap pseudo-random
   index into palette entries 16–31.
4. Draws the string `CitrusOS is running` over the wallpaper using a
   **hand-authored 5×8 bitmap font** and a tight `stosb`-style pixel blitter.
5. Halts the CPU.

Everything above lives in **one 512-byte sector** with `0xAA55` at the end.

---

## Requirements

- **NASM** (assembler)
- **QEMU** (`qemu-system-i386`) — for running
- A Unix-like shell (Linux, macOS, WSL) for the build/run commands

Install (Debian/Ubuntu):

```bash
sudo apt install nasm qemu-system-x86
