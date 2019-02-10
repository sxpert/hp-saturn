/******************************************************************************
 * 1X
 *
 *
 */ 

`include "decstates.v"

`DEC_1X: begin
    case (nb_in)
    4'h3: decstate <= `DEC_13X;
    4'h4: decstate <= `DEC_14X;
    4'h5: decstate <= `DEC_15X;
    4'h6, 4'h7, 4'h8, 4'hC: begin
        t_ptr <= (nb_in[0] & nb_in[1]) | (nb_in[2] & nb_in[3]);
        t_add_sub <= nb_in[3];
        decstate <= `DEC_PTR_MATH;
    end
    4'h9: decstate <= `DEC_D0_EQ_2N;
    4'hA: decstate <= `DEC_D0_EQ_4N;
    4'hB: decstate <= `DEC_D0_EQ_5N;
    4'hD: decstate <= `DEC_D1_EQ_2N;
    4'hE: decstate <= `DEC_D1_EQ_4N;
    4'hF: decstate <= `DEC_D1_EQ_5N;
    default: begin 
        $display("ERROR : DEC_1X %h", nb_in);
        decode_error <= 1;    
    end
    endcase
end
