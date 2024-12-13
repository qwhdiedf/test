module matrix_alu(
	rstn, clk,
	start, finish,
	a, b, k, op, z
    );
	parameter integer sig_width = 23;      // RANGE 2 TO 253
  	parameter integer exp_width = 8;       // RANGE 3 TO 31
  	parameter integer ieee_compliance = 0; // RANGE 0 TO 1

	input 	wire 			clk, rstn, start;
	input  	wire [1151:0] 	a;			// 32 * 6 * 6
  	input  	wire [191:0] 	b;			// 32 * 1 * 6
	input 	wire [31:0]		k;
	input 	wire  [1:0]		op;			// 01 - add; 10 - dot; 
	output 	wire  [191:0]	z;			// 32 * 1 * 6
	output 	reg 			finish;

	reg  	[31:0] 		dot[0:5];
	wire  	[31:0] 		add[0:5];
	wire  	[31:0] 		vec[0:5];
	reg  	[31:0] 		res[0:5];

	reg [31:0] 	a_1_in, a_2_in, a_3_in;
	reg [31:0] 	b_1_in, b_2_in, b_3_in;
	reg 		op_in;
	wire [31:0]	sum_out;

	reg [5:0]	row_num;
	reg [191:0] cur_row;

	reg [31:0] 	left_sum_reg, right_sum_reg, k_a;
	wire [31:0]	row_sum, k_res;
	reg  		load_left, load_right, load_col;
	reg  		row_fin, mulk, nx_ready;

    wire        m_axis_result_tvalid_add;
    wire        m_axis_result_tvalid_mult;

	always @(*) begin
		case(row_num)
		6'b000001: 	cur_row = a[191:0];
		6'b000010: 	cur_row = a[383:192];
		6'b000100: 	cur_row = a[575:384];
		6'b001000: 	cur_row = a[767:576];
		6'b010000: 	cur_row = a[959:768];
		6'b100000: 	cur_row = a[1151:960];
		default:	cur_row = 192'd0;
		endcase
	end

	MAC3 u_mat_MAC(
		.a_1(a_1_in),
		.a_2(a_2_in),
		.a_3(a_3_in),
		.b_1(b_1_in),
		.b_2(b_2_in),
		.b_3(b_3_in),
		.op(op_in),
		.sum(sum_out)
	);

	// load data to MAC3
	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			a_1_in <= 0;
			b_1_in <= 0;
			a_2_in <= 0;
			b_2_in <= 0;
			a_3_in <= 0;
			b_3_in <= 0;
			op_in <= 0;
		end
		else if (load_left == 1) begin
			a_1_in <= cur_row[31:0];
			b_1_in <= b[31:0];
			a_2_in <= cur_row[63:32];
			b_2_in <= b[63:32];
			a_3_in <= cur_row[95:64];
			b_3_in <= b[95:64];
			op_in <= 1'b1;
		end
		else if (load_right == 1) begin
			a_1_in <= cur_row[127:96];
			b_1_in <= b[127:96];
			a_2_in <= cur_row[159:128];
			b_2_in <= b[159:128];
			a_3_in <= cur_row[191:160];
			b_3_in <= b[191:160];
			op_in <= 1'b1;
		end
		else if (load_col == 1) begin
			b_1_in <= 0;
			b_2_in <= 0;
			b_3_in <= 0;
			op_in <= 1'b0;
			if (row_num == 6'b000001) begin
				a_1_in <= a[        31:     0];
				a_2_in <= a[        223:    192];
				a_3_in <= b[        31:     0];
			end
			else if (row_num == 6'b000010) begin
				a_1_in <= a[        63:     32];
				a_2_in <= a[        255:    224];
				a_3_in <= b[        63:     32];
			end
			else if (row_num == 6'b000100) begin
				a_1_in <= a[        95:     64];
				a_2_in <= a[        287:    256];
				a_3_in <= b[        95:     64];
			end
			else if (row_num == 6'b001000) begin
				a_1_in <= a[        127:    96];
				a_2_in <= a[        319:    288];
				a_3_in <= b[        127:    96];
			end
			else if (row_num == 6'b010000) begin
				a_1_in <= a[        159:    128];
				a_2_in <= a[        351:    320];
				a_3_in <= b[        159:    128];
			end
			else if (row_num == 6'b100000) begin
				a_1_in <= a[        191:    160];
				a_2_in <= a[        383:    352];
				a_3_in <= b[        191:    160];
			end
		end
	end

	// row control signal
	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			row_num <= 0;
		end
		else if (start == 1) begin
			row_num <= 6'b000001;
		end
		else if (nx_ready == 1) begin
			row_num <= {row_num[4:0], 1'b0};	// left shift
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			load_left <= 0;
		end else if (op != 2'b10) begin
			load_left <= 0;
		end
		else if (start == 1 || nx_ready == 1 && row_num != 6'b100000) begin
			load_left <= 1;
		end
		else begin
			load_left <= 0;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			load_right <= 0;
		end
		else if (load_left == 1) begin
			load_right <= 1;
		end
		else begin
			load_right <= 0;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			row_fin <= 0;
		end
		else if (load_right == 1) begin
			row_fin <= 1;
		end
		else begin
			row_fin <= 0;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			mulk <= 0;
		end
		else if (row_fin == 1 || load_col == 1) begin
			mulk <= 1;
		end
		else begin
			mulk <= 0;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			nx_ready <= 0;
		end
		else if (mulk == 1) begin
			nx_ready <= 1;
		end
		else begin
			nx_ready <= 0;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			finish <= 0;
		end
		else if (nx_ready == 1 && row_num == 6'b100000) begin
			finish <= 1;
		end
		else begin
			finish <= 0;
		end
	end

	// result value store
	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			left_sum_reg <= 0;
		end
		else if (load_right == 1) begin
			left_sum_reg <= sum_out;
		end
		else begin
			left_sum_reg <= left_sum_reg;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			right_sum_reg <= 0;
		end
		else if (row_fin == 1) begin
			right_sum_reg <= sum_out;
		end
		else begin
			right_sum_reg <= right_sum_reg;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			// row_sum_reg <= 0;
		end
		else if (nx_ready == 1) begin
			// if (op == 2'b10) begin
				case(row_num)
				6'b000001: 	res[0] <= k_res;
				6'b000010: 	res[1] <= k_res;
				6'b000100: 	res[2] <= k_res;
				6'b001000: 	res[3] <= k_res;
				6'b010000: 	res[4] <= k_res;
				6'b100000: 	res[5] <= k_res;
				default:	;
				endcase
			// end
			// else if (op == 2'b01) begin
			// 	case(row_num)
			// 	6'b000001: 	res[0] <= k_res;
			// 	6'b000010: 	res[1] <= k_res;
			// 	6'b000100: 	res[2] <= k_res;
			// 	6'b001000: 	res[3] <= k_res;
			// 	6'b010000: 	res[4] <= k_res;
			// 	6'b100000: 	res[5] <= k_res;
			// 	default:	;
			// 	endcase
			// end
		end
	end

	
    float_add_sub u_sumup (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(left_sum_reg),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(right_sum_reg),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add),  
        .m_axis_result_tdata(row_sum)    
    );

	// add
	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			load_col <= 0;
		end else if ( op != 2'b01) begin
			load_col <= 0;
		end
		else if (start == 1 || nx_ready == 1 && row_num != 6'b100000) begin
			load_col <= 1;
		end
		else begin
			load_col <= 0;
		end
	end

	
    float_mult u_mulk (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(k_a),            
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(k),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult),  
        .m_axis_result_tdata(k_res)    
    );

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			k_a <= 0;
		end
		else if (mulk == 1) begin
			if (op == 2'b10) begin
				k_a <= row_sum; 
			end
			else if (op == 2'b01) begin
				k_a <= sum_out; 
			end
		end
	end

	assign z = {res[5], res[4], res[3], res[2], res[1], res[0]};
	
endmodule
