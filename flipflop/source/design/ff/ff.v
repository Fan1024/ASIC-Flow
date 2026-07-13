// Code your design here
module ff(
  input clk,
  input rst,
  input din,
  input en,
  output dout
);
  
  reg ff = 1'bz;
  
  
  always @(posedge clk) begin
    if(rst) begin
    	ff <= 0;
    end
    else begin
      if(en) begin
        ff <= din;
      end
      else begin
      	ff <= ff;
      end
    end
  end
  
  /*
  always @(posedge clk) begin
    if(rst) begin
    	ff <= 0;
    end
    else begin
        ff <= din;
    end
  end
  */
  
  assign dout = ff;
  
endmodule
