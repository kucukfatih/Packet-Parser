`timescale 1ns / 1ps

module packet_decoder(

    input wire clk,
    input wire rst,
    input wire [31:0] packet4_byte,
    input wire data_valid,
    input wire last_valid,
    input wire [3:0] keep,
    output reg [31:0] payload,
    output reg [3:0] payload_keep,
    output reg payload_valid,
    output reg payload_last_valid,
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
    reg payload_overflow;
    reg [15:0] temp_payload;
    reg [1:0] overflow_keep;
    
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
            payload_last_valid <= 0;
            payload_keep <= 0;
            payload_overflow <= 0;
        end
        else begin
            if(data_valid || payload_overflow) begin         
                byte_cnt <= byte_cnt + 1;
                case(byte_cnt + 1)
                    12'd1 : begin
                            dest_addr [47:16] <= packet4_byte;
                    end
                    12'd2 : begin
                            {dest_addr [15:0],src_addr [47:32]} <= packet4_byte;  
                    end
                    12'd3 : begin
                            src_addr [31:0] <= packet4_byte;
                    end
                    12'd4 : begin
                            if(packet4_byte[31:16] == 16'h8100) begin // checking the vlan_tag
                                vlan_tag [31:0] <= packet4_byte;
                                vlan_flag <= 1'b1;
            
                            end
                            else begin
                                eth_type [15:0] <= packet4_byte [31:16];
                                payload [31:16] <= packet4_byte [15:0];
                                payload_valid <= 1'b0;
                                vlan_flag <= 1'b0;
                                
                            end
                    end
                    12'd5 : begin
                            if(vlan_flag ) begin
                                eth_type [15:0] <= packet4_byte [31:16];
                                payload [31:16] <= packet4_byte [15:0];
                                temp_payload <= packet4_byte [31:15];
                                payload_valid <= 1'b0;
                            end
                            else begin
                                payload [15:0] <= packet4_byte [31:16];
                                temp_payload <= packet4_byte [15:0];
                                payload_valid <= 1'b1;
                            end
                    end
                    12'd6 : begin
                            if(vlan_flag) begin
                                payload <= {temp_payload,packet4_byte [31:16]};
                                temp_payload <= payload [15:0];
                                payload_valid <= 1'b1;
                            end
                            else begin
                                payload <= {temp_payload,packet4_byte[31:16]};
                                temp_payload <= packet4_byte [15:0];
                                vlan_flag <= 1'b0;
                            end
                    end       
                    default : begin
                            if (!payload_overflow) begin // checking the payload overflow
                                if(last_valid || ( 4*(byte_cnt+1)>= MTU )) begin  // checking the last valid or maximum byte size
                                    case(keep)
                                        4'b0000 : begin
                                                    payload [31:16] <= temp_payload;
                                                    payload_keep <= 4'b0011;
                                                    byte_cnt <= 0;
                                                    payload_valid <= 1'b0;
                                                    payload_last_valid <= 1'b1;
                                        end
                                        4'b0001 : begin
                                                    payload [31:8] <= {temp_payload,packet4_byte [31:24]};
                                                    payload_keep <= 4'b0111;
                                                    byte_cnt <= 0;
                                                    payload_valid <= 1'b0;
                                                    payload_last_valid <= 1'b1;
                                        end
                                        4'b0011 : begin
                                                    payload <= {temp_payload,packet4_byte [31:16]};
                                                    payload_keep <= 4'b1111;
                                                    byte_cnt <= 0;
                                                    payload_valid <= 1'b0;
                                                    payload_last_valid <= 1'b1;

                                        end
                                        4'b0111 : begin
                                                    payload  <= {temp_payload,packet4_byte [31:16]};
                                                    temp_payload [15:8] <= packet4_byte [15:8]; 
                                                    payload_overflow <= 1'b1;
                                                    overflow_keep <= 2'b01;
                                        end
                                        4'b1111 : begin
                                                    payload <= {temp_payload,packet4_byte [31:16]};
                                                    temp_payload [15:8] <= packet4_byte [15:0]; 
                                                    payload_overflow <= 1'b1;
                                                    overflow_keep <= 2'b11;

                                        end
                                        default : begin
                                                    payload <= payload;
                                        end
                                    endcase 
                                end
                                else begin 
                                    payload <= {temp_payload,packet4_byte [31:16]};
                                    temp_payload <= payload [15:0];
                                end
                            end
                            else begin
                                case (overflow_keep)
                                    2'b01 : begin
                                                payload [31:24] <= temp_payload [15:8];
                                                payload_valid <= 1'b0;
                                                payload_last_valid <= 1'b1;
                                                payload_keep <= 4'b0001;
                                                byte_cnt <= 0;
                                                payload_overflow <= 0;

                                    end
                                    2'b11 : begin
                                                payload [31:16] <= temp_payload;
                                                payload_valid <= 1'b0;
                                                payload_last_valid <= 1'b1;
                                                payload_keep <= 4'b0011;
                                                byte_cnt <= 0;
                                                payload_overflow <= 0;
                                    end
                                    default : begin
                                                payload <= payload;

                                    end

                                endcase
                            end
                                
                    end
                endcase
            end
            else begin
                if (!byte_cnt) begin
                    payload_last_valid <= 1'b0;
                end
                else begin
                    byte_cnt <= byte_cnt;
                end
            end
        end
    end
    
    assign dest_addr_valid = (byte_cnt == 2);
    assign src_addr_valid = (byte_cnt == 3);
    assign vlan_tag_valid = (byte_cnt == 4) && vlan_flag;
    assign eth_type_valid = (byte_cnt == 5);
    
endmodule


