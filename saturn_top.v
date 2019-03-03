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
    .o_char_to_send (t_led)
);

wire [7:0] t_led;
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

reg [0:0] clk_en;
reg [7:0] test;

initial begin
    clk_en = 1'b1;
    test   = 8'b1;
end

always @(posedge clk) begin
    test   <= {test[6:0], test[7]};

    if (reset) begin
        clk_en <= 1'b1;
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
    wifi_gpio0
);

input  wire [0:0] clk_25mhz;
input  wire [6:0] btn;
output reg  [7:0] led;
output reg  [0:0] wifi_gpio0;

/* this is necessary, otherwise, the esp32 module reboots the fpga in passthrough */
assign wifi_gpio0 = btn[0];

saturn_bus main_bus (
    .i_clk          (clk_25mhz),
    .i_clk_en       (clk_en),
    .i_reset        (reset),
    .o_halt         (halt),
    .o_char_to_send (t_led)
);

reg  [25:0] delay;
reg  [0:0]  clk_en;
reg  [0:0]  reset;
wire [0:0]  halt;
wire [7:0]  t_led;

`define DELAY_START 26'h08287C0

initial begin
    led   = 8'h01;
    delay = `DELAY_START;
    reset = 1'b1;
end

always @(posedge clk_25mhz) begin
    delay <= delay + 26'b1;
    if (delay[25]) begin
        delay  <= `DELAY_START;
        reset  <= btn[1];
        clk_en <= 1'b1;
    end

    if (clk_en) 
        clk_en <= 1'b0;

    led <= t_led;
end

endmodule

`endif
