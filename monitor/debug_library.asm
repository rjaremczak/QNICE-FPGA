;;
;;=======================================================================================
;; The collection of debugging routines starts here
;;=======================================================================================
;;
;
;***************************************************************************************
;* DBG$DISASM disassembles a single instruction pointed to by R8. R8 will be 
;* incremented according to the addressing modes used in the instruction.
;*
;* R8: Contains the address of the instruction to be disassembled
;*
;* R8 WILL BE CHANGED BY THIS FUNCTION!
;***************************************************************************************
;
DBG$DISASM          INCRB
                    RSUB    IO$PUT_W_HEX, 1
                    MOVE    R8, R0              ; Remember the address
                    MOVE    CHR$TAB, R8         ; Print a TAB character
                    RSUB    IO$PUTCHAR, 1
                    MOVE    @R0++, R1           ; Fetch the instruction
                    MOVE    R1, R8              ; Print the instruction code
                    RSUB    IO$PUT_W_HEX, 1
                    MOVE    CHR$TAB, R8         ; Print a TAB character
                    RSUB    IO$PUTCHAR, 1
                    MOVE    R1, R2              ; R1 contains the instruction
                    SHR     0x0009, R2          ; Get opcode * 8
                    AND     0x0078, R2          ; Filter out the unnecessary LSBs
                    CMP     0x0078, R2          ; Is it a branch/subroutine call?
                    RBRA    _DBG$DISASM_BRSU, Z ; Yes!
; Treat non-branch/subroutine calls:
                    MOVE    _DBG$MNEMONICS, R8  ; Get address of mnemonic array
                    ADD     R2, R8              ; Get pointer to mnemonic
                    RSUB    IO$PUTS, 1          ; Print mnemonic
                    MOVE    CHR$TAB, R8         ; Print a TAB character
                    RSUB    IO$PUTCHAR, 1
                    RSUB    _DBG$HANDLE_SOURCE, 1
; TODO: Treat normal instructions...

                    RBRA    _DBG$DISASM_EXIT, 1
; Tread branches and subroutine calls:
_DBG$DISASM_BRSU    MOVE    _DBG$BRSU_MNEMONICS, R8
                    RSUB    IO$PUTS, 1
; TODO: Treat branches/sr calls...

_DBG$DISASM_EXIT    RSUB    IO$PUT_CRLF, 1
                    MOVE    R0, R8              ; Restore address
                    DECRB
                    RET
;
;  The following routine prints out the source operand and expects R1 to contain
; the instruction and R0 to contain the address. If the operand is R15 indirect,
; R0 will be incremented.
;
_DBG$HANDLE_SOURCE  MOVE    R1, R2              ; Extract the source operand reg.#
                    AND     0x0F80, R2          ; Is it @R15++?
                    CMP     0x0F80, R2
                    RBRA    _DBG$HSRC_NO_CONST, !Z
; The source operand is @R15++, i.e. a constant:
                    MOVE    @R0++, R8           ; Get contents of next memory cell
                    RSUB    IO$PUT_W_HEX, 1     ; Print constant
                    RBRA    _DBG$HSRC_EXIT, 1
_DBG$HSRC_NO_CONST  MOVE    R1, R2
                    SHR     0x0006, R2          ; The two LSBs are now the mode bits
                    MOVE    R2, R3              ; R3 holds the mode bits
                    AND     0x0003, R3          ; ...and only the mode bits
                    CMP     0x0001, R3          ; Mode @Rxx?
                    RBRA    _DBG$HSRC_1, !Z     ; No!
                    MOVE    '@', R8             ; Print '@'
                    RSUB    IO$PUTCHAR, 1
                    RBRA    _DBG$HSRC_2, 1      ; No deal with the register number
_DBG$HSRC_1         CMP     0x0003, R3          ; Mode @--Rxx?
                    RBRA    _DBG$HSRC_2, !Z     ; No!
                    MOVE    _DBG$PREDECREMENT, R8
                    RSUB    IO$PUTS, 1
_DBG$HSRC_2         NOP

; TODO: Handle @, --, ++
                    

                    AND     0x003C, R2
                    MOVE    _DBG$REGISTERS, R8
                    ADD     R2, R8
                    RSUB    IO$PUTS, 1

_DBG$HSRC_EXIT      MOVE    _DBG$DELIMITER, R8  ; Print delimiter
                    RSUB    IO$PUTS, 1
                    RET
;
; All mnemonics are assumed to be eight characters long (including a 0-terminator)
_DBG$MNEMONICS      .ASCII_W    "MOVE   "
                    .ASCII_W    "ADD    "
                    .ASCII_W    "ADDC   "
                    .ASCII_W    "SUB    "
                    .ASCII_W    "SUBC   "
                    .ASCII_W    "SHL    "
                    .ASCII_W    "SHR    "
                    .ASCII_W    "SWAP   "
                    .ASCII_W    "NOT    "
                    .ASCII_W    "AND    "
                    .ASCII_W    "OR     "
                    .ASCII_W    "XOR    "
                    .ASCII_W    "CMP    "
                    .ASCII_W    "INT    "
                    .ASCII_W    "HALT   "
                    .ASCII_W    "BRSU   "       ; This is not really necessary
_DBG$BRSU_MNEMONICS .ASCII_W    "ABRA   "
                    .ASCII_W    "ASUB   "
                    .ASCII_W    "RBRA   "
                    .ASCII_W    "RSUB   "
; Register Names are expected to be four bytes long (including a 0-terminator)
_DBG$REGISTERS      .ASCII_W    "R0 "
                    .ASCII_W    "R1 "
                    .ASCII_W    "R2 "
                    .ASCII_W    "R3 "
                    .ASCII_W    "R4 "
                    .ASCII_W    "R5 "
                    .ASCII_W    "R6 "
                    .ASCII_W    "R7 "
                    .ASCII_W    "R8 "
                    .ASCII_W    "R9 "
                    .ASCII_W    "R10"
                    .ASCII_W    "R11"
                    .ASCII_W    "R12"
                    .ASCII_W    "R13"
                    .ASCII_W    "R14"
                    .ASCII_W    "R15"
_DBG$DELIMITER      .ASCII_W    ", "
_DBG$PREDECREMENT   .ASCII_W    "@--"
