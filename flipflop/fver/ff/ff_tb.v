// Code your testbench here
// or browse Examples
module ff_tb();

  reg clk = 1;
  reg rst = 1;
  reg din = 0;
  //reg en = 0;
  wire dout;
  
  integer period = 10;
  
  ff uut(
    .clk(clk),
    .rst(rst),
    .din(din),
    //.en(en),
    .dout(dout)
  );
  
  
  initial begin
    forever #(period/2) clk = ~clk;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    
    #(2*period);
    
    rst = 1'b0;
    #(2*period);
    
    din = 1'b1;
    #(2*period);
    
    //en = 1'b1;
    //#(2*period);
    
    //en = 1'b0;
    din = 1'b0;
    #(10*period);
    
    $finish;
  end
  
endmodule