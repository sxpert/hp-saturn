`ifndef _DECSTATES
`define _DECSTATES


`define DEC_START            0      //  X
`define DEC_0X               1      //  0X
`define DEC_RTNCC            2      //  03
`define DEC_SETHEX           3      //  04
`define DEC_SETDEC           4      //  05
`define DEC_P_EQ_N           5      //  2n
`define DEC_LC_LEN           6      //  3n...
`define DEC_LC               7      //  3n[x]
`define DEC_GOTO             8      //  6
`define DEC_GOTO_LOOP        9      //  6[x]
`define DEC_GOTO_EXEC       10      //  6xxx -> exec
`define DEC_8X              11      //  8X
`define DEC_80X             12      //  80X
`define DEC_CONFIG          20      //  805
`define DEC_RESET           21      //  80A
`define DEC_C_EQ_P_N        22      //  80Cm
`define DEC_82X_CLRHST      23      //  82X
`define DEC_ST_EQ_0_N       24      //  84n
`define DEC_ST_EQ_1_N       25      //  85n
`define DEC_GOVLNG          26      //  8D
`define DEC_GOVLNG_LOOP     27      //  8D[x]
`define DEC_GOVLNG_EXEC     28      //  8Dxxxxx -> exec
`define DEC_GOSBVL          29      //  8F
`define DEC_GOSBVL_LOOP     30      //  8F[x]
`define DEC_GOSBVL_EXEC     31      //  8Fxxxxx -> exec
`define DEC_BX              64      //  Bx

`endif