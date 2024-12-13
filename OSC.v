module OSC(
input wire rstn,
input wire clk,
input wire  [31:0] parameter_Kv,

input wire  [31:0] parameter_lamb,
input wire  [31:0] parameter_scale_xyz,

input wire step0,


input wire  [31:0] dq_1, // velocity
input wire  [31:0] dq_2,
input wire  [31:0] dq_3,
input wire  [31:0] dq_4,
input wire  [31:0] dq_5,
input wire  [31:0] dq_6,

input wire  [31:0] target_1,    // target
input wire  [31:0] target_2,
input wire  [31:0] target_3,

input wire  [31:0] EE_position_1,    // EE_position
input wire  [31:0] EE_position_2,
input wire  [31:0] EE_position_3,

input wire  [31:0] J_1_1,       // Jacobian_Matrix
input wire  [31:0] J_2_1,
input wire  [31:0] J_3_1,

input wire  [31:0] J_1_2,       // Jacobian_Matrix
input wire  [31:0] J_2_2,
input wire  [31:0] J_3_2,

input wire  [31:0] J_1_3,       // Jacobian_Matrix
input wire  [31:0] J_2_3,
input wire  [31:0] J_3_3,

input wire  [31:0] J_1_4,       // Jacobian_Matrix
input wire  [31:0] J_2_4,
input wire  [31:0] J_3_4,

input wire  [31:0] J_1_5,       // Jacobian_Matrix
input wire  [31:0] J_2_5,
input wire  [31:0] J_3_5,

input wire  [31:0] J_1_6,       // Jacobian_Matrix
input wire  [31:0] J_2_6,
input wire  [31:0] J_3_6,

input wire  [31:0] M_1_1,       // inertia matrix in joint space
input wire  [31:0] M_2_1,
input wire  [31:0] M_3_1,
input wire  [31:0] M_4_1,
input wire  [31:0] M_5_1,
input wire  [31:0] M_6_1,

input wire  [31:0] M_1_2,       // inertia matrix in joint space
input wire  [31:0] M_2_2,
input wire  [31:0] M_3_2,
input wire  [31:0] M_4_2,
input wire  [31:0] M_5_2,
input wire  [31:0] M_6_2,

input wire  [31:0] M_1_3,       // inertia matrix in joint space
input wire  [31:0] M_2_3,
input wire  [31:0] M_3_3,
input wire  [31:0] M_4_3,
input wire  [31:0] M_5_3,
input wire  [31:0] M_6_3,

input wire  [31:0] M_1_4,       // inertia matrix in joint space
input wire  [31:0] M_2_4,
input wire  [31:0] M_3_4,
input wire  [31:0] M_4_4,
input wire  [31:0] M_5_4,
input wire  [31:0] M_6_4,

input wire  [31:0] M_1_5,       // inertia matrix in joint space
input wire  [31:0] M_2_5,
input wire  [31:0] M_3_5,
input wire  [31:0] M_4_5,
input wire  [31:0] M_5_5,
input wire  [31:0] M_6_5,

input wire  [31:0] M_1_6,       // inertia matrix in joint space
input wire  [31:0] M_2_6,
input wire  [31:0] M_3_6,
input wire  [31:0] M_4_6,
input wire  [31:0] M_5_6,
input wire  [31:0] M_6_6,

// inertia matrix in task space
input wire [31:0] Mx_1_1,       
input wire [31:0] Mx_1_2,
input wire [31:0] Mx_1_3,       
input wire [31:0] Mx_2_1,
input wire [31:0] Mx_2_2,       
input wire [31:0] Mx_2_3,
input wire [31:0] Mx_3_1,       
input wire [31:0] Mx_3_2,
input wire [31:0] Mx_3_3,

input wire  [31:0] gravity_bias_1,
input wire  [31:0] gravity_bias_2,
input wire  [31:0] gravity_bias_3,
input wire  [31:0] gravity_bias_4,
input wire  [31:0] gravity_bias_5,
input wire  [31:0] gravity_bias_6,

output wire [31:0] u_1,      
output wire [31:0] u_2, 
output wire [31:0] u_3, 
output wire [31:0] u_4, 
output wire [31:0] u_5, 
output wire [31:0] u_6,

output reg  	   valid

);

// steps
reg 			step1, 
				step2, 
				step3, 
				step4,
				step5,
				step6,
				step7;

// parameter
wire 	[31:0] 	parameter_kv_x_lamb, 
				parameter_minus_Kv;

// u task
wire 	[31:0] 	u_task_1, 
				u_task_2, 
				u_task_3;

reg 	[31:0] 	u_task_1_reg, 
				u_task_2_reg, 
				u_task_3_reg;

// u task after limit
wire 	[31:0] 	u_task_1_after_limit,
				u_task_2_after_limit,
				u_task_3_after_limit,
				u_task_1_after_para,
				u_task_2_after_para,
				u_task_3_after_para;

reg 	[31:0] 	u_task_1_after_limit_reg,
				u_task_2_after_limit_reg,
				u_task_3_after_limit_reg;

wire 	[191:0] u_task_after_limit;

// matrix M
wire 	[191:0] 	M_1, M_2, M_3, M_4, M_5, M_6;
wire 	[1151:0] 	mat_M;

// vec dq
wire 	[191:0] 	dq;
reg 	[191:0] 	dot_M_dq_reg;

wire 	[191:0] 	Mx1, Mx2, Mx3;
wire 	[1151:0]	Mx;

reg 	[191:0] 	dot_Mx_u_task_reg;

wire [31:0] parameter_K1, parameter_minus_K1;

wire                m_axis_result_tvalid_mult_1;
wire                m_axis_result_tvalid_sub_1;


assign parameter_K1 		= 32'b00111111100000000000000000000000;		// 1.0
assign parameter_minus_K1 	= 32'b10111111100000000000000000000000;		// -1.0

assign Mx1 = {96'd0, Mx_1_3, Mx_1_2, Mx_1_1};
assign Mx2 = {96'd0, Mx_2_3, Mx_2_2, Mx_2_1};
assign Mx3 = {96'd0, Mx_3_3, Mx_3_2, Mx_3_1};

assign Mx = {576'd0, Mx3, Mx2, Mx1};

// matrix J
wire 	[191:0] 	J1, J2, J3, J4, J5, J6;
wire 	[1151:0] 	J;

wire 	[191:0] 	dot_JT_Mx_u_task;
reg 	[191:0] 	dot_JT_Mx_u_task_reg;

wire 	[191:0] 	gravity_bias;
wire 	[1151:0] 	dots;
reg 	[191:0] 	u_reg;

assign gravity_bias = {
	gravity_bias_6,
	gravity_bias_5,
	gravity_bias_4,
	gravity_bias_3,
	gravity_bias_2,
	gravity_bias_1
	};

assign M_1 = {M_1_6, M_1_5, M_1_4, M_1_3, M_1_2, M_1_1};
assign M_2 = {M_2_6, M_2_5, M_2_4, M_2_3, M_2_2, M_2_1};
assign M_3 = {M_3_6, M_3_5, M_3_4, M_3_3, M_3_2, M_3_1};
assign M_4 = {M_4_6, M_4_5, M_4_4, M_4_3, M_4_2, M_4_1};
assign M_5 = {M_5_6, M_5_5, M_5_4, M_5_3, M_5_2, M_5_1};
assign M_6 = {M_6_6, M_6_5, M_6_4, M_6_3, M_6_2, M_6_1};

assign mat_M 	= {M_6, M_5, M_4, M_3, M_2, M_1};
assign dq 		= {dq_6, dq_5, dq_4, dq_3, dq_2, dq_1};

assign J1 = {96'd0, J_3_1, J_2_1, J_1_1};
assign J2 = {96'd0, J_3_2, J_2_2, J_1_2};
assign J3 = {96'd0, J_3_3, J_2_3, J_1_3};
assign J4 = {96'd0, J_3_4, J_2_4, J_1_4};
assign J5 = {96'd0, J_3_5, J_2_5, J_1_5};
assign J6 = {96'd0, J_3_6, J_2_6, J_1_6};

assign J = {J6, J5, J4, J3, J2, J1};

// matrix alu unit
reg 	[1151:0] 	mlu_a;
reg 	[191:0] 	mlu_b;
reg 	[31:0] 		mlu_k;
reg  	[1:0]		mlu_op;
reg 				start ;
wire 	[191:0] 	mlu_z;
wire 				finish;

matrix_alu u_mlu(
	.clk(clk),
	.rstn(rstn),
	.start(start),
	.finish(finish),
	.a(mlu_a),
	.b(mlu_b),	
	.k(mlu_k),
	.op(mlu_op),
	.z(mlu_z)
);


float_mult kv_lamb_mult (
    .s_axis_a_tvalid(1'b1),           
    .s_axis_a_tdata(parameter_Kv),              
    .s_axis_b_tvalid(1'b1),           
    .s_axis_b_tdata(parameter_lamb),              
    .m_axis_result_tvalid(m_axis_result_tvalid_mult_1),  
    .m_axis_result_tdata(parameter_kv_x_lamb)    
);

// assign u_task_1 = EE_position_1 - target_1;
// assign u_task_2 = EE_position_2 - target_2;
// assign u_task_3 = EE_position_3 - target_3;

float_sub u_task_sub_1 (
    .s_axis_a_tvalid(1'b1),            
    .s_axis_a_tdata(EE_position_1),              
    .s_axis_b_tvalid(1'b1),            
    .s_axis_b_tdata(target_1),              
    .m_axis_result_tvalid(m_axis_result_tvalid_sub_1), 
    .m_axis_result_tdata(u_task_1)    
);

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        u_task_1_reg <= 0;
    end
    else if (step0 == 1) begin
        u_task_1_reg <= u_task_1;
    end
    else begin
        u_task_1_reg <= u_task_1_reg;
    end
end

float_sub u_task_sub_2 (
    .s_axis_a_tvalid(1'b1),            
    .s_axis_a_tdata(EE_position_2),              
    .s_axis_b_tvalid(1'b1),            
    .s_axis_b_tdata(target_2),              
    .m_axis_result_tvalid(m_axis_result_tvalid_sub_2), 
    .m_axis_result_tdata(u_task_2)    
);

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        u_task_2_reg <= 0;
    end
    else if (step0 == 1) begin
        u_task_2_reg <= u_task_2;
    end
    else begin
        u_task_2_reg <= u_task_2_reg;
    end
end

float_sub u_task_sub_3 (
    .s_axis_a_tvalid(1'b1),            
    .s_axis_a_tdata(EE_position_3),              
    .s_axis_b_tvalid(1'b1),            
    .s_axis_b_tdata(target_3),              
    .m_axis_result_tvalid(m_axis_result_tvalid_sub_3), 
    .m_axis_result_tdata(u_task_3)    
);

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        u_task_3_reg <= 0;
    end
    else if (step0 == 1) begin
        u_task_3_reg <= u_task_3;
    end
    else begin
        u_task_3_reg <= u_task_3_reg;
    end
end

// begin
// step1 
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        step1 <= 0;
    end else if (finish) begin
        step1 <= 0;
    end
    else if (step0 == 1) begin
        step1 <= 1;
    end
    else begin
        step1 <= step1;
    end
end
// xyz
// u_task_1_after_limit = min(u_task_1_reg, parameter_scale_xyz)
// assign u_task_1_after_limit = ( u_task_1_reg >  parameter_scale_xyz ) ? parameter_scale_xyz  : u_task_1_reg;
// assign u_task_2_after_limit = ( u_task_2_reg >  parameter_scale_xyz ) ? parameter_scale_xyz  : u_task_2_reg;
// assign u_task_3_after_limit = ( u_task_3_reg >  parameter_scale_xyz ) ? parameter_scale_xyz  : u_task_3_reg;

min     u_task_1_min(
    .a(u_task_1_reg),
    .b(parameter_scale_xyz),
    .c(u_task_1_after_limit)
);

float_mult u_task_1_mult (
  .s_axis_a_tvalid(1'b1),            
  .s_axis_a_tdata(u_task_1_after_limit),              
  .s_axis_b_tvalid(1'b1),          
  .s_axis_b_tdata(parameter_kv_x_lamb),              
  .m_axis_result_tvalid(m_axis_result_tvalid_mult_2),  
  .m_axis_result_tdata(u_task_1_after_para)   
);


min     u_task_2_min(
    .a(u_task_2_reg),
    .b(parameter_scale_xyz),
    .c(u_task_2_after_limit)
);

float_mult u_task_2_mult (
  .s_axis_a_tvalid(1'b1),            
  .s_axis_a_tdata(u_task_2_after_limit),              
  .s_axis_b_tvalid(1'b1),          
  .s_axis_b_tdata(parameter_kv_x_lamb),              
  .m_axis_result_tvalid(m_axis_result_tvalid_mult_3),  
  .m_axis_result_tdata(u_task_2_after_para)   
);

min     u_task_3_min(
    .a(u_task_3_reg),
    .b(parameter_scale_xyz),
    .c(u_task_3_after_limit)
);

float_mult u_task_3_mult (
  .s_axis_a_tvalid(1'b1),            
  .s_axis_a_tdata(u_task_3_after_limit),              
  .s_axis_b_tvalid(1'b1),          
  .s_axis_b_tdata(parameter_kv_x_lamb),              
  .m_axis_result_tvalid(m_axis_result_tvalid_mult_4),  
  .m_axis_result_tdata(u_task_3_after_para)   
);

// a,beita,gama
// assign u_task_1_4 = ( u_task_1_4 >  parameter_scale_abg ) ? parameter_scale_abg  : u_task_1_4;
// assign u_task_1_5 = ( u_task_1_5 >  parameter_scale_abg ) ? parameter_scale_abg  : u_task_1_5;
// assign u_task_1_6 = ( u_task_1_6 >  parameter_scale_abg ) ? parameter_scale_abg  : u_task_1_6;

// �?后需要乘上两个参�? return self.control_dict['Kv'] * self.control_dict['lamb'] * self.u_task

// u_task_1_after_limit_reg
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        u_task_1_after_limit_reg <= 0;
    end
    else if (step1 == 1) begin
        u_task_1_after_limit_reg <= u_task_1_after_para;
    end
    else begin
        u_task_1_after_limit_reg <= u_task_1_after_limit_reg;
    end
end

// u_task_2_after_limit_reg
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        u_task_2_after_limit_reg <= 0;
    end
    else if (step1 == 1) begin
        u_task_2_after_limit_reg <= u_task_2_after_para;
    end
    else begin
        u_task_2_after_limit_reg <= u_task_2_after_limit_reg;
    end
end

// u_task_3_after_limit_reg
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        u_task_3_after_limit_reg <= 0;
    end
    else if (step1 == 1) begin
        u_task_3_after_limit_reg <= u_task_3_after_para;
    end
    else begin
        u_task_3_after_limit_reg <= u_task_3_after_limit_reg;
    end
end

assign u_task_after_limit = {		// step1
	96'd0,
	u_task_3_after_limit_reg, 
	u_task_2_after_limit_reg, 
	u_task_1_after_limit_reg
	};

// dot(M, dq_vector)
// u = -1 * self.control_dict['Kv'] * np.dot(M, dq_vector)
// 注意这里的负号没有实�?

// dot_M_dq 
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        dot_M_dq_reg <= 0;
    end
    else if (step1 == 1 && finish) begin
        dot_M_dq_reg <= mlu_z;
    end
    else begin
        dot_M_dq_reg <= dot_M_dq_reg;
    end
end

// # isolate task space forces corresponding to controlled DOF
//         u_task = u_task[control_dof]
// 		   u_task[:3]

// step2
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        step2 <= 0;
    end
    else if (step1 == 1 && finish) begin
        step2 <= 1;
    end
    else begin
        step2 <= 0;
    end
end

// u -= np.dot(J.T, np.dot(Mx, u_task))
// dot(Mx, u_task)
// dot_Mx_u_task_1

// step3
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        step3 <= 0;
    end else if (finish) begin
        step3 <= 0;
    end
    else if (step2 == 1) begin
        step3 <= 1;
    end
    else begin
        step3 <= step3;
    end
end

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        dot_Mx_u_task_reg <= 0;
    end
    else if (step3 == 1 && finish) begin
        dot_Mx_u_task_reg <= mlu_z;
    end
    else begin
        dot_Mx_u_task_reg <= dot_Mx_u_task_reg;
    end
end

// step4
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        step4 <= 0;
    end
    else if (step3 == 1 && finish) begin
        step4 <= 1;
    end
    else begin
        step4 <= 0;
    end
end

// step5
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        step5 <= 0;
    end else if (finish) begin
        step5 <= 0;
    end
    else if (step4 == 1) begin
        step5 <= 1;
    end
    else begin
        step5 <= step5;
    end
end

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        dot_JT_Mx_u_task_reg <= 0;
    end
    else if (step5 == 1 && finish) begin
        dot_JT_Mx_u_task_reg <= mlu_z;
    end
    else begin
        dot_JT_Mx_u_task_reg <= dot_JT_Mx_u_task_reg;
    end
end

// step6
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        step6 <= 0;
    end
    else if (step5 == 1 && finish) begin
        step6 <= 1;
    end
    else begin
        step6 <= 0;
    end
end

// step7
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        step7 <= 0;
    end else if (finish) begin
        step7 <= 0;
    end
    else if (step6 == 1) begin
        step7 <= 1;
    end
    else begin
        step7 <= step7;
    end
end

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        mlu_a <= 0;
		mlu_b <= 0;
		mlu_k <= parameter_K1;
		mlu_op <= 2'b00;
		start <= 1'b0;

    end
    else if (step0 == 1) begin
        mlu_a <= mat_M;
		mlu_b <= dq;
		mlu_k <= parameter_Kv;
		mlu_op <= 2'b10;				// dot
		start <= 1'b1;
    end
    else if (step2 == 1) begin
        mlu_a <= Mx;
		mlu_b <= u_task_after_limit;
		mlu_k <= parameter_K1;
		mlu_op <= 2'b10;				// dot
		start <= 1'b1;
    end
	else if (step4 == 1) begin
		mlu_a <= J;
		mlu_b <= dot_Mx_u_task_reg;
		mlu_k <= parameter_K1;
		mlu_op <= 2'b10;				// dot
		start <= 1'b1;
	end
	else if (step6 == 1) begin
		mlu_a <= dots;
		mlu_b <= gravity_bias;
		mlu_k <= parameter_minus_K1;
		mlu_op <= 2'b01;				// dot
		start <= 1'b1;
	end 
	else begin
		mlu_a <= mlu_a;
		mlu_b <= mlu_b;
		mlu_k <= mlu_k;
		mlu_op <= mlu_op;				// dot
		start <= 1'b0;
	end 
end

assign dots = {768'd0, 
	dot_JT_Mx_u_task_reg, 
	// 191'd0
	dot_M_dq_reg
	};

// final valid
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        valid <= 0;
    end
    else if (step7 == 1 && finish) begin
        valid <= 1;
    end
    else begin
        valid <= 0;
    end
end

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        u_reg <= 0;
    end
    else if (step7 == 1 && finish) begin
        u_reg <= mlu_z;
    end
    else begin
        u_reg <= u_reg;
    end
end

assign u_1 = u_reg[   31:     0];
assign u_2 = u_reg[   63:     32];
assign u_3 = u_reg[   95:     64];
assign u_4 = u_reg[   127:    96];
assign u_5 = u_reg[   159:    128];
assign u_6 = u_reg[   191:    160];

endmodule


