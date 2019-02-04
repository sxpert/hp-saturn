module mask_gen (
// ports
    clk,
    nibble_width,
    nibble_start,
    mask
);
input clk; // clock
input wire [3:0] nibble_width; // length of mask in nibbles
input wire [3:0] nibble_start; // nibble where the mask starts
output reg [63:0] mask;// 64 bits mask

reg [4:0] n_max;
wire [3:0] nm1 = n_max[3:0];
reg [15:0] bitmask_1;
reg [15:0] bitmask_2;
reg [15:0] bitmask;
//wire [3:0] nm1;

always @( posedge clk) begin
    bitmask_1[ 0] = nibble_start==0;
    bitmask_1[ 1] = nibble_start==1  | bitmask_1[0];
    bitmask_1[ 2] = nibble_start==2  | bitmask_1[1];
    bitmask_1[ 3] = nibble_start==3  | bitmask_1[2];
    bitmask_1[ 4] = nibble_start==4  | bitmask_1[3];
    bitmask_1[ 5] = nibble_start==5  | bitmask_1[4];
    bitmask_1[ 6] = nibble_start==6  | bitmask_1[5];
    bitmask_1[ 7] = nibble_start==7  | bitmask_1[6];
    bitmask_1[ 8] = nibble_start==8  | bitmask_1[7]; 
    bitmask_1[ 9] = nibble_start==9  | bitmask_1[8];
    bitmask_1[10] = nibble_start==10 | bitmask_1[9];
    bitmask_1[11] = nibble_start==11 | bitmask_1[10];
    bitmask_1[12] = nibble_start==12 | bitmask_1[11];
    bitmask_1[13] = nibble_start==13 | bitmask_1[12];
    bitmask_1[14] = nibble_start==14 | bitmask_1[13];
    bitmask_1[15] = nibble_start==15 | bitmask_1[14];
    $display("bm1 : %b", bitmask_1);


    n_max <= nibble_start + nibble_width + 1;
    $display("n_max : %h", n_max);
    //nm1[3:0] = n_max[3:0];

    bitmask_2[15] = nm1==15;
    bitmask_2[14] = nm1==14 | bitmask_2[15];
    bitmask_2[13] = nm1==13 | bitmask_2[14];
    bitmask_2[12] = nm1==12 | bitmask_2[13];
    bitmask_2[11] = nm1==11 | bitmask_2[12];
    bitmask_2[10] = nm1==10 | bitmask_2[11];
    bitmask_2[ 9] = nm1==9  | bitmask_2[10];
    bitmask_2[ 8] = nm1==8  | bitmask_2[9];
    bitmask_2[ 7] = nm1==7  | bitmask_2[8];
    bitmask_2[ 6] = nm1==6  | bitmask_2[7];
    bitmask_2[ 5] = nm1==5  | bitmask_2[6];
    bitmask_2[ 4] = nm1==4  | bitmask_2[5];
    bitmask_2[ 3] = nm1==3  | bitmask_2[4];
    bitmask_2[ 2] = nm1==2  | bitmask_2[3];
    bitmask_2[ 1] = nm1==1  | bitmask_2[2];
    bitmask_2[ 0] = nm1==0  | bitmask_2[1];
    $display("bm2 : %b", bitmask_2);

    bitmask = n_max[4] ? bitmask_1 | bitmask_2 : bitmask_1 & bitmask_2;
    $display("bm  : %b", bitmask);

    mask[ 3: 0] = {4{bitmask[ 0]}}; 
    mask[ 7: 4] = {4{bitmask[ 1]}}; 
    mask[11: 8] = {4{bitmask[ 2]}}; 
    mask[15:12] = {4{bitmask[ 3]}}; 
    mask[19:16] = {4{bitmask[ 4]}}; 
    mask[23:20] = {4{bitmask[ 5]}}; 
    mask[27:24] = {4{bitmask[ 6]}}; 
    mask[31:28] = {4{bitmask[ 7]}}; 
    mask[35:32] = {4{bitmask[ 8]}}; 
    mask[39:36] = {4{bitmask[ 9]}}; 
    mask[43:40] = {4{bitmask[10]}}; 
    mask[47:44] = {4{bitmask[11]}}; 
    mask[51:48] = {4{bitmask[12]}}; 
    mask[55:52] = {4{bitmask[13]}}; 
    mask[59:56] = {4{bitmask[14]}}; 
    mask[63:60] = {4{bitmask[15]}}; 
end

endmodule

`ifdef SIM

//`timescale 1 ns / 100 ps

module mask_gen_tb;

// inputs
reg clock;

reg [3:0] nw;
reg [3:0] ns;
// outputs
wire [63:0] m;


mask_gen U0 (
    .clk (clock),
    .nibble_width (nw),
    .nibble_start (ns),
    .mask (m)
);


always 
    #10 clock = (clock === 1'b0);

initial begin
    //$monitor ("clk %b", clock);
    $monitor ("clk %b | nw %d | ns %d | m %h", clock, nw, ns, m);
    //#10 $display("1");
    //#10 $display("2");
    //#10 $finish;
end 


initial begin
    $dumpfile("text.vcd");
    $dumpvars(clock, nw, ns, m);
    $display($time, "starting simulation");
    clock = 0;
    $display("starting the simulation");
    run_mask_gen(4, 0);
    run_mask_gen(4, 1);
    run_mask_gen(4, 2);
    run_mask_gen(4, 3);
    run_mask_gen(4, 4);
    run_mask_gen(4, 5);
    run_mask_gen(4, 6);
    run_mask_gen(4, 7);
    run_mask_gen(4, 8);
    run_mask_gen(4, 9);
    run_mask_gen(4,10);
    run_mask_gen(4,11);
    run_mask_gen(4,12);
    run_mask_gen(4,13);
    run_mask_gen(4,14);
    run_mask_gen(4,15);

    //run_mask_gen(4, 0);
    //run_mask_gen(4, 0);
    //run_mask_gen(4, 0);
    //run_mask_gen(4, 0);
    $finish;
end


task run_mask_gen;
    input [3:0] _nw;
    input [3:0] _ns;
    begin
        $display("running", _nw, _ns);
        @(posedge clock);
        nw = _nw;
        ns = _ns;
    end
endtask

endmodule

`endif
