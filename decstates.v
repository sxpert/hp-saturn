`ifndef _DECSTATES
`define _DECSTATES


`define DEC_START           0       //  X
`define DEC_P_EQ_N          1       //  2n
`define DEC_GOTO            2       //  6
`define DEC_GOTO_LOOP       3       //  6[x]
`define DEC_GOTO_EXEC       4       //  6xxx -> exec
`define DEC_8               5       //  8X
`define DEC_GOVLNG          6       //  8D
`define DEC_GOVLNG_LOOP     7       //  8D[x]
`define DEC_GOVLNG_EXEC     8       //  8Dxxxxx -> exec
`define DEC_GOSBVL          9       //  8F
`define DEC_GOSBVL_LOOP     10      //  8F[x]
`define DEC_GOSBVL_EXEC     11      //  8Fxxxxx -> exec

`endif