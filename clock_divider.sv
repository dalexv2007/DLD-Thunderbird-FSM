module clock_divider (
    input logic clk_in,
    output logic clk_200Hz,
    output logic clk_1Hz
);
    logic [31:0] counter = 0;

    always_ff @(posedge clk_in) begin
        counter <= counter + 1;
    end

    assign clk_200Hz = counter[18];
    assign clk_1Hz = counter[25];
endmodule