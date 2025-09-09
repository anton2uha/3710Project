# 3710 Project

## ALU Instructions

closely follows implementation listed [here](https://my.eng.utah.edu/~cs3710/handouts/cr16a-prog-ref.pdf)

Destination input = A, Src input = B. This means CMP does A<B and SUB does A-B.

src2 = A src1 = B for cmp instruction

## Lab 1 List of instructions

- ADD = 4'b0101
- ADDU = 4'b0110
- ADDC = 4'b0111
- SUB = 4'b1001
- SUBC = 4'b1010
- CMP = 4'b1011
- AND = 4'b0001
- OR = 4'b0010
- XOR = 4'b0011
- MOV = 4'b1101
- LSH = 4'b0100
- NOT = 4'b1000
- ASHU = 4'b1100
- NOP = 4'b0000

## Lab 2:

### Questions

- How many read and write ports should your regfile have? What control signals will be needed to control read
  and write operations.

- Would you prefer a MUX or a TRI-BUF interface? Keep in mind that modern FPGA synthesis tools will not
  generate tri-state buffers in the logic, and will convert tri-state buffers into MUXes. I strongly recommend that
  you guys design a MUX-based architecture.

- How would you organize the regfile to interface with the ALU? Think about the data-path bus interface between
  the regfile and the ALU.

- How will you integrate the ALU Flags with the regfile? Are the flags a separate set of (processor status)
  registers, or one of the registers in the regfile is dedicated to work as a flag register?

- How will you design a TestBench that will perform a sequence of reads and writes to and from the regfile,
  via the ALU?

- Will the Reg file be a 2D design or 1D / traditional design?

### Modules / Tasks

- Bus module (Ian / Martin)
- MUX module (Anthony / Evelyn)
- REG File module (Anthony / Evelyn)
- Bus module tb (Anthony / Evelyn) We might collab on this
- MUX module tb (Ian / Martin)
- REG File module tb (Ian / Martin)
- ALU module (already done, but maybe needs refining?)
- Programming the FPGA // This is gonna be big

### Commitments

- We should try to get the implementation and testbenches done next week (by Sept 11th) so that we have time for the report
- The report is 7-8 pages (Like actually? 3700 was 8 pages of graphics, is it the same for this?)
  - If the report is really 7-8 pages of text, lets use the last week to get it done.
- RTL Diagram
