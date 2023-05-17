`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2023 06:58:19 PM
// Design Name: 
// Module Name: SPI_Wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SPI_Wrapper(
    input MOSI,
    output  MISO,
    input SS_n,
    input clk,
    input rst_n
    );

    wire [9:0] din;
    wire rx_valid;
    wire tx_valid;
    wire[7:0] dout;
    parameter MEM_DEPTH=256;
    parameter ADDR_SIZE=8;
 

SPI_SLAVE DUT1(MOSI,MISO,SS_n,clk,rst_n,din,rx_valid,dout,tx_valid);
RAM #(.MEM_DEPTH(MEM_DEPTH),.ADDR_SIZE(ADDR_SIZE)) DUT(din,clk,rst_n,rx_valid,dout,tx_valid);
endmodule

module RAM(
    input [9:0]din,
    input clk,
    input rst_n,
    input rx_valid,
    output reg [7:0]dout,
    output reg tx_valid
    );
   
    reg flag_w,flag_r;   
    parameter MEM_DEPTH=256;
    parameter ADDR_SIZE=8;
    reg [7:0]mem[MEM_DEPTH-1:0];
    reg [ ADDR_SIZE-1:0 ]wr_addr;
    reg [ ADDR_SIZE-1:0 ]rd_addr;

    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // reset
            flag_w<=0;
            flag_r<=0;
            dout<=0;
            tx_valid<=0;
            wr_addr<=0;
            rd_addr<=0;
        end
        else if (rx_valid) begin
        case(din[9:8])
        2'b00:begin
            wr_addr<=din[7:0];
            tx_valid<=0;
            flag_w<=1;
            flag_r<=0;
        end
        2'b01:begin
            if (flag_w) begin
                /* code */
                mem[wr_addr]<=din[7:0];
            tx_valid<=0;
            flag_w<=0;
            flag_r<=0;
            end
            
        end
        2'b10:begin
            rd_addr<=din[7:0];
            tx_valid<=0;
            flag_r <=1;
            flag_w<=0;
        end       
        2'b11:begin
            if (flag_r) begin
                /* code */
            dout<=mem[rd_addr];
            tx_valid<=1;  
            flag_w<=0;
            flag_r<=0;
            end
            
        end
        endcase  
        end
        
    end
    
endmodule

module SPI_SLAVE(input MOSI,
    output reg MISO,
    input SS_n,
    input clk,
    input rst_n,
    output reg [9:0] din,
    output reg rx_valid,
    input[7:0]dout,
    input tx_valid
    );
parameter IDLE=3'b000;
    parameter CHK_CMD=3'b001;
    parameter WRITE=3'b010;
    parameter READ_ADD=3'b011;
    parameter READ_DATA=3'b100;
    reg [2:0] cs,ns;
    reg ADD_Ready;
integer counter =0;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        // reset
        //counter <=0;
       // MISO<=0;
        cs<=IDLE;
        ADD_Ready<=0;
    end
    else
    cs<=ns; 
end
always @(cs,MOSI,SS_n)begin
    case(cs)
    IDLE:if(~SS_n)
        ns=CHK_CMD;
        else
        ns=IDLE;
    CHK_CMD:if(SS_n)
            ns=IDLE;
            else if(~MOSI)
            ns=WRITE;
            else if(~ADD_Ready)
            ns=READ_ADD;
            else 
            ns=READ_DATA;
    WRITE:if(SS_n)
            ns=IDLE;
    READ_DATA:if(SS_n)
            ns=IDLE;
    READ_ADD:if(SS_n)
            ns=IDLE;
    endcase
end
always @(posedge clk ) begin
    if (cs==IDLE) begin
        counter<=0;
        din<=0;
        rx_valid<=0;
        MISO<=0;
    end
    else if (cs==WRITE) begin
            if (counter<10) begin
                din[9-counter]<=MOSI;
                 counter<=counter+1;
                  rx_valid<=0;
             end
            else
                 rx_valid<=1;
    end
    else if (cs==READ_ADD) begin
            if (counter<10) begin
                din[9-counter]<=MOSI;
                 counter<=counter+1;
                  rx_valid<=0;
             end
            else begin
                 rx_valid<=1;
                ADD_Ready<=1;
                 end
    end
    else if (cs==READ_DATA) begin
        if (counter<10) begin
                din[9-counter]<=MOSI;
                 counter<=counter+1;
                  rx_valid<=0;
             end
            else begin
                 rx_valid<=1;
                 ADD_Ready<=0;
                 end
        if (tx_valid) begin
            if (counter>2) begin
                MISO<=dout[counter-3];
                 counter<=counter-1;
             end
        end
    end
end
endmodule



module SPI_Wrapper_tb();
    reg MOSI,SS_n,clk,rst_n;
    wire  MISO;
    SPI_Wrapper DUT(MOSI,MISO,SS_n,clk,rst_n);
    integer i=0;
    initial begin
        clk=0;
        forever
        #2 clk=~clk;
    end
    initial begin
        rst_n=0;
        $readmemh("mem.dat",DUT.DUT.mem);
        repeat(5) @(negedge clk);
        rst_n=1;
        repeat(5) @(negedge clk);
        SS_n=0;//chk_cmd
        @(negedge clk)
        MOSI=0; //write
        @(negedge clk)
        MOSI=0; //write
        @(negedge clk)
        MOSI=0; //write address
        for(i=0;i<8;i=i+1)begin
            @(negedge clk) MOSI=1;
        end
        @(negedge clk) SS_n=1;/////////////////////////////////////////////////case write address done
        repeat(5) @(negedge clk);
        SS_n=0;//chk_cmd
        @(negedge clk)
        MOSI=0; //write
        @(negedge clk)
        MOSI=0; //write
        @(negedge clk)
        MOSI=1; //write data
        for(i=0;i<8;i=i+1)begin
            @(negedge clk) MOSI=$random;
        end
         @(negedge clk) SS_n=1;/////////////////////////////////////////////////case write data done
        repeat(5) @(negedge clk);
        SS_n=0;//chk_cmd
        @(negedge clk)
        MOSI=1; //read
        @(negedge clk)
        MOSI=1; //read 
        @(negedge clk)
        MOSI=0; //write data
        for(i=0;i<8;i=i+1)begin
            @(negedge clk) MOSI=1;
        end
         @(negedge clk) SS_n=1;/////////////////////////////////////////////////case read addr done
        repeat(5) @(negedge clk);
        SS_n=0;//chk_cmd
        @(negedge clk)
        MOSI=1; //read
        @(negedge clk)
        MOSI=1; //read
        @(negedge clk)
        MOSI=1; //read data
        for(i=0;i<8;i=i+1)begin
            @(negedge clk) MOSI=$random;
        end
        repeat(9) @(negedge clk);
        @(negedge clk) SS_n=1;/////////////////////////////////////////////////case read data done
        repeat(5) @(negedge clk);
        $stop;
    end

    endmodule