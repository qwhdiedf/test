// Float Point
`define SIG_WIDTH 23
`define EXP_WIDTH 8
`define IEEE_COMPLIANCE 0
`define DATA_WIDTH 32
// SNN Network
`define ADDRESSSIZE_OF_SRAM 10
`define NUERONS_NUM 1024

module SNN_Processing_Core(
    // control signal
    input   wire                                        clk,
    input   wire                                        rst,
    input   wire                                        start_snn_compute,      // last for one clock
    // from OSC
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_1,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_2,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_3,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_4,
    input   wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_5,
    input   wire[3:0]                                   sram_initial_mode,      // 0 stand for None
    input   wire[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   input_value_snn,
    input   wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          input_address_snn,
    // outputs
    output  reg                                         snn_output_valid,
    output  wire[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   u_adapt
    //output  wire                                        SNN_ip_error
);

    localparam IDLE =                   4'b0001;
    localparam INITIAL =                4'b0010;
    localparam COMPUTE =                4'b0100;
    localparam DONE =                   4'b1000;

/**************************************
        wire declaration
**************************************/
    // state reg declaration
        reg [3:0]                                   current_state;
        reg [3:0]                                   next_state;
    
    // LIF
        wire                                        start_lif;                          // last for one clock, each trun on need a independent start signal
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           bias;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           encoders;
        wire[1:0]                                   refractory_time_old;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           voltage_old;
        wire[1:0]                                   refractory_time_new;
        wire                                        spike_output;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           voltage_new;
        //wire                                        error_lif;
    
    // Processing_Engine
        wire                                        start_processing_engine;            // last for one clock
        wire                                        last_one_processing_engine;         // last for one clock
        wire                                        spike_output_processing_engine;     // last for one clock
        wire[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   weight_old; 
        //wire                                        error_processing_engine;
        wire                                        output_valid_processing_engine;

    // Learning_Engine
        wire                                        start_learning_engine;              // last for one clock
        wire                                        spike_output_learning_engine;       // last until output_valid
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           alpha;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_old_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_old_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_old_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_old_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_old_5; 
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           trace_value_old;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           trace_value_new;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_new_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_new_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_new_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_new_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           weight_new_5;
        //wire                                        error_learning_engine;

    // Scheduler
        wire                                        spike_valid;
        wire                                        spike_output_lif;
        wire                                        output_valid_learning_engine;
        wire                                        refractory_time_sram_data_select;
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          bias_and_encoders_sram_address_scheduler;             
        wire                                        bias_and_encoders_sram_write_enable_scheduler;       
        wire                                        bias_and_encoders_sram_chip_select_scheduler;        
        wire[`ADDRESSSIZE_OF_SRAM - 2 : 0]          refractory_time_sram_address_scheduler;           
        wire                                        refractory_time_sram_write_enable_scheduler;   
        wire                                        refractory_time_sram_chip_select_scheduler;    
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          voltage_sram_address_scheduler;                
        wire                                        voltage_sram_write_enable_scheduler;           
        wire                                        voltage_sram_chip_select_scheduler;            
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          weight_sram_address_scheduler;                 
        wire                                        weight_sram_write_enable_scheduler;            
        wire                                        weight_sram_chip_select_scheduler;             
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          trace_value_sram_address_scheduler;            
        wire                                        trace_value_sram_write_enable_scheduler;       
        wire                                        trace_value_sram_chip_select_scheduler;        
        wire                                        over_snn_compute;
        

    // bias_and_encoders_sram 1024 * 64
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          bias_and_encoders_sram_address;
        wire[2*`SIG_WIDTH + 2*`EXP_WIDTH + 1 : 0]   bias_and_encoders_sram_data_out;
        wire[2*`SIG_WIDTH + 2*`EXP_WIDTH + 1 : 0]   bias_and_encoders_sram_data_in;         
        wire                                        bias_and_encoders_sram_write_enable;    
        wire                                        bias_and_encoders_sram_chip_select;

    // refractory_time_sram 512 * 4 
        wire[`ADDRESSSIZE_OF_SRAM - 2 : 0]          refractory_time_sram_address;
        wire[3:0]                                   refractory_time_sram_data_out;
        wire[3:0]                                   refractory_time_sram_data_in;
        wire                                        refractory_time_sram_write_enable;
        wire                                        refractory_time_sram_chip_select;

    // voltage_sram 1024 * 32 
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          voltage_sram_address;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           voltage_sram_data_out;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           voltage_sram_data_in;
        wire                                        voltage_sram_write_enable;
        wire                                        voltage_sram_chip_select;
    
    // weight_sram 1024 * 160 
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          weight_sram_address;
        wire[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   weight_sram_data_out;
        wire[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   weight_sram_data_in;
        wire                                        weight_sram_write_enable;
        wire                                        weight_sram_chip_select;
    
    // trace_value_sram 1024 * 32 
        wire[`ADDRESSSIZE_OF_SRAM - 1 : 0]          trace_value_sram_address;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           trace_value_sram_data_out;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           trace_value_sram_data_in;
        wire                                        trace_value_sram_write_enable;
        wire                                        trace_value_sram_chip_select;
     

/**************************************
        wire connection
**************************************/
    // LIF
        assign bias = bias_and_encoders_sram_data_out[2*`DATA_WIDTH - 1 : `DATA_WIDTH];
        assign encoders = bias_and_encoders_sram_data_out[`DATA_WIDTH - 1 : 0];
        assign refractory_time_old = (refractory_time_sram_data_select) ? refractory_time_sram_data_out[3:2] : refractory_time_sram_data_out[1:0];
        assign voltage_old = voltage_sram_data_out;

    // Processing_Engine
        assign weight_old = weight_sram_data_out;

    // Learning_Engine
        assign alpha = 32'b10101110110101101011111110010101;            // Alpha = -9.765625000000001e-11
        assign weight_old_1 = weight_sram_data_out[1*`SIG_WIDTH + 1*`EXP_WIDTH      : 0                              ];
        assign weight_old_2 = weight_sram_data_out[2*`SIG_WIDTH + 2*`EXP_WIDTH + 1  : 1*`SIG_WIDTH + 1*`EXP_WIDTH + 1];
        assign weight_old_3 = weight_sram_data_out[3*`SIG_WIDTH + 3*`EXP_WIDTH + 2  : 2*`SIG_WIDTH + 2*`EXP_WIDTH + 2];
        assign weight_old_4 = weight_sram_data_out[4*`SIG_WIDTH + 4*`EXP_WIDTH + 3  : 3*`SIG_WIDTH + 3*`EXP_WIDTH + 3];
        assign weight_old_5 = weight_sram_data_out[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4  : 4*`SIG_WIDTH + 4*`EXP_WIDTH + 4];
        assign trace_value_old = trace_value_sram_data_out;

    // Scheduler
        assign spike_output_lif = spike_output;

    // bias_and_encoders_sram 1024 * 64
        assign bias_and_encoders_sram_address = (sram_initial_mode == 1) ? input_address_snn : bias_and_encoders_sram_address_scheduler;
        assign bias_and_encoders_sram_data_in = (sram_initial_mode == 1) ? input_value_snn[2*`SIG_WIDTH + 2*`EXP_WIDTH + 1 : 0] : 0;
        assign bias_and_encoders_sram_write_enable = (sram_initial_mode == 1) ? 1'b0 : bias_and_encoders_sram_write_enable_scheduler;
        assign bias_and_encoders_sram_chip_select = (sram_initial_mode == 1) ? 1'b0 : bias_and_encoders_sram_chip_select_scheduler;

    // refractory_time_sram 512 * 4 
        assign refractory_time_sram_address = (sram_initial_mode == 2) ? input_address_snn[`ADDRESSSIZE_OF_SRAM - 2 : 0] : refractory_time_sram_address_scheduler;
        assign refractory_time_sram_data_in = (sram_initial_mode == 2) ? input_value_snn[3 : 0] : (refractory_time_sram_data_select) ? {refractory_time_new,refractory_time_sram_data_out[1:0]} : {refractory_time_sram_data_out[3:2],refractory_time_new}; 
        assign refractory_time_sram_write_enable = (sram_initial_mode == 2) ? 1'b0 : refractory_time_sram_write_enable_scheduler;
        assign refractory_time_sram_chip_select = (sram_initial_mode == 2) ? 1'b0 : refractory_time_sram_chip_select_scheduler;

    // voltage_sram 1024 * 32    
        assign voltage_sram_address = (sram_initial_mode == 3) ? input_address_snn : voltage_sram_address_scheduler;
        assign voltage_sram_write_enable = (sram_initial_mode == 3) ? 1'b0 : voltage_sram_write_enable_scheduler;
        assign voltage_sram_data_in = (sram_initial_mode == 3) ? input_value_snn[`SIG_WIDTH + `EXP_WIDTH : 0] : voltage_new;
        assign voltage_sram_chip_select = (sram_initial_mode == 3) ? 1'b0 : voltage_sram_chip_select_scheduler;
    
    // weight_sram 1024 * 160 
        assign weight_sram_address = (sram_initial_mode == 4) ? input_address_snn : weight_sram_address_scheduler;
        assign weight_sram_data_in = (sram_initial_mode == 4) ? input_value_snn : {weight_new_5, weight_new_4, weight_new_3, weight_new_2, weight_new_1};
        assign weight_sram_write_enable = (sram_initial_mode == 4) ? 1'b0 : weight_sram_write_enable_scheduler;
        assign weight_sram_chip_select = (sram_initial_mode == 4) ? 1'b0 : weight_sram_chip_select_scheduler;

     // trace_value_sram 1024 * 32 
        assign trace_value_sram_address = (sram_initial_mode == 5) ? input_address_snn : trace_value_sram_address_scheduler;
        assign trace_value_sram_write_enable = (sram_initial_mode == 5) ? 1'b0 : trace_value_sram_write_enable_scheduler;
        assign trace_value_sram_data_in = (sram_initial_mode == 5) ? input_value_snn[`SIG_WIDTH + `EXP_WIDTH : 0] : trace_value_new;
        assign trace_value_sram_chip_select = (sram_initial_mode == 5) ? 1'b0 : trace_value_sram_chip_select_scheduler;


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
                        next_state = COMPUTE;
                    end else if (sram_initial_mode != 0) begin
                        next_state = INITIAL;
                    end else begin
                        next_state = IDLE;
                    end 
                end
            INITIAL:
                begin
                    if (sram_initial_mode == 0) begin
                        next_state = IDLE;
                    end else begin
                        next_state = INITIAL;
                    end
                end
            COMPUTE:      
                begin
                    if (over_snn_compute) begin
                        next_state = DONE;
                    end else begin
                        next_state = COMPUTE;
                    end 
                end
            DONE:   // last for one clocks    
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
        stage: INITIAL
**************************************/ 
    // sram_initial_mode
    // always @(*) begin
    //     case(sram_initial_mode)
    //         1 : begin
                
    //         end

    //     endcase
    // end



/**************************************
        stage: COMPUTE
**************************************/ 
   

/**************************************
        stage: DONE
**************************************/
     // snn_output_valid      only activate for one turn
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            snn_output_valid <= 0;
        end else if (current_state == DONE) begin
            snn_output_valid <= 1;
        end else begin
            snn_output_valid <= 0;
        end
    end   


/**************************************
        for check
**************************************/
    // SNN_ip_error
    //assign SNN_ip_error = error_lif | error_processing_engine | error_learning_engine;

/**************************************
        Instance
**************************************/
    // Instance of LIF 
    LIF u_LIF (
        .clk                            (clk                            ), 
        .rst                            (rst                            ), 
        .start_lif                      (start_lif                      ), 
        .bias                           (bias                           ), 
        .encoders                       (encoders                       ), 
        .refractory_time_old            (refractory_time_old            ), 
        .voltage_old                    (voltage_old                    ), 
        .spike_valid                    (spike_valid                    ), 
        .refractory_time_new            (refractory_time_new            ), 
        .spike_output                   (spike_output                   ), 
        .voltage_new                    (voltage_new                    )
        //.error_lif                      (error_lif                      )
    );

    // Instance of Processing_Engine 
    Processing_Engine u_Processing_Engine(
        .clk                            ( clk                           ),
        .rst                            ( rst                           ),
        .start_processing_engine        ( start_processing_engine       ),
        .last_one_processing_engine     ( last_one_processing_engine    ),
        .spike_output_processing_engine ( spike_output_processing_engine),
        .weight_old                     ( weight_old                    ),
        .output_valid                   ( output_valid_processing_engine),
        .u_adapt                        ( u_adapt                       )
        //.error_processing_engine        ( error_processing_engine       )
    );

    // Instance of Learning_Engine 
    Learning_Engine u_Learning_Engine(
        .clk                            ( clk                           ),
        .rst                            ( rst                           ),
        .start_learning_engine          ( start_learning_engine         ),
        .spike_output_learning_engine   ( spike_output_learning_engine  ),
        .alpha                          ( alpha                         ),
        .training_signal_1              ( training_signal_1             ),
        .training_signal_2              ( training_signal_2             ),
        .training_signal_3              ( training_signal_3             ),
        .training_signal_4              ( training_signal_4             ),
        .training_signal_5              ( training_signal_5             ),
        .weight_old_1                   ( weight_old_1                  ),
        .weight_old_2                   ( weight_old_2                  ),
        .weight_old_3                   ( weight_old_3                  ),
        .weight_old_4                   ( weight_old_4                  ),
        .weight_old_5                   ( weight_old_5                  ),
        .trace_value_old                ( trace_value_old               ),
        .output_valid                   ( output_valid_learning_engine  ),
        .trace_value_new                ( trace_value_new               ),
        .weight_new_1                   ( weight_new_1                  ),
        .weight_new_2                   ( weight_new_2                  ),
        .weight_new_3                   ( weight_new_3                  ),
        .weight_new_4                   ( weight_new_4                  ),
        .weight_new_5                   ( weight_new_5                  )
        //.error_learning_engine          ( error_learning_engine         )
    );

    // Instance of Scheduler 
    Scheduler u_Scheduler(
        .clk                                 ( clk                                           ),
        .rst                                 ( rst                                           ),
        .start_snn_compute                   ( start_snn_compute                             ),
        .spike_valid                         ( spike_valid                                   ),
        .spike_output_lif                    ( spike_output_lif                              ),
        .output_valid_learning_engine        ( output_valid_learning_engine                  ),
        // .output_valid_processing_engine      (output_valid_processing_engine                 ),
        .start_lif                           ( start_lif                                     ),
        .start_processing_engine             ( start_processing_engine                       ),
        .last_one_processing_engine          ( last_one_processing_engine                    ),
        .spike_output_processing_engine      ( spike_output_processing_engine                ),
        .start_learning_engine               ( start_learning_engine                         ),
        .spike_output_learning_engine        ( spike_output_learning_engine                  ),
        .bias_and_encoders_sram_address      ( bias_and_encoders_sram_address_scheduler      ), 
        .bias_and_encoders_sram_write_enable ( bias_and_encoders_sram_write_enable_scheduler ), 
        .bias_and_encoders_sram_chip_select  ( bias_and_encoders_sram_chip_select_scheduler  ),
        .refractory_time_sram_address        ( refractory_time_sram_address_scheduler        ),
        .refractory_time_sram_data_select    ( refractory_time_sram_data_select              ),
        .refractory_time_sram_write_enable   ( refractory_time_sram_write_enable_scheduler   ),
        .refractory_time_sram_chip_select    ( refractory_time_sram_chip_select_scheduler    ),
        .voltage_sram_address                ( voltage_sram_address_scheduler                ),
        .voltage_sram_write_enable           ( voltage_sram_write_enable_scheduler           ),
        .voltage_sram_chip_select            ( voltage_sram_chip_select_scheduler            ),
        .weight_sram_address                 ( weight_sram_address_scheduler                 ),
        .weight_sram_write_enable            ( weight_sram_write_enable_scheduler            ),
        .weight_sram_chip_select             ( weight_sram_chip_select_scheduler             ),
        .trace_value_sram_address            ( trace_value_sram_address_scheduler            ),
        .trace_value_sram_write_enable       ( trace_value_sram_write_enable_scheduler       ),
        .trace_value_sram_chip_select        ( trace_value_sram_chip_select_scheduler        ),
        .over_snn_compute                    ( over_snn_compute                              )
    );

    // bias_and_encoders_sram 1024 * 64  sram_initial_mode = 1
    ram_1024x64 bias_and_encoders_sram_1024x64 (
        .clka(clk),   
        .ena(~bias_and_encoders_sram_chip_select),      
        .wea(~bias_and_encoders_sram_write_enable),     
        .addra(bias_and_encoders_sram_address),  
        .dina(bias_and_encoders_sram_data_in),   
        .douta(bias_and_encoders_sram_data_out) 
    );


    // refractory_time_sram 512 * 4 sram_initial_mode = 2
    ram_512x4 refractory_time_sram_512x4 (
        .clka(clk),    
        .ena(~refractory_time_sram_chip_select),    
        .wea(~refractory_time_sram_write_enable),      
        .addra(refractory_time_sram_address),  
        .dina(refractory_time_sram_data_in),    
        .douta(refractory_time_sram_data_out)  
    );

    // voltage_sram 1024 * 32 sram_initial_mode = 3 
    ram_1024x32 voltage_sram_1024x32 (
        .clka(clk),   
        .ena(~voltage_sram_chip_select),      
        .wea(~voltage_sram_write_enable),      
        .addra(voltage_sram_address),  
        .dina(voltage_sram_data_in),    
        .douta(voltage_sram_data_out)  
    );

    // weight_sram 1024 * 160 sram_initial_mode = 4
    ram_1024x160 weight_sram_1024x160 (
        .clka(clk),    
        .ena(~weight_sram_chip_select),      
        .wea(~weight_sram_write_enable),     
        .addra(weight_sram_address),  
        .dina(weight_sram_data_in),    
        .douta(weight_sram_data_out)  
    );

    // trace_value_sram 1024 * 32 sram_initial_mode = 5
    ram_1024x32 trace_value_sram_1024x32 (
        .clka(clk),    
        .ena(~trace_value_sram_chip_select),      
        .wea(~trace_value_sram_write_enable),     
        .addra(trace_value_sram_address),  
        .dina(trace_value_sram_data_in),   
        .douta(trace_value_sram_data_out)  
);


endmodule