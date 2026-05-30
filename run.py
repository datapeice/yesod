import os
import subprocess

def main():
    files_to_delete = ['crt0.rel', 'main.ihx', 'main.lk', 'main.lst', 'main.map', 'main.noi', 'main.rel', 'main.sym']
    for f in files_to_delete:
        if os.path.exists(f):
            os.remove(f)
            print(f"Deleted {f}")

    print("assembling crt0.s")
    subprocess.run(['sdasz80', '-o', 'crt0.rel', 'crt0.s'], check=True)
    
    print("linking crt0.rel")
    subprocess.run(['sdcc', '-mz80', '--no-std-crt0', '--opt-code-size',
                    '-Wl-b_GSINIT=0x0200', '-Wl-b_DATA=0x8000',
                    'crt0.rel'], check=True)

    rom = {}
    max_addr = 0
    
    with open('main.ihx', 'r') as f:
        for line in f:
            if not line.startswith(':'):
                continue
            length = int(line[1:3], 16)
            addr = int(line[3:7], 16)
            rectype = int(line[7:9], 16)
            
            if rectype == 0:
                for i in range(length):
                    byte = int(line[9 + i*2 : 11 + i*2], 16)
                    if addr + i < 0x8000:
                        rom[addr + i] = byte
                        if addr + i > max_addr:
                            max_addr = addr + i
            elif rectype == 1:
                break

    size = min(max_addr + 1, 1024)
    rom_array = [rom.get(i, 0) for i in range(size)]

    c_code = f"const uint8_t z80_rom[{size}] = {{\n"
    for i in range(0, size, 16):
        chunk = rom_array[i:i+16]
        hex_vals = ', '.join([f"0x{b:02X}" for b in chunk])
        c_code += f"  {hex_vals},\n"
    c_code += "};\n"

    print(f"\ngenerated code (Size: {size} bytes):")
    
    with open('z80_rom.h', 'w') as f:
        f.write(c_code)
    print("Saved to z80_rom.h")

if __name__ == '__main__':
    main()