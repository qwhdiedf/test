module min(
    input     wire       [31:0]      a,
    input     wire       [31:0]      b,

    output    wire       [31:0]      c
);


    wire       [7:0]     sel;
    wire                 m_axis_result_tvalid_min;

    float_cmp u_float_cmp (
       .s_axis_a_tvalid(1'b1),            
       .s_axis_a_tdata(a),             
       .s_axis_b_tvalid(1'b1),            
       .s_axis_b_tdata(b),             
       .m_axis_result_tvalid(m_axis_result_tvalid_min),  
       .m_axis_result_tdata(sel)    
    );

    assign  c = ( sel == 1 ) ? a : b;
 

endmodule
