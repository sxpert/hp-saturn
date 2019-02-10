`include "fields.v"

`DEC_ab_FIELDS: begin
    field_table <= {1'b0, nb_in[3]};
    $display("DEC_ab_FIELDS %b %h", {1'b0, !nb_in[3]}, nb_in[2:0]);
    case (nb_in[2:0])
    4'h0: begin
        field <= `T_FIELD_P;
        alu_first <= P;
        alu_last  <= P;
    end
    4'h1: begin
        field <= `T_FIELD_WP;
        alu_first <= 0;
        alu_last  <= P;
    end
    4'h2: begin
        field <= `T_FIELD_XS;
        alu_first <= 2;
        alu_last  <= 2;
    end
    4'h3: begin
        field <= `T_FIELD_X;
        alu_first <= 0;
        alu_last  <= 2;
    end
    4'h4: begin
        field <= `T_FIELD_S;
        alu_first <= 15;
        alu_last  <= 15;
    end
    4'h5: begin
        field <= `T_FIELD_M;
        alu_first <= 3;
        alu_last  <= 14;
    end
    4'h6: begin
        field <= `T_FIELD_B;
        alu_first <= 0;
        alu_last  <= 1;
    end
    4'h7: begin
        field <= `T_FIELD_W;
        alu_first <= 0;
        alu_last  <= 15;
    end
    endcase
    decstate <= fields_return;
end