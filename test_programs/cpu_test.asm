// Extended CPU test

#include "../dist_kit/sysdef.asm"
#include "../dist_kit/monitor.def"

                .ORG    0x8000

// This is a comprehensive test suite of the QNICE processor.
// The QNICE processor has 18 different instructions, 4 different addressing
// modes, and 5 different status flags.
// Making an exhaustive test of all possible combinations of the three
// different paramterss is too big.
// Instead, this program tests all combinations of all pairs of parameters.
// In other words, it tests:
// * All combinations of instructions and status flags.
// * All combinations of instructions and addressing modes.
// * All combinations of addressing modes and status flags.

// We can't explicitly test the HALT instruction, so we must just assume that
// it works as expected.

// Tests in this file:
// UNC      : Test unconditional absolute and relative branches
// R14_ST   : Test that moving data into R14 sets the correct status bits
// MOVE_IMM : Test the MOVE immediate instruction, and the X, Z, and N-conditional branches
// MOVE_REG : Test the MOVE register instruction, and the X, Z, and N-conditional branches
// CMP_IMM  : Test compare with immediate value and Z-conditional absolute branch
// CMP_REG  : Test compare between two registers and Z-conditional relative branch
// REG_13   : Test all 13 registers can contain different values
// ADD      : Test the ADD instruction, and the status register
// MOVE_CV  : Test the MOVE instruction doesn't change C and V flags
// MOVE_MEM : Test the MOVE instruction to/from a memory address
// ADDC     : Test the ADDC instruction with and without carry

// More tests to do:
// Test that PC is the same as R15
//

// Instruction | Flags affected
//             | V | N | Z | C | X |
// MOVE        | . | * | * | . | * |
// ADD/SUB     | * | * | * | * | * |
// SHL         | . | . | . | * | . |
// SHR         | . | . | . | . | * |
// SWAP        | . | * | * | . | * |
// NOT         | . | * | * | . | * |
// AND/OR/XOR  | . | * | * | . | * |
// CMP         | * | * | * | 0 | 0 |
// BRA/SUB     | . | . | . | . | . |


// ---------------------------------------------------------------------------
// Test unconditional absolute and relative branches.

L_UNC_0         ABRA    E_UNC_1, !1             // Verify "absolute branch never" is not taken.

                ABRA    L_UNC_1, 1              // Verify "absolute branch always" is taken.
                HALT

E_UNC_1         HALT

E_UNC_2         HALT

L_UNC_2         RBRA    L_UNC_3, 1              // Verify "relative branch always" is taken in the forward direction.
                HALT

L_UNC_1         RBRA    E_UNC_2, !1             // Verify "relative branch never" is not taken.
                RBRA    L_UNC_2, 1              // Verify "relative branch always" is taken in the backward direction.
                HALT

L_UNC_3


// ---------------------------------------------------------------------------
// Test that moving data into R14 sets the correct status bits

L_R14_ST_00     MOVE    0x00FF, R14                // Set all bits in the status register
                RBRA    E_R14_ST_01, !V            // Verify "relative branch nonoverflow" is not taken.
                RBRA    L_R14_ST_01, V             // Verify "relative branch overflow" is taken.
E_R14_ST_01     HALT
L_R14_ST_01
                RBRA    E_R14_ST_02, !N            // Verify "relative branch nonnegative" is not taken.
                RBRA    L_R14_ST_02, N             // Verify "relative branch negative" is taken.
E_R14_ST_02     HALT
L_R14_ST_02
                RBRA    E_R14_ST_03, !Z            // Verify "relative branch nonzero" is not taken.
                RBRA    L_R14_ST_03, Z             // Verify "relative branch zero" is taken.
E_R14_ST_03     HALT
L_R14_ST_03
                RBRA    E_R14_ST_04, !C            // Verify "relative branch noncarry" is not taken.
                RBRA    L_R14_ST_04, C             // Verify "relative branch carry" is taken.
E_R14_ST_04     HALT
L_R14_ST_04
                RBRA    E_R14_ST_05, !X            // Verify "relative branch nonX" is not taken.
                RBRA    L_R14_ST_05, X             // Verify "relative branch X" is taken.
E_R14_ST_05     HALT
L_R14_ST_05
                RBRA    E_R14_ST_06, !1            // Verify "relative branch never" is not taken.
                RBRA    L_R14_ST_06, 1             // Verify "relative branch always" is taken.
E_R14_ST_06     HALT
L_R14_ST_06

L_R14_ST_10     MOVE    0x0000, R14                // Clear all bits in the status register
                RBRA    E_R14_ST_11, V             // Verify "relative branch overflow" is not taken.
                RBRA    L_R14_ST_11, !V            // Verify "relative branch nonoverflow" is taken.
E_R14_ST_11     HALT
L_R14_ST_11
                RBRA    E_R14_ST_12, N             // Verify "relative branch negative" is not taken.
                RBRA    L_R14_ST_12, !N            // Verify "relative branch nonnegative" is taken.
E_R14_ST_12     HALT
L_R14_ST_12
                RBRA    E_R14_ST_13, Z             // Verify "relative branch zero" is not taken.
                RBRA    L_R14_ST_13, !Z            // Verify "relative branch nonzero" is taken.
E_R14_ST_13     HALT
L_R14_ST_13
                RBRA    E_R14_ST_14, C             // Verify "relative branch carry" is not taken.
                RBRA    L_R14_ST_14, !C            // Verify "relative branch noncarry" is taken.
E_R14_ST_14     HALT
L_R14_ST_14
                RBRA    E_R14_ST_15, X             // Verify "relative branch X" is not taken.
                RBRA    L_R14_ST_15, !X            // Verify "relative branch nonX" is taken.
E_R14_ST_15     HALT
L_R14_ST_15
                RBRA    E_R14_ST_16, !1            // Verify "relative branch never" is not taken.
                RBRA    L_R14_ST_16, 1             // Verify "relative branch always" is taken.
E_R14_ST_16     HALT
L_R14_ST_16



// ---------------------------------------------------------------------------
// Test the MOVE immediate instruction, and the X, Z, and N-conditional branches

L_MOVE_IMM_00   MOVE    0x1234, R0
                ABRA    E_MOVE_IMM_01, Z        // Verify "absolute branch zero" is not taken.
                ABRA    L_MOVE_IMM_01, !Z       // Verify "absolute branch nonzero" is taken.
E_MOVE_IMM_01   HALT
L_MOVE_IMM_01
                ABRA    E_MOVE_IMM_02, N        // Verify "absolute branch negative" is not taken.
                ABRA    L_MOVE_IMM_02, !N       // Verify "absolute branch nonnegative" is taken.
E_MOVE_IMM_02   HALT
L_MOVE_IMM_02
                ABRA    E_MOVE_IMM_03, X        // Verify "absolute branch X" is not taken.
                ABRA    L_MOVE_IMM_03, !X       // Verify "absolute branch nonX" is taken.
E_MOVE_IMM_03   HALT
L_MOVE_IMM_03
                ABRA    E_MOVE_IMM_04, !1       // Verify "absolute branch never" is not taken.
                ABRA    L_MOVE_IMM_04, 1        // Verify "absolute branch always" is taken.
E_MOVE_IMM_04   HALT
L_MOVE_IMM_04


L_MOVE_IMM_10   MOVE    0x0000, R0
                ABRA    E_MOVE_IMM_11, !Z       // Verify "absolute branch nonzero" is not taken.
                ABRA    L_MOVE_IMM_11, Z        // Verify "absolute branch zero" is taken.
E_MOVE_IMM_11   HALT
L_MOVE_IMM_11
                ABRA    E_MOVE_IMM_12, N        // Verify "absolute branch negative" is not taken.
                ABRA    L_MOVE_IMM_12, !N       // Verify "absolute branch nonnegative" is taken.
E_MOVE_IMM_12   HALT
L_MOVE_IMM_12
                ABRA    E_MOVE_IMM_13, X        // Verify "absolute branch X" is not taken.
                ABRA    L_MOVE_IMM_13, !X       // Verify "absolute branch nonX" is taken.
E_MOVE_IMM_13   HALT
L_MOVE_IMM_13
                ABRA    E_MOVE_IMM_14, !1       // Verify "absolute branch never" is not taken.
                ABRA    L_MOVE_IMM_14, 1        // Verify "absolute branch always" is taken.
E_MOVE_IMM_14   HALT
L_MOVE_IMM_14


L_MOVE_IMM_20   MOVE    0xFEDC, R0
                ABRA    E_MOVE_IMM_21, Z        // Verify "absolute branch zero" is not taken.
                ABRA    L_MOVE_IMM_21, !Z       // Verify "absolute branch nonzero" is taken.
E_MOVE_IMM_21   HALT
L_MOVE_IMM_21
                ABRA    E_MOVE_IMM_22, !N       // Verify "absolute branch nonnegative" is not taken.
                ABRA    L_MOVE_IMM_22, N        // Verify "absolute branch negative" is taken.
E_MOVE_IMM_22   HALT
L_MOVE_IMM_22
                ABRA    E_MOVE_IMM_23, X        // Verify "absolute branch X" is not taken.
                ABRA    L_MOVE_IMM_23, !X       // Verify "absolute branch nonX" is taken.
E_MOVE_IMM_23   HALT
L_MOVE_IMM_23
                ABRA    E_MOVE_IMM_24, !1       // Verify "absolute branch never" is not taken.
                ABRA    L_MOVE_IMM_24, 1        // Verify "absolute branch always" is taken.
E_MOVE_IMM_24   HALT
L_MOVE_IMM_24


L_MOVE_IMM_30   MOVE    0xFFFF, R0
                ABRA    E_MOVE_IMM_31, Z        // Verify "absolute branch zero" is not taken.
                ABRA    L_MOVE_IMM_31, !Z       // Verify "absolute branch nonzero" is taken.
E_MOVE_IMM_31   HALT
L_MOVE_IMM_31
                ABRA    E_MOVE_IMM_32, !N       // Verify "absolute branch nonnegative" is not taken.
                ABRA    L_MOVE_IMM_32, N        // Verify "absolute branch negative" is taken.
E_MOVE_IMM_32   HALT
L_MOVE_IMM_32
                ABRA    E_MOVE_IMM_33, !X       // Verify "absolute branch nonX" is not taken.
                ABRA    L_MOVE_IMM_33, X        // Verify "absolute branch X" is taken.
E_MOVE_IMM_33   HALT
L_MOVE_IMM_33
                ABRA    E_MOVE_IMM_34, !1       // Verify "absolute branch never" is not taken.
                ABRA    L_MOVE_IMM_34, 1        // Verify "absolute branch always" is taken.
E_MOVE_IMM_34   HALT
L_MOVE_IMM_34


// ---------------------------------------------------------------------------
// Test the MOVE register instruction, and the X, Z, and N-conditional branches

L_MOVE_REG_00   MOVE    0x1234, R1
                MOVE    0x0000, R2
                MOVE    0xFEDC, R3
                MOVE    0xFFFF, R4

                MOVE    R1, R0
                RBRA    E_MOVE_REG_01, Z        // Verify "absolute branch zero" is not taken.
                RBRA    L_MOVE_REG_01, !Z       // Verify "absolute branch nonzero" is taken.
E_MOVE_REG_01   HALT
L_MOVE_REG_01
                RBRA    E_MOVE_REG_02, N        // Verify "absolute branch negative" is not taken.
                RBRA    L_MOVE_REG_02, !N       // Verify "absolute branch nonnegative" is taken.
E_MOVE_REG_02   HALT
L_MOVE_REG_02
                RBRA    E_MOVE_REG_03, X        // Verify "absolute branch X" is not taken.
                RBRA    L_MOVE_REG_03, !X       // Verify "absolute branch nonX" is taken.
E_MOVE_REG_03   HALT
L_MOVE_REG_03
                RBRA    E_MOVE_REG_04, !1       // Verify "absolute branch never" is not taken.
                RBRA    L_MOVE_REG_04, 1        // Verify "absolute branch always" is taken.
E_MOVE_REG_04   HALT
L_MOVE_REG_04


L_MOVE_REG_10   MOVE    R2, R0
                RBRA    E_MOVE_REG_11, !Z       // Verify "absolute branch nonzero" is not taken.
                RBRA    L_MOVE_REG_11, Z        // Verify "absolute branch zero" is taken.
E_MOVE_REG_11   HALT
L_MOVE_REG_11
                RBRA    E_MOVE_REG_12, N        // Verify "absolute branch negative" is not taken.
                RBRA    L_MOVE_REG_12, !N       // Verify "absolute branch nonnegative" is taken.
E_MOVE_REG_12   HALT
L_MOVE_REG_12
                RBRA    E_MOVE_REG_13, X        // Verify "absolute branch X" is not taken.
                RBRA    L_MOVE_REG_13, !X       // Verify "absolute branch nonX" is taken.
E_MOVE_REG_13   HALT
L_MOVE_REG_13
                RBRA    E_MOVE_REG_14, !1       // Verify "absolute branch never" is not taken.
                RBRA    L_MOVE_REG_14, 1        // Verify "absolute branch always" is taken.
E_MOVE_REG_14   HALT
L_MOVE_REG_14


L_MOVE_REG_20   MOVE    R3, R0
                RBRA    E_MOVE_REG_21, Z        // Verify "absolute branch zero" is not taken.
                RBRA    L_MOVE_REG_21, !Z       // Verify "absolute branch nonzero" is taken.
E_MOVE_REG_21   HALT
L_MOVE_REG_21
                RBRA    E_MOVE_REG_22, !N       // Verify "absolute branch nonnegative" is not taken.
                RBRA    L_MOVE_REG_22, N        // Verify "absolute branch negative" is taken.
E_MOVE_REG_22   HALT
L_MOVE_REG_22
                RBRA    E_MOVE_REG_23, X        // Verify "absolute branch X" is not taken.
                RBRA    L_MOVE_REG_23, !X       // Verify "absolute branch nonX" is taken.
E_MOVE_REG_23   HALT
L_MOVE_REG_23
                RBRA    E_MOVE_REG_24, !1       // Verify "absolute branch never" is not taken.
                RBRA    L_MOVE_REG_24, 1        // Verify "absolute branch always" is taken.
E_MOVE_REG_24   HALT
L_MOVE_REG_24


L_MOVE_REG_30   MOVE    R4, R0
                RBRA    E_MOVE_REG_31, Z        // Verify "absolute branch zero" is not taken.
                RBRA    L_MOVE_REG_31, !Z       // Verify "absolute branch nonzero" is taken.
E_MOVE_REG_31   HALT
L_MOVE_REG_31
                RBRA    E_MOVE_REG_32, !N       // Verify "absolute branch nonnegative" is not taken.
                RBRA    L_MOVE_REG_32, N        // Verify "absolute branch negative" is taken.
E_MOVE_REG_32   HALT
L_MOVE_REG_32
                RBRA    E_MOVE_REG_33, !X       // Verify "absolute branch nonX" is not taken.
                RBRA    L_MOVE_REG_33, X        // Verify "absolute branch X" is taken.
E_MOVE_REG_33   HALT
L_MOVE_REG_33
                RBRA    E_MOVE_REG_34, !1       // Verify "absolute branch never" is not taken.
                RBRA    L_MOVE_REG_34, 1        // Verify "absolute branch always" is taken.
E_MOVE_REG_34   HALT
L_MOVE_REG_34


// ---------------------------------------------------------------------------
// Test compare with immediate value and Z-conditional absolute branch

L_CMP_IMM_0     MOVE    0x1234, R0
                MOVE    0x4321, R1

// Compare R0 with correct value.
                CMP     0x1234, R0
                ABRA    E_CMP_IMM_1, !Z         // Verify "absolute branch nonzero" is not taken.
                ABRA    L_CMP_IMM_1, Z          // Verify "absolute branch zero" is taken.
E_CMP_IMM_1     HALT
L_CMP_IMM_1
                CMP     R0, 0x1234
                ABRA    E_CMP_IMM_2, !Z         // Verify "absolute branch nonzero" is not taken.
                ABRA    L_CMP_IMM_2, Z          // Verify "absolute branch zero" is taken.
E_CMP_IMM_2     HALT
L_CMP_IMM_2

// Compare R1 with correct value.
                CMP     0x4321, R1
                ABRA    E_CMP_IMM_3, !Z         // Verify "absolute branch nonzero" is not taken.
                ABRA    L_CMP_IMM_3, Z          // Verify "absolute branch zero" is taken.
E_CMP_IMM_3     HALT
L_CMP_IMM_3
                CMP     R1, 0x4321
                ABRA    E_CMP_IMM_4, !Z         // Verify "absolute branch nonzero" is not taken.
                ABRA    L_CMP_IMM_4, Z          // Verify "absolute branch zero" is taken.
E_CMP_IMM_4     HALT
L_CMP_IMM_4

// Compare R1 with incorrect value.
                CMP     0x1234, R1
                ABRA    E_CMP_IMM_5, Z          // Verify "absolute branch zero" is not taken.
                ABRA    L_CMP_IMM_5, !Z         // Verify "absolute branch nonzero" is taken.
E_CMP_IMM_5     HALT
L_CMP_IMM_5
                CMP     R1, 0x1234
                ABRA    E_CMP_IMM_6, Z          // Verify "absolute branch zero" is not taken.
                ABRA    L_CMP_IMM_6, !Z         // Verify "absolute branch nonzero" is taken.
E_CMP_IMM_6     HALT
L_CMP_IMM_6
                MOVE    R0, R1
// Compare R1 with correct value.
                CMP     0x1234, R1
                ABRA    E_CMP_IMM_7, !Z         // Verify "absolute branch nonzero" is not taken.
                ABRA    L_CMP_IMM_7, Z          // Verify "absolute branch zero" is taken.
E_CMP_IMM_7     HALT
L_CMP_IMM_7
                CMP     R1, 0x1234
                ABRA    E_CMP_IMM_8, !Z         // Verify "absolute branch nonzero" is not taken.
                ABRA    L_CMP_IMM_8, Z          // Verify "absolute branch zero" is taken.
E_CMP_IMM_8     HALT
L_CMP_IMM_8


// ---------------------------------------------------------------------------
// Test compare between two registers and Z-conditional relative branch

L_CMP_REG_0     MOVE    0x1234, R0
                MOVE    0x4321, R1

// Compare registers with different values.
                CMP     R0, R1
                RBRA    E_CMP_REG_1, Z          // Verify "relative branch zero" is not taken.
                RBRA    L_CMP_REG_1, !Z         // Verify "relative branch nonzero" is taken.
E_CMP_REG_1     HALT
L_CMP_REG_1
                CMP     R1, R0
                RBRA    E_CMP_REG_2, Z          // Verify "relative branch zero" is not taken.
                RBRA    L_CMP_REG_2, !Z         // Verify "relative branch nonzero" is taken.
E_CMP_REG_2     HALT
L_CMP_REG_2
                MOVE    R1, R0

// Compare registers with equal values.
                CMP     R0, R1
                RBRA    E_CMP_REG_3, !Z         // Verify "relative branch nonzero" is not taken.
                RBRA    L_CMP_REG_3, Z          // Verify "relative branch zero" is taken.
E_CMP_REG_3     HALT
L_CMP_REG_3
                CMP     R1, R0
                RBRA    E_CMP_REG_4, !Z         // Verify "relative branch nonzero" is not taken.
                RBRA    L_CMP_REG_4, Z          // Verify "relative branch zero" is taken.
E_CMP_REG_4     HALT
L_CMP_REG_4


// REG_13   : Test all 13 registers can contain different values
L_REG_13_00     MOVE    0x0123, R0
                MOVE    0x1234, R1
                MOVE    0x2345, R2
                MOVE    0x3456, R3
                MOVE    0x4567, R4
                MOVE    0x5678, R5
                MOVE    0x6789, R6
                MOVE    0x789A, R7
                MOVE    0x89AB, R8
                MOVE    0x9ABC, R9
                MOVE    0xABCD, R10
                MOVE    0xBCDE, R11
                MOVE    0xCDEF, R12

                CMP     0x0123, R0
                RBRA    E_REG_13_00, !Z
                CMP     0x1234, R1
                RBRA    E_REG_13_00, !Z
                CMP     0x2345, R2
                RBRA    E_REG_13_00, !Z
                CMP     0x3456, R3
                RBRA    E_REG_13_00, !Z
                CMP     0x4567, R4
                RBRA    E_REG_13_00, !Z
                CMP     0x5678, R5
                RBRA    E_REG_13_00, !Z
                CMP     0x6789, R6
                RBRA    E_REG_13_00, !Z
                CMP     0x789A, R7
                RBRA    E_REG_13_00, !Z
                CMP     0x89AB, R8
                RBRA    E_REG_13_00, !Z
                CMP     0x9ABC, R9
                RBRA    E_REG_13_00, !Z
                CMP     0xABCD, R10
                RBRA    E_REG_13_00, !Z
                CMP     0xBCDE, R11
                RBRA    E_REG_13_00, !Z
                CMP     0xCDEF, R12
                RBRA    E_REG_13_00, !Z
                RBRA    L_REG_13_01, 1
E_REG_13_00     HALT
L_REG_13_01


// ---------------------------------------------------------------------------
// Test the ADD instruction, and the status register
// Addition                 | V | N | Z | C | X | 1 |
// 0x1234 + 0x4321 = 0x5555 | 0 | 0 | 0 | 0 | 0 | 1 | ADD_0
// 0x8765 + 0x9876 = 0x1FDB | 1 | 0 | 0 | 1 | 0 | 1 | ADD_1
// 0x1234 + 0x9876 = 0xAAAA | 0 | 1 | 0 | 0 | 0 | 1 | ADD_2
// 0xFEDC + 0xEDCB = 0xECA7 | 0 | 1 | 0 | 1 | 0 | 1 | ADD_3
// 0xFEDC + 0x0123 = 0xFFFF | 0 | 1 | 0 | 0 | 1 | 1 | ADD_4
// 0xFEDC + 0x0124 = 0x0000 | 0 | 0 | 1 | 1 | 0 | 1 | ADD_5
// 0x7654 + 0x6543 = 0xDB97 | 1 | 1 | 0 | 0 | 0 | 1 | ADD_6

// Addition                 | V | N | Z | C | X | 1 |
// 0x1234 + 0x4321 = 0x5555 | 0 | 0 | 0 | 0 | 0 | 1 | ADD_0

                MOVE    0x0000, R14             // Clear status register

L_ADD_00        MOVE    0x1234, R0
                ADD     0x4321, R0

                RBRA    E_ADD_01, V             // Verify "relative branch overflow" is not taken.
                RBRA    L_ADD_01, !V            // Verify "relative branch nonoverflow" is taken.
E_ADD_01        HALT
L_ADD_01
                RBRA    E_ADD_02, N             // Verify "relative branch negative" is not taken.
                RBRA    L_ADD_02, !N            // Verify "relative branch nonnegative" is taken.
E_ADD_02        HALT
L_ADD_02
                RBRA    E_ADD_03, Z             // Verify "relative branch zero" is not taken.
                RBRA    L_ADD_03, !Z            // Verify "relative branch nonzero" is taken.
E_ADD_03        HALT
L_ADD_03
                RBRA    E_ADD_04, C             // Verify "relative branch carry" is not taken.
                RBRA    L_ADD_04, !C            // Verify "relative branch noncarry" is taken.
E_ADD_04        HALT
L_ADD_04
                RBRA    E_ADD_05, X             // Verify "relative branch X" is not taken.
                RBRA    L_ADD_05, !X            // Verify "relative branch nonX" is taken.
E_ADD_05        HALT
L_ADD_05
                RBRA    E_ADD_06, !1            // Verify "relative branch never" is not taken.
                RBRA    L_ADD_06, 1             // Verify "relative branch always" is taken.
E_ADD_06        HALT
L_ADD_06
                MOVE    R14, R1                 // Verify status register: --000001
                CMP     0x0001, R1
                RBRA    E_ADD_07, !Z
                RBRA    L_ADD_07, Z
E_ADD_07        HALT
L_ADD_07
                CMP     0x5555, R0              // Verify result
                RBRA    E_ADD_08, !Z
                RBRA    L_ADD_08, Z
E_ADD_08        HALT
L_ADD_08


// Addition                 | V | N | Z | C | X | 1 |
// 0x8765 + 0x9876 = 0x1FDB | 1 | 0 | 0 | 1 | 0 | 1 | ADD_1
L_ADD_10        MOVE    0x8765, R0
                ADD     0x9876, R0

                RBRA    E_ADD_11, !V            // Verify "relative branch nonoverflow" is not taken.
                RBRA    L_ADD_11, V             // Verify "relative branch overflow" is taken.
E_ADD_11        HALT
L_ADD_11
                RBRA    E_ADD_12, N             // Verify "relative branch negative" is not taken.
                RBRA    L_ADD_12, !N            // Verify "relative branch nonnegative" is taken.
E_ADD_12        HALT
L_ADD_12
                RBRA    E_ADD_13, Z             // Verify "relative branch zero" is not taken.
                RBRA    L_ADD_13, !Z            // Verify "relative branch nonzero" is taken.
E_ADD_13        HALT
L_ADD_13
                RBRA    E_ADD_14, !C            // Verify "relative branch noncarry" is not taken.
                RBRA    L_ADD_14, C             // Verify "relative branch carry" is taken.
E_ADD_14        HALT
L_ADD_14
                RBRA    E_ADD_15, X             // Verify "relative branch X" is not taken.
                RBRA    L_ADD_15, !X            // Verify "relative branch nonX" is taken.
E_ADD_15        HALT
L_ADD_15
                RBRA    E_ADD_16, !1            // Verify "relative branch never" is not taken.
                RBRA    L_ADD_16, 1             // Verify "relative branch always" is taken.
E_ADD_16        HALT
L_ADD_16
                MOVE    R14, R1                 // Verify status register: --100101
                CMP     0x0025, R1
                RBRA    E_ADD_17, !Z
                RBRA    L_ADD_17, Z
E_ADD_17        HALT
L_ADD_17
                CMP     0x1FDB, R0
                RBRA    E_ADD_18, !Z
                RBRA    L_ADD_18, Z
E_ADD_18        HALT
L_ADD_18


// Addition                 | V | N | Z | C | X | 1 |
// 0x1234 + 0x9876 = 0xAAAA | 0 | 1 | 0 | 0 | 0 | 1 | ADD_2
L_ADD_20        MOVE    0x1234, R0
                ADD     0x9876, R0

                RBRA    E_ADD_21, V             // Verify "relative branch overflow" is not taken.
                RBRA    L_ADD_21, !V            // Verify "relative branch nonoverflow" is taken.
E_ADD_21        HALT
L_ADD_21
                RBRA    E_ADD_22, !N            // Verify "relative branch nonnegative" is not taken.
                RBRA    L_ADD_22, N             // Verify "relative branch negative" is taken.
E_ADD_22        HALT
L_ADD_22
                RBRA    E_ADD_23, Z             // Verify "relative branch zero" is not taken.
                RBRA    L_ADD_23, !Z            // Verify "relative branch nonzero" is taken.
E_ADD_23        HALT
L_ADD_23
                RBRA    E_ADD_24, C             // Verify "relative branch carry" is not taken.
                RBRA    L_ADD_24, !C            // Verify "relative branch noncarry" is taken.
E_ADD_24        HALT
L_ADD_24
                RBRA    E_ADD_25, X             // Verify "relative branch X" is not taken.
                RBRA    L_ADD_25, !X            // Verify "relative branch nonX" is taken.
E_ADD_25        HALT
L_ADD_25
                RBRA    E_ADD_26, !1            // Verify "relative branch never" is not taken.
                RBRA    L_ADD_26, 1             // Verify "relative branch always" is taken.
E_ADD_26        HALT
L_ADD_26
                MOVE    R14, R1                 // Verify status register: --010001
                CMP     0x0011, R1
                RBRA    E_ADD_27, !Z
                RBRA    L_ADD_27, Z
E_ADD_27        HALT
L_ADD_27
                CMP     0xAAAA, R0
                RBRA    E_ADD_28, !Z
                RBRA    L_ADD_28, Z
E_ADD_28        HALT
L_ADD_28


// Addition                 | V | N | Z | C | X | 1 |
// 0xFEDC + 0xEDCB = 0xECA7 | 0 | 1 | 0 | 1 | 0 | 1 | ADD_3
L_ADD_30        MOVE    0xFEDC, R0
                ADD     0xEDCB, R0

                RBRA    E_ADD_31, V             // Verify "relative branch overflow" is not taken.
                RBRA    L_ADD_31, !V            // Verify "relative branch nonoverflow" is taken.
E_ADD_31        HALT
L_ADD_31
                RBRA    E_ADD_32, !N            // Verify "relative branch nonnegative" is not taken.
                RBRA    L_ADD_32, N             // Verify "relative branch negative" is taken.
E_ADD_32        HALT
L_ADD_32
                RBRA    E_ADD_33, Z             // Verify "relative branch zero" is not taken.
                RBRA    L_ADD_33, !Z            // Verify "relative branch nonzero" is taken.
E_ADD_33        HALT
L_ADD_33
                RBRA    E_ADD_34, !C            // Verify "relative branch noncarry" is not taken.
                RBRA    L_ADD_34, C             // Verify "relative branch carry" is taken.
E_ADD_34        HALT
L_ADD_34
                RBRA    E_ADD_35, X             // Verify "relative branch X" is not taken.
                RBRA    L_ADD_35, !X            // Verify "relative branch nonX" is taken.
E_ADD_35        HALT
L_ADD_35
                RBRA    E_ADD_36, !1            // Verify "relative branch never" is not taken.
                RBRA    L_ADD_36, 1             // Verify "relative branch always" is taken.
E_ADD_36        HALT
L_ADD_36
                MOVE    R14, R1                 // Verify status register: --010101
                CMP     0x0015, R1
                RBRA    E_ADD_37, !Z
                RBRA    L_ADD_37, Z
E_ADD_37        HALT
L_ADD_37
                CMP     0xECA7, R0
                RBRA    E_ADD_38, !Z
                RBRA    L_ADD_38, Z
E_ADD_38        HALT
L_ADD_38


// Addition                 | V | N | Z | C | X | 1 |
// 0xFEDC + 0x0123 = 0xFFFF | 0 | 1 | 0 | 0 | 1 | 1 | ADD_4
L_ADD_40        MOVE    0xFEDC, R0
                ADD     0x0123, R0

                RBRA    E_ADD_41, V             // Verify "relative branch overflow" is not taken.
                RBRA    L_ADD_41, !V            // Verify "relative branch nonoverflow" is taken.
E_ADD_41        HALT
L_ADD_41
                RBRA    E_ADD_42, !N            // Verify "relative branch nonnegative" is not taken.
                RBRA    L_ADD_42, N             // Verify "relative branch negative" is taken.
E_ADD_42        HALT
L_ADD_42
                RBRA    E_ADD_43, Z             // Verify "relative branch zero" is not taken.
                RBRA    L_ADD_43, !Z            // Verify "relative branch nonzero" is taken.
E_ADD_43        HALT
L_ADD_43
                RBRA    E_ADD_44, C             // Verify "relative branch carry" is not taken.
                RBRA    L_ADD_44, !C            // Verify "relative branch noncarry" is taken.
E_ADD_44        HALT
L_ADD_44
                RBRA    E_ADD_45, !X            // Verify "relative branch nonX" is not taken.
                RBRA    L_ADD_45, X             // Verify "relative branch X" is taken.
E_ADD_45        HALT
L_ADD_45
                RBRA    E_ADD_46, !1            // Verify "relative branch never" is not taken.
                RBRA    L_ADD_46, 1             // Verify "relative branch always" is taken.
E_ADD_46        HALT
L_ADD_46
                MOVE    R14, R1                 // Verify status register: --010011
                CMP     0x0013, R1
                RBRA    E_ADD_47, !Z
                RBRA    L_ADD_47, Z
E_ADD_47        HALT
L_ADD_47
                CMP     0xFFFF, R0
                RBRA    E_ADD_48, !Z
                RBRA    L_ADD_48, Z
E_ADD_48        HALT
L_ADD_48


// Addition                 | V | N | Z | C | X | 1 |
// 0xFEDC + 0x0124 = 0x0000 | 0 | 0 | 1 | 1 | 0 | 1 | ADD_5
L_ADD_50        MOVE    0xFEDC, R0
                ADD     0x0124, R0

                RBRA    E_ADD_51, V             // Verify "relative branch overflow" is not taken.
                RBRA    L_ADD_51, !V            // Verify "relative branch nonoverflow" is taken.
E_ADD_51        HALT
L_ADD_51
                RBRA    E_ADD_52, N             // Verify "relative branch negative" is not taken.
                RBRA    L_ADD_52, !N            // Verify "relative branch nonnegative" is taken.
E_ADD_52        HALT
L_ADD_52
                RBRA    E_ADD_53, !Z            // Verify "relative branch nonzero" is not taken.
                RBRA    L_ADD_53, Z             // Verify "relative branch zero" is taken.
E_ADD_53        HALT
L_ADD_53
                RBRA    E_ADD_54, !C            // Verify "relative branch noncarry" is not taken.
                RBRA    L_ADD_54, C             // Verify "relative branch carry" is taken.
E_ADD_54        HALT
L_ADD_54
                RBRA    E_ADD_55, X             // Verify "relative branch X" is not taken.
                RBRA    L_ADD_55, !X            // Verify "relative branch nonX" is taken.
E_ADD_55        HALT
L_ADD_55
                RBRA    E_ADD_56, !1            // Verify "relative branch never" is not taken.
                RBRA    L_ADD_56, 1             // Verify "relative branch always" is taken.
E_ADD_56        HALT
L_ADD_56
                MOVE    R14, R1                 // Verify status register: --001101
                CMP     0x000D, R1
                RBRA    E_ADD_57, !Z
                RBRA    L_ADD_57, Z
E_ADD_57        HALT
L_ADD_57
                CMP     0x0000, R0
                RBRA    E_ADD_58, !Z
                RBRA    L_ADD_58, Z
E_ADD_58        HALT
L_ADD_58


// Addition                 | V | N | Z | C | X | 1 |
// 0x7654 + 0x6543 = 0xDB97 | 1 | 1 | 0 | 0 | 0 | 1 | ADD_6
L_ADD_60        MOVE    0x7654, R0
                ADD     0x6543, R0

                RBRA    E_ADD_61, !V            // Verify "relative branch nonoverflow" is not taken.
                RBRA    L_ADD_61, V             // Verify "relative branch overflow" is taken.
E_ADD_61        HALT
L_ADD_61
                RBRA    E_ADD_62, !N            // Verify "relative branch nonnegative" is not taken.
                RBRA    L_ADD_62, N             // Verify "relative branch negative" is taken.
E_ADD_62        HALT
L_ADD_62
                RBRA    E_ADD_63, Z             // Verify "relative branch zero" is not taken.
                RBRA    L_ADD_63, !Z            // Verify "relative branch nonzero" is taken.
E_ADD_63        HALT
L_ADD_63
                RBRA    E_ADD_64, C             // Verify "relative branch carry" is not taken.
                RBRA    L_ADD_64, !C            // Verify "relative branch noncarry" is taken.
E_ADD_64        HALT
L_ADD_64
                RBRA    E_ADD_65, X             // Verify "relative branch X" is not taken.
                RBRA    L_ADD_65, !X            // Verify "relative branch nonX" is taken.
E_ADD_65        HALT
L_ADD_65
                RBRA    E_ADD_66, !1            // Verify "relative branch never" is not taken.
                RBRA    L_ADD_66 1              // Verify "relative branch always" is taken.
E_ADD_66        HALT
L_ADD_66
                MOVE    R14, R1                 // Verify status register: --110001
                CMP     0x0031, R1
                RBRA    E_ADD_67, !Z
                RBRA    L_ADD_67, Z
E_ADD_67        HALT
L_ADD_67
                CMP     0xDB97, R0
                RBRA    E_ADD_68, !Z
                RBRA    L_ADD_68, Z
E_ADD_68        HALT
L_ADD_68


// ---------------------------------------------------------------------------
// Test the MOVE instruction doesn't change C and V flags.
L_MOVE_CV_00    MOVE    0x0000, R14             // Clear all bits in the status register

                MOVE    0x0000, R0              // Perform a MOVE instruction
                RBRA    E_MOVE_CV_01, V         // Verify "relative branch overflow" is not taken.
                RBRA    L_MOVE_CV_01, !V        // Verify "relative branch nonoverflow" is taken.
E_MOVE_CV_01    HALT
L_MOVE_CV_01
                RBRA    E_MOVE_CV_02, C         // Verify "relative branch carry" is not taken.
                RBRA    L_MOVE_CV_02, !C        // Verify "relative branch noncarry" is taken.
E_MOVE_CV_02    HALT
L_MOVE_CV_02

L_MOVE_CV_10    MOVE    0x00FF, R14             // Set all bits in the status register

                MOVE    0x0000, R0              // Perform a MOVE instruction
                RBRA    E_MOVE_CV_11, !V        // Verify "relative branch nonoverflow" is not taken.
                RBRA    L_MOVE_CV_11, V         // Verify "relative branch overflow" is taken.
E_MOVE_CV_11    HALT
L_MOVE_CV_11
                RBRA    E_MOVE_CV_12, !C        // Verify "relative branch noncarry" is not taken.
                RBRA    L_MOVE_CV_12, C         // Verify "relative branch carry" is taken.
E_MOVE_CV_12    HALT
L_MOVE_CV_12


// ---------------------------------------------------------------------------
// MOVE_MEM : Test the MOVE instruction to/from a memory address.

L_MOVE_MEM_00   MOVE    VAL1234, R0
                MOVE    VAL4321, R1
                MOVE    BSS0, R2
                MOVE    BSS1, R3
                MOVE    @R0, R4                 // Now R4 contains 0x1234
                MOVE    @R1, R5                 // Now R5 contains 0x4321

                CMP     R4, 0x1234
                RBRA    E_MOVE_MEM_01, !Z
                RBRA    L_MOVE_MEM_01, Z
E_MOVE_MEM_01   HALT
L_MOVE_MEM_01
                CMP     R5, 0x4321
                RBRA    E_MOVE_MEM_02, !Z
                RBRA    L_MOVE_MEM_02, Z
E_MOVE_MEM_02   HALT
L_MOVE_MEM_02

                MOVE    R4, @R2                 // Now BSS0 contains 0x1234
                MOVE    R5, @R3                 // Now BSS1 contains 0x4321

                CMP     R4, 0x1234              // R4 still contains 0x1234
                RBRA    E_MOVE_MEM_03, !Z
                RBRA    L_MOVE_MEM_03, Z
E_MOVE_MEM_03   HALT
L_MOVE_MEM_03
                CMP     R5, 0x4321              // R5 still contains 0x4321
                RBRA    E_MOVE_MEM_04, !Z
                RBRA    L_MOVE_MEM_04, Z
E_MOVE_MEM_04   HALT
L_MOVE_MEM_04

                MOVE    @R2, R5                 // Now R5 contains 0x1234
                MOVE    @R3, R4                 // Now R4 contains 0x4321

                CMP     R5, 0x1234
                RBRA    E_MOVE_MEM_05, !Z
                RBRA    L_MOVE_MEM_05, Z
E_MOVE_MEM_05   HALT
L_MOVE_MEM_05
                CMP     R4, 0x4321
                RBRA    E_MOVE_MEM_06, !Z
                RBRA    L_MOVE_MEM_06, Z
E_MOVE_MEM_06   HALT
L_MOVE_MEM_06



// ---------------------------------------------------------------------------
// Test the ADDC instruction
// Addition                     | V | N | Z | C | X | 1 |
// 0x1234 + 0x4321 + 0 = 0x5555 | 0 | 0 | 0 | 0 | 0 | 1 |
// 0x1234 + 0x9876 + 0 = 0xAAAA | 0 | 1 | 0 | 0 | 0 | 1 |
// 0x7654 + 0x6543 + 0 = 0xDB97 | 1 | 1 | 0 | 0 | 0 | 1 |
// 0x8765 + 0x9876 + 0 = 0x1FDB | 1 | 0 | 0 | 1 | 0 | 1 |
// 0xFEDC + 0x0123 + 0 = 0xFFFF | 0 | 1 | 0 | 0 | 1 | 1 |
// 0xFEDC + 0x0124 + 0 = 0x0000 | 0 | 0 | 1 | 1 | 0 | 1 |
// 0xFEDC + 0xEDCB + 0 = 0xECA7 | 0 | 1 | 0 | 1 | 0 | 1 |

// 0x1234 + 0x4321 + 1 = 0x5556 | 0 | 0 | 0 | 0 | 0 | 1 |
// 0x1234 + 0x9876 + 1 = 0xAAAB | 0 | 1 | 0 | 0 | 0 | 1 |
// 0x7654 + 0x6543 + 1 = 0xDB98 | 1 | 1 | 0 | 0 | 0 | 1 |
// 0x8765 + 0x9876 + 1 = 0x1FDC | 1 | 0 | 0 | 1 | 0 | 1 |
// 0xFEDC + 0x0122 + 1 = 0xFFFF | 0 | 1 | 0 | 0 | 1 | 1 |
// 0xFEDC + 0x0123 + 1 = 0x0000 | 0 | 0 | 1 | 1 | 0 | 1 |
// 0xFEDC + 0xEDCB + 1 = 0xECA8 | 0 | 1 | 0 | 1 | 0 | 1 |

L_ADDC_00       MOVE    STIM_ADDC, R8
L_ADDC_01       MOVE    @R8, R0                 // First operand
                RBRA    L_ADDC_02, Z            // End of test
                ADD     0x0001, R8
                MOVE    @R8, R1                 // Second operand
                ADD     0x0001, R8
                MOVE    @R8, R2                 // Carry input
                ADD     0x0001, R8
                MOVE    @R8, R3                 // Expected result
                ADD     0x0001, R8
                MOVE    @R8, R4                 // Expected status
                ADD     0x0001, R8

                MOVE    R2, R14                 // Set carry input
                ADDC    R0, R1
                MOVE    R14, R9                 // Copy status
                CMP     R1, R3                  // Verify expected result
                RBRA    E_ADDC_01, !Z           // Jump if error
                CMP     R9, R4                  // Verify expected status
                RBRA    L_ADDC_01, Z
E_ADDC_01       HALT
L_ADDC_02



// ---------------------------------------------------------------------------
// Test the SUB instruction
// Subtraction              | V | N | Z | C | X | 1 |
// 0x5678 - 0x4321 = 0x1357 | 0 | 0 | 0 | 0 | 0 | 1 |
// 0x5678 - 0x5678 = 0x0000 | 0 | 0 | 1 | 0 | 0 | 1 |
// 0x5678 - 0x5679 = 0xFFFF | 0 | 1 | 0 | 1 | 1 | 1 |
// 0x5678 - 0x89AB = 0xCCCD | 1 | 1 | 0 | 1 | 0 | 1 |
// 0x5678 - 0xFEDC = 0x579C | 0 | 0 | 0 | 1 | 0 | 1 |
// 0x89AB - 0x4321 = 0x468A | 1 | 0 | 0 | 0 | 0 | 1 |

L_SUB_00        MOVE    STIM_SUB, R8
L_SUB_01        MOVE    @R8, R1                 // First operand
                RBRA    L_SUB_02, Z             // End of test
                ADD     0x0001, R8
                MOVE    @R8, R0                 // Second operand
                ADD     0x0001, R8
                MOVE    @R8, R2                 // Carry input
                ADD     0x0001, R8
                MOVE    @R8, R3                 // Expected result
                ADD     0x0001, R8
                MOVE    @R8, R4                 // Expected status
                ADD     0x0001, R8

                MOVE    R2, R14                 // Set carry input
                SUB     R0, R1
                MOVE    R14, R9                 // Copy status
                CMP     R1, R3                  // Verify expected result
                RBRA    E_SUB_01, !Z            // Jump if error
                CMP     R9, R4                  // Verify expected status
                RBRA    L_SUB_01, Z
E_SUB_01        HALT
L_SUB_02


// ---------------------------------------------------------------------------
// Test the SUBC instruction
// Subtraction                  | V | N | Z | C | X | 1 |
// 0x5678 - 0x4321 - 0 = 0x1357 | 0 | 0 | 0 | 0 | 0 | 1 |
// 0x5678 - 0x5678 - 0 = 0x0000 | 0 | 0 | 1 | 0 | 0 | 1 |
// 0x5678 - 0x5679 - 0 = 0xFFFF | 0 | 1 | 0 | 1 | 1 | 1 |
// 0x5678 - 0x89AB - 0 = 0xCCCD | 1 | 1 | 0 | 1 | 0 | 1 |
// 0x5678 - 0xFEDC - 0 = 0x579C | 0 | 0 | 0 | 1 | 0 | 1 |
// 0x89AB - 0x4321 - 0 = 0x468A | 1 | 0 | 0 | 0 | 0 | 1 |
// 0x5678 - 0x4321 - 1 = 0x1357 | 0 | 0 | 0 | 0 | 0 | 1 |
// 0x5678 - 0x5678 - 1 = 0xFFFF | 0 | 1 | 0 | 1 | 1 | 1 |
// 0x5678 - 0x5677 - 1 = 0x0000 | 0 | 0 | 1 | 0 | 0 | 1 |
// 0x5678 - 0x89AB - 1 = 0xCCCD | 1 | 1 | 0 | 1 | 0 | 1 |
// 0x5678 - 0xFEDC - 1 = 0x579C | 0 | 0 | 0 | 1 | 0 | 1 |
// 0x89AB - 0x4321 - 1 = 0x468A | 1 | 0 | 0 | 0 | 0 | 1 |

L_SUBC_00       MOVE    STIM_SUBC, R8
L_SUBC_01       MOVE    @R8, R1                 // First operand
                RBRA    L_SUBC_02, Z            // End of test
                ADD     0x0001, R8
                MOVE    @R8, R0                 // Second operand
                ADD     0x0001, R8
                MOVE    @R8, R2                 // Carry input
                ADD     0x0001, R8
                MOVE    @R8, R3                 // Expected result
                ADD     0x0001, R8
                MOVE    @R8, R4                 // Expected status
                ADD     0x0001, R8

                MOVE    R2, R14                 // Set carry input
                SUBC    R0, R1
                MOVE    R14, R9                 // Copy status
                CMP     R1, R3                  // Verify expected result
                RBRA    E_SUBC_01, !Z           // Jump if error
                CMP     R9, R4                  // Verify expected status
                RBRA    L_SUBC_01, Z
E_SUBC_01       HALT
L_SUBC_02



// Everything worked as expected! We are done now.
EXIT            MOVE    OK, R8
                SYSCALL(puts, 1)
                SYSCALL(exit, 1)

OK              .ASCII_W    "OK\n"

VAL1234         .DW     0x1234
VAL4321         .DW     0x4321
BSS0            .DW     0x0000
BSS1            .DW     0x0000


STIM_ADDC       .DW     0x1234, 0x4321, 0x0000, 0x5555, 0x0001
                .DW     0x1234, 0x9876, 0x0000, 0xAAAA, 0x0011
                .DW     0x7654, 0x6543, 0x0000, 0xDB97, 0x0031
                .DW     0x8765, 0x9876, 0x0000, 0x1FDB, 0x0025
                .DW     0xFEDC, 0x0123, 0x0000, 0xFFFF, 0x0013
                .DW     0xFEDC, 0x0124, 0x0000, 0x0000, 0x000D
                .DW     0xFEDC, 0xEDCB, 0x0000, 0xECA7, 0x0015

                .DW     0x1234, 0x4321, 0x0005, 0x5556, 0x0001
                .DW     0x1234, 0x9876, 0x0005, 0xAAAB, 0x0011
                .DW     0x7654, 0x6543, 0x0005, 0xDB98, 0x0031
                .DW     0x8765, 0x9876, 0x0005, 0x1FDC, 0x0025
                .DW     0xFEDC, 0x0122, 0x0005, 0xFFFF, 0x0013
                .DW     0xFEDC, 0x0123, 0x0005, 0x0000, 0x000D
                .DW     0xFEDC, 0xEDCB, 0x0005, 0xECA8, 0x0015

                .DW     0x0000

STIM_SUB        .DW     0x5678, 0x4321, 0x0000, 0x1357, 0x0001
                .DW     0x5678, 0x5678, 0x0005, 0x0000, 0x0009
                .DW     0x5678, 0x5679, 0x0000, 0xFFFF, 0x0017
                .DW     0x5678, 0x89AB, 0x0005, 0xCCCD, 0x0035
                .DW     0x5678, 0xFEDC, 0x0000, 0x579C, 0x0005
                .DW     0x89AB, 0x4321, 0x0005, 0x468A, 0x0021

                .DW     0x0000

STIM_SUBC       .DW     0x5678, 0x4321, 0x0000, 0x1357, 0x0001
                .DW     0x5678, 0x5678, 0x0000, 0x0000, 0x0009
                .DW     0x5678, 0x5679, 0x0000, 0xFFFF, 0x0017
                .DW     0x5678, 0x89AB, 0x0000, 0xCCCD, 0x0035
                .DW     0x5678, 0xFEDC, 0x0000, 0x579C, 0x0005
                .DW     0x89AB, 0x4321, 0x0000, 0x468A, 0x0021

                .DW     0x5678, 0x4321, 0x0004, 0x1356, 0x0001
                .DW     0x5678, 0x5678, 0x0004, 0xFFFF, 0x0017
                .DW     0x5678, 0x5677, 0x0004, 0x0000, 0x0009
                .DW     0x5678, 0x89AB, 0x0004, 0xCCCC, 0x0035
                .DW     0x5678, 0xFEDC, 0x0004, 0x579B, 0x0005
                .DW     0x89AB, 0x4321, 0x0004, 0x4689, 0x0021

                .DW     0x0000


// The OLD version of cpu_test is here for now. TBD: Remove


                ;
                ; MOVE and CMP
                ;
                MOVE    0x1234, R0
                CMP     0x1234, R0
                RBRA    M1, Z
                ; Moving a constant to a register or comparing that with a constant failed.
                HALT
M1              CMP     R0, 0x1234
                RBRA    M1_1, Z
                ; CMP with constant as second parameter failed.
                HALT
M1_1            MOVE    R0, R1
                CMP     R1, 0x1234
                RBRA    M2, Z
                ; Moving the contents of a register to another register failed.
                HALT
M2              MOVE    M2_SCRATCH, R1
                MOVE    R0, @R1
                CMP     0x1234, @R1
                RBRA    M3, Z
                ; Either writing indirect to memory or reading this in a compare failed.
                HALT
M2_SCRATCH      .BLOCK  2               ; Two scratch memory cells.
M3              MOVE    @R1++, @R1++
                MOVE    M2_SCRATCH, R2
                ADD     0x0002, R2
                CMP     R2, R1
                RBRA    M3_1, Z         ; R1 points to the correct address.
                HALT
M3_1            SUB     0x0001, R1
                MOVE    @R1, R2
                CMP     R0, R2
                RBRA    M4, Z
                ;  If we end up here, the second memory cell in M2_SCRATCH did either not contain
                ; 0x1234 or the value could not be retrieved.
                HALT
                ;  Now we test OR @R0++, @R0:
M4              MOVE    M2_SCRATCH, R0
                MOVE    0x5555, @R0++
                MOVE    0xAAAA, @R0
                SUB     0x0001, R0
                OR      @R0++, @R0
                CMP     0xFFFF, @R0
                RBRA    M5, Z
                HALT
                ; test ADD R4, @--R4
M5_VAR          .DW     0x0004, 0xFFFF, 0x4444, 0x9876, 0x5432, 0x2309
M5              MOVE    M5_VAR, R4
                ADD     1, R4
                ADD     R4, @--R4
                MOVE    @R4, R4
                CMP     @R4, 0x2309
                RBRA    M6, Z
                HALT
                ; test ADD @--R4, R4
                ; for more details, see test_programs/predec.asm
M6_VAR          .DW 0x0003, 0xAAAA, 0xFFFF, 0xCCCC, 0xBBBB, 0xEEEE
M6              MOVE    M6_VAR, R4              ; now points to 0x0003 
                ADD     1, R4                   ; now points to 0xAAAA
                ADD     @--R4, R4               ; now should point to 0xCCCC
                CMP     0xCCCC, @R4
                RBRA    M7, Z
                HALT
                ; test ADD @--R4, @R4
M7_VAR         .DW     0xAAAA, 0x1234, 0xBBBB
M7              MOVE    M7_VAR, R4
                ADD     2, R4
                ADD     @--R4, @R4
                CMP     @R4, 0x2468
                RBRA    M8, Z
                HALT
                ; test ADD @--R4, @--R4
M8_VAR          .DW     0x5555, 0x0076, 0x1900, 0xDDDD, 0x9999, 0x8888
M8              MOVE    M8_VAR, R4
                ADD     3, R4
                ADD     @--R4, @--R4
                CMP     @R4, 0x1976
                RBRA    M9, Z
                HALT
                ; ADD @R4, @--R4
M9_VAR          .DW     0x1100, 0x4455
M9              MOVE    M9_VAR, R4
                ADD     1, R4
                ADD     @R4, @--R4
                CMP     @R4, 0x5555
                RBRA    CPU_OK, Z
                HALT

                ; If we end up here we can be pretty sure that the CPU is working.
CPU_OK          SYSCALL(exit, 1)
