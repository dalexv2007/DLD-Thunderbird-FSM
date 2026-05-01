module clock_divider (
    input logic clk_in,
    output logic clk_out
);
    logic [31:0] counter = 0;

    always_ff @(posedge clk_in) begin
        counter <= counter + 1;
    end

    assign clk_out = counter[25];
endmodule