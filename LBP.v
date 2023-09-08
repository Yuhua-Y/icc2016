`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  reg [13:0] 	gray_addr;
output   reg gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output reg [13:0] 	lbp_addr;
output  reg	lbp_valid;
output  reg [7:0]lbp_data;
output  reg	finish;

reg [2:0]cur_st;
reg [2:0]next_st;
parameter  IDLE=3'd0,ADDR_DETERMINED=3'd1,READ_3=3'd2,READ_9=3'd3,WRITE=3'd4,FINISH=3'd5;

reg [7:0]buff0;
reg [7:0]buff1;
reg [7:0]buff2;
reg [7:0]buff3;
reg [7:0]buff5;
reg [7:0]buff6;
reg [7:0]buff7;
reg [7:0]buff8;

reg [7:0]CENTRAL_DATA;//CENTRAL
reg [13:0]out_addr;
reg [4:0]counter;
//====================================================================

always@(posedge clk or posedge reset)begin
    if(reset)
        cur_st<=IDLE;
    else
        cur_st<=next_st;
end

always @(*) begin
    case(cur_st)
        IDLE:next_st=(~gray_ready)?IDLE:ADDR_DETERMINED;
        ADDR_DETERMINED:next_st=(out_addr[6:0]==1)?READ_9:READ_3;
        READ_3:next_st=(counter==3)?WRITE:READ_3;
        READ_9:next_st=(counter==9)?WRITE:READ_9;
        WRITE:next_st=(out_addr<16255)?ADDR_DETERMINED:FINISH;
        FINISH:next_st=FINISH;
        default:next_st=IDLE;
    endcase
end

always@(*)begin   
    case(cur_st)
    READ_9:gray_req=(counter<=9)?1:0;
    READ_3:gray_req=(counter<=3)?1:0;
    default:gray_req=1'b0;
    endcase
end

//set out_addr
always @(posedge clk ) begin
    case(cur_st)
        IDLE:out_addr<=129;
        WRITE:out_addr<=out_addr+1;
    endcase
end

//counter
always @(posedge clk) begin
    case (cur_st)
        READ_9:begin
             if(counter==9)
                counter<=0;
             else
                counter<=counter+1;
        end 
        READ_3:begin
            if(counter==3)
                counter<=0;
             else
                counter<=counter+1;
        end
        default:  counter<=0;
    endcase
end


//set gray_addr
always@(*)begin
    case (cur_st)
        READ_9:begin
            case (counter)
                1:gray_addr=out_addr-129;
                2:gray_addr=out_addr-128;
                3:gray_addr=out_addr-127;
                4:gray_addr=out_addr-1;
                5:gray_addr=out_addr;
                6:gray_addr=out_addr+1;
                7:gray_addr=out_addr+127;
                8:gray_addr=out_addr+128;
                9:gray_addr=out_addr+129;
                default:gray_addr=0;
             endcase
            end
        READ_3:begin
            case (counter)
               1:gray_addr=out_addr-127;// new buff[2]\[5]\[8]
               2:gray_addr=out_addr+1;
               3:gray_addr=out_addr+129;
                default:gray_addr=0;
            endcase
               end
        default:gray_addr=0;
    endcase
end

//buff
always @(posedge clk) begin//posedge clk
    case (cur_st)
        READ_3: begin
            case(counter)
            1:begin
                buff0<=buff1;
                buff1<=buff2;
                buff2<=gray_data;
            end
            2:begin
                buff3<=CENTRAL_DATA;
                CENTRAL_DATA<=buff5;
                buff5<=gray_data;
            end
            3:begin
                buff6<=buff7;
                buff7<=buff8;
                buff8<=gray_data;
            end
            endcase
        end
        READ_9: begin
            case (counter)
                1:buff0<=gray_data;
                2:buff1<=gray_data;
                3:buff2<=gray_data;
                4:buff3<=gray_data;
                5:CENTRAL_DATA<=gray_data;
                6:buff5<=gray_data;
                7:buff6<=gray_data;
                8:buff7<=gray_data;
                9:buff8<=gray_data;
            endcase
        end
    endcase
end


//lbp_valid
always@(posedge clk)begin
    case(cur_st)
    WRITE:lbp_valid<=1'b1;
    default:lbp_valid<=1'b0;
    endcase
end

//Lbp_addr
always @(posedge clk) begin
    if(cur_st==WRITE)
        lbp_addr<=out_addr;
end

//Lbp_data
always@(posedge clk)begin
    case (cur_st)
        WRITE: begin
            if((out_addr[6:0]==0)||(out_addr[6:0]==127)) 
                lbp_data<=8'b0;
            else begin
            lbp_data[0]<=(buff0>=CENTRAL_DATA);
            lbp_data[1]<=(buff1>=CENTRAL_DATA);
            lbp_data[2]<=(buff2>=CENTRAL_DATA);
            lbp_data[3]<=(buff3>=CENTRAL_DATA);
            lbp_data[4]<=(buff5>=CENTRAL_DATA);
            lbp_data[5]<=(buff6>=CENTRAL_DATA);
            lbp_data[6]<=(buff7>=CENTRAL_DATA);
            lbp_data[7]<=(buff8>=CENTRAL_DATA);
            end
        end
        default:lbp_data<=0;
    endcase
end

always @(*) begin
    if(cur_st==FINISH)
        finish=1;
    else
        finish=0;
end



//====================================================================
endmodule
