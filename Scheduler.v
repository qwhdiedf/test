// Float Point 
`define SIG_WIDTH 23
`define EXP_WIDTH 8
`define IEEE_COMPLIANCE 0
// SNN Network
`define ADDRESSSIZE_OF_SRAM 10
`define NUERONS_NUM 1024


module Scheduler(
    // control signal
    input   wire                                        clk,
    input   wire                                        rst,
    // snn_controller
    input   wire                                        start_snn_compute,      // last for one clock
    // lif input
    input   wire                                        spike_valid,
    input   wire                                        spike_output_lif,
    // learning_engine input
    input   wire                                        output_valid_learning_engine,
    // processing_engine input
    // input   wire                                        output_valid_processing_engine,
    // lif output
    output  reg                                         start_lif,
    // processing_engine outputs
    output  reg                                         start_processing_engine,
    output  reg                                         last_one_processing_engine,
    output  reg                                         spike_output_processing_engine,
    // learning_engine outputs
    output  reg                                         start_learning_engine,
    output  reg                                         spike_output_learning_engine,
    // bias_and_encoders_sram 1024 * 64
    output  wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          bias_and_encoders_sram_address,
    output  reg                                         bias_and_encoders_sram_write_enable,
    output  reg                                         bias_and_encoders_sram_chip_select,
    // refractory_time_sram 512 * 4
    output  wire[`ADDRESSSIZE_OF_SRAM - 2 : 0]          refractory_time_sram_address,
    output  wire                                        refractory_time_sram_data_select,
    output  reg                                         refractory_time_sram_write_enable,
    output  reg                                         refractory_time_sram_chip_select,
    // voltage_sram 1024 * 32
    output  wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          voltage_sram_address,
    output  reg                                         voltage_sram_write_enable,
    output  reg                                         voltage_sram_chip_select,
    // weight_sram 1024 * 160
    output  wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          weight_sram_address,
    output  reg                                         weight_sram_write_enable,
    output  reg                                         weight_sram_chip_select,
    // trace_value_sram 1024 * 32
    output  wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          trace_value_sram_address,
    output  reg                                         trace_value_sram_write_enable,
    output  reg                                         trace_value_sram_chip_select,
    // snn_controller
    output  reg                                         over_snn_compute         // last for one clock
);


    localparam IDLE =                                   5'b00001;
    localparam LIF =                                    5'b00010;
    localparam PROCESSING =                             5'b00100;
    localparam LEARNING =                               5'b01000;
    localparam DONE =                                   5'b10000;


/**************************************
        wire declaration
**************************************/
    // state reg declaration
        reg [4:0]                               current_state;
        reg [4:0]                               next_state;
    
    // control signal
        reg                                     control_counter;
        reg [`ADDRESSSIZE_OF_SRAM - 1 : 0]      nueron_counter;
        wire                                    lif_begin;
        reg                                     start_processing_stage;
        reg                                     start_processing_stage_reg_1;
        reg                                     start_processing_stage_reg_2;
        reg                                     start_processing_stage_reg_3;

    // variables
        reg                                     spike_valid_reg;


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
                    if (start_snn_compute) begin
                        next_state = LIF;
                    end else begin
                        next_state = IDLE;
                    end 
                end
            LIF:                                        // last for 5 clocks ?  xxx
                begin
                    if (spike_valid) begin
                        next_state = PROCESSING;
                    end else begin
                        next_state = LIF;
                    end 
                end 
            PROCESSING:                                 // last for 3 clocks ?  xxx
                begin
                    if(start_processing_stage_reg_3) begin
                        next_state = LEARNING;
                    end else begin
                        next_state = PROCESSING;
                    end
                end
            LEARNING:                                   // last for 5 clocks ?  xxx
                begin
                    if(output_valid_learning_engine) begin
                        if (nueron_counter == (`NUERONS_NUM - 1)) begin
                            next_state = DONE;
                        end else begin
                            next_state = LIF;
                        end
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
        control signal
**************************************/
    // control_counter
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            control_counter <= 0;
        end else if (output_valid_learning_engine) begin
            control_counter <= 1;
        end else begin
            control_counter <= 0;
        end
    end

    // start_processing_stage_reg_1      
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_processing_stage_reg_1 <= 0;
        end else if (start_processing_stage) begin
            start_processing_stage_reg_1 <= 1;
        end else begin
            start_processing_stage_reg_1 <= 0;
        end
    end 

    // start_processing_stage_reg_2      
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_processing_stage_reg_2 <= 0;
        end else if (start_processing_stage_reg_1) begin
            start_processing_stage_reg_2 <= 1;
        end else begin
            start_processing_stage_reg_2 <= 0;
        end
    end

    // start_processing_stage_reg_3     
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_processing_stage_reg_3 <= 0;
        end else if (start_processing_stage_reg_2) begin
            start_processing_stage_reg_3 <= 1;
        end else begin
            start_processing_stage_reg_3 <= 0;
        end
    end 
    
    // nueron_counter
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            nueron_counter <= `ADDRESSSIZE_OF_SRAM'b0;
        end else if (start_snn_compute) begin
            nueron_counter <= `ADDRESSSIZE_OF_SRAM'b0;
        end else if (control_counter) begin
            nueron_counter <= nueron_counter + 1;
        end else begin
            nueron_counter <= nueron_counter;
        end
    end   


/**************************************
        stage: LIF
**************************************/ 
    // start_lif
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_lif <= 0;
        end else if (((current_state == IDLE) && (next_state == LIF)) || ((current_state == LEARNING) && (next_state == LIF))) begin
            start_lif <= 1;
        end else begin
            start_lif <= 0;
        end
    end   
   
    // spike_valid_reg
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            spike_valid_reg <= 0;
        end else if (start_snn_compute) begin
            spike_valid_reg <= 0;
        end else if (spike_valid) begin
            spike_valid_reg <= spike_output_lif;
        end else begin
            spike_valid_reg <= spike_valid_reg;
        end
    end  

    // bias_and_encoders_sram_address
    assign bias_and_encoders_sram_address = nueron_counter;

    // bias_and_encoders_sram_chip_select
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            bias_and_encoders_sram_chip_select <= 1;
        end else if ((start_lif == 1) || (spike_valid == 1)) begin
            bias_and_encoders_sram_chip_select <= 0;
        end else begin
            bias_and_encoders_sram_chip_select <= 1;
        end
    end   

    // bias_and_encoders_sram_write_enable no write
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            bias_and_encoders_sram_write_enable <= 1;
        end else if (spike_valid) begin
            bias_and_encoders_sram_write_enable <= 1;
        end else begin
            bias_and_encoders_sram_write_enable <= 1;
        end
    end  

    // refractory_time_sram_address
    assign refractory_time_sram_address = nueron_counter[`ADDRESSSIZE_OF_SRAM - 1 : 1];

    // refractory_time_sram_data_select
    assign refractory_time_sram_data_select = nueron_counter[0];

    // refractory_time_sram_chip_select
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            refractory_time_sram_chip_select <= 1;
        end else if ((start_lif == 1) || (spike_valid == 1)) begin
            refractory_time_sram_chip_select <= 0;
        end else begin
            refractory_time_sram_chip_select <= 1;
        end
    end   

    // refractory_time_sram_write_enable
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            refractory_time_sram_write_enable <= 1;
        end else if (spike_valid) begin
            refractory_time_sram_write_enable <= 0;
        end else begin
            refractory_time_sram_write_enable <= 1;
        end
    end 

    // voltage_sram_address
    assign voltage_sram_address = nueron_counter;

    // voltage_sram_chip_select
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            voltage_sram_chip_select <= 1;
        end else if ((start_lif == 1) || (spike_valid == 1)) begin
            voltage_sram_chip_select <= 0;
        end else begin
            voltage_sram_chip_select <= 1;
        end
    end   

    // voltage_sram_write_enable
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            voltage_sram_write_enable <= 1;
        end else if (spike_valid) begin
            voltage_sram_write_enable <= 0;
        end else begin
            voltage_sram_write_enable <= 1;
        end
    end  


/**************************************
        stage: PROCESSING
**************************************/
    // start_processing_stage      
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_processing_stage <= 0;
        end else if ((current_state == LIF) && (next_state == PROCESSING)) begin
            start_processing_stage <= 1;
        end else begin
            start_processing_stage <= 0;
        end
    end 
    
    // start_processing_engine      only activate for one turn
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_processing_engine <= 0;
        end else if ((current_state == LIF) && (next_state == PROCESSING) && (nueron_counter == 0)) begin
            start_processing_engine <= 1;
        end else begin
            start_processing_engine <= 0;
        end
    end   
    
    // last_one_processing_engine
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            last_one_processing_engine <= 0;
        end else if (nueron_counter == (`NUERONS_NUM - 1) && start_processing_stage) begin
            last_one_processing_engine <= 1;
        end else begin
            last_one_processing_engine <= 0;
        end
    end 

    // spike_output_processing_engine
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            spike_output_processing_engine <= 0;
        end else if ((start_processing_stage == 1) && (spike_valid_reg == 1)) begin
            spike_output_processing_engine <= 1;
        end else begin
            spike_output_processing_engine <= 0;
        end
    end 


/**************************************
        stage: LEARNING
**************************************/
    // start_learning_engine        activate for each turn
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_learning_engine <= 0;
        end else if ((current_state == PROCESSING) && (next_state == LEARNING)) begin
            start_learning_engine <= 1;
        end else begin
            start_learning_engine <= 0;
        end
    end  
    
    // spike_output_learning_engine
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            spike_output_learning_engine <= 0;
        end else if ((current_state == LEARNING) && (spike_valid_reg == 1)) begin
            spike_output_learning_engine <= 1;
        end else begin
            spike_output_learning_engine <= 0;
        end
    end 

    // weight_sram_address
    assign weight_sram_address = nueron_counter;

    // weight_sram_chip_select
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_sram_chip_select <= 1;
        end else if ((start_learning_engine == 1) || (output_valid_learning_engine == 1) || (start_processing_stage == 1)) begin
            weight_sram_chip_select <= 0;
        end else begin
            weight_sram_chip_select <= 1;
        end
    end   

    // weight_sram_write_enable   xxx   check for the function
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            weight_sram_write_enable <= 1;
        end else if (output_valid_learning_engine == 1) begin
            weight_sram_write_enable <= 0;
        end else begin
            weight_sram_write_enable <= 1;
        end
    end 

    // trace_value_sram_address
    assign trace_value_sram_address = nueron_counter;

    // trace_value_sram_chip_select
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            trace_value_sram_chip_select <= 1;
        end else if ((start_learning_engine == 1) || (output_valid_learning_engine == 1)) begin
            trace_value_sram_chip_select <= 0;
        end else begin
            trace_value_sram_chip_select <= 1;
        end
    end   

    // trace_value_sram_write_enable
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            trace_value_sram_write_enable <= 1;
        end else if (output_valid_learning_engine) begin
            trace_value_sram_write_enable <= 0;
        end else begin
            trace_value_sram_write_enable <= 1;
        end
    end 


/**************************************
        stage: DONE
**************************************/
    // over_snn_compute
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            over_snn_compute <= 0;
        end else if (current_state == DONE) begin
            over_snn_compute <= 1;
        end else begin
            over_snn_compute <= 0;
        end
    end   

endmodule




