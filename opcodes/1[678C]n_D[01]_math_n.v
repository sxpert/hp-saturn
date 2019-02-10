/******************************************************************************
 *1[678C]		D[01]=D[01][+-] (n+1)
 *
 *
 */ 

`DEC_PTR_MATH: begin
    case ({t_ptr, t_add_sub})
    2'b00: {Carry, D0} <= D0 + (nb_in + 1);
    2'b01: {Carry, D0} <= D0 - (nb_in + 1);
    2'b10: {Carry, D1} <= D1 + (nb_in + 1);
    2'b11: {Carry, D1} <= D1 - (nb_in + 1);
    endcase
    decstate <= `DEC_START;
`ifdef SIM
    $display("%5h D%b=D%b%s\t%2d", inst_start_PC, t_ptr, t_ptr, t_add_sub?"-":"+", nb_in+1);
`endif
end