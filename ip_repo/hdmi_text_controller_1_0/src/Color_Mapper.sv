//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//                                                                       --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module color_mapper ( input  logic [9:0] DrawX, DrawY,
                       input logic [31:0] slv_regs[601],
                       output logic [7:0]  Red, Green, Blue );
    


logic [10:0] sprite_addr;
logic [7:0] sprite_data;

//get the position of the Block we in
//20 regs per row, 30 rows per col
logic[20:0] regnum; //which reg it is in
logic[4:0] charnum; //Which Char it is in inside the Reg
logic[3:0] rownum; //row in the font stuff
logic[2:0] colnum;     
logic[31:0] usereg;
logic[31:0] control_reg;

always_comb begin
    regnum = (DrawY/16)*20+(DrawX/8)/4;
    charnum = (DrawX/8)%4;
    rownum = DrawY%16;
    colnum = DrawX%8;
end

assign usereg = slv_regs[regnum];
logic conbit; //the control bit for that char for inverse
//int lowbound = 8*charnum; int upbound = 8*(charnum+1)-1; //get the upper and lower bound
always_comb
begin
    if (charnum == 0) begin
        sprite_addr = {usereg[6:0],rownum};
        conbit = usereg[7];
    end else if (charnum == 1) begin
        sprite_addr = {usereg[14:8],rownum};
        conbit = usereg[15];
    end else if (charnum == 2) begin
        sprite_addr = {usereg[22:16],rownum};
        conbit = usereg[23];
    end else begin
        sprite_addr = {usereg[30:24],rownum};
        conbit = usereg[31];
    end
end



font_rom fontrom (
    .addr(sprite_addr),
    .data(sprite_data)
);

logic [7:0] BGR,BGG,BGB; //BackGround Color
logic [7:0] FGR,FGG,FGB; //FrontGround Color

assign control_reg = slv_regs[600];
//Getting the background and frontground color
assign BGR = {4'b0000,control_reg[12:9]}; 
assign BGG = {4'b0000,control_reg[8:5]}; 
assign BGB = {4'b0000,control_reg[4:1]};
assign FGR = {4'b0000,control_reg[24:21]}; 
assign FGG = {4'b0000,control_reg[20:17]}; 
assign FGB = {4'b0000,control_reg[16:13]};

logic colweneed; 
assign colweneed = sprite_data[7 - colnum]; //the pixel we need
always_comb begin
    if (colweneed == 1) begin
        //if pixel on
        if (conbit == 0) begin
            //if no inverse
            Red = FGR; Green = FGG; Blue = FGB;
        end else begin
            //if inverse
            Red = BGR; Green = BGG; Blue = BGB;
        end
    end
    else begin
        //if pixel off
        if (conbit == 0) begin
            //if no inverse
            Red = BGR; Green = BGG; Blue = BGB;
        end else begin
            //if inverse
            Red = FGR; Green = FGG; Blue = FGB;
        end
    end
end


endmodule
