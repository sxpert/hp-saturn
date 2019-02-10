
/******************************************************************************
 * 80
 * a lot of things start with 80...
 *
 */ 

`include "decstates.v"
`include "bus_commands.v"

`DEC_80X: begin
    case (nb_in)
    4'h5: begin
        add_out <= C[19:0];
        next_cycle <= `BUSCMD_CONFIGURE;
        decstate <= `DEC_START;
    `ifdef SIM
            $display("%05h CONFIG", inst_start_PC);
    `endif
    end
    4'hA: begin
        next_cycle <= `BUSCMD_RESET;
        decstate <= `DEC_START;
    `ifdef SIM
            $display("%05h RESET", inst_start_PC);
    `endif
    end
    4'hC:	decstate <= `DEC_C_EQ_P_N;
    4'hD:	decstate <= `DEC_P_EQ_C_N;
    default: begin
        $display("ERROR : DEC_80X");
        decode_error <= 1;
    end
    endcase
end
