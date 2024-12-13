module MAC3(
	input wire 	[31:0] 	a_1,
	input wire 	[31:0] 	a_2,
	input wire 	[31:0] 	a_3,
	input wire 	[31:0] 	b_1,
	input wire 	[31:0] 	b_2,
	input wire 	[31:0] 	b_3,
	input wire  	 	op,

	output wire [31:0] 	sum
    );

	wire [31:0] m_1, m_2, m_3, sa_1, sa_2, sa_3;
    wire [31:0] sa_00;

    wire        m_axis_result_tvalid_mult_1;
    wire        m_axis_result_tvalid_mult_2;
    wire        m_axis_result_tvalid_mult_3;

    wire        m_axis_result_tvalid_add_1;
    wire        m_axis_result_tvalid_add_2;

/**************************************
        Instance
**************************************/
    // Instance of float_mult
    float_mult u_mult_1 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(a_1),              
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(b_1),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_1),  
        .m_axis_result_tdata(m_1)    
    );
	
    float_mult u_mult_2 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(a_2),              
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(b_2),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_2),  
        .m_axis_result_tdata(m_2)    
    );

    float_mult u_mult_3 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(a_3),              
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(b_3),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_3),  
        .m_axis_result_tdata(m_3)    
    );

	assign sa_1 = op ? m_1 : a_1;
	assign sa_2 = op ? m_2 : a_2;
	assign sa_3 = op ? m_3 : a_3;

    
    // Instance of DW_fp_add
    float_add_sub u_float_add_sub_1 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(sa_1),             
        .s_axis_b_tvalid(1'b1),          
        .s_axis_b_tdata(sa_2),            
        .m_axis_result_tvalid(m_axis_result_tvalid_add_1),  
        .m_axis_result_tdata(sa_00)   
    );

    float_add_sub u_float_add_sub_2 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(sa_00),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(sa_3),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_2), 
        .m_axis_result_tdata(sum)    
    );
endmodule
