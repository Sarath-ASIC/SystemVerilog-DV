module counter_ip #( 
                   parameter WIDTH =8 
                    )
  (input logic clk,
   input logic rst_n,
   input logic en,
   input logic load,
   input logic load_value;
   output logic [WIDTH-1 : 0] cout
  );

  always_ff @ (posedge clk ) 
    begin
    if(!rs_n)
      cout <= 8'b00000000;
    else if (load)
      cout <= load_value;
    else(enable)
      cout <= cout + 1;
    end
endmodule
      
  
  
