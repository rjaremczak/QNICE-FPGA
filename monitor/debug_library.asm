;;
;;=======================================================================================
;; The collection of debugging routines starts here
;;
;; 29-AUG-2015      Bernd Ulmann    Initial version
;; 25-JUL-2020      Bernd Ulmann    Added support for HALT, RTI, and INT
;; 07-AUG-2020      Bernd Ulmann    RBRA/RSUB now displays the absolute destination addr.
;; 20-SEP-2020      Bernd Ulmann    Take care of the new EXC instruction
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
                    MOVE    ' ', R8             ; Print a delimiter
                    RSUB    IO$PUTCHAR, 1
                    MOVE    @R0++, R1           ; Fetch the instruction
                    MOVE    R1, R8              ; Print the instruction code
                    RSUB    IO$PUT_W_HEX, 1
                    MOVE    ' ', R8             ; Print a delimiter
                    RSUB    IO$PUTCHAR, 1
                    MOVE    R1, R2              ; R1 contains the instruction
                    AND     0xFFFB, SR          ; clear C (shift in '0')                    
                    SHR     0x0009, R2          ; Get opcode * 8
                    AND     0x0078, R2          ; Filter out the unnecessary LSBs
                    CMP     0x0070, R2          ; Is it a control instruction?
                    RBRA    _DBG$DISASM_CTRL, Z ; Yes. :-)
                    CMP     0x0078, R2          ; Is it a branch/subroutine call?
                    RBRA    _DBG$DISASM_BRSU, Z ; Yes!
; Treat non-branch/subroutine calls:
                    MOVE    _DBG$MNEMONICS, R8  ; Get address of mnemonic array
                    ADD     R2, R8              ; Get pointer to mnemonic
                    RSUB    IO$PUTS, 1          ; Print mnemonic
                    CMP     0x0070, R2          ; Is it HALT (shifted 3 to the left)?
                    RBRA    _DBG$DISASM_EXIT, Z ; Yes, do not fetch operands
                    MOVE    ' ', R8             ; Print a delimiter
                    RSUB    IO$PUTCHAR, 1
                    RSUB    _DBG$HANDLE_SOURCE, 1
                    RSUB    _DBG$HANDLE_DEST, 1
                    RBRA    _DBG$DISASM_EXIT, 1 ; Finished...
; Treat control instructions:
_DBG$DISASM_CTRL    MOVE    R1, R2              ; Determine the type of control instruction
                    AND     0x0800, R2          ; If bit 11 is set it is an EXC instruction
                    RBRA    _DBG$DISASM_NO_EXC, Z
                    MOVE    _DBG$EXC_MNEMONIC, R8
                    RSUB    IO$PUTS, 1          ; Print the mnemonic
                    MOVE    ' ', R8
                    RSUB    IO$PUTCHAR, 1       ; ...and a delimiter
                    MOVE    R1, R8              ; Refetch the instruction
                    AND     0xFFFB, SR          ; clear C (shift in '0')                                        
                    SHR     0x0006, R8          ; Get the constant
                    AND     0x001F, R8
                    RSUB    IO$PUT_W_HEX, 1
                    MOVE    ' ', R8
                    RSUB    IO$PUTCHAR, 1       ; Print another delimiter
                    RSUB    _DBG$HANDLE_DEST, 1
                    RBRA    _DBG$DISASM_EXIT, 1
_DBG$DISASM_NO_EXC  MOVE    R1, R2
                    AND     0xFFFB, SR          ; clear C (shift in '0')                    
                    SHR     0x0003, R2          ; Shift only three to the right as
                    AND     0x01F8, R2          ; each mnemonic is 8 characters long
                    MOVE    _DBG$CTRL_MNEMONICS, R8
                    ADD     R2, R8
                    RSUB    IO$PUTS, 1          ; Print mnemonic
                    MOVE    ' ', R8             ; Print a delimiter
                    RSUB    IO$PUTCHAR, 1
                    CMP     0x0010, R2          ; Was the instruction INT?
                    RBRA    _DBG$DISASM_EXIT, !Z; No, so we are finished here
                    RSUB    _DBG$HANDLE_DEST, 1 ; Take care of the destination operand
                    RBRA    _DBG$DISASM_EXIT, 1 ; Finished
; Treat branches and subroutine calls:
_DBG$DISASM_BRSU    MOVE    R1, R2              ; Determine branch/call type
                    AND     0xFFFB, SR          ; clear C (shift in '0')
                    SHR     0x0001, R2
                    AND     0x0018, R2          ; 00...00MM000, M = mode
                    MOVE    _DBG$BRSU_MNEMONICS, R8
                    ADD     R2, R8
                    RSUB    IO$PUTS, 1          ; Print mnemonic
                    MOVE    ' ', R8             ; Print a delimiter
                    RSUB    IO$PUTCHAR, 1
                    RSUB    _DBG$HANDLE_SOURCE, 1
                    MOVE    R1, R2              ; Reread instruction
                    AND     0x0008, R2          ; Determine negation flag
                    RBRA    _DBG$NO_NEGATE, Z   ; No negation
                    MOVE    '!', R8
                    RSUB    IO$PUTCHAR, 1
_DBG$NO_NEGATE      MOVE    R1, R2              ; No side effects...
                    AND     0x0007, R2          ; Get condition codes
                    MOVE    _DBG$CONDITIONCODES, R3
                    ADD     R2, R3
                    MOVE    @R3, R8
                    RSUB    IO$PUTCHAR, 1       ; Print condition code
; Compute and display the destination address in case of RSUB/RBRA
                    MOVE    R1, R2              ; Remember the instruction
                    AND     0xFFA0, R2          ; Check if it is RBRA/RSUB
                    CMP     0xFFA0, R2
                    RBRA    _DBG$DISASM_EXIT, !Z
                    MOVE    _DBG$REL_S, R8
                    RSUB    IO$PUTS, 1          ; Print "   ("
                    MOVE    R0, R8              ; Get current address
                    MOVE    @--R8, R8           ; Get relative address 
                    ADD     R0, R8              ; Add current address
                    RSUB    IO$PUT_W_HEX, 1     ; Print address
                    MOVE    ')', R8
                    RSUB    IO$PUTCHAR, 1

_DBG$DISASM_EXIT    RSUB    IO$PUT_CRLF, 1
                    MOVE    R0, R8              ; Restore address
                    DECRB
                    RET
_DBG$REL_S          .ASCII_W    "\t\t(-> "
;
;  The following routine prints out the source operand and expects R1 to contain
; the instruction and R0 to contain the address. If the operand is R15 indirect,
; R0 will be incremented.
;
_DBG$HANDLE_SOURCE  MOVE    R1, R4              ; Prepare the source operand
                    AND     0xFFFB, SR          ; clear C (shift in '0')
                    SHR     0x0006, R4
;
;  This routine does the actual operand decoding and is used for source and
; destination operands as well.
;
_DBG$HANDLE_OPERAND MOVE    R4, R2              ; Extract the source operand reg.#
                    AND     0x003E, R2          ; Is it @R15++?
                    CMP     0x003E, R2
                    RBRA    _DBG$HSRC_NO_CONST, !Z
; The source operand is @R15++, i.e. a constant:
                    MOVE    @R0++, R8           ; Get contents of next memory cell
                    RSUB    IO$PUT_W_HEX, 1     ; Print constant
                    RBRA    _DBG$HSRC_EXIT, 1
; The source operand is something else:
_DBG$HSRC_NO_CONST  MOVE    R4, R2              ; Get instruction again
                    MOVE    R2, R3              ; R3 holds the mode bits
                    AND     0x0003, R3          ; ...and only the mode bits
                    MOVE    R3, R3              ; Is the mode == 0?
                    RBRA    _DBG$HSRC_0, Z      ; Yes -> direct mode, no '@'
                    MOVE    '@', R8             ; Print a '@'-character
                    RSUB    IO$PUTCHAR, 1
                    CMP     0x0003, R3          ; Is is @--?
                    RBRA    _DBG$HSRC_0, !Z     ; No...
                    MOVE    _DBG$DECREMENT, R8
                    RSUB    IO$PUTS, 1
_DBG$HSRC_0         AND     0x003C, R2          ; Get offset into register name array
                    MOVE    _DBG$REGISTERS, R8
                    ADD     R2, R8              ; Determine entry point
                    RSUB    IO$PUTS, 1          ; Print register name
                    CMP     0x0002, R3          ; Was the mode @Rxx++?
                    RBRA    _DBG$HSRC_EXIT, !Z  ; No
                    MOVE    _DBG$INCREMENT, R8  ; Print '++'
                    RSUB    IO$PUTS, 1
_DBG$HSRC_EXIT      MOVE    ' ', R8             ; Print delimiter
                    RSUB    IO$PUTCHAR, 1
                    RET
;
;  The following routine uses _DBG$HANDLE_SOURCE to handle the destination parameter.
;
_DBG$HANDLE_DEST    MOVE    R1, R4
                    RBRA    _DBG$HANDLE_OPERAND, 1
;
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
                    .ASCII_W    "rsrvd  "
                    .ASCII_W    "CTRL   "       ; This is not really necessary
_DBG$CTRL_MNEMONICS .ASCII_W    "HALT   "
                    .ASCII_W    "RTI    "
                    .ASCII_W    "INT    "
                    .ASCII_W    "INCRB  "
                    .ASCII_W    "DECRB  "
_DBG$EXC_MNEMONIC   .ASCII_W    "EXC    "       ; EXC is pretty special
                    .ASCII_W    "BRSU   "       ; This also is not really necessary
_DBG$BRSU_MNEMONICS .ASCII_W    "ABRA   "
                    .ASCII_W    "ASUB   "
                    .ASCII_W    "RBRA   "
                    .ASCII_W    "RSUB   "
_DBG$CONDITIONCODES .ASCII_P    "1XCZNVIM"      ; Condition codes for branches/calls
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
_DBG$DECREMENT      .ASCII_W    "--"
_DBG$INCREMENT      .ASCII_W    "++"
