;
;;=======================================================================================
;; The collection of USB-keyboard related functions starts here.
;;=======================================================================================
;
;
;***************************************************************************************
;* KBD$GETCHAR reads a character from the USB-keyboard.
;*
;* R8 will contain the character read in its lower eight bits.
;***************************************************************************************
;
KBD$GETCHAR     INCRB
                MOVE    IO$KBD_STATE, R0    ; R0 contains the address of the status register
                MOVE    IO$KBD_DATA, R1     ; R1 contains the address of the receiver reg.
_KBD$GETC_LOOP  MOVE    @R0, R2             ; Read status register
                AND     0x0001, R2          ; Only bit 0 is of interest
                RBRA    _KBD$GETC_LOOP, Z   ; Loop until a character has been received
                MOVE    @R1, R8             ; Get the character from the receiver register
                DECRB
                RET

