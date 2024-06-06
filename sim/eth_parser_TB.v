module eth_parser_TB;

    reg clk;
    reg rst;
    reg [31:0] packet4_byte;
    reg data_valid;
    reg last_valid;
    reg [3:0] keep;
    wire [31:0] payload;
    wire payload_valid;
    wire [47:0] dest_addr;
    wire [47:0] src_addr;
    wire [31:0] vlan_tag;
    wire [15:0] eth_type;
    wire payload_last_valid;
    wire [3:0] payload_keep;
    wire dest_addr_valid;
    wire src_addr_valid;
    wire vlan_tag_valid;
    wire eth_type_valid;
    
    packet_decoder uut (.clk(clk),
    .rst(rst),
    .packet4_byte(packet4_byte),
    .data_valid(data_valid),
    .last_valid(last_valid),
    .keep(keep),
    .payload(payload),
    .payload_valid(payload_valid),
    .dest_addr(dest_addr),
    .src_addr(src_addr),
    .vlan_tag(vlan_tag),
    .eth_type(eth_type),
    .payload_last_valid(payload_last_valid),
    .payload_keep(payload_keep),
    .dest_addr_valid(dest_addr_valid),
    .src_addr_valid(src_addr_valid),
    .vlan_tag_valid(vlan_tag_valid),
    .eth_type_valid(eth_type_valid));
    
    initial clk = 0;
    always #5 clk = !clk;
    
    initial begin
    rst = 1;
    last_valid = 1'b0;
    #10
    rst = 0;
    packet4_byte = 32'hA1BAABBB;
    #15
    rst = 1;
    data_valid = 1'b1;
    keep = 4'b0011;
    packet4_byte = 32'hA1AAAAAA;
    #10
    packet4_byte = 32'hAAAAAAAB;
    #10
    packet4_byte = 32'h12345678;
    #10
    packet4_byte = 32'h8100DEF0;
    #10
    packet4_byte = 32'h12345678;
    #10
    packet4_byte = 32'h9ABCDEF0;
    #10
    packet4_byte = 32'h12345678;
    #10
    packet4_byte = 32'hAAAAAAAA;
    #10
    packet4_byte = 32'hAAAAACDA;
    #10
    packet4_byte = 32'hAAEAACDA;
    #10
    packet4_byte = 32'hEAAAACDA;
    last_valid =  1'b1;
    #10;
    last_valid = 1'b0;
    data_valid = 1'b0;
    #50;
    packet4_byte = 32'h9ABCDEF0;
    data_valid = 1'b1;
    #10;
    packet4_byte = 32'hAAEAACDA;
    #60;
    last_valid = 1'b1;
    #10;
    last_valid = 1'b0;
    data_valid = 1'b0;
    #50;
    $finish;
    end
    
endmodule
