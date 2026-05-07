OLED_ADDR EQU 0x78

ORG 0000h 

START:
        LD SP, 0xA000
        
        CALL I2C_INIT
        CALL I2C_START

        LD C, OLED_ADDR
        CALL I2C_WRITE

        LD C, 0x00
        CALL I2C_WRITE

        LD HL, INIT_SEQ
        LD B, INIT_LEN
        CALL SEND_DATA
        CALL I2C_STOP

        CALL CLEAR_DISPLAY

        LD HL, MSG_SHALOM
        LD B, MSG_LEN

        CALL WRITE_DISPLAY

        HALT

WRITE_DISPLAY:
        CALL I2C_START

        LD C, OLED_ADDR
        CALL I2C_WRITE

        LD C, 0x40
        CALL I2C_WRITE

        CALL SEND_DATA
        CALL I2C_STOP

        RET

CLEAR_DISPLAY:
        CALL I2C_START
        LD C, OLED_ADDR
        CALL I2C_WRITE
        LD C, 0x40
        CALL I2C_WRITE

        LD HL, 1024
_clear_loop:
        LD C, 0x00
        CALL I2C_WRITE
        DEC HL 
        LD A, H
        OR L
        JR NZ, _clear_loop

        
        CALL I2C_STOP
        RET

SEND_DATA: 
        LD C, (HL)
        PUSH BC
        CALL I2C_WRITE
        POP BC
        INC HL
        DJNZ SEND_DATA

        RET
        
I2C_WRITE: 
        LD B, 8
_write_loop:
        RLC C
        LD A, 0x00
        JR NC, _send_bit
        LD A, 0x02
_send_bit:
        OUT (0xFF), A
        INC A
        OUT (0xFF), A
        DEC A
        OUT (0xFF), A

        DJNZ _write_loop

        LD A, 0x02
        OUT (0xFF), A
        LD A, 0x03
        OUT (0xFF), A
        LD A, 0x02
        OUT (0xFF), A

        RET

I2C_INIT:
        LD A, 0xFF
        OUT (0xFF), A
        RET

I2C_START:
        LD A, 0x01
        OUT (0xFF), A
        LD A, 0x00
        OUT (0xFF), A

        RET

I2C_STOP:
        LD A, 0x00
        OUT (0xFF), A
        LD A, 0x01
        OUT (0xFF), A
        LD A, 0x03
        OUT (0xFF), A

        RET

INIT_SEQ:
        DB 0xAE
        DB 0x20, 0x00
        DB 0x21, 0x00, 0x7F
        DB 0x22, 0x00, 0x07
        DB 0xA1
        DB 0xC8
        DB 0x8D, 0x14
        DB 0xAF
INIT_LEN EQU $ - INIT_SEQ

MSG_SHALOM:
        DB 0x46, 0x49, 0x49, 0x49, 0x31, 0x00
        DB 0x7F, 0x08, 0x04, 0x04, 0x78, 0x00
        DB 0x20, 0x54, 0x54, 0x54, 0x78, 0x00
        DB 0x00, 0x41, 0x7F, 0x40, 0x00, 0x00
        DB 0x38, 0x44, 0x44, 0x44, 0x38, 0x00
        DB 0x7C, 0x04, 0x18, 0x04, 0x78, 0x00
        DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        DB 0x3F, 0x40, 0x38, 0x40, 0x3F, 0x00
        DB 0x38, 0x44, 0x44, 0x44, 0x38, 0x00
        DB 0x7C, 0x08, 0x04, 0x04, 0x08, 0x00
        DB 0x00, 0x41, 0x7F, 0x40, 0x00, 0x00
        DB 0x38, 0x44, 0x44, 0x48, 0x7F, 0x00
        DB 0x00, 0x00, 0x5F, 0x00, 0x00, 0x00
MSG_LEN EQU $ - MSG_SHALOM