/******************************************************************************
 * 82x
 * 
 * lots of things there
 *
 */

`include "decstates.v"

`DEC_82X_CLRHST: begin
    HST <= HST & !nb_in;
    decstate <= `DEC_START;
`ifdef SIM
    $write("%5h ", inst_start_PC);
    case (nb_in)
        4'h1:	 $display("XM=0");
        4'h2:	 $display("SB=0");
        4'h4:    $display("SR=0");
        4'h8:	 $display("MP=0");
        4'hf:    $display("CLRHST");
        default: $display("CLRHST\t%f", nb_in);
    endcase
`endif
end
