/******************************************************************************
 * 13X
 *
 *
 */ 

`include "decstates.v"

`DEC_13X: begin
    case (nb_in)
    4'h4: D0[19:0] <= C[19:0];
    4'h5: D1[19:0] <= C[19:0];
    default: begin 
        $display("ERROR : DEC_13X");
        decode_error <= 1;    
    end
    endcase
    decstate <= `DEC_START;
`ifdef SIM
    $write("%5h ", inst_start_PC);
    if (!nb_in[1]) 
        $write("D");
    else 
        $write("%sD", nb_in[3]?"C":"A");
    $write("%b", nb_in[0]);
    if (!nb_in[1]) 
        $write("=%s%s", nb_in[2]?"C":"A", nb_in[3]?"S":"");
    else
        $write("%s", nb_in[3]?"XS":"EX");
    $display("");
`endif
end
