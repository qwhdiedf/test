`define SIG_WIDTH 23
`define EXP_WIDTH 8
//`define IEEE_COMPLIANCE 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      "

module Learning_Engine(
    // control signal
    input   wire                                    clk,
    input   wire                                    rst,
    // from scheduler
    input   wire                                    start_learning_engine,                      // last for one clock
    input   wire                                    spike_output_learning_engine,                // last until output_valid
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       alpha,
    // from OSC
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       training_signal_1,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       training_signal_2,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       training_signal_3,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       training_signal_4,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       training_signal_5,
    
    // from SRAM
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_old_1,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_old_2,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_old_3,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_old_4,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       weight_old_5, 
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       trace_value_old,
    // outputs
    output  reg                                     output_valid,
    output  reg [`SIG_WIDTH + `EXP_WIDTH : 0]       trace_value_new,
    output  reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_new_1,
    output  reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_new_2,
    output  reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_new_3,
    output  reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_new_4,
    output  reg [`SIG_WIDTH + `EXP_WIDTH : 0]       weight_new_5
    //output  wire                                    error_learning_engine
);


    localparam IDLE =                   4'b0001;
    localparam DECAY =                  4'b0010;
    localparam LEARNING =               4'b0100;
    localparam DONE =                   4'b1000;


/**************************************
        wire declaration
**************************************/
    // state reg declaration
        reg [3:0]                               current_state;
        reg [3:0]                               next_state;

    // control signal
        reg                                     decay_step0;
        reg                                     decay_step1;
        reg                                     decay_step2;
        reg                                     learning_step1;
        reg                                     learning_step2;
        reg                                     learning_step3;
        
    // DW_fp_add_6
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_1;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_1;
        //wire[7:0]                               status_inst_DW_fp_add_1;

    // DW_fp_add_7
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_2;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_2;
        //wire[7:0]                               status_inst_DW_fp_add_2;    

    // DW_fp_add_8
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_3;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_3;
       //wire[7:0]                               status_inst_DW_fp_add_3;    

    // DW_fp_add_9
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_4;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_4;
        //wire[7:0]                               status_inst_DW_fp_add_4;    

    // DW_fp_add_10
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add_5;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add_5;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add_5;
        //wire[7:0]                               status_inst_DW_fp_add_5;        

    // DW_fp_mult_1
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_1;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_1;
        //wire[7:0]                               status_inst_DW_fp_mult_1;  
    
    // DW_fp_mult_2
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_2;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_2;
        //wire[7:0]                               status_inst_DW_fp_mult_2; 
    
    // DW_fp_mult_3
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_3;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_3;
        //wire[7:0]                               status_inst_DW_fp_mult_3; 

    // DW_fp_mult_4
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_4;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_4;
        //wire[7:0]                               status_inst_DW_fp_mult_4; 

    // DW_fp_mult_5
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult_5;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult_5;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult_5;
        //wire[7:0]                               status_inst_DW_fp_mult_5; 

    // variables
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       trace_value_decay;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       alpha_mult_error_1;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       alpha_mult_error_2;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       alpha_mult_error_3;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       alpha_mult_error_4;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       alpha_mult_error_5;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       delta_weight_1;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       delta_weight_2;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       delta_weight_3;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       delta_weight_4;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       delta_weight_5;

    // for check
        /*wire                                    error_DW_fp_add_1;
        wire                                    error_DW_fp_add_2;
        wire                                    error_DW_fp_add_3;
        wire                                    error_DW_fp_add_4;
        wire                                    error_DW_fp_add_5;
        wire                                    error_DW_fp_mult_1;
        wire                                    error_DW_fp_mult_2;
        wire                                    error_DW_fp_mult_3;
        wire                                    error_DW_fp_mult_4;
        wire                                    error_DW_fp_mult_5;*/

        wire                                    m_axis_result_tvalid_add_1;
        wire                                    m_axis_result_tvalid_add_2;
        wire                                    m_axis_result_tvalid_add_3;
        wire                                    m_axis_result_tvalid_add_4;
        wire                                    m_axis_result_tvalid_add_5;

        wire                                    m_axis_result_tvalid_mult_1;
        wire                                    m_axis_result_tvalid_mult_2;
        wire                                    m_axis_result_tvalid_mult_3;
        wire                                    m_axis_result_tvalid_mult_4;
        wire                                    m_axis_result_tvalid_mult_5;
        

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

    // state machine ---judge next_state  
    always @(*) begin
        case(current_state)
            IDLE:
                begin
                    if (start_learning_engine) begin
                        next_state = DECAY;
                    end else begin
                        next_state = IDLE;
                    end 
                end
            DECAY:      // last for two clocks
                begin
                    if (decay_step2) begin
                        next_state = LEARNING;
                    end else begin
                        next_state = DECAY;
                    end 
                end
            LEARNING:   // last for three clocks    
                begin
                    if(learning_step3) begin
                        next_state = DONE;
                    end else begin
                        next_state = LEARNING;
                    end
                end
            DONE:     
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
        stage: DECAY
**************************************/ 
// step1
    // decay_step0
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            decay_step0 <= 0;
        end else if ((current_state == IDLE) && (next_state == DECAY)) begin
            decay_step0 <= 1;
        end
        else begin
            decay_step0 <= 0;
        end
    end 

    // decay_step1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            decay_step1 <= 0;
        end else if (decay_step0) begin
            decay_step1 <= 1;
        end
        else begin
            decay_step1 <= 0;
        end
    end    
    
    // trace_value_decay
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            trace_value_decay <= 32'b00000000000000000000000000000000;
        end else if (decay_step1) begin
            trace_value_decay <= z_inst_DW_fp_mult_1;
        end
        else begin
            trace_value_decay <= trace_value_decay;
        end
    end   

    assign inst_a_DW_fp_mult_1 = (decay_step1) ? trace_value_old : (learning_step1) ? alpha : (learning_step2) ?  alpha_mult_error_1 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_mult_1 = (decay_step1) ? 32'b00111111010100011001100001010111 : (learning_step1) ? training_signal_1 : (learning_step2) ?  trace_value_new : 32'b00000000000000000000000000000000;
    
// step2
    // decay_step2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            decay_step2 <= 0;
        end else if (decay_step1) begin
            decay_step2 <= 1;
        end
        else begin
            decay_step2 <= 0;
        end
    end     
    
    // trace_value_new
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            trace_value_new <= 32'b00000000000000000000000000000000;
        end else if (decay_step2) begin
            if (spike_output_learning_engine) begin
                trace_value_new <= z_inst_DW_fp_add_1;
            end else begin
                trace_value_new <= trace_value_decay;
            end
        end else begin
            trace_value_new <= trace_value_new;
        end
    end   

    assign inst_a_DW_fp_add_1 = (decay_step2) ? trace_value_decay : (learning_step3) ? delta_weight_1 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_1 = (decay_step2) ? 32'b01000011001101010100010011101101 : (learning_step3) ? weight_old_1 : 32'b00000000000000000000000000000000;
    
/**************************************
        stage: LEARNING
**************************************/ 
// step1
    // learning_step1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            learning_step1 <= 0;
        end else if ((current_state == DECAY) && (next_state == LEARNING)) begin
            learning_step1 <= 1;
        end
        else begin
            learning_step1 <= 0;
        end
    end    
    
    // alpha_mult_error_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            alpha_mult_error_1 <= 32'b00000000000000000000000000000000;
        end else if (learning_step1) begin
            alpha_mult_error_1 <= z_inst_DW_fp_mult_1;
        end
        else begin
            alpha_mult_error_1 <= alpha_mult_error_1;
        end
    end 

    // alpha_mult_error_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            alpha_mult_error_2 <= 32'b00000000000000000000000000000000;
        end else if (learning_step1) begin
            alpha_mult_error_2 <= z_inst_DW_fp_mult_2;
        end
        else begin
            alpha_mult_error_2 <= alpha_mult_error_2;
        end
    end 

    // alpha_mult_error_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            alpha_mult_error_3 <= 32'b00000000000000000000000000000000;
        end else if (learning_step1) begin
            alpha_mult_error_3 <= z_inst_DW_fp_mult_3;
        end
        else begin
            alpha_mult_error_3 <= alpha_mult_error_3;
        end
    end 

    // alpha_mult_error_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            alpha_mult_error_4 <= 32'b00000000000000000000000000000000;
        end else if (learning_step1) begin
            alpha_mult_error_4 <= z_inst_DW_fp_mult_4;
        end
        else begin
            alpha_mult_error_4 <= alpha_mult_error_4;
        end
    end 

    // alpha_mult_error_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            alpha_mult_error_5 <= 32'b00000000000000000000000000000000;
        end else if (learning_step1) begin
            alpha_mult_error_5 <= z_inst_DW_fp_mult_5;
        end
        else begin
            alpha_mult_error_5 <= alpha_mult_error_5;
        end
    end 

    assign inst_a_DW_fp_mult_2 =  (learning_step1) ? alpha : (learning_step2) ?  alpha_mult_error_2 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_mult_2 =  (learning_step1) ? training_signal_2 : (learning_step2) ?  trace_value_new : 32'b00000000000000000000000000000000;

    assign inst_a_DW_fp_mult_3 =  (learning_step1) ? alpha : (learning_step2) ?  alpha_mult_error_3 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_mult_3 =  (learning_step1) ? training_signal_3 : (learning_step2) ?  trace_value_new : 32'b00000000000000000000000000000000;

    assign inst_a_DW_fp_mult_4 =  (learning_step1) ? alpha : (learning_step2) ?  alpha_mult_error_4 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_mult_4 =  (learning_step1) ? training_signal_4 : (learning_step2) ?  trace_value_new : 32'b00000000000000000000000000000000;

    assign inst_a_DW_fp_mult_5 =  (learning_step1) ? alpha : (learning_step2) ?  alpha_mult_error_5 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_mult_5 =  (learning_step1) ? training_signal_5 : (learning_step2) ?  trace_value_new : 32'b00000000000000000000000000000000;

// step2
    // learning_step2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            learning_step2 <= 0;
        end else if (learning_step1) begin
            learning_step2 <= 1;
        end
        else begin
            learning_step2 <= 0;
        end
    end    
    
    // delta_weight_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            delta_weight_1 <= 32'b00000000000000000000000000000000;
        end else if (learning_step2) begin
            delta_weight_1 <= z_inst_DW_fp_mult_1;
        end
        else begin
            delta_weight_1 <= delta_weight_1;
        end
    end

    // delta_weight_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            delta_weight_2 <= 32'b00000000000000000000000000000000;
        end else if (learning_step2) begin
            delta_weight_2 <= z_inst_DW_fp_mult_2;
        end
        else begin
            delta_weight_2 <= delta_weight_2;
        end
    end

    // delta_weight_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            delta_weight_3 <= 32'b00000000000000000000000000000000;
        end else if (learning_step2) begin
            delta_weight_3 <= z_inst_DW_fp_mult_3;
        end
        else begin
            delta_weight_3 <= delta_weight_3;
        end
    end

    // delta_weight_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            delta_weight_4 <= 32'b00000000000000000000000000000000;
        end else if (learning_step2) begin
            delta_weight_4 <= z_inst_DW_fp_mult_4;
        end
        else begin
            delta_weight_4 <= delta_weight_4;
        end
    end

    // delta_weight_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            delta_weight_5 <= 32'b00000000000000000000000000000000;
        end else if (learning_step2) begin
            delta_weight_5 <= z_inst_DW_fp_mult_5;
        end
        else begin
            delta_weight_5 <= delta_weight_5;
        end
    end
    
// step3
    // learning_step3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            learning_step3 <= 0;
        end else if (learning_step2) begin
            learning_step3 <= 1;
        end
        else begin
            learning_step3 <= 0;
        end
    end    
    
    // weight_new_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_new_1 <= 32'b00000000000000000000000000000000;
        end else if (learning_step3) begin
            weight_new_1 <= z_inst_DW_fp_add_1;
        end
        else begin
            weight_new_1 <= weight_new_1;
        end
    end

    // weight_new_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_new_2 <= 32'b00000000000000000000000000000000;
        end else if (learning_step3) begin
            weight_new_2 <= z_inst_DW_fp_add_2;
        end
        else begin
            weight_new_2 <= weight_new_2;
        end
    end

    // weight_new_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_new_3 <= 32'b00000000000000000000000000000000;
        end else if (learning_step3) begin
            weight_new_3 <= z_inst_DW_fp_add_3;
        end
        else begin
            weight_new_3 <= weight_new_3;
        end
    end

    // weight_new_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_new_4 <= 32'b00000000000000000000000000000000;
        end else if (learning_step3) begin
            weight_new_4 <= z_inst_DW_fp_add_4;
        end
        else begin
            weight_new_4 <= weight_new_4;
        end
    end

    // weight_new_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_new_5 <= 32'b00000000000000000000000000000000;
        end else if (learning_step3) begin
            weight_new_5 <= z_inst_DW_fp_add_5;
        end
        else begin
            weight_new_5 <= weight_new_5;
        end
    end

    assign inst_a_DW_fp_add_2 = (learning_step3) ? delta_weight_2 : 32'b00000000000000000000000000000000;
    assign inst_a_DW_fp_add_3 = (learning_step3) ? delta_weight_3 : 32'b00000000000000000000000000000000;
    assign inst_a_DW_fp_add_4 = (learning_step3) ? delta_weight_4 : 32'b00000000000000000000000000000000;
    assign inst_a_DW_fp_add_5 = (learning_step3) ? delta_weight_5 : 32'b00000000000000000000000000000000;
    
    assign inst_b_DW_fp_add_2 = (learning_step3) ? weight_old_2 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_3 = (learning_step3) ? weight_old_3 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_4 = (learning_step3) ? weight_old_4 : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add_5 = (learning_step3) ? weight_old_5 : 32'b00000000000000000000000000000000;


/**************************************
        Done
**************************************/
    // output_valid
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            output_valid <= 0;
        end else if (current_state == DONE) begin
            output_valid <= 1;
        end
        else begin
            output_valid <= 0;
        end
    end    


/**************************************
        for check
**************************************/
    // DW_fp_add_6
    /*assign error_DW_fp_add_1 = ((status_inst_DW_fp_add_1 == 0) || (status_inst_DW_fp_add_1 == 1)) ? 0 : 1;

    // DW_fp_add_7
    assign error_DW_fp_add_2 = ((status_inst_DW_fp_add_2 == 0) || (status_inst_DW_fp_add_2 == 1)) ? 0 : 1;

    // DW_fp_add_8
    assign error_DW_fp_add_3 = ((status_inst_DW_fp_add_3 == 0) || (status_inst_DW_fp_add_3 == 1)) ? 0 : 1;

    // DW_fp_add_9
    assign error_DW_fp_add_4 = ((status_inst_DW_fp_add_4 == 0) || (status_inst_DW_fp_add_4 == 1)) ? 0 : 1;

    // DW_fp_add_10
    assign error_DW_fp_add_5 = ((status_inst_DW_fp_add_5 == 0) || (status_inst_DW_fp_add_5 == 1)) ? 0 : 1;

    // DW_fp_mult_1
    assign error_DW_fp_mult_1 = ((status_inst_DW_fp_mult_1 == 0) || (status_inst_DW_fp_mult_1 == 1)) ? 0 : 1;

    // DW_fp_mult_2
    assign error_DW_fp_mult_2 = ((status_inst_DW_fp_mult_2 == 0) || (status_inst_DW_fp_mult_2 == 1)) ? 0 : 1;

    // DW_fp_mult_3
    assign error_DW_fp_mult_3 = ((status_inst_DW_fp_mult_3 == 0) || (status_inst_DW_fp_mult_3 == 1)) ? 0 : 1;

    // DW_fp_mult_4
    assign error_DW_fp_mult_4 = ((status_inst_DW_fp_mult_4 == 0) || (status_inst_DW_fp_mult_4 == 1)) ? 0 : 1;

    // DW_fp_mult_5
    assign error_DW_fp_mult_5 = ((status_inst_DW_fp_mult_5 == 0) || (status_inst_DW_fp_mult_5 == 1)) ? 0 : 1;

    // error_learning_engine 
    assign error_learning_engine = error_DW_fp_mult_1 | error_DW_fp_mult_2 | error_DW_fp_mult_3 | error_DW_fp_mult_4 | error_DW_fp_mult_5 | error_DW_fp_add_1 | error_DW_fp_add_2 | error_DW_fp_add_3 | error_DW_fp_add_4 | error_DW_fp_add_5;*/

/**************************************
        Instance
**************************************/
    // Instance of DW_fp_add_6
    float_add_sub u_float_add_sub_6 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_1),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_1),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_1),  
        .m_axis_result_tdata(z_inst_DW_fp_add_1)    
    );

    // Instance of DW_fp_add_7
    float_add_sub u_float_add_sub_7 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_2),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_2),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_2),  
        .m_axis_result_tdata(z_inst_DW_fp_add_2)    
    );

    // Instance of DW_fp_add_8
    float_add_sub u_float_add_sub_8 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_3),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_3),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_3),  
        .m_axis_result_tdata(z_inst_DW_fp_add_3)    
    );

    // Instance of DW_fp_add_9
    float_add_sub u_float_add_sub_9 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_4),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_4),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_4),  
        .m_axis_result_tdata(z_inst_DW_fp_add_4)    
    );

    // Instance of DW_fp_add_10
    float_add_sub u_float_add_sub_10 (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add_5),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add_5),              
        .m_axis_result_tvalid(m_axis_result_tvalid_add_5),  
        .m_axis_result_tdata(z_inst_DW_fp_add_5)    
    );

    // Instance of DW_fp_mult_1
    float_mult u_float_mult_1 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_1),        
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(inst_b_DW_fp_mult_1),             
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_1),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_1)    
    );

    // Instance of DW_fp_mult_2
    float_mult u_float_mult_2 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_2),        
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(inst_b_DW_fp_mult_2),             
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_2),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_2)    
    );

    // Instance of DW_fp_mult_3
    float_mult u_float_mult_3 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_3),        
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(inst_b_DW_fp_mult_3),             
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_3),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_3)    
    );

    // Instance of DW_fp_mult_4
    float_mult u_float_mult_4 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_4),        
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(inst_b_DW_fp_mult_4),             
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_4),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_4)    
    );

    // Instance of DW_fp_mult_5
    float_mult u_float_mult_5 (
        .s_axis_a_tvalid(1'b1),           
        .s_axis_a_tdata(inst_a_DW_fp_mult_5),        
        .s_axis_b_tvalid(1'b1),           
        .s_axis_b_tdata(inst_b_DW_fp_mult_5),             
        .m_axis_result_tvalid(m_axis_result_tvalid_mult_5),  
        .m_axis_result_tdata(z_inst_DW_fp_mult_5)    
    );

endmodule