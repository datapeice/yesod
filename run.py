import sys
import os
import subprocess

def build(asm_file):
    if not os.path.exists(asm_file):
        print(f"Err: file {asm_file} not found.")
        return

    bin_file = asm_file.replace('.asm', '.bin')
    
    print(f"Compiling {asm_file} -> {bin_file}...")
    try:
        subprocess.run(['pasmo', '--bin', asm_file, bin_file], check=True)
    except FileNotFoundError:
        print("pasmo.exe is not here")
        return
    except subprocess.CalledProcessError:
        print("Check syntax")
        return

    with open(bin_file, 'rb') as f:
        data = f.read()

    array_name = "z80_rom"
    c_code = f"// Generated from {asm_file}\n"
    c_code += f"const uint8_t {array_name}[{len(data)}] = {{\n  "

    lines = []
    chunk_size = 12
    
    for i in range(0, len(data), chunk_size):
        chunk = data[i:i+chunk_size]
        hex_chunk = ", ".join([f"0x{b:02X}" for b in chunk])
        lines.append(hex_chunk)

    c_code += ",\n  ".join(lines)
    c_code += "\n};\n"

    h_file = asm_file.replace('.asm', '.h')
    with open(h_file, 'w', encoding='utf-8') as f:
        f.write(c_code)

    print("\n[ УСПЕШНО ]")
    print(f"Size of ROM: {len(data)} байт")
    print(f"Stored in file: {h_file}\n")
    
    print(c_code)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python build_rom.py code.asm")
    else:
        build(sys.argv[1])