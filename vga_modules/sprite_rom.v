// Single Port ROM for Sprite Data
`timescale 1ns / 1ps
module sprite_rom
#(parameter DATA_WIDTH=16, parameter ADDR_WIDTH=10)
(
    input clk,
    input [(ADDR_WIDTH-1):0] addr,
    output reg [(DATA_WIDTH-1):0] data_out
);

    reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

    initial begin
        $readmemh("C:/Users/IT Admin/Documents/3710_SpritetoHexConverter/Sprites/Little Man Walking/LittleMan_0_Hex.hex", rom);
    end

    always @ (posedge clk)
    begin
        data_out <= rom[addr];
    end

endmodule