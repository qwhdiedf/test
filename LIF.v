`define SIG_WIDTH 23
`define EXP_WIDTH 8
`define IEEE_COMPLIANCE 0


module LIF(
    // control signal
    input   wire                                    clk,
    input   wire                                    rst,
    // from scheduler
    input   wire                                    start_lif,      // last for one clock, each trun on need a independent start signal
    // parameters
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       bias,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       encoders,
    // current states
    input   wire[1:0]                               refractory_time_old,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]       voltage_old,
    // outputs
    output  reg                                     spike_valid,
    output  reg [1:0]                               refractory_time_new,
    output  reg                                     spike_output,
    output  reg [`SIG_WIDTH + `EXP_WIDTH : 0]       voltage_new
    //output  wire                                    error_lif
);

    localparam IDLE =                   4'b0001;
    localparam START =                  4'b0010;
    localparam COMPUTE =                4'b0100;
    localparam SPIKE =                  4'b1000;

/**************************************
        wire declaration
**************************************/
    // state reg declaration
        reg [3:0]                               current_state;
        reg [3:0]                               next_state;
    
    // control signal
        reg                                     start_step1;
        reg                                     compute_step1;
        reg                                     compute_step2;
        reg                                     compute_step3;
    
    // DW_fp_add
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_add;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_add;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_add;
        //wire[7:0]                               status_inst_DW_fp_add;    

    // DW_fp_mult
        // inputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_a_DW_fp_mult;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       inst_b_DW_fp_mult;
        // outputs
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       z_inst_DW_fp_mult;
        //wire[7:0]                               status_inst_DW_fp_mult;    

    // Calculation process variable
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       j_current;
        wire                                    delta_t;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]       expm1_result;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       j_minus_voltage;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       delta_voltage;
        reg [`SIG_WIDTH + `EXP_WIDTH : 0]       voltage_accumulated;

        wire                                    m_axis_result_tvalid_add;
        wire                                    m_axis_result_tvalid_mult;
    

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
                    if (start_lif) begin
                        next_state = START;
                    end else begin
                        next_state = IDLE;
                    end 
                end
            START:      // last for two clocks
                begin
                    if(start_step1) begin
                        next_state = COMPUTE;
                    end else begin
                        next_state = START;
                    end
                end
            COMPUTE:   // last for three clocks    
                begin
                    if(compute_step3) begin
                        next_state = SPIKE;
                    end else begin
                        next_state = COMPUTE;
                    end
                end
            SPIKE:     
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
        stage: START
**************************************/ 
    // start_step1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_step1 <= 0;
        end else if ((current_state == START) && (start_step1 == 0)) begin
            start_step1 <= 1;
        end else begin
            start_step1 <= 0;
        end
    end
    
    // j_current: j_current = bias + encoders
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            j_current <= 32'b00000000000000000000000000000000;
        end else if (current_state == START) begin
            j_current <= z_inst_DW_fp_add;
        end else begin
            j_current <= j_current;
        end
    end

    // refractory_time_new: value from {0,1,2}
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            refractory_time_new <= 2'b00;
        end else if (start_step1) begin
            if (refractory_time_old == 2'b00) begin
                refractory_time_new <= 2'b00;
            end else begin
                refractory_time_new <= refractory_time_old - 1;
            end
        end else if (current_state == SPIKE) begin
            if (spike_output) begin
                refractory_time_new <= 2'b10;
            end else begin
                refractory_time_new <= refractory_time_new;
            end
        end else begin
            refractory_time_new <= refractory_time_new;
        end
    end

    // delta_t: refractory_time_new = 0, delta_t = 1; refractory_time_new != 0, delta_t = 0
    assign delta_t = (refractory_time_new == 0) ? 1 : 0;

    // expm1_result:  delta = 0, expm1_result = 0; delta = 1, expm1_result = -0.04877058; 
    assign expm1_result = (delta_t == 0) ? 32'b00000000000000000000000000000000 : 32'b10111101010001111100001110101000;


/**************************************
        stage: COMPUTE
**************************************/
// step1
    // compute_step1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            compute_step1 <= 0;
        end else if ((current_state == START) && (next_state == COMPUTE)) begin
            compute_step1 <= 1;
        end else begin
            compute_step1 <= 0;
        end
    end

    // j_minus_voltage
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            j_minus_voltage <= 32'b00000000000000000000000000000000;
        end else if (compute_step1) begin
            j_minus_voltage <= z_inst_DW_fp_add;
        end else begin
            j_minus_voltage <= j_minus_voltage;
        end
    end

// step2
    // compute_step2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            compute_step2 <= 0;
        end else if (compute_step1) begin
            compute_step2 <= 1;
        end else begin
            compute_step2 <= 0;
        end
    end

    // inst_a_DW_fp_mult
    assign inst_a_DW_fp_mult = (compute_step2) ? j_minus_voltage: 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_mult = (compute_step2) ? expm1_result : 32'b00000000000000000000000000000000;

    // delta_voltage: = (J - voltage) * expm1_result
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            delta_voltage <= 32'b00000000000000000000000000000000;
        end else if (compute_step2) begin
            delta_voltage <= z_inst_DW_fp_mult;
        end else begin
            delta_voltage <= delta_voltage;
        end
    end

// step3
    // compute_step3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            compute_step3 <= 0;
        end else if (compute_step2) begin
            compute_step3 <= 1;
        end else begin
            compute_step3 <= 0;
        end
    end

    // voltage_accumulated: voltage_accumulated = voltage - (J - voltage) * expm1_result
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            voltage_accumulated <= 32'b00000000000000000000000000000000;
        end else if (compute_step3) begin
            voltage_accumulated <= z_inst_DW_fp_add;
        end else begin
            voltage_accumulated <= voltage_accumulated;
        end
    end


/**************************************
        stage: SPIKE
**************************************/
    // spike_valid
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            spike_valid <= 0;
        end else if (current_state == SPIKE) begin
            spike_valid <= 1;
        end else begin
            spike_valid <= 0;
        end
    end

    // spike_output
    always @(*) begin
        if (voltage_accumulated[31] == 0 && voltage_accumulated[30:23] >= 8'b01111111) begin
            spike_output = 1;
        end else begin
            spike_output = 0;
        end
    end

    // voltage_new
    always @(*) begin
        if (spike_output) begin
            voltage_new = 0;
        end else if (voltage_accumulated[31] == 1'b1 ) begin
            voltage_new = 0;
        end else begin
            voltage_new = voltage_accumulated;
        end
    end

/**************************************
        for check
**************************************/
    // DW_fp_add
    //assign error_DW_fp_add = ((status_inst_DW_fp_add == 0) || (status_inst_DW_fp_add == 1)) ? 0 : 1;
    assign inst_a_DW_fp_add = (current_state == START) ? bias : (compute_step1) ?  j_current : (compute_step3) ? voltage_old : 32'b00000000000000000000000000000000;
    assign inst_b_DW_fp_add = (current_state == START) ? encoders : (compute_step1) ? {~voltage_old[31],voltage_old[30:0]} : (compute_step3) ? {~delta_voltage[31],delta_voltage[30:0]} : 32'b00000000000000000000000000000000;   

    // DW_fp_mult
    //assign error_DW_fp_mult = ((status_inst_DW_fp_mult == 0) || (status_inst_DW_fp_mult == 1)) ? 0 : 1;

    // error_lif
    //assign error_lif = error_DW_fp_mult | error_DW_fp_add;

/**************************************
        Instance
**************************************/
    // Instance of DW_fp_add
    float_add_sub  u_float_add_sub (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_add),              
        .s_axis_b_tvalid(1'b1),            
        .s_axis_b_tdata(inst_b_DW_fp_add),             
        .m_axis_result_tvalid(m_axis_result_tvalid_add),  
        .m_axis_result_tdata(z_inst_DW_fp_add)    
    );

    // Instance of DW_fp_mult
    float_mult     u_float_mult (
        .s_axis_a_tvalid(1'b1),            
        .s_axis_a_tdata(inst_a_DW_fp_mult),             
        .s_axis_b_tvalid(1'b1),          
        .s_axis_b_tdata(inst_b_DW_fp_mult),             
        .m_axis_result_tvalid(m_axis_result_tvalid_mult),  
        .m_axis_result_tdata(z_inst_DW_fp_mult)   
    );
    
endmodule