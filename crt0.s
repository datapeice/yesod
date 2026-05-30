.module crt0
    .globl  _main
    .area _HEADER (ABS)
    .org 0x0000

_start::
    DI 
    LD SP, #0xA000
    IM 1 
    
    LD A, #0x03
    OUT (0xFF), A

    JP _init_and_main

_i2c_start:
    LD A, #0x01
    OUT (0xFF), A
    LD A, #0x00
    OUT (0xFF), A
    RET

_i2c_stop:
    LD A, #0x00
    OUT (0xFF), A
    LD A, #0x01
    OUT (0xFF), A
    LD A, #0x03
    OUT (0xFF), A
    RET

    .org 0x0038
_int_m1::
    PUSH AF
    
    LD A, (0x8401)
    OR A
    JR NZ, _int_done
    
    LD A, #1
    LD (0x8401), A
    LD A, #10
    LD (0x8402), A
    
_int_done:
    POP AF
    EI
    RETI

_i2c_write:
    LD B, #8
_write_loop:
    RLC C
    LD A, #0x00
    JR NC, _send_bit
    LD A, #0x02
_send_bit:
    OUT (0xFF), A
    INC A
    OUT (0xFF), A
    DEC A
    OUT (0xFF), A
    DJNZ _write_loop
    
    LD A, #0x02
    OUT (0xFF), A
    INC A
    OUT (0xFF), A
    DEC A
    OUT (0xFF), A
    RET

_ssd1306_Init:
    DI
    CALL _i2c_start
    LD C, #0x78
    CALL _i2c_write
    LD C, #0x00
    CALL _i2c_write
    
    LD HL, #_init_seq_data
    LD B, #14 
_init_loop:
    LD C, (HL)
    PUSH HL
    PUSH BC
    CALL _i2c_write
    POP BC
    POP HL
    INC HL
    DJNZ _init_loop

    CALL _i2c_stop
    RET

_init_seq_data:
    .db 0xAE
    .db 0x20, 0x00 
    .db 0x21, 0x00, 0x7F
    .db 0x22, 0x00, 0x07
    .db 0xA1
    .db 0xC8
    .db 0x8D, 0x14
    .db 0xAF

_ssd1306_UpdateScreen:
    CALL _i2c_start
    LD C, #0x78
    CALL _i2c_write
    LD C, #0x00 
    CALL _i2c_write
    
    LD C, #0x21 
    CALL _i2c_write
    LD C, #0x00
    CALL _i2c_write
    LD C, #0x7F
    CALL _i2c_write
    
    LD C, #0x22
    CALL _i2c_write
    LD C, #0x06
    CALL _i2c_write
    LD C, #0x07
    CALL _i2c_write
    CALL _i2c_stop
    
    CALL _i2c_start
    LD C, #0x78
    CALL _i2c_write
    LD C, #0x40
    CALL _i2c_write
    
    LD HL, #0x8300
    LD DE, #256 
_send_loop:
    LD C, (HL)
    PUSH DE
    CALL _i2c_write
    POP DE
    INC HL
    DEC DE
    LD A, D
    OR E
    JR NZ, _send_loop
    
    CALL _i2c_stop
    RET

_init_and_main:
    CALL _ssd1306_Init

    LD A, #120
    LD (0x8400), A
    XOR A
    LD (0x8401), A 
    LD (0x8402), A
    LD (0x8403), A

    EI

_game_loop:
    LD HL, #0x8000
    LD BC, #1024
_clear_loop:
    LD (HL), #0x00
    INC HL
    DEC BC
    LD A, B
    OR C
    JR NZ, _clear_loop

    LD HL, #0x8380
    LD B, #128
_floor_loop:
    LD (HL), #0x80
    INC HL
    DJNZ _floor_loop

    LD A, (0x8403)
    OR A
    JR Z, _not_game_over
    
    LD HL, #0x80B0 
    LD (HL), #0x3E
    INC H
    INC HL
    INC HL
    LD HL, #0x80D0
    LD (HL), #0x3E
    INC HL
    INC HL
    INC HL
    JP _draw_frame

_not_game_over:
    LD A, (0x8401)
    OR A
    JR NZ, _dino_jumping
    
    LD HL, #0x8394 
    LD (HL), #0xFF
    JR _draw_cactus

_dino_jumping:
    LD HL, #0x8314
    LD (HL), #0xFF
    
    LD A, (0x8402)
    DEC A
    LD (0x8402), A
    JR NZ, _draw_cactus
    XOR A
    LD (0x8401), A

_draw_cactus:
    LD A, (0x8400)
    LD L, A
    LD H, #0x00
    LD DE, #0x8380
    ADD HL, DE
    LD (HL), #0xFF

    LD A, (0x8400)
    SUB #4
    CP #121
    JR C, _cactus_ok
    LD A, #120
_cactus_ok:
    LD (0x8400), A

    LD A, (0x8400)
    CP #24
    JR NC, _draw_frame
    CP #9
    JR C, _draw_frame
    
    LD A, (0x8401)
    OR A
    JR NZ, _draw_frame
    
    LD A, #1
    LD (0x8403), A

_draw_frame:
    CALL _ssd1306_UpdateScreen
    JP _game_loop

    .area _GSINIT
    
_gsinit::
    .area _GSFINAL
    RET