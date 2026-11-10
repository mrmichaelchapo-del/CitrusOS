; ============================================================================
; CitrusOS — boot.asm
; ----------------------------------------------------------------------------
; Single 512-byte boot sector.
;
;  1. Enter VGA Mode 13h (320x200x256, linear framebuffer at 0xA0000)
;  2. Load a custom orange palette into the VGA DAC (ports 0x3C8 / 0x3C9)
;  3. Fill the screen with a procedural "pulp" pattern
;  4. Draw "CitrusOS is running" with a hand-authored 5x8 bitmap font
;  5. Halt
;
; Build:  nasm -f bin boot.asm -o citrus.img
; Run:    qemu-system-i386 -drive format=raw,file=citrus.img
;
; License: BSD 3-Clause (see README.md)
; ============================================================================

[BITS 16]
[ORG 0x7C00]

start:
    ; ------------------------------------------------------------------
    ; 1. VGA Mode 13h — 320x200, 256 colors, framebuffer at 0xA0000
    ; ------------------------------------------------------------------
    mov ax, 0x0013
    int 0x10

    ; ------------------------------------------------------------------
    ; 2. Load custom palette (entries 16..31) via the VGA DAC
    ;    Write start index to 0x3C8, then R/G/B (6-bit) to 0x3C9.
    ;    The DAC auto-increments, so one index write covers all entries.
    ; ------------------------------------------------------------------
    mov dx, 0x3C8
    mov al, 16                  ; first palette entry to rewrite
    out dx, al

    inc dx                      ; DX = 0x3C9 (data port)
    mov cx, 16                  ; 16 entries
.pal:
    mov al, 63                  ; R (0..63) — max red
    out dx, al
    mov al, 24                  ; G (0..63) — some green for orange
    out dx, al
    xor al, al                  ; B = 0
    out dx, al
    loop .pal

    ; ------------------------------------------------------------------
    ; 3. Pulp wallpaper fill
    ;    ES:DI = framebuffer, one byte per pixel.
    ;    index = ((offset / 7) + (offset % 7)) & 0x0F + 16
    ; ------------------------------------------------------------------
    mov ax, 0xA000
    mov es, ax
    xor di, di                  ; pixel offset 0
    mov cx, 64000               ; 320 * 200 pixels

.pulp:
    mov ax, di
    xor dx, dx
    mov bx, 7
    div bx                      ; AX = DI/7, DX = DI%7
    add al, dl                  ; mix quotient + remainder
    and al, 0x0F                ; 0..15
    add al, 16                  ; shift into our custom palette range
    stosb                       ; [ES:DI] = AL, DI++
    loop .pulp

    ; ------------------------------------------------------------------
    ; 4. Draw the string over the wallpaper
    ; ------------------------------------------------------------------
    mov si, msg
    mov di, 320*90 + 40         ; start at row 90, column 40
.next_char:
    lodsb                       ; AL = [DS:SI], SI++
    or al, al                   ; end of string?
    jz .hang
    call draw_char
    add di, 6                   ; advance 5 px glyph + 1 px gap
    jmp .next_char

.hang:
    cli
    hlt
    jmp .hang

; ----------------------------------------------------------------------------
; draw_char
;   In : AL = character, DI = screen offset (Mode 13h linear)
;   Out: character blitted to screen in white (palette index 0x0F)
;   Uses: AX, BX, CX, SI, DI
; ----------------------------------------------------------------------------
draw_char:
    push cx
    push bx
    push si
    push di

    sub al, 'C'                 ; font table starts at 'C'
    cmp al, 11                  ; 11 glyphs total
    jae .done                   ; out of range -> skip
    shl ax, 3                   ; AX = glyph_index * 8 (5x8 font)
    mov si, font
    add si, ax

    mov cx, 8                   ; 8 rows per glyph
.row:
    lodsb                       ; AL = row bitmap
    mov bl, 5                   ; 5 columns
.col:
    shl al, 1                   ; carry = leftmost pixel
    jnc .skip
    mov byte [es:di], 0x0F      ; white pixel
.skip:
    inc di
    dec bl
    jnz .col
    add di, 320 - 5             ; next scanline
    loop .row

.done:
    pop di
    pop si
    pop bx
    pop cx
    ret

; ----------------------------------------------------------------------------
; Data
; ----------------------------------------------------------------------------
msg db "CitrusOS is running", 0

; 5x8 font, stored in FIRST-APPEARANCE ORDER of the message:
;   C  i  t  r  u  s  O  S  ' '  n  g
; Each glyph is 8 bytes (one per row), low 5 bits used, MSB-first.
font:
    db 0x0E,0x11,0x10,0x10,0x10,0x11,0x0E,0x00   ; C
    db 0x04,0x0C,0x04,0x04,0x04,0x04,0x0E,0x00   ; i
    db 0x1F,0x04,0x04,0x04,0x04,0x04,0x04,0x00   ; t
    db 0x00,0x00,0x00,0x0A,0x15,0x11,0x11,0x00   ; r
    db 0x00,0x00,0x11,0x11,0x11,0x13,0x0D,0x00   ; u
    db 0x00,0x00,0x0E,0x11,0x0E,0x01,0x0E,0x00   ; s
    db 0x0E,0x11,0x11,0x11,0x11,0x11,0x0E,0x00   ; O
    db 0x0E,0x11,0x10,0x0E,0x01,0x11,0x0E,0x00   ; S
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00   ; space
    db 0x00,0x00,0x11,0x11,0x11,0x11,0x0D,0x00   ; n
    db 0x00,0x0E,0x11,0x11,0x0D,0x01,0x0E,0x00   ; g

; ----------------------------------------------------------------------------
; Boot signature — required by the BIOS at bytes 510..511
; ----------------------------------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55