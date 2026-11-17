module data_in(
input rst,
input clk,
input data_in,
input count_reset_sig,
output reg [4:0] out,
output reg [3:0] count_out

//output reg clk_div	// ADD THIS TO TOP MOD PORT
	 
);
	
 

    always@(posedge clk) //?
    begin
        if(!rst)
            begin
                out = 5'b00000;       
                count_out = 4'b0000;     
            end
		else
            begin
                if(count_reset_sig)  
                    begin
                        count_out = 4'h0;
						out = 5'b00000;
								
                    end
                else
                    begin					
                        out = {out[3:0], data_in};
                        count_out = count_out + 1; 								
                    end
            end
    end
endmodule