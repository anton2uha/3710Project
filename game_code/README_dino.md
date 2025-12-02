# Dino Runner Assembly

Assembly program: `assembler/dino.asm`  
Assembler: `assembler/assembler.py`

## What it does
- Minimal Chrome-dino-style endless runner using the CR16a-ish ISA.
- Uses a 16x2 tile map in shared RAM and a single moving obstacle. The dino jumps for a fixed duration when SPACE is pressed.
- External logic should render VRAM tiles to VGA and write the SPACE key state into RAM for the CPU to poll.

## Memory map (assumptions)
- `0x00E0` (`KEY_ADDR`): external PS/2 interface writes `1` while SPACE is down, `0` otherwise.
- `0x00F3` (`SCORE_ADDR`): CPU writes score (low byte) every frame for display/telemetry.
- `0x00F6` (`CRASH_ADDR`): CPU writes `1` once on collision and halts in a tight loop.
- `0x0100` (`VRAM_ROW0`): start of tile row 0 (air row).
- `0x0110` (`VRAM_ROW1`): start of tile row 1 (ground row). Width is 16 tiles (0x10).

Tile codes the VGA side should map to glyphs/colors (feel free to swap art):
- `0`: empty / background
- `1`: ground segment
- `2`: dino sprite
- `3`: cactus/obstacle

## Register conventions inside the program
- R0: software zero (initialized to 0)
- R1: scratch / address math
- R2: VRAM row0 base (0x0100)
- R3: `WORLD_WIDTH` (16)
- R4: dino x-column (2)
- R5: dino y-state (0 = ground, 1 = air)
- R6: obstacle x-position
- R7: jump timer (counts down frames aloft)
- R8: generic counter (delay/fill loops)
- R9: `KEY_ADDR` pointer
- R10: score (low byte)
- R11: VRAM row1 base (0x0110)
- R12: cactus tile code (3)
- R13: jump duration (frames aloft)
- R14: ground tile code (1)
- R15: dino tile code (2)

## Game loop summary
1. Delay for pacing (`MOVI 0x20, R8` loop sets frame time).  
2. Poll SPACE at `KEY_ADDR`; if idle and not already mid-jump, seed `R7` with `R13` (default 6 frames) and set dino to air row.  
3. Count down `R7`; when it reaches zero, drop dino back to ground.  
4. Move obstacle one column left; when it wraps past column 0, reset to `WORLD_WIDTH-1` and increment score.  
5. Collision: if obstacle x matches dino x **and** dino is on ground, set `CRASH_ADDR` to 1 and halt.  
6. Redraw VRAM every frame:
   - Clear row0 to empty
   - Repaint row1 to ground tiles
   - Draw obstacle on row1 at `R6`
   - Draw dino on row0 or row1 depending on `R5`
7. Write score to `SCORE_ADDR` and loop.

## VGA/PS2 integration notes
- Drive port A of the dual-port RAM with the CPU (already wired in `cpu_top.v`). Use port B in a VGA renderer to fetch tile codes starting at `0x0100`. Each tile is one 16-bit word; only the low byte is used by this program.  
- Map the 16x2 tile grid as: row0 indices `0x0100..0x010F`, row1 indices `0x0110..0x011F`. Compute pixel positions however you like (e.g., each tile -> an 8x8 glyph).  
- Feed the SPACE key from `space_key_detector` (or similar) into `KEY_ADDR` by writing `1/0` into `ram[0x00E0]` using port B. Pulsed or level is fine; level is assumed.  
- Provide glyphs/colors for tile codes 0–3. If you already have art, update your VGA side to use those patterns; otherwise let me know and I can help craft simple bitmaps.

## Tuning knobs
- Frame pacing: change `MOVI 0x20, R8` near `frame_delay` for speed. Larger = slower.  
- Jump duration: change `MOVI 0x06, R13`.  
- World width: change `MOVI 0x10, R3` and the dependent `ADDI 0x10, R11`; adjust VRAM span on the VGA side accordingly.  
- Starting positions: edit `R4` (dino column) or initial `R6` setup (obstacle spawn).  

## Building
From the repo root:
```
cd assembler
python assembler.py dino.asm output.hex
```
`output.hex` will contain the machine code ready for `$readmemh` or for loading into your RAM init file. If you use a different init path than the existing `true_dual_port_ram_single_clock` modules, point `$readmemh` at the new hex.

## Gotchas
- The control FSM sign-extends most immediates; addresses above 0x7F are built with `ORI` + shifts to keep them positive (see how `0xE0`/`0x0100` are formed).  
- Branches are 8-bit displacements; keep new code additions compact or re-run assembly so labels stay in range.  
- CMP sets flags in a nonstandard way in the current ALU (flags[0] asserted when A > B), so use the provided BEQ/BNE/BGE/BLT patterns already in the program.  

## What to provide if changes are needed
- VGA glyphs/bitmaps for tile codes 0–3 (or a palette plan).  
- If the keyboard is mapped to a different address or uses pulses instead of a level, share that so the poll logic can be adjusted.  
- Any different VRAM geometry so we can change the tile math and constants.
