/*
    (c) Raphaël Jacquot 2019
    
		This file is part of hp_saturn.

    hp_saturn is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    hp_saturn is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.

 */

`default_nettype none

`ifdef SIM
module saturn_top;

saturn_bus main_bus (
    .i_clk          (clk),
    .i_clk_en       (clk_en),
    .i_reset        (reset),
    .o_halt         (halt),
    .o_char_to_send (char_to_send),
    .o_char_valid   (char_valid),
    .i_serial_busy  (serial_busy)
);

saturn_serial serial_port (
    .i_clk          (clk),
    .i_char_to_send (char_to_send),
    .i_char_valid   (char_valid),
    .o_serial_busy  (serial_busy)
);

wire [7:0] char_to_send;
wire [0:0] char_valid;
wire [0:0] serial_busy;

wire [7:0]  led;
reg  [0:0] reset;
wire [0:0] halt;
reg	 [0:0] clk;

initial begin
	$display("TOP       : starting the simulation");
	clk = 0;
	reset = 1;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	reset = 0;
    $display("TOP       : reset done, waiting for instructions");
	@(posedge halt);
    $display("TOP       : instructed to stop, halt is %b", halt);
	$finish;
end

always 
    #10 clk = (clk === 1'b0);

reg [3:0] delay;
reg [0:0] clk_en;
reg [7:0] test;

initial begin
    delay  = 4'b0001;
    clk_en = 1'b0;
    test   = 8'b1;
end

always @(posedge clk) begin
    test   <= {test[6:0], test[7]};

    delay  <= { delay[2:0], delay[3]};
    clk_en <= delay[0]?1'b1:1'b0;

    if (reset) begin
        clk_en <= 1'b0;
        test   <= 8'b1;
    end
end

endmodule

`else

/*
 *
 *
 *
 */

module saturn_top (
	clk_25mhz,
	btn,
	led,
    wifi_gpio0,
    ftdi_rxd
);

input  wire [0:0] clk_25mhz;
input  wire [6:0] btn;
output reg  [7:0] led;
output wire [0:0] wifi_gpio0;
output wire [0:0] ftdi_rxd;

/* this is necessary, otherwise, the esp32 module reboots the fpga in passthrough */
assign wifi_gpio0 = btn[0];

saturn_bus main_bus (
    .i_clk           (clk_25mhz),
    .i_clk_en        (clk_en),
    .i_reset         (reset),
    .o_halt          (halt),
    .o_phase         (phase),
    .o_cycle_ctr     (cycle_ctr),
    .o_instr_decoded (instr_decoded),
    .o_debug_cycle   (debug_cycle),
    .o_char_to_send  (char_to_send),
    .o_char_counter  (char_counter),
    .o_char_valid    (char_valid),
    .o_char_send     (char_send),
    .i_serial_busy   (serial_busy)
);

saturn_serial serial_port (
    .i_clk          (clk_25mhz),
    .i_char_to_send (char_to_send),
    .i_char_valid   (char_valid),
    .o_serial_tx    (ftdi_rxd),
    .o_serial_busy  (serial_busy)
);

reg  [25:0] delay;
reg  [0:0]  clk2;
reg  [0:0]  clk_en;
reg  [0:0]  reset;
wire [0:0]  halt;
wire [1:0]  phase;
wire [31:0] cycle_ctr;
wire [0:0]  instr_decoded;
wire [0:0]  debug_cycle;
wire [7:0]  char_to_send;
wire [9:0]  char_counter;
wire [0:0]  char_valid;
wire [0:0]  char_send;
wire [0:0]  serial_busy;


/* 1/4 s */
`define DELAY_START 26'h20A1F0
`define TEST_BIT    23

/* 1/8 s */
// `define DELAY_START 26'h1050F8
// `define TEST_BIT    22

/* 1/16 s */
// `define DELAY_START 26'h08287C
// `define TEST_BIT    21

/* 1/32 s */
// `define DELAY_START 26'h4143E
// `define TEST_BIT    20

initial begin
    led   = 8'h00;
    delay = `DELAY_START;
    reset = 1'b1;
    clk2  = 1'b0;
end

always @(posedge clk_25mhz) begin
    reset  <= btn[1];
    delay  <= delay[`TEST_BIT]?`DELAY_START:delay + 26'b1;
    clk_en <= (delay[`TEST_BIT]?1'b1:1'b0) && !halt;
    
    led[7] <= halt;
    led[6] <= char_send;
    led[5] <= serial_busy;
    led[4] <= debug_cycle;
    led[3] <= clk_en;
    led[2] <= instr_decoded;

    led[1:0] <= phase;
end

endmodule

`endif
