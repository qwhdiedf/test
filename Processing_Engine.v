`define SIG_WIDTH 23
`define EXP_WIDTH 8
`define IEEE_COMPLIANCE 0

module Processing_Engine(
    // control signal
    input   wire                                        clk,
    input   wire                                        rst,
    // from scheduler
    input   wire                                        start_processing_engine,      // last for one clock
    input   wire                                        last_one_processing_engine,   // last for one clock
    input   wire                                        spike_output_processing_engine,                  // last for one clock xxx
    // from SRAM
    input   wire[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   weight_old,  
    // outputs
    output  reg                                         output_valid,
    output  reg [5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   u_adapt
    //output  wire                                        error_processing_engine
) ;


    localparam IDLE =                   3'b001;
    localparam PROCESSING =             3'b010;
    localparam DONE =                   3'b100;


/**************************************
        wire declaration
**************************************/
    // state reg declaration
        reg [2:0]                               current_state;
        reg [2:0]                               next_state;
    
    // control signal
        reg                                     last_one_processing_engine_reg;

    // variables
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       u_accumulated_1;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       u_accumulated_2;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       u_accumulated_3;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       u_accumulated_4;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       u_accumulated_5;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_5;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_1_mult_1000;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_2_mult_1000;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_3_mult_1000;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_4_mult_1000;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_5_mult_1000;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_5;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_5;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_5;
        /*wire[7:0]                               status_inst_DW_fp_add_1;
        wire[7:0]                               status_inst_DW_fp_add_2;
        wire[7:0]                               status_inst_DW_fp_add_3;
        wire[7:0]                               status_inst_DW_fp_add_4;
        wire[7:0]                               status_inst_DW_fp_add_5;*/
        reg                                     spike_output_processing_engine_reg;
        reg                                     spike_output_processing_engine_reg_2;

        wire                                    m_axis_result_tvalid_add_1;
        wire                                    m_axis_result_tvalid_add_2;
        wire                                    m_axis_result_tvalid_add_3;
        wire                                    m_axis_result_tvalid_add_4;
        wire                                    m_axis_result_tvalid_add_5;

        wire                                    m_axis_result_tvalid_mult_6;
        wire                                    m_axis_result_tvalid_mult_7;
        wire                                    m_axis_result_tvalid_mult_8;
        wire                                    m_axis_result_tvalid_mult_9;
        wire                                    m_axis_result_tvalid_mult_10;

    // DW_fp_mult_6
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_6;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_6;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_6;
        //wire[7:0]                               status_inst_DW_fp_mult_6;   // xxx
    
    // DW_fp_mult_7
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_7;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_7;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_7;
        //wire[7:0]                               status_inst_DW_fp_mult_7;   // xxx

    // DW_fp_mult_8
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_8;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_8;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_8;
        //wire[7:0]                               status_inst_DW_fp_mult_8;   // xxx

    // DW_fp_mult_9
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_9;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_9;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_9;
        //wire[7:0]                               status_inst_DW_fp_mult_9;   // xxx

    // DW_fp_mult_10
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_10;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_10;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_10;
        //wire[7:0]                               status_inst_DW_fp_mult_10;   // xxx


/**************************************
        state machine
**************************************/
    // state machine ---state transferring
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            current_state <= IDLE;     
        end else begin
            current_state <= next_state;
        end
    end

    // last_one_processing_engine_reg
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            last_one_processing_engine_reg <= 0;     
        end else if (last_one_processing_engine) begin
            last_one_processing_engine_reg <= 1;
        end else begin
            last_one_processing_engine_reg <= 0;
        end
    end    

    // state machine ---judge next_state  
    always @(*) begin
        case(current_state)
            IDLE:
                begin
                    if (start_processing_engine) begin
                        next_state = PROCESSING;
                    end else begin
                        next_state = IDLE;
                    end 
                end
            PROCESSING:      // last for a long time
                begin
                    if(last_one_processing_engine_reg) begin
                        next_state = DONE;
                    end else begin
                        next_state = PROCESSING;
                    end
                end
            DONE:           // last for one clock  
                begin
                    next_state = IDLE;
                end
            default:
                begin
                    next_state = IDLE;
                end
        endcase
    end

/**************************************
        stage: PROCESSING
**************************************/ 
    assign weight_1 = weight_old[1*`SIG_WIDTH + 1*`EXP_WIDTH + 0 : 0];
    assign weight_2 = weight_old[2*`SIG_WIDTH + 2*`EXP_WIDTH + 1 : 1*`SIG_WIDTH + 1*`EXP_WIDTH + 1];
    assign weight_3 = weight_old[3*`SIG_WIDTH + 3*`EXP_WIDTH + 2 : 2*`SIG_WIDTH + 2*`EXP_WIDTH + 2];
    assign weight_4 = weight_old[4*`SIG_WIDTH + 4*`EXP_WIDTH + 3 : 3*`SIG_WIDTH + 3*`EXP_WIDTH + 3];
    assign weight_5 = weight_old[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 4*`SIG_WIDTH + 4*`EXP_WIDTH + 4];

    // spike_output_processing_engine_reg
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            spike_output_processing_engine_reg <= 0;
        end else if (spike_output_processing_engine) begin
            spike_output_processing_engine_reg <= 1;
        end else begin
            spike_output_processing_engine_reg <= 0;
        end
    end

    // spike_output_processing_engine_reg_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            spike_output_processing_engine_reg_2 <= 0;
        end else if (spike_output_processing_engine_reg) begin
            spike_output_processing_engine_reg_2 <= 1;
        end else begin
            spike_output_processing_engine_reg_2 <= 0;
        end
    end

    // inst_a_DW_fp_mult_6
    assign inst_a_DW_fp_mult_6 = weight_1;

    // inst_b_DW_fp_mult_6
    assign inst_b_DW_fp_mult_6 = 32'b01000100011110100000000000000000;

    // weight_1_mult_1000
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_1_mult_1000 <= 32'b00000000000000000000000000000000;
        end else if (spike_output_processing_engine_reg) begin
            weight_1_mult_1000 <= z_inst_DW_fp_mult_6;
        end else begin
            weight_1_mult_1000 <= weight_1_mult_1000;
        end
    end

    // inst_a_DW_fp_mult_7
    assign inst_a_DW_fp_mult_7 = weight_2;

    // inst_b_DW_fp_mult_7
    assign inst_b_DW_fp_mult_7 = 32'b01000100011110100000000000000000;

    // weight_2_mult_1000
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_2_mult_1000 <= 32'b00000000000000000000000000000000;
        end else if (spike_output_processing_engine_reg) begin
            weight_2_mult_1000 <= z_inst_DW_fp_mult_7;
        end else begin
            weight_2_mult_1000 <= weight_2_mult_1000;
        end
    end

    // inst_a_DW_fp_mult_8
    assign inst_a_DW_fp_mult_8 = weight_3;

    // inst_b_DW_fp_mult_8
    assign inst_b_DW_fp_mult_8 = 32'b01000100011110100000000000000000;

    // weight_3_mult_1000
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_3_mult_1000 <= 32'b00000000000000000000000000000000;
        end else if (spike_output_processing_engine_reg) begin
            weight_3_mult_1000 <= z_inst_DW_fp_mult_8;
        end else begin
            weight_3_mult_1000 <= weight_3_mult_1000;
        end
    end

    // inst_a_DW_fp_mult_9
    assign inst_a_DW_fp_mult_9 = weight_4;

    // inst_b_DW_fp_mult_9
    assign inst_b_DW_fp_mult_9 = 32'b01000100011110100000000000000000;

    // weight_4_mult_1000
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_4_mult_1000 <= 32'b00000000000000000000000000000000;
        end else if (spike_output_processing_engine_reg) begin
            weight_4_mult_1000 <= z_inst_DW_fp_mult_9;
        end else begin
            weight_4_mult_1000 <= weight_4_mult_1000;
        end
    end

    // inst_a_DW_fp_mult_10
    assign inst_a_DW_fp_mult_10 = weight_5;

    // inst_b_DW_fp_mult_10
    assign inst_b_DW_fp_mult_10 = 32'b01000100011110100000000000000000;

    // weight_5_mult_1000
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_5_mult_1000 <= 32'b00000000000000000000000000000000;
        end else if (spike_output_processing_engine_reg) begin
            weight_5_mult_1000 <= z_inst_DW_fp_mult_10;
        end else begin
            weight_5_mult_1000 <= weight_5_mult_1000;
        end
    end

    // u_accumulated_1 xxx check for the timing, if there needs one more clock to wait for the calcalation
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            u_accumulated_1 <= 32'b00000000000000000000000000000000;
        end else if (start_processing_engine) begin
            u_accumulated_1 <= 32'b00000000000000000000000000000000;
        end else if ((current_state == PROCESSING) && (spike_output_processing_engine_reg_2 == 1)) begin
            u_accumulated_1 <= z_inst_DW_fp_add_1;
        end
        else begin
            u_accumulated_1 <= u_accumulated_1;
        end
    end
    
    assign inst_a_DW_fp_add_1 = (current_state == PROCESSING) ? u_accumulated_1: 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_1 = (current_state == PROCESSING) ? weight_1_mult_1000 : 32'b00000000000000000000000000000000;
    
    // u_accumulated_2 
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            u_accumulated_2 <= 32'b00000000000000000000000000000000;
        end else if (start_processing_engine) begin
            u_accumulated_2 <= 32'b00000000000000000000000000000000;
        end else if ((current_state == PROCESSING) && (spike_output_processing_engine_reg_2 == 1)) begin
            u_accumulated_2 <= z_inst_DW_fp_add_2;
        end
        else begin
            u_accumulated_2 <= u_accumulated_2;
        end
    end
    
    assign inst_a_DW_fp_add_2 = (current_state == PROCESSING) ? u_accumulated_2: 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_2 = (current_state == PROCESSING) ? weight_2_mult_1000 : 32'b00000000000000000000000000000000;
    
    // u_accumulated_3 
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            u_accumulated_3 <= 32'b00000000000000000000000000000000;
        end else if (start_processing_engine) begin
            u_accumulated_3 <= 32'b00000000000000000000000000000000;
        end else if ((current_state == PROCESSING) && (spike_output_processing_engine_reg_2 == 1)) begin
            u_accumulated_3 <= z_inst_DW_fp_add_3;
        end
        else begin
            u_accumulated_3 <= u_accumulated_3;
        end
    end
    
    assign inst_a_DW_fp_add_3 = (current_state == PROCESSING) ? u_accumulated_3: 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_3 = (current_state == PROCESSING) ? weight_3_mult_1000 : 32'b00000000000000000000000000000000;

    // u_accumulated_4 
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            u_accumulated_4 <= 32'b00000000000000000000000000000000;
        end else if (start_processing_engine) begin
            u_accumulated_4 <= 32'b00000000000000000000000000000000;
        end else if ((current_state == PROCESSING) && (spike_output_processing_engine_reg_2 == 1)) begin
            u_accumulated_4 <= z_inst_DW_fp_add_4;
        end
        else begin
            u_accumulated_4 <= u_accumulated_4;
        end
    end
    
    assign inst_a_DW_fp_add_4 = (current_state == PROCESSING) ? u_accumulated_4: 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_4 = (current_state == PROCESSING) ? weight_4_mult_1000 : 32'b00000000000000000000000000000000;

    // u_accumulated_5 
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            u_accumulated_5 <= 32'b00000000000000000000000000000000;
        end else if (start_processing_engine) begin
            u_accumulated_5 <= 32'b00000000000000000000000000000000;
        end else if ((current_state == PROCESSING) && (spike_output_processing_engine_reg_2 == 1)) begin
            u_accumulated_5 <= z_inst_DW_fp_add_5;
        end
        else begin
            u_accumulated_5 <= u_accumulated_5;
        end
    end
    
    assign inst_a_DW_fp_add_5 = (current_state == PROCESSING) ? u_accumulated_5: 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_5 = (current_state == PROCESSING) ? weight_5_mult_1000 : 32'b00000000000000000000000000000000;
    
    
/**************************************
        stage: DONE
**************************************/     
    // output_valid
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            output_valid <= 1'b0;
        end else if ((current_state == DONE)) begin
            output_valid <= 1'b1;
        end
        else begin
            output_valid <= 1'b0;
        end
    end
    
    // u_adapt
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            u_adapt <= {160{1'b0}};
        end else if ((current_state == DONE)) begin
            u_adapt <= {u_accumulated_5,u_accumulated_4,u_accumulated_3,u_accumulated_2,u_accumulated_1};
        end
        else begin
            u_adapt <= u_adapt;
        end
    end

/**************************************
        for check
**************************************/
    // DW_fp_add
    /*assign error_DW_fp_add_1 = ((status_inst_DW_fp_add_1 == 0) || (status_inst_DW_fp_add_1 == 1)) ? 0 : 1;
    assign error_DW_fp_add_2 = ((status_inst_DW_fp_add_2 == 0) || (status_inst_DW_fp_add_2 == 1)) ? 0 : 1;
    assign error_DW_fp_add_3 = ((status_inst_DW_fp_add_3 == 0) || (status_inst_DW_fp_add_3 == 1)) ? 0 : 1;
    assign error_DW_fp_add_4 = ((status_inst_DW_fp_add_4 == 0) || (status_inst_DW_fp_add_4 == 1)) ? 0 : 1;
    assign error_DW_fp_add_5 = ((status_inst_DW_fp_add_5 == 0) || (status_inst_DW_fp_add_5 == 1)) ? 0 : 1;
    
    // error_processing_engine
    assign error_processing_engine = error_DW_fp_add_1 | error_DW_fp_add_2 | error_DW_fp_add_3 | error_DW_fp_add_4 | error_DW_fp_add_5;*/

/**************************************
        Instance
**************************************/
    // Instance of DW_fp_add
    float_add_sub u_float_add_sub_1 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_1),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_1),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_1),  
        .m_axis_result_tdata(z_inst_DW_fp_add_1)    
    );

    // Instance of DW_fp_add
    float_add_sub u_float_add_sub_2 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_2),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_2),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_2),  
        .m_axis_result_tdata(z_inst_DW_fp_add_2)    
    );

    // Instance of DW_fp_add
    float_add_sub u_float_add_sub_3 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_3),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_3),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_3),  
        .m_axis_result_tdata(z_inst_DW_fp_add_3)    
    );

    // Instance of DW_fp_add
    float_add_sub u_float_add_sub_4 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_4),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_4),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_4),  
        .m_axis_result_tdata(z_inst_DW_fp_add_4)    
    );

    // Instance of DW_fp_add
    float_add_sub u_float_add_sub_5 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_5),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_5),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_5),  
        .m_axis_result_tdata(z_inst_DW_fp_add_5)    
    );

    // Instance of DW_fp_mult_6
    float_mult u_float_mult_6 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_6),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_mult_6),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_6),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_6)   
    );

    // Instance of DW_fp_mult_7
    float_mult u_float_mult_7 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_7),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_mult_7),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_7),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_7)   
    );

    // Instance of DW_fp_mult_8
    float_mult u_float_mult_8 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_8),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_mult_8),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_8),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_8)   
    );

    // Instance of DW_fp_mult_9
    float_mult u_float_mult_9 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_9),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_mult_9),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_9),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_9)   
    );

    // Instance of DW_fp_mult_10
    float_mult u_float_mult_10 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_10),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_mult_10),              
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_10),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_10)   
    );

endmodule