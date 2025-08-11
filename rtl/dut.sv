//---------------------------------------------------------------------------
// DUT - Mini project 
//---------------------------------------------------------------------------
`include "common.vh"

module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//input SRAM interface
  output wire          dut__tb__sram_input_write_enable  ,
  output wire [15:0]   dut__tb__sram_input_write_address ,
  output wire [31:0]   dut__tb__sram_input_write_data    ,
  output wire [15:0]   dut__tb__sram_input_read_address  , 
  input  wire [31:0]   tb__dut__sram_input_read_data     ,     

//weight SRAM interface
  output wire          dut__tb__sram_weight_write_enable  ,
  output wire [15:0]   dut__tb__sram_weight_write_address ,
  output wire [31:0]   dut__tb__sram_weight_write_data    ,
  output wire [15:0]   dut__tb__sram_weight_read_address  , 
  input  wire [31:0]   tb__dut__sram_weight_read_data     ,     

//result SRAM interface
  output wire          dut__tb__sram_result_write_enable  ,
  output wire [15:0]   dut__tb__sram_result_write_address ,
  output wire [31:0]   dut__tb__sram_result_write_data    ,
  output wire [15:0]   dut__tb__sram_result_read_address  , 
  input  wire [31:0]   tb__dut__sram_result_read_data          

);

//reg          dut__tb__sram_input_write_enable_r;
//reg [11:0]   dut__tb__sram_input_write_address_r;
//reg [31:0]   dut__tb__sram_input_write_data_r;
//reg [11:0]   dut__tb__sram_input_read_address_r;

//reg dut__tb__sram_weight_write_enable_r;
//reg [11:0]   dut__tb__sram_weight_write_address_r;
//reg [31:0]   dut__tb__sram_weight_write_data_r;
//reg [11:0]   dut__tb__sram_weight_read_address_r;

//reg [11:0]   dut__tb__sram_result_write_address_r;
//reg [31:0]   dut__tb__sram_result_write_data_r;
//reg [11:0]   dut__tb__sram_result_read_address_r;

reg compute_multi; 


// synopsys translate_off
  shortreal test_val;
  assign test_val = $bitstoshortreal(Adata); 
  // This is a helper val for seeing the 32bit flaot value, you can repicate 
  // this for any signal, but keep it between the translate_off and
  // translate_on 
// synopsys translate_on

reg Arows;
reg Acols;
reg Brows;
reg Bcols;
reg Crows;
reg Ccols;

reg [15:0] Aaddress;
reg [15:0] Baddress;
reg [15:0] Caddress;
reg [15:0] Caddress_w;
reg [31:0] Adata;
reg [31:0] Bdata;
wire [31:0] Cdata;
reg [31:0] Cdata_w = 32'b0;
reg [31:0] C_Acc;
reg C_WE;
reg [2:0] irnd = 3'd0;
wire [7:0] status;
reg BA = 1'd1;

reg A_address = 1'd0;
reg B_address = 1'd0;
reg C_address = 1'd0;

`ifndef SRAM_ADDR_WIDTH
    `define SRAM_ADDR_WIDTH 16
  `endif

  `ifndef SRAM_DATA_WIDTH
    `define SRAM_DATA_WIDTH 32
  `endif
  
`ifndef FSM_BIT_WIDTH
    `define FSM_BIT_WIDTH 6
  `endif
  
  typedef enum logic [`FSM_BIT_WIDTH-1:0] {
  IDLE                          = `FSM_BIT_WIDTH'b000_001,
  GET_R_C          		        = `FSM_BIT_WIDTH'b000_010,
  COMPUTE_MULTIPLICATION	    = `FSM_BIT_WIDTH'b000_100,
  SAVE_C_VALUE			        = `FSM_BIT_WIDTH'b001_000,
  COMPUTE_COMPLETE           	= `FSM_BIT_WIDTH'b010_000
  } e_states;
  
  e_states current_state, next_state;
  
  reg               set_dut_ready         ;
  reg               get_RC_A      		  ;
  reg	            get_RC_B      		  ;
  reg [1:0]		    read_addr_selA		  ;
  reg [1:0]			read_addr_selB		  ;
  reg [1:0]			read_addr_selC		  ;
  reg				save_rc_A     		  ;
  reg				save_rc_B     		  ;
  reg				check_size    		  ;
  reg               compute_multiplication;
  reg               write_enable_selC     ;
  reg 				reset_C               ;
  
always @(posedge clk) begin : proc_current_state_fsm
if(!reset_n) begin // Synchronous reset
    current_state <= IDLE;
  end else begin
    current_state <= next_state;
  end
end

always @(*) begin : proc_next_state_fsm
  case (current_state)
  
  
	IDLE                       : begin
      if (dut_valid) begin
        set_dut_ready          = 1'b0;
        get_RC_A               = 1'b0;
	    get_RC_B               = 1'b0;
        read_addr_selA         = 2'b00;
	    read_addr_selB         = 2'b00;
	    read_addr_selC         = 2'b00;
	    save_rc_A	           = 1'b0;
	    save_rc_B	           = 1'b0;
	    check_size	           = 1'b0;
        compute_multiplication = 1'b0;
        write_enable_selC      = 1'b0;
        next_state             = GET_R_C;
      end
      else begin
        set_dut_ready          = 1'b1;
        get_RC_A               = 1'b0;
	    get_RC_B               = 1'b0;
        read_addr_selA         = 2'b00;
	    read_addr_selB         = 2'b00;
	    read_addr_selC         = 2'b00;
	    save_rc_A	           = 1'b0;
	    save_rc_B	           = 1'b0;
	    check_size	           = 1'b0;
        compute_multiplication = 1'b0;
        write_enable_selC      = 1'b0;
        next_state             = IDLE;
      end
    end
	
	GET_R_C		       : begin
	    set_dut_ready          = 1'b0;
        get_RC_A               = 1'b1;
	    get_RC_B               = 1'b1;
        read_addr_selA         = 2'b01;
	    read_addr_selB         = 2'b01;
	    read_addr_selC         = 2'b00;
	    save_rc_A	           = 1'b0;
	    save_rc_B	           = 1'b0;
	    check_size	           = 1'b0;
        compute_multiplication = 1'b0;
        write_enable_selC      = 1'b0;
        next_state             = COMPUTE_MULTIPLICATION;
	end
		
	COMPUTE_MULTIPLICATION : begin
	    set_dut_ready          = 1'b0;
        get_RC_A               = 1'b0;
	    get_RC_B               = 1'b0;
        read_addr_selA         = 2'b01;
	    read_addr_selB         = 2'b01;
	    read_addr_selC         = (C_address > 0) ? 2'b10 : 2'b00 ;
	    save_rc_A	           = 1'b1;
	    save_rc_B	           = 1'b1;
	    check_size	           = 1'b0;
        compute_multiplication = 1'b1;
        write_enable_selC      = 1'b0;
        next_state             = (B_address == (BA * Brows)) ? SAVE_C_VALUE : COMPUTE_MULTIPLICATION;
	end
	
	SAVE_C_VALUE           : begin
	    set_dut_ready          = 1'b0;
        get_RC_A               = 1'b0;
	    get_RC_B               = 1'b0;
        read_addr_selA         = 2'b10;
	    read_addr_selB         = 2'b10;
	    read_addr_selC         = 2'b01;
	    save_rc_A	           = 1'b1;
	    save_rc_B	           = 1'b1;
	    check_size	           = 1'b1;
        compute_multiplication = 1'b0;
        write_enable_selC      = 1'b1;
        next_state             = (C_address == ((Crows * Ccols))) ? COMPUTE_COMPLETE : COMPUTE_MULTIPLICATION;
	end
	
	COMPUTE_COMPLETE       : begin
	    set_dut_ready          = 1'b1;
        get_RC_A               = 1'b0;
	    get_RC_B               = 1'b0;
        read_addr_selA         = 2'b00;
	    read_addr_selB         = 2'b00;
	    read_addr_selC         = 2'b00;
	    save_rc_A	           = 1'b0;
	    save_rc_B	           = 1'b0;
	    check_size             = 1'b0;
        compute_multiplication = 1'b0;
        write_enable_selC      = 1'b0;
        next_state             = IDLE;
	end
	
	default					:begin
	    set_dut_ready          = 1'b1;
        get_RC_A               = 1'b0;
	    get_RC_B               = 1'b0;
        read_addr_selA         = 2'b00;
	    read_addr_selB         = 2'b00;
	    read_addr_selC         = 2'b00;
	    save_rc_A	           = 1'b0;
	    save_rc_B	           = 1'b0;
	    check_size	           = 1'b0;
        compute_multiplication = 1'b0;
        write_enable_selC      = 1'b0;
        next_state             = IDLE;
	end
  endcase
end

always @(posedge clk) begin : proc_compute_multi
  if(!reset_n) begin
    compute_multi <= 0;
  end else begin
    compute_multi <= (set_dut_ready) ? 1'b1 : 1'b0;
  end
end

assign dut_ready = compute_multi;

always@(posedge clk) begin: proc_rc_size
  if(!reset_n) begin
    Arows <= 1'b0;
	Acols <= 1'b0;
	Brows <= 1'b0;
	Bcols <= 1'b0;
  end else begin
    Arows <= (get_RC_A ? (tb__dut__sram_input_read_data[31:16]) : (save_rc_A ? (Arows) : 1'b0));
	Acols <= (get_RC_A ? (tb__dut__sram_input_read_data[15:0]) : (save_rc_A ? (Acols) : 1'b0));
	Brows <= (get_RC_B ? (tb__dut__sram_weight_read_data[31:16]) : (save_rc_B ? (Brows) : 1'b0));
	Bcols <= (get_RC_B ? (tb__dut__sram_weight_read_data[15:0]) : (save_rc_B ? (Bcols) : 1'b0));
   end
 end
 
 assign Crows = Arows;
 assign Ccols = Bcols;
 
always@(posedge clk) begin

	if (!reset_n) begin
	   Aaddress <= 0;
	end
	
	else if (check_size) begin
		if ((B_address == (BA * Brows)) && (BA < Bcols)) begin
			Aaddress <= 16'b0;
			A_address <= 1'd0;
			BA <= BA + 1'd1;
		end
		else if (BA == Bcols)
			BA <= 1'd1;
		else if (B_address == (Brows * Bcols)) begin
		    Aaddress <= ((Arows - 1) * Acols + 1);
			A_address <= 1'd0;
		end
	end

	  
	else if (read_addr_selA == 2'b00 && !check_size)
		Aaddress <= `SRAM_ADDR_WIDTH'b0;
	else if (read_addr_selA == 2'b01 && !check_size) begin
		Aaddress <= Aaddress + `SRAM_ADDR_WIDTH'b1;
		A_address <= A_address + 1'd1;
	end
	else if (read_addr_selA == 2'b10 && !check_size) begin
		Aaddress <= Aaddress;
		A_address <= A_address;
	end
	else if (read_addr_selA == 2'b11 && !check_size)
		Aaddress <= `SRAM_ADDR_WIDTH'b01;
	  //else begin
	  //	Aaddress <= Aaddress;
	  //	A_address <= A_address;
	  //end
end

assign dut__tb__sram_input_read_address = Aaddress;

always@(posedge clk) begin

	if (!reset_n) begin
	   Baddress <= 0;
	end
	
	else if (check_size) begin
		if (B_address == (Brows * Bcols)) begin
			Baddress <= 16'b0;
			B_address <= 1'd0;
		end
	end

	else if (read_addr_selB == 2'b00 && !check_size)
		Baddress <= `SRAM_ADDR_WIDTH'b0;
	else if (read_addr_selB == 2'b01 && !check_size) begin
		Baddress <= Baddress + `SRAM_ADDR_WIDTH'b1;
		B_address <= B_address + 1'd1;
	end
	else if (read_addr_selB == 2'b10 && !check_size) begin
		Baddress <= Baddress;
		B_address <= B_address;
	end
	else if (read_addr_selB == 2'b11 && !check_size)
		Baddress <= `SRAM_ADDR_WIDTH'b01;
	  	  //else begin
		  //	Baddress <= Baddress;
		  //	B_address <= B_address;
	  	  //end
end

assign dut__tb__sram_weight_read_address = Baddress;

always@(posedge clk) begin
	if (!reset_n) begin
	   Caddress <= 0;
	end
	else begin
	  if (read_addr_selC == 2'b00)
		Caddress <= `SRAM_ADDR_WIDTH'b0;
	  else if (read_addr_selC == 2'b01) begin
		Caddress <= Caddress + `SRAM_ADDR_WIDTH'b1;
		C_address <= C_address + 1'd1;
	  end
	  else if (read_addr_selC == 2'b10) begin
	    Caddress <= Caddress;
		C_address <= C_address;
	   end
	  else if (read_addr_selC == 2'b11)
	    Caddress <= `SRAM_ADDR_WIDTH'b01;
	end
end

assign dut__tb__sram_result_read_address = Caddress;

always@(posedge clk) begin
	if(!reset_n) begin
		C_WE <= 1'b0;
	end else begin
		C_WE <= write_enable_selC ? 1'b1 : 1'b0;
	end
end

assign dut__tb__sram_result_write_enable = C_WE;

always@(posedge clk) begin
	if (!reset_n) begin
		Caddress_w <= 16'b0;
	end else begin
		Caddress_w <= (write_enable_selC) ? Caddress : `SRAM_DATA_WIDTH'b0;
	end
end

assign dut__tb__sram_result_write_address = Caddress_w;

always @(posedge clk) begin
  if(!reset_n) begin
    Cdata_w <= `SRAM_DATA_WIDTH'b0;
  end else begin
    Cdata_w <= (write_enable_selC) ? Cdata : `SRAM_DATA_WIDTH'b0;
  end
end

assign dut__tb__sram_result_write_data = Cdata_w;

always@(posedge clk) begin
	if(!reset_n) begin
		Adata <= `SRAM_DATA_WIDTH'b0;
		Bdata <= `SRAM_DATA_WIDTH'b0;
		C_Acc <= `SRAM_DATA_WIDTH'b0;
	end
	else begin
	   if (compute_multiplication) begin
			if (A_address == 1'd1) begin
				Adata <= tb__dut__sram_input_read_data;
				Bdata <= tb__dut__sram_weight_read_data;
				C_Acc <= 0;
			end
			else begin
				Adata <= tb__dut__sram_input_read_data;
				Bdata <= tb__dut__sram_weight_read_data;
				C_Acc <= Cdata;
			end
		end
	    else begin
		    Adata <= `SRAM_DATA_WIDTH'b0;
			Bdata <= `SRAM_DATA_WIDTH'b0;
			C_Acc <= `SRAM_DATA_WIDTH'b0;
		end
	end
end

DW_fp_mac_inst 
  FP_MAC ( 
  .Adata(tb__dut__sram_input_read_data),
  .Bdata(tb__dut__sram_weight_read_data),
  .C_Acc(accum_result),
  .irnd(3'd0),
  .Cdata(mac_result_z),
  .status()
);

endmodule

module DW_fp_mac_inst #(
  parameter inst_sig_width = 23,
  parameter inst_exp_width = 8,
  parameter inst_ieee_compliance = 0 // These need to be fixed to decrease error
) ( 
  input wire [inst_sig_width+inst_exp_width : 0] Adata,
  input wire [inst_sig_width+inst_exp_width : 0] Bdata,
  input wire [inst_sig_width+inst_exp_width : 0] C_Acc,
  input wire [2 : 0] irnd,
  output wire [inst_sig_width+inst_exp_width : 0] Cdata,
  output wire [7 : 0] status
);

  // Instance of DW_fp_mac
  DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
    .a(Adata),
    .b(Bdata),
    .c(C_Acc),
    .rnd(3'd0),
    .z(Cdata),
    .status(status) 
  );

endmodule: DW_fp_mac_inst
