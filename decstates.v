`ifndef _DECSTATES
`define _DECSTATES


`define DEC_START            0      //  X
`define DEC_0X               1      //  0X
`define DEC_RTNCC            2      //  03
`define DEC_SETHEX           3      //  04
`define DEC_SETDEC           4      //  05
`define DEC_1X              10      //  1X
`define DEC_14X             11      //  14X
`define DEC_15X             12      //  15X
`define DEC_MEMACCESS       13      //  1[45]x[y]
`define DEC_D0_EQ_5N        14      //  1B
`define DEC_D0_EQ_5N_LOOP   15      //  1Bxxxxx (exec)
`define DEC_D1_EQ_5N        16      //  1F
`define DEC_D1_EQ_5N_LOOP   17      //  1Fxxxxx (exec)
`define DEC_P_EQ_N          20      //  2n
`define DEC_LC_LEN          21      //  3n...
`define DEC_LC              22      //  3n[x]
`define DEC_GOTO            30      //  6
`define DEC_GOTO_LOOP       31      //  6[x] -> exec
`define DEC_GOSUB           32      //  7
`define DEC_GOSUB_LOOP      33      //  7[x] -> exec
`define DEC_8X              40      //  8X
`define DEC_80X             41      //  80X
`define DEC_CONFIG          42      //  805
`define DEC_RESET           43      //  80A
`define DEC_C_EQ_P_N        44      //  80Cm
`define DEC_82X_CLRHST      50      //  82X
`define DEC_ST_EQ_0_N       51      //  84n
`define DEC_ST_EQ_1_N       52      //  85n
`define DEC_GOVLNG          60      //  8D
`define DEC_GOVLNG_LOOP     61      //  8D[x]
`define DEC_GOVLNG_EXEC     62      //  8Dxxxxx -> exec
`define DEC_GOSBVL          63      //  8F
`define DEC_GOSBVL_LOOP     64      //  8F[x]
`define DEC_GOSBVL_EXEC     65      //  8Fxxxxx -> exec
`define DEC_AX              70      //  Ax
`define DEC_AaX_EXEC        71      //  Aax
`define DEC_AbX_EXEC        72      //  Abx
`define DEC_BX              80      //  Bx
`define DEC_DX             100      //  Dx

`endif