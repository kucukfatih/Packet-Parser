`timescale 1ns / 1ps

module packet_decoder(

    input wire clk,
    input wire rst,
    input wire [31:0] packet4_byte,
    input wire data_valid,
    input wire last_valid,
    input wire [3:0] keep,
    output reg [31:0] payload,
    output reg payload_valid,
    output reg [47:0] dest_addr, // 6 byte
    output reg [47:0] src_addr, // 6 byte
    output reg [31:0] vlan_tag, // 4 byte
    output reg [15:0] eth_type, // 2 byte
    output wire dest_addr_valid,
    output wire src_addr_valid,
    output wire vlan_tag_valid,
    output wire eth_type_valid
    
    );
    
    reg [11:0] byte_cnt;
    reg vlan_flag;
    
    localparam MTU = 1522;
     
    always @(posedge clk,negedge rst) begin
        if(!rst) begin
            byte_cnt <= 0;
            vlan_flag <= 0;
            payload_valid <= 0;
            payload <= 0;
            dest_addr <= 0;
            src_addr <= 0;
            vlan_tag <= 0;
            eth_type <= 0;
        end
        else begin
            if(data_valid) begin         
                byte_cnt <= byte_cnt + 1;
                case(byte_cnt + 1)
                    10'd1 : begin
                            dest_addr [47:16] <= packet4_byte;
                    end
                    10'd2 : begin
                            {dest_addr [15:0],src_addr [47:32]} <= packet4_byte;  
                    end
                    10'd3 : begin
                            src_addr [31:0] <= packet4_byte;
                    end
                    10'd4 : begin
                            if(packet4_byte[31:16] == 16'h8100) begin // checking the vlan_tag
                                vlan_tag [31:0] <= packet4_byte;
                                vlan_flag <= 1'b1;
            
                            end
                            else begin
                                eth_type [15:0] <= packet4_byte [31:16];
                                payload [31:16] <= packet4_byte [15:0];
                                vlan_flag <= 1'b0;
                                
                            end
                    end
                    10'd5 : begin
                            if(vlan_flag ) begin
                                eth_type [15:0] <= packet4_byte [31:16];
                                payload [31:16] <= packet4_byte [15:0];
                                payload_valid <= 1'b0;
                            end
                            else begin
                                payload <= packet4_byte;
                                payload_valid <= 1'b1;
                            end
                    end
                    10'd6 : begin
                            payload <= packet4_byte;
                            payload_valid <= 1'b1;
                            vlan_flag <= 1'b0;
                    end       
                    default : begin
                            if(last_valid || ( 4*(byte_cnt+1)>= MTU )) begin  // checking the last valid or maximum byte size
                                payload_valid <= 1'b0;
                                byte_cnt <= 1'b0;
                                case(keep)
                                    4'b0000 : payload <= payload;
                                    4'b0001 : payload [31:24] <= packet4_byte [31:24];
                                    4'b0011 : payload [31:16] <= packet4_byte [31:16];
                                    4'b0111 : payload [31:8] <= packet4_byte [31:8];
                                    4'b1111 : payload <= packet4_byte;
                                    default : payload <= payload;
                                endcase 
                            end
                            else begin 
                                payload <= packet4_byte;
                            end
                                
                    end
                endcase
            end
            else begin
                byte_cnt <= byte_cnt;
            end
        end
    end
    
    assign dest_addr_valid = (byte_cnt == 2);
    assign src_addr_valid = (byte_cnt == 3);
    assign vlan_tag_valid = (byte_cnt == 4)&& vlan_flag;
    assign eth_type_valid = (byte_cnt == 5);
    
endmodule


