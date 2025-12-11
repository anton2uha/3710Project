# ECE 3710 Final Project - Infinite Runner Game
**Team Members:** Anthony, Evelyn, Martin, Ian

## Project Overview
This project implements a custom CPU with VGA graphics and PS/2 keyboard input to create an endless runner game on an FPGA. The player controls a player sprite that must jump over cacti obstacles using the spacebar.
- **Player:** Player at fixed X position, Y position controlled by jump physics
- **Obstacles:** Cacti scroll from right to left at fixed Y position
- **Collision Detection:** Implemented in assembly game code

### Compilation Instructions
- Set the top-level entity to be cpu_top.v
- Before compiling, ensure the memory files for game code and sprite hex values are properly linked using the correct location.

### Running the Game
1. Connect VGA monitor to the board
2. Connect PS/2 keyboard to the board
3. Power on the board and program it with the `.sof` file
4. Press **KEY[0]** on the FPGA to reset if needed
5. Use **SPACEBAR** to make the player jump over cacti
6. Game runs indefinitely. Avoid the obstacles to continue playing

### Pin Assignments
Exact pin assignments are located in `/resources/pin_out.qsf` for the pins below:
- **VGA Pins:** VGA_R[7:0], VGA_G[7:0], VGA_B[7:0], VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N
- **PS/2 Pins:** PS2_CLK, PS2_DAT
- **Clock:** 50 MHz system clock (CLOCK_50)
- **Reset:** KEY[0] (active low)

### VGA Subsystem Details
- **Resolution:** 640×480 @ 60Hz
- **Color Format:** RGB888 output (RGB565 stored in ROM)
- **Sprite ROM Memory Map:** for `../Sprites/Combined_manWalking+Cactus+bg.hex`
  - Addresses 0-4095: Player animation (4 frames, 32×32 each)
  - Addresses 4096-5119: Cactus obstacle (32×32)
  - Addresses 5120+: Background tiles


## Authors' Contributions
- **Evelyn:** PS/2 keyboard interface, CPU testing and debugging
- **Anthony:** Top-level CPU integration, assembler, game logic
- **Ian:** Dual-port RAM, PS/2 controller, VGA-game integration
- **Martin** Complete VGA subsystem design and implementation

---

**Last Updated:** December 10th 2025

---
