#!/usr/bin/env python3
"""
Simple 16-bit Assembler with Label Support
Supports basic instruction encoding for a 16-bit architecture
"""

import re
import sys

class Assembler:
    def __init__(self):
        # Instruction definitions: mnemonic -> (opcode, format)
        # Format types: 'RR' (register-register), 'RI' (register-immediate)
        self.labels = {}  # Label name -> address mapping
        self.instructions = {
            # Arithmetic instructions
            'ADD':  {'opcode': 0b0000, 'ext': 0b0101, 'format': 'RR'},
            'ADDI': {'opcode': 0b0101, 'format': 'RI'},
            'ADDU':  {'opcode': 0b0000, 'ext': 0b0110, 'format': 'RR'},
            'ADDUI': {'opcode': 0b0110, 'format': 'RI'},
            'ADDC':  {'opcode': 0b0000, 'ext': 0b0111, 'format': 'RR'},
            'ADDCI': {'opcode': 0b0111, 'format': 'RI'},
    
            'SUB':   {'opcode': 0b0000, 'ext': 0b1001, 'format': 'RR'},
            'SUBI':  {'opcode': 0b1001, 'format': 'RI'},
            'SUBC':  {'opcode': 0b0000, 'ext': 0b1010, 'format': 'RR'},
            'SUBCI': {'opcode': 0b1010, 'format': 'RI'},

            # MUL not in our ISA, will keep here for now
            'MUL':   {'opcode': 0b0000, 'ext': 0b1110, 'format': 'RR'},
            'MULI':  {'opcode': 0b1110, 'format': 'RI'},
    
            'CMP':   {'opcode': 0b0000, 'ext': 0b1011, 'format': 'RR'},
            'CMPI':  {'opcode': 0b1011, 'format': 'RI'},
    
            # Logical instructions
            'AND':   {'opcode': 0b0000, 'ext': 0b0001, 'format': 'RR'},
            'ANDI':  {'opcode': 0b0001, 'format': 'RI'},
    
            'OR':    {'opcode': 0b0000, 'ext': 0b0010, 'format': 'RR'},
            'ORI':   {'opcode': 0b0010, 'format': 'RI'},
    
            'XOR':   {'opcode': 0b0000, 'ext': 0b0011, 'format': 'RR'},
            'XORI':  {'opcode': 0b0011, 'format': 'RI'},

            'NOT':   {'opcode': 0b0000, 'ext': 0b1000, 'format': 'RR'},
    
            # Move instruction
            'MOV':   {'opcode': 0b0000, 'ext': 0b1101, 'format': 'RR'},
            'MOVI':  {'opcode': 0b1101, 'format': 'RI'},

            # Shift instructions (different opcode from ISA doc)
            'LSH':   {'opcode': 0b0000, 'ext': 0b1111, 'format': 'RR'},
            'LSHI':  {'opcode': 0b1111, 'upper': 0b000, 'format': 'SHIFT_I'},
            'ASHU':  {'opcode': 0b0000, 'ext': 0b1110, 'format': 'RR'},
            'ASHUI': {'opcode': 0b1110, 'upper': 0b001, 'format': 'SHIFT_I'},

            # LOAD/STORE
            'LOAD': {'opcode': 0b0100, 'ext': 0b0000, 'format': 'MEM'},
            'STOR': {'opcode': 0b0100, 'ext': 0b0100, 'format': 'MEM'},

            # Branch conditional instructions (8-bit displacement)
            'BEQ':  {'opcode': 0b1100, 'cond': 0b0000, 'format': 'BCOND'},
            'BNE':  {'opcode': 0b1100, 'cond': 0b0001, 'format': 'BCOND'},
            'BGE':  {'opcode': 0b1100, 'cond': 0b1101, 'format': 'BCOND'},
            'BCS':  {'opcode': 0b1100, 'cond': 0b0010, 'format': 'BCOND'},
            'BCC':  {'opcode': 0b1100, 'cond': 0b0011, 'format': 'BCOND'},
            'BHI':  {'opcode': 0b1100, 'cond': 0b0100, 'format': 'BCOND'},
            'BLS':  {'opcode': 0b1100, 'cond': 0b0101, 'format': 'BCOND'},
            'BLO':  {'opcode': 0b1100, 'cond': 0b1010, 'format': 'BCOND'},
            'BHS':  {'opcode': 0b1100, 'cond': 0b1011, 'format': 'BCOND'},
            'BGT':  {'opcode': 0b1100, 'cond': 0b0110, 'format': 'BCOND'},
            'BLE':  {'opcode': 0b1100, 'cond': 0b0111, 'format': 'BCOND'},
            'BLT':  {'opcode': 0b1100, 'cond': 0b1100, 'format': 'BCOND'},
            'BUC':  {'opcode': 0b1100, 'cond': 0b1110, 'format': 'BCOND'},

            # Jump conditional instructions (register target)
            'JEQ':  {'opcode': 0b0100, 'cond': 0b0000, 'format': 'JCOND'},
            'JNE':  {'opcode': 0b0100, 'cond': 0b0001, 'format': 'JCOND'},
            'JGE':  {'opcode': 0b0100, 'cond': 0b1101, 'format': 'JCOND'},
            'JCS':  {'opcode': 0b0100, 'cond': 0b0010, 'format': 'JCOND'},
            'JCC':  {'opcode': 0b0100, 'cond': 0b0011, 'format': 'JCOND'},
            'JHI':  {'opcode': 0b0100, 'cond': 0b0100, 'format': 'JCOND'},
            'JLS':  {'opcode': 0b0100, 'cond': 0b0101, 'format': 'JCOND'},
            'JLO':  {'opcode': 0b0100, 'cond': 0b1010, 'format': 'JCOND'},
            'JHS':  {'opcode': 0b0100, 'cond': 0b1011, 'format': 'JCOND'},
            'JGT':  {'opcode': 0b0100, 'cond': 0b0110, 'format': 'JCOND'},
            'JLE':  {'opcode': 0b0100, 'cond': 0b0111, 'format': 'JCOND'},
            'JLT':  {'opcode': 0b0100, 'cond': 0b1100, 'format': 'JCOND'},
            'JUC':  {'opcode': 0b0100, 'cond': 0b1110, 'format': 'JCOND'},
        }
        
        # Register mapping (R0-R15)
        self.registers = {f'R{i}': i for i in range(16)}
    
    def parse_label_definition(self, line):
        """Check if line is a label definition and return label name, or None"""
        line = line.strip()
        if line.endswith(':') and not line.startswith(';'):
            label_name = line[:-1].strip()
            # Validate label name (must be alphanumeric/underscore, not a register)
            if label_name and label_name.upper() not in self.registers:
                return label_name
        return None
        
    def parse_register(self, reg_str):
        """Parse register name and return register number"""
        reg_str = reg_str.strip().upper()
        if reg_str in self.registers:
            return self.registers[reg_str]
        raise ValueError(f"Invalid register: {reg_str}")
    
    def parse_immediate(self, imm_str, current_addr=None, allow_label=False):
        """Parse immediate value (decimal, hex, or label reference)"""
        imm_str = imm_str.strip()
        
        # Check if it's a label reference
        if allow_label and not (imm_str.startswith('0x') or imm_str.startswith('0X') or 
                                imm_str.startswith('0b') or imm_str.startswith('0B') or
                                imm_str.startswith('-') or imm_str.isdigit()):
            # It's a label
            if imm_str not in self.labels:
                raise ValueError(f"Undefined label: {imm_str}")
            target_addr = self.labels[imm_str]
            if current_addr is None:
                raise ValueError(f"Cannot calculate displacement for label {imm_str}")
            # Calculate displacement (relative to next instruction)
            displacement = target_addr - current_addr
            return displacement
        
        try:
            if imm_str.startswith('0x') or imm_str.startswith('0X'):
                value = int(imm_str, 16)
            elif imm_str.startswith('0b') or imm_str.startswith('0B'):
                value = int(imm_str, 2)
            else:
                value = int(imm_str)
            return value
        except ValueError:
            raise ValueError(f"Invalid immediate value: {imm_str}")
    
    def sign_extend_8bit(self, value):
        """Sign extend an 8-bit value"""
        if value & 0x80:  # If sign bit is set
            return value | 0xFF00  # Extend with 1s
        return value & 0xFF
    
    def assemble_instruction(self, line, current_addr=0):
        """Assemble a single instruction line"""
        # Remove comments
        if ';' in line:
            line = line.split(';')[0]
        
        line = line.strip()
        if not line:
            return None
        
        # Check for label definition
        if line.endswith(':'):
            # This is a label definition, skip it during assembly
            return None
        
        # Parse instruction and operands
        parts = re.split(r'[\s,]+', line)
        mnemonic = parts[0].upper()
        
        if mnemonic not in self.instructions:
            raise ValueError(f"Unknown instruction: {mnemonic}")
        
        instr_def = self.instructions[mnemonic]
        opcode = instr_def['opcode']
        format_type = instr_def['format']
        
        if format_type == 'RR':
            # Register-Register format: ADD Rsrc, Rdest
            if len(parts) != 3:
                raise ValueError(f"Invalid operands for {mnemonic}: expected 2 registers")
            
            rsrc = self.parse_register(parts[1])
            rdest = self.parse_register(parts[2])
            op_ext = instr_def['ext']
            
            # Encode: [opcode:4][rdest:4][op_ext:4][rsrc:4]
            instruction = (opcode << 12) | (rdest << 8) | (op_ext << 4) | rsrc
            
        elif format_type == 'RI':
            # Register-Immediate format: ADDI Imm, Rdest
            if len(parts) != 3:
                raise ValueError(f"Invalid operands for {mnemonic}: expected immediate and register")
            
            imm = self.parse_immediate(parts[1])
            rdest = self.parse_register(parts[2])
            
            # Check if immediate fits in 8 bits (signed)
            if imm < -128 or imm > 255:
                raise ValueError(f"Immediate value {imm} out of range [-128, 255]")
            
            # Convert to 8-bit representation
            if imm < 0:
                imm = imm & 0xFF
            
            imm_hi = (imm >> 4) & 0xF
            imm_lo = imm & 0xF
            
            # Encode: [opcode:4][rdest:4][imm_hi:4][imm_lo:4]
            instruction = (opcode << 12) | (rdest << 8) | (imm_hi << 4) | imm_lo
        
        elif format_type == 'SHIFT_I':
            imm = self.parse_immediate(parts[1])
            rdest = self.parse_register(parts[2])
    
            # Range check: -15 to +15
            if imm < -15 or imm > 15:
                raise ValueError(f"Shift amount {imm} out of range [-15, 15]")
    
            # Convert to 5-bit 2's complement
            if imm < 0:
                five_bit_value = (imm & 0x1F)  # 5-bit 2's complement
            else:
                five_bit_value = imm
    
            # Extract sign bit and magnitude
            sign_bit = (five_bit_value >> 4) & 1
            magnitude = five_bit_value & 0xF
    
            # Determine upper 3 bits based on instruction
            upper_bits = instr_def['upper']  # 0b000 for LSHI, 0b001 for ASHUI
    
            # [opcode:4][rdest:4][upper:3][s:1][magnitude:4]
            instruction = (opcode << 12) | (rdest << 8) | (upper_bits << 5) | (sign_bit << 4) | magnitude
        
        elif format_type == 'MEM':
            # Memory format: LOAD/STOR first_reg, addr_reg
            if len(parts) != 3:
                raise ValueError(f"Invalid operands for {mnemonic}: expected 2 registers")
    
            first_reg = self.parse_register(parts[1])   # Rdest for LOAD, Rsrc for STOR
            addr_reg = self.parse_register(parts[2])    # Raddr
            op_ext = instr_def['ext']
    
            # Encode: [opcode:4][first_reg:4][op_ext:4][addr_reg:4]
            instruction = (opcode << 12) | (first_reg << 8) | (op_ext << 4) | addr_reg
        
        elif format_type == 'BCOND':
            # Branch conditional: BEQ disp or BEQ label
            if len(parts) != 2:
                raise ValueError(f"Invalid operands for {mnemonic}: expected displacement or label")
    
            # Allow label references for branches
            disp = self.parse_immediate(parts[1], current_addr=current_addr, allow_label=True)
            cond = instr_def['cond']
    
            # Check if displacement fits in 8 bits (signed)
            if disp < -128 or disp > 127:
                raise ValueError(f"Displacement {disp} out of range [-128, 127] for label or offset")
    
            # Convert to 8-bit representation
            if disp < 0:
                disp = disp & 0xFF
    
            disp_hi = (disp >> 4) & 0xF
            disp_lo = disp & 0xF
    
            # Encode: [opcode:4][cond:4][disp_hi:4][disp_lo:4]
            instruction = (opcode << 12) | (cond << 8) | (disp_hi << 4) | disp_lo

        elif format_type == 'JCOND':
            # Jump conditional: JEQ Rtarget
            if len(parts) != 2:
                raise ValueError(f"Invalid operands for {mnemonic}: expected register")
    
            rtarget = self.parse_register(parts[1])
            cond = instr_def['cond']
    
            # Encode: [opcode:4][cond:4][1100][rtarget:4]
            instruction = (opcode << 12) | (cond << 8) | (0b1100 << 4) | rtarget
            
        else:
            raise ValueError(f"Unknown instruction format: {format_type}")
        
        return instruction
    
    def collect_labels(self, lines):
        """First pass: collect all labels and their addresses"""
        self.labels = {}
        addr = 0
        
        for line_num, line in enumerate(lines, 1):
            # Remove comments
            if ';' in line:
                line = line.split(';')[0]
            
            line = line.strip()
            if not line:
                continue
            
            # Check for label definition
            label_name = self.parse_label_definition(line)
            if label_name:
                if label_name in self.labels:
                    raise ValueError(f"Line {line_num}: Duplicate label '{label_name}'")
                self.labels[label_name] = addr
            else:
                # It's an instruction, increment address
                addr += 1
    
    def assemble_file(self, input_file, output_file, output_format='hex'):
        """Assemble an entire file with two-pass assembly"""
        try:
            with open(input_file, 'r') as f:
                lines = f.readlines()
            
            # First pass: collect labels
            self.collect_labels(lines)
            
            # Second pass: assemble instructions
            machine_code = []
            addr = 0
            
            for line_num, line in enumerate(lines, 1):
                try:
                    instruction = self.assemble_instruction(line, current_addr=addr)
                    if instruction is not None:
                        machine_code.append(instruction)
                        addr += 1
                except Exception as e:
                    print(f"Error on line {line_num}: {e}", file=sys.stderr)
                    print(f"  Line: {line.strip()}", file=sys.stderr)
                    return False
            
            # Write output
            with open(output_file, 'w') as f:
                for instr in machine_code:
                    if output_format == 'hex':
                        f.write(f"{instr:04X}\n")
                    elif output_format == 'bin':
                        f.write(f"{instr:016b}\n")
                    elif output_format == 'dec':
                        f.write(f"{instr}\n")
            
            print(f"Successfully assembled {len(machine_code)} instructions")
            if self.labels:
                print(f"Labels defined: {', '.join(self.labels.keys())}")
            print(f"Output written to: {output_file}")
            return True
            
        except FileNotFoundError:
            print(f"Error: File '{input_file}' not found", file=sys.stderr)
            return False
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            return False
    
    def assemble_string(self, code, output_format='hex'):
        """Assemble code from a string and return list of instructions"""
        lines = code.strip().split('\n')
        
        # First pass: collect labels
        self.collect_labels(lines)
        
        # Second pass: assemble instructions
        machine_code = []
        addr = 0
        
        for line_num, line in enumerate(lines, 1):
            try:
                instruction = self.assemble_instruction(line, current_addr=addr)
                if instruction is not None:
                    machine_code.append(instruction)
                    addr += 1
            except Exception as e:
                print(f"Error on line {line_num}: {e}", file=sys.stderr)
                print(f"  Line: {line.strip()}", file=sys.stderr)
                raise
        
        # Format output
        result = []
        for instr in machine_code:
            if output_format == 'hex':
                result.append(f"{instr:04X}")
            elif output_format == 'bin':
                result.append(f"{instr:016b}")
            elif output_format == 'dec':
                result.append(str(instr))
        
        return result


def main():
    if len(sys.argv) < 3:
        print("Usage: python assembler.py <input.asm> <output.hex> [format]")
        print("  format: hex (default), bin, or dec")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    output_format = sys.argv[3] if len(sys.argv) > 3 else 'hex'
    
    assembler = Assembler()
    success = assembler.assemble_file(input_file, output_file, output_format)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

