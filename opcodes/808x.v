/******************************************************************************
 * 808x
 * a lot of things start with 808x...
 *
 */ 

`include "decstates.v"

`DEC_808X: begin
    case (nb_in)
    4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9, 4'hA, 4'hB: begin
        t_reg = nb_in[3];
        t_set_test = nb_in[1];
        t_set_test_val = nb_in[0];
        decstate <= `DEC_AC_BIT_SET_TEST;
    end
    default: begin
        $display("ERROR : DEC_808X");
        decode_error <= 1;
    end
    endcase
end
