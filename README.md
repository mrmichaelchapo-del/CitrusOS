# 🍊 CitrusOS

A tiny hobby operating system that boots from a **single 512-byte boot sector**,
paints a pulpy orange wallpaper in VGA Mode 13h, and renders its name with a
custom 5×8 bitmap font — no BIOS text routines, no second stage.

![status](https://img.shields.io/badge/stage-boot%20sector-orange)
![size](https://img.shields.io/badge/boot%20sector-512%20bytes-orange)
![mode](https://img.shields.io/badge/display-VGA%20Mode%2013h-orange)
![license](https://img.shields.io/badge/license-BSD%203--Clause-orange)

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
```

macOS (Homebrew):

```bash
brew install nasm qemu
```

---

## Build

```bash
nasm -f bin boot.asm -o citrus.img
```

That produces `citrus.img`, exactly **512 bytes**, bootable by BIOS.

---

## Run

```bash
qemu-system-i386 -drive format=raw,file=citrus.img
```

You should see an orange pulp wallpaper with `CitrusOS is running` on it.

> On modern high-DPI displays the 320×200 image will look small or stretched in
> a window. That's expected for Mode 13h.

---

## Repository layout

```
CitrusOS/
├── boot.asm     # the entire OS: boot sector, palette, wallpaper, font, renderer
├── citrus.img   # build artifact (generated, not committed)
└── README.md
```

---

## How it works (short tour)

- **Boot**: BIOS loads sector 0 to `0x7C00` and jumps to it.
- **Mode 13h**: `int 0x10` with `AX=0x0013` switches to 320×200 linear framebuffer
  at physical `0xA0000`.
- **Palette**: write index to `0x3C8`, then R/G/B (6-bit, 0–63) to `0x3C9`.
  The DAC auto-increments, so 16 entries cost one index write + 48 `out`s.
- **Pulp fill**: for each pixel, `index = ((offset / 7) + (offset % 7)) & 0x0F + 16`
  — a cheap pattern that reads as pulp cells rather than stripes.
- **Font**: 5×8 glyphs, one byte per row, low 5 bits used. Glyphs are stored in
  **first-appearance order** of the message so the renderer can index with
  `sub al, 'C'` instead of a lookup table.
- **Renderer**: shifts each row bitmap left, sets a white pixel when carry is 1,
  advances 6 px per character (5 px glyph + 1 px gap).

---

## Design constraints

This is deliberately a **512-byte, no-second-stage** OS. That imposes real limits:

- The font only contains the 11 unique glyphs in `CitrusOS is running`.
- Changing the message means reordering or extending the font table.
- No memory management, interrupts, or shell — those need a second stage.

Those constraints are the point right now. The next milestones lift them.

---

## Roadmap

- [x] Boot sector that boots in QEMU
- [x] VGA Mode 13h + custom DAC palette
- [x] Procedural pulp wallpaper
- [x] Custom 5×8 bitmap font + string renderer
- [ ] Full printable-ASCII font (spend the free sector bytes)
- [ ] 2× scaled text for readability at 320×200
- [ ] Second-stage loader (`int 0x13`) so the kernel can grow past 512 bytes
- [ ] Protected mode (GDT → 32-bit)
- [ ] Keyboard input + a tiny shell
- [ ] Paging + heap

---

## License

BSD 3-Clause License

Copyright (c) 2026, CitrusOS

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

## Acknowledgments

Built as a learning project in bare-metal x86 assembly.
Inspired by the classic osdev.org bootloader path.