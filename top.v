// Float Point
`define SIG_WIDTH 23
`define EXP_WIDTH 8
`define IEEE_COMPLIANCE 0
`define DATA_WIDTH 32
// SNN Network
`define ADDRESSSIZE_OF_SRAM 10
`define NUERONS_NUM 1024

module top(
    // control signal
    input   wire                                        clk_p,
    input   wire                                        clk_n,
    //input   wire                                        clk,
    input   wire                                        rst,
    input   wire                                        chip_enable,            // config
    //input   wire                                        start_chip_compute,     // compute

    // initial
    // input   wire                                        data_valid,
    input   wire                                        uart_rxd,

    // outputs
    //output  reg                                         chip_output_valid,
    output  reg                                         chip_output_data
);

    localparam IDLE =                           6'b000001;
    localparam SRAM_INITIAL =                   6'b000010;
    localparam PARAMETER_INITIAL =              6'b000100;
    localparam OSC_COMPUTE =                    6'b001000;
    localparam SNN_COMPUTE =                    6'b010000;
    localparam DONE =                           6'b100000;

    localparam	integer	BYTES    = 4;	    //the number of received bytes 
    localparam	integer	BPS 	 = 9600;	
    localparam	integer	CLK_FRE  = 25_000_000; //25mhz

/**************************************
        wire declaration
**************************************/
    // state reg declaration
        reg [5:0]                                   current_state;
        reg [5:0]                                   next_state;

    // SNN
        wire                                        snn_output_valid;
        reg [3:0]                                   sram_initial_mode; 
        reg [5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0]   input_value_snn;
        reg [`ADDRESSSIZE_OF_SRAM - 1 : 0]          input_address_snn;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_1;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_2;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_3;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_4;
        wire[`SIG_WIDTH + `EXP_WIDTH : 0]           training_signal_5;
    
    // OSC
        wire  	                                    output_valid_osc;

        reg [31:0] dq_1;
        reg [31:0] dq_2;
        reg [31:0] dq_3;
        reg [31:0] dq_4;
        reg [31:0] dq_5;
        reg [31:0] dq_6;

        reg [31:0] target_1;
        reg [31:0] target_2;
        reg [31:0] target_3;

        reg [31:0] EE_position_1;
        reg [31:0] EE_position_2;
        reg [31:0] EE_position_3;

        reg [31:0] M_1_1;
        reg [31:0] M_2_1;
        reg [31:0] M_3_1;
        reg [31:0] M_4_1;
        reg [31:0] M_5_1;
        reg [31:0] M_6_1;

        reg [31:0] M_1_2;
        reg [31:0] M_2_2;
        reg [31:0] M_3_2;
        reg [31:0] M_4_2;
        reg [31:0] M_5_2;
        reg [31:0] M_6_2;

        reg [31:0] M_1_3;
        reg [31:0] M_2_3;
        reg [31:0] M_3_3;
        reg [31:0] M_4_3;
        reg [31:0] M_5_3;
        reg [31:0] M_6_3;

        reg [31:0] M_1_4;
        reg [31:0] M_2_4;
        reg [31:0] M_3_4;
        reg [31:0] M_4_4;
        reg [31:0] M_5_4;
        reg [31:0] M_6_4;

        reg [31:0] M_1_5;
        reg [31:0] M_2_5;
        reg [31:0] M_3_5;
        reg [31:0] M_4_5;
        reg [31:0] M_5_5;
        reg [31:0] M_6_5;

        reg [31:0] M_1_6;
        reg [31:0] M_2_6;
        reg [31:0] M_3_6;
        reg [31:0] M_4_6;
        reg [31:0] M_5_6;
        reg [31:0] M_6_6;

        reg [31:0] Mx_1_1;       
        reg [31:0] Mx_1_2;
        reg [31:0] Mx_1_3;       
        reg [31:0] Mx_2_1;
        reg [31:0] Mx_2_2;       
        reg [31:0] Mx_2_3;
        reg [31:0] Mx_3_1;       
        reg [31:0] Mx_3_2;
        reg [31:0] Mx_3_3;

        reg [31:0] gravity_bias_1;
        reg [31:0] gravity_bias_2;
        reg [31:0] gravity_bias_3;
        reg [31:0] gravity_bias_4;
        reg [31:0] gravity_bias_5;
        reg [31:0] gravity_bias_6;

        wire[31:0] u_1;      
        wire[31:0] u_2; 
        wire[31:0] u_3; 
        wire[31:0] u_4; 
        wire[31:0] u_5; 
        wire[31:0] u_6;

    // OSC fixed parameters
        wire [31:0] parameter_Kv = 32'b01000001101000000000000000000000 ;   
        wire [31:0] parameter_lamb = 32'b01000001001000000000000000000000 ;
        wire [31:0] parameter_scale_xyz = 32'b00111101010011001100110011001101 ;
        
        wire [31:0] J_1_1 = 32'b10111111000111000011110000011000;       
        wire [31:0] J_2_1 = 32'b00111000100100000000100101111100;
        wire [31:0] J_3_1 = 32'b10110011010010111111111101101001;
        
        wire [31:0] J_1_2 = 32'b00110101001110011110010011110000;       
        wire [31:0] J_2_2 = 32'b00111110100000000100000110000110;
        wire [31:0] J_3_2 = 32'b10110101001001001100000110011010;

        wire [31:0] J_1_3 = 32'b00111010000100010010011110110011;       
        wire [31:0] J_2_3 = 32'b00111110100110010101110010010010;
        wire [31:0] J_3_3 = 32'b10111001010110010011010000110101;

        wire [31:0] J_1_4 = 32'b00110100001001101000101010101011;       
        wire [31:0] J_2_4 = 32'b10111001011001111111011111110101;
        wire [31:0] J_3_4 = 32'b10110110001111001101000101000010;

        wire [31:0] J_1_5 = 32'b00000000000000000000000000000000;      
        wire [31:0] J_2_5 = 32'b10111111000111000010100001110001;
        wire [31:0] J_3_5 = 32'b10111111000011001101100111100111;

        wire [31:0] J_1_6 = 32'b00111001110110001111000100111111;       
        wire [31:0] J_2_6 = 32'b00110110010000000110000100000100;
        wire [31:0] J_3_6 = 32'b10111011111101011100001010001110;


    // control signal
        reg sram_initial_end;
        reg one_sram_initial_end;
        reg one_sram_initial_end_reg;
        reg sram_initial_end_reg;
        reg input_address_snn_counter;

        reg parameter_initial_end;
        reg [6:0] parameter_counter;

        reg step0;

        reg start_snn_compute;
        wire[5*`SIG_WIDTH + 5*`EXP_WIDTH + 4 : 0] u_adapt;

        reg [8:0] chip_output_counter;





/**************************************
        add for fpga test
**************************************/
        wire [31:0] data_input;
        reg         start_chip_compute;
        reg         chip_output_valid;
        wire        uart_bytes_vld;

    IBUFDS IBUFDS_inst ( 
      .O(clk),  // Buffer output 
      .I(clk_p),  // Diff_p buffer input (connect directly to top-level port) 
      .IB(clk_n) // Diff_n buffer input (connect directly to top-level port) 
    ); 
    

    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            start_chip_compute <= 1'b0;
        else if((sram_initial_end == 1'b1) && (current_state == SRAM_INITIAL))
            start_chip_compute <= 1'b1;
        else
            start_chip_compute <= 1'b0;
    end
        
        
        
/**************************************
        wire connection
**************************************/
    

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
                    if (chip_enable) begin
                        next_state = SRAM_INITIAL;
                    end /*else if (start_chip_compute) begin
                        next_state = PARAMETER_INITIAL;
                    end*/ else begin
                        next_state = IDLE;
                    end 
                end
            SRAM_INITIAL:
                begin
                    if (start_chip_compute) begin
                        next_state = PARAMETER_INITIAL;
                    end else begin
                        next_state = SRAM_INITIAL;
                    end 
                end
            PARAMETER_INITIAL:
                begin
                    if (parameter_initial_end) begin
                        next_state = OSC_COMPUTE;
                    end else begin
                        next_state = PARAMETER_INITIAL;
                    end 
                end
            OSC_COMPUTE:      
                begin
                    if (output_valid_osc) begin
                        next_state = SNN_COMPUTE;
                    end else begin
                        next_state = OSC_COMPUTE;
                    end 
                end
            SNN_COMPUTE:      
                begin
                    if (snn_output_valid) begin
                        next_state = DONE;
                    end else begin
                        next_state = SNN_COMPUTE;
                    end 
                end
            DONE:   // last for one clocks    
                begin
                    if (chip_output_counter == 352) begin
                        next_state = IDLE;
                    end else begin
                        next_state = DONE;
                    end
                end
            default:
                begin
                    next_state = IDLE;
                end
        endcase
    end


/**************************************
        stage: SRAM_INITIAL
**************************************/  
    // sram_initial_mode
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            sram_initial_mode <= 4'b0000;     
        end else if ((current_state == IDLE) && (next_state == SRAM_INITIAL)) begin
            sram_initial_mode <= 4'b0001;
        end else if (current_state == SRAM_INITIAL) begin
            case(sram_initial_mode)
                4'b0001:        // bias_and_encoders_sram
                    begin
                        if (one_sram_initial_end_reg) begin
                            sram_initial_mode <= 4'b0011; 
                        end else begin
                            sram_initial_mode <= sram_initial_mode;
                        end
                    end
                4'b0010:        // refractory_time_sram
                    begin
                        if (one_sram_initial_end) begin
                            sram_initial_mode <= 4'b0100; 
                        end else begin
                            sram_initial_mode <= sram_initial_mode;
                        end
                    end
                4'b0011:        // voltage_sram
                    begin
                        if (one_sram_initial_end) begin
                            sram_initial_mode <= 4'b0010; 
                        end else begin
                            sram_initial_mode <= sram_initial_mode;
                        end
                    end
                4'b0100:        // weight_sram
                    begin 
                        if (one_sram_initial_end) begin
                            sram_initial_mode <= 4'b0101; 
                        end else begin
                            sram_initial_mode <= sram_initial_mode;
                        end
                    end
                4'b0101:        // trace_value_sram
                    begin 
                        if (one_sram_initial_end) begin
                            sram_initial_mode <= 4'b0000; 
                        end else begin
                            sram_initial_mode <= sram_initial_mode;
                        end
                    end
                default:
                    begin
                        sram_initial_mode <= sram_initial_mode;
                    end
            endcase
        end else begin
            sram_initial_mode <= 4'b0000; 
        end
    end
    
    // input_address_snn
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            input_address_snn <= 0;
        end else if (current_state == SRAM_INITIAL) begin
            if (input_address_snn_counter) begin
                input_address_snn <= input_address_snn + 1;
            end else begin
                input_address_snn <= input_address_snn;
            end
        end else begin
            input_address_snn <= 0;
        end
    end

    // input_address_snn_counter
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            input_address_snn_counter <= 0;
        end else if (current_state == SRAM_INITIAL) begin
            if ((sram_initial_mode == 4'b0001) && (input_address_snn_counter == 1)) begin
                input_address_snn_counter <= 0;
            end else begin
                input_address_snn_counter <= 1;
            end
        end else begin
            input_address_snn_counter <= 0;
        end
    end


    // one_sram_initial_end
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            one_sram_initial_end <= 0;
        end else if (input_address_snn == 1023) begin
            one_sram_initial_end <= 1;
        end else begin
            one_sram_initial_end <= 0;
        end
    end

    // one_sram_initial_end_reg
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            one_sram_initial_end_reg <= 0;
        end else if (one_sram_initial_end) begin
            one_sram_initial_end_reg <= 1;
        end else begin
            one_sram_initial_end_reg <= 0;
        end
    end
 
    // input_value_snn
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            input_value_snn <= 0;
        end else if (current_state == SRAM_INITIAL) begin
            case(sram_initial_mode)
                4'b0001:        // bias_and_encoders_sram
                    begin
                        if (input_address_snn_counter) begin
                            input_value_snn <= data_input;
                        end else begin
                            input_value_snn <= {data_input, input_value_snn[31:0]};
                        end  
                    end
                4'b0010:        // refractory_time_sram
                    begin
                        input_value_snn <= data_input;
                    end
                4'b0011:        // voltage_sram
                    begin
                        input_value_snn <= data_input;
                    end
                4'b0100:        // weight_sram
                    begin 
                        input_value_snn <= data_input;
                    end
                4'b0101:        // trace_value_sram
                    begin 
                        input_value_snn <= data_input;
                    end
                default:
                    begin
                        input_value_snn <= data_input;
                    end
            endcase
        end else begin
            input_value_snn <= 0;
        end
    end

    // sram_initial_end_reg
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            sram_initial_end_reg <= 0;
        end else if ((sram_initial_mode == 4'b0101) && (input_address_snn == 1023)) begin
            sram_initial_end_reg <= 1;
        end else begin
            sram_initial_end_reg <= 0;
        end
    end

    // sram_initial_end
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            sram_initial_end <= 0;
        end else if (sram_initial_end_reg) begin
            sram_initial_end <= 1;
        end else begin
            sram_initial_end <= 0;
        end
    end

/**************************************
        stage: PARAMETER_INITIAL
**************************************/ 
    // parameter_counter
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            parameter_counter <= 0;
        end else if (current_state == PARAMETER_INITIAL) begin
                parameter_counter <= parameter_counter + 1;
        end else begin
            parameter_counter <= 0;
        end
    end

// parameter
    // dq_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dq_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 0)) begin
            dq_1 <= data_input;
        end else begin
            dq_1 <= dq_1;
        end
    end

    // dq_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dq_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 1)) begin
            dq_2 <= data_input;
        end else begin
            dq_2 <= dq_2;
        end
    end

    // dq_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dq_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 2)) begin
            dq_3 <= data_input;
        end else begin
            dq_3 <= dq_3;
        end
    end

    // dq_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dq_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 3)) begin
            dq_4 <= data_input;
        end else begin
            dq_4 <= dq_4;
        end
    end

    // dq_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dq_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 4)) begin
            dq_5 <= data_input;
        end else begin
            dq_5 <= dq_5;
        end
    end

    // dq_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dq_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 5)) begin
            dq_6 <= data_input;
        end else begin
            dq_6 <= dq_6;
        end
    end

    // target_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            target_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 6)) begin
            target_1 <= data_input;
        end else begin
            target_1 <= target_1;
        end
    end

    // target_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            target_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 7)) begin
            target_2 <= data_input;
        end else begin
            target_2 <= target_2;
        end
    end

    // target_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            target_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 8)) begin
            target_3 <= data_input;
        end else begin
            target_3 <= target_3;
        end
    end

    // EE_position_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            EE_position_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 9)) begin
            EE_position_1 <= data_input;
        end else begin
            EE_position_1 <= EE_position_1;
        end
    end

    // EE_position_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            EE_position_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 10)) begin
            EE_position_2 <= data_input;
        end else begin
            EE_position_2 <= EE_position_2;
        end
    end

    // EE_position_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            EE_position_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 11)) begin
            EE_position_3 <= data_input;
        end else begin
            EE_position_3 <= EE_position_3;
        end
    end
    
    // M_1_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_1_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 12)) begin
            M_1_1 <= data_input;
        end else begin
            M_1_1 <= M_1_1;
        end
    end

    // M_2_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_2_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 13)) begin
            M_2_1 <= data_input;
        end else begin
            M_2_1 <= M_2_1;
        end
    end

    // M_3_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_3_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 14)) begin
            M_3_1 <= data_input;
        end else begin
            M_3_1 <= M_3_1;
        end
    end

    // M_4_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_4_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 15)) begin
            M_4_1 <= data_input;
        end else begin
            M_4_1 <= M_4_1;
        end
    end

    // M_5_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_5_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 16)) begin
            M_5_1 <= data_input;
        end else begin
            M_5_1 <= M_5_1;
        end
    end

    // M_6_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_6_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 17)) begin
            M_6_1 <= data_input;
        end else begin
            M_6_1 <= M_6_1;
        end
    end

    // M_1_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_1_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 18)) begin
            M_1_2 <= data_input;
        end else begin
            M_1_2 <= M_1_2;
        end
    end

    // M_2_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_2_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 19)) begin
            M_2_2 <= data_input;
        end else begin
            M_2_2 <= M_2_2;
        end
    end

    // M_3_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_3_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 20)) begin
            M_3_2 <= data_input;
        end else begin
            M_3_2 <= M_3_2;
        end
    end

    // M_4_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_4_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 21)) begin
            M_4_2 <= data_input;
        end else begin
            M_4_2 <= M_4_2;
        end
    end

    // M_5_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_5_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 22)) begin
            M_5_2 <= data_input;
        end else begin
            M_5_2 <= M_5_2;
        end
    end
    
    // M_6_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_6_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 23)) begin
            M_6_2 <= data_input;
        end else begin
            M_6_2 <= M_6_2;
        end
    end

    // M_1_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_1_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 24)) begin
            M_1_3 <= data_input;
        end else begin
            M_1_3 <= M_1_3;
        end
    end

    // M_2_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_2_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 25)) begin
            M_2_3 <= data_input;
        end else begin
            M_2_3 <= M_2_3;
        end
    end

    // M_3_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_3_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 26)) begin
            M_3_3 <= data_input;
        end else begin
            M_3_3 <= M_3_3;
        end
    end

    // M_4_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_4_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 26)) begin
            M_4_3 <= data_input;
        end else begin
            M_4_3 <= M_4_3;
        end
    end

    // M_5_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_5_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 27)) begin
            M_5_3 <= data_input;
        end else begin
            M_5_3 <= M_5_3;
        end
    end

    // M_6_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_6_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 28)) begin
            M_6_3 <= data_input;
        end else begin
            M_6_3 <= M_6_3;
        end
    end

    // M_1_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_1_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 29)) begin
            M_1_4 <= data_input;
        end else begin
            M_1_4 <= M_1_4;
        end
    end

    // M_2_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_2_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 30)) begin
            M_2_4 <= data_input;
        end else begin
            M_2_4 <= M_2_4;
        end
    end

    // M_3_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_3_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 31)) begin
            M_3_4 <= data_input;
        end else begin
            M_3_4 <= M_3_4;
        end
    end

    // M_4_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_4_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 32)) begin
            M_4_4 <= data_input;
        end else begin
            M_4_4 <= M_4_4;
        end
    end

    // M_5_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_5_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 33)) begin
            M_5_4 <= data_input;
        end else begin
            M_5_4 <= M_5_4;
        end
    end

    // M_6_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_6_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 34)) begin
            M_6_4 <= data_input;
        end else begin
            M_6_4 <= M_6_4;
        end
    end

    // M_1_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_1_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 35)) begin
            M_1_5 <= data_input;
        end else begin
            M_1_5 <= M_1_5;
        end
    end

    // M_2_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_2_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 36)) begin
            M_2_5 <= data_input;
        end else begin
            M_2_5 <= M_2_5;
        end
    end

    // M_3_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_3_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 37)) begin
            M_3_5 <= data_input;
        end else begin
            M_3_5 <= M_3_5;
        end
    end

    // M_4_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_4_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 38)) begin
            M_4_5 <= data_input;
        end else begin
            M_4_5 <= M_4_5;
        end
    end

    // M_5_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_5_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 39)) begin
            M_5_5 <= data_input;
        end else begin
            M_5_5 <= M_5_5;
        end
    end

    // M_6_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_6_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 40)) begin
            M_6_5 <= data_input;
        end else begin
            M_6_5 <= M_6_5;
        end
    end

    // M_1_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_1_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 41)) begin
            M_1_6 <= data_input;
        end else begin
            M_1_6 <= M_1_6;
        end
    end

    // M_2_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_2_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 42)) begin
            M_2_6 <= data_input;
        end else begin
            M_2_6 <= M_2_6;
        end
    end

    // M_3_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_3_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 43)) begin
            M_3_6 <= data_input;
        end else begin
            M_3_6 <= M_3_6;
        end
    end

    // M_4_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_4_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 44)) begin
            M_4_6 <= data_input;
        end else begin
            M_4_6 <= M_4_6;
        end
    end

    // M_5_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_5_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 45)) begin
            M_5_6 <= data_input;
        end else begin
            M_5_6 <= M_5_6;
        end
    end

    // M_6_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            M_6_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 46)) begin
            M_6_6 <= data_input;
        end else begin
            M_6_6 <= M_6_6;
        end
    end

    // Mx_1_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_1_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 47)) begin
            Mx_1_1 <= data_input;
        end else begin
            Mx_1_1 <= Mx_1_1;
        end
    end

    // Mx_1_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_1_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 48)) begin
            Mx_1_2 <= data_input;
        end else begin
            Mx_1_2 <= Mx_1_2;
        end
    end

    // Mx_1_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_1_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 49)) begin
            Mx_1_3 <= data_input;
        end else begin
            Mx_1_3 <= Mx_1_3;
        end
    end

    // Mx_2_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_2_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 50)) begin
            Mx_2_1 <= data_input;
        end else begin
            Mx_2_1 <= Mx_2_1;
        end
    end

    // Mx_2_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_2_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 51)) begin
            Mx_2_2 <= data_input;
        end else begin
            Mx_2_2 <= Mx_2_2;
        end
    end

    // Mx_2_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_2_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 52)) begin
            Mx_2_3 <= data_input;
        end else begin
            Mx_2_3 <= Mx_2_3;
        end
    end

    // Mx_3_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_3_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 53)) begin
            Mx_3_1 <= data_input;
        end else begin
            Mx_3_1 <= Mx_3_1;
        end
    end

    // Mx_3_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_3_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 54)) begin
            Mx_3_2 <= data_input;
        end else begin
            Mx_3_2 <= Mx_3_2;
        end
    end

    // Mx_3_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            Mx_3_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 55)) begin
            Mx_3_3 <= data_input;
        end else begin
            Mx_3_3 <= Mx_3_3;
        end
    end

    // gravity_bias_1
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            gravity_bias_1 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 56)) begin
            gravity_bias_1 <= data_input;
        end else begin
            gravity_bias_1 <= gravity_bias_1;
        end
    end

    // gravity_bias_2
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            gravity_bias_2 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 57)) begin
            gravity_bias_2 <= data_input;
        end else begin
            gravity_bias_2 <= gravity_bias_2;
        end
    end

    // gravity_bias_3
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            gravity_bias_3 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 58)) begin
            gravity_bias_3 <= data_input;
        end else begin
            gravity_bias_3 <= gravity_bias_3;
        end
    end

    // gravity_bias_4
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            gravity_bias_4 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 59)) begin
            gravity_bias_4 <= data_input;
        end else begin
            gravity_bias_4 <= gravity_bias_4;
        end
    end

    // gravity_bias_5
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            gravity_bias_5 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 60)) begin
            gravity_bias_5 <= data_input;
        end else begin
            gravity_bias_5 <= gravity_bias_5;
        end
    end

    // gravity_bias_6
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            gravity_bias_6 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 61)) begin
            gravity_bias_6 <= data_input;
        end else begin
            gravity_bias_6 <= gravity_bias_6;
        end
    end

    // parameter_initial_end
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            parameter_initial_end <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (parameter_counter == 62)) begin
            parameter_initial_end <= 1;
        end else begin
            parameter_initial_end <= parameter_initial_end;
        end
    end


/**************************************
        stage: OSC_COMPUTE
**************************************/
    // step0
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            step0 <= 0;
        end else if ((current_state == PARAMETER_INITIAL) && (next_state == OSC_COMPUTE)) begin
            step0 <= 1;
        end else begin
            step0 <= 0;
        end
    end

/**************************************
        stage: SNN_COMPUTE
**************************************/ 
    // start_snn_compute
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            start_snn_compute <= 0;
        end else if ((current_state == OSC_COMPUTE) && (next_state == SNN_COMPUTE)) begin
            start_snn_compute <= 1;
        end else begin
            start_snn_compute <= 0;
        end
    end

    assign  training_signal_1 = u_1;
    assign  training_signal_2 = u_2;
    assign  training_signal_3 = u_3;
    assign  training_signal_4 = u_4;
    assign  training_signal_5 = u_5;
    assign  training_signal_6 = u_6;

/**************************************
        stage: DONE
**************************************/
    // chip_output_valid
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            chip_output_valid <= 0;
        end else if ((current_state == DONE) && (chip_output_valid == 0) && (chip_output_counter == 352)) begin
            chip_output_valid <= 1;
        end else begin
            chip_output_valid <= 0;
        end
    end
    
    // chip_output_counter
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            chip_output_counter <= 0;
        end else if (current_state == DONE) begin
            chip_output_counter <= chip_output_counter + 1;
        end else begin
            chip_output_counter <= 0;
        end
    end

    // 
    always @(*) begin
        case (chip_output_counter)
            0: chip_output_data <= u_1[0];
            1: chip_output_data <= u_1[1];
            2: chip_output_data <= u_1[2];
            3: chip_output_data <= u_1[3];
            4: chip_output_data <= u_1[4];
            5: chip_output_data <= u_1[5];
            6: chip_output_data <= u_1[6];
            7: chip_output_data <= u_1[7];
            8: chip_output_data <= u_1[8];
            9: chip_output_data <= u_1[9];
            10: chip_output_data <= u_1[10];
            11: chip_output_data <= u_1[11];
            12: chip_output_data <= u_1[12];
            13: chip_output_data <= u_1[13];
            14: chip_output_data <= u_1[14];
            15: chip_output_data <= u_1[15];
            16: chip_output_data <= u_1[16];
            17: chip_output_data <= u_1[17];
            18: chip_output_data <= u_1[18];
            19: chip_output_data <= u_1[19];
            20: chip_output_data <= u_1[20];
            21: chip_output_data <= u_1[21];
            22: chip_output_data <= u_1[22];
            23: chip_output_data <= u_1[23];
            24: chip_output_data <= u_1[24];
            25: chip_output_data <= u_1[25];
            26: chip_output_data <= u_1[26];
            27: chip_output_data <= u_1[27];
            28: chip_output_data <= u_1[28];
            29: chip_output_data <= u_1[29];
            30: chip_output_data <= u_1[30];
            31: chip_output_data <= u_1[31];

            32: chip_output_data <= u_2[0];
            33: chip_output_data <= u_2[1];
            34: chip_output_data <= u_2[2];
            35: chip_output_data <= u_2[3];
            36: chip_output_data <= u_2[4];
            37: chip_output_data <= u_2[5];
            38: chip_output_data <= u_2[6];
            39: chip_output_data <= u_2[7];
            40: chip_output_data <= u_2[8];
            41: chip_output_data <= u_2[9];
            42: chip_output_data <= u_2[10];
            43: chip_output_data <= u_2[11];
            44: chip_output_data <= u_2[12];
            45: chip_output_data <= u_2[13];
            46: chip_output_data <= u_2[14];
            47: chip_output_data <= u_2[15];
            48: chip_output_data <= u_2[16];
            49: chip_output_data <= u_2[17];
            50: chip_output_data <= u_2[18];
            51: chip_output_data <= u_2[19];
            52: chip_output_data <= u_2[20];
            53: chip_output_data <= u_2[21];
            54: chip_output_data <= u_2[22];
            55: chip_output_data <= u_2[23];
            56: chip_output_data <= u_2[24];
            57: chip_output_data <= u_2[25];
            58: chip_output_data <= u_2[26];
            59: chip_output_data <= u_2[27];
            60: chip_output_data <= u_2[28];
            61: chip_output_data <= u_2[29];
            62: chip_output_data <= u_2[30];
            63: chip_output_data <= u_2[31];

            64: chip_output_data <= u_3[0];
            65: chip_output_data <= u_3[1];
            66: chip_output_data <= u_3[2];
            67: chip_output_data <= u_3[3];
            68: chip_output_data <= u_3[4];
            69: chip_output_data <= u_3[5];
            70: chip_output_data <= u_3[6];
            71: chip_output_data <= u_3[7];
            72: chip_output_data <= u_3[8];
            73: chip_output_data <= u_3[9];
            74: chip_output_data <= u_3[10];
            75: chip_output_data <= u_3[11];
            76: chip_output_data <= u_3[12];
            77: chip_output_data <= u_3[13];
            78: chip_output_data <= u_3[14];
            79: chip_output_data <= u_3[15];
            80: chip_output_data <= u_3[16];
            81: chip_output_data <= u_3[17];
            82: chip_output_data <= u_3[18];
            83: chip_output_data <= u_3[19];
            84: chip_output_data <= u_3[20];
            85: chip_output_data <= u_3[21];
            86: chip_output_data <= u_3[22];
            87: chip_output_data <= u_3[23];
            88: chip_output_data <= u_3[24];
            89: chip_output_data <= u_3[25];
            90: chip_output_data <= u_3[26];
            91: chip_output_data <= u_3[27];
            92: chip_output_data <= u_3[28];
            93: chip_output_data <= u_3[29];
            94: chip_output_data <= u_3[30];
            95: chip_output_data <= u_3[31];

            96: chip_output_data <= u_4[0];
            97: chip_output_data <= u_4[1];
            98: chip_output_data <= u_4[2];
            99: chip_output_data <= u_4[3];
            100: chip_output_data <= u_4[4];
            101: chip_output_data <= u_4[5];
            102: chip_output_data <= u_4[6];
            103: chip_output_data <= u_4[7];
            104: chip_output_data <= u_4[8];
            105: chip_output_data <= u_4[9];
            106: chip_output_data <= u_4[10];
            107: chip_output_data <= u_4[11];
            108: chip_output_data <= u_4[12];
            109: chip_output_data <= u_4[13];
            110: chip_output_data <= u_4[14];
            111: chip_output_data <= u_4[15];
            112: chip_output_data <= u_4[16];
            113: chip_output_data <= u_4[17];
            114: chip_output_data <= u_4[18];
            115: chip_output_data <= u_4[19];
            116: chip_output_data <= u_4[20];
            117: chip_output_data <= u_4[21];
            118: chip_output_data <= u_4[22];
            119: chip_output_data <= u_4[23];
            120: chip_output_data <= u_4[24];
            121: chip_output_data <= u_4[25];
            122: chip_output_data <= u_4[26];
            123: chip_output_data <= u_4[27];
            124: chip_output_data <= u_4[28];
            125: chip_output_data <= u_4[29];
            126: chip_output_data <= u_4[30];
            127: chip_output_data <= u_4[31];

            128: chip_output_data <= u_5[0];
            129: chip_output_data <= u_5[1];
            130: chip_output_data <= u_5[2];
            131: chip_output_data <= u_5[3];
            132: chip_output_data <= u_5[4];
            133: chip_output_data <= u_5[5];
            134: chip_output_data <= u_5[6];
            135: chip_output_data <= u_5[7];
            136: chip_output_data <= u_5[8];
            137: chip_output_data <= u_5[9];
            138: chip_output_data <= u_5[10];
            139: chip_output_data <= u_5[11];
            140: chip_output_data <= u_5[12];
            141: chip_output_data <= u_5[13];
            142: chip_output_data <= u_5[14];
            143: chip_output_data <= u_5[15];
            144: chip_output_data <= u_5[16];
            145: chip_output_data <= u_5[17];
            146: chip_output_data <= u_5[18];
            147: chip_output_data <= u_5[19];
            148: chip_output_data <= u_5[20];
            149: chip_output_data <= u_5[21];
            150: chip_output_data <= u_5[22];
            151: chip_output_data <= u_5[23];
            152: chip_output_data <= u_5[24];
            153: chip_output_data <= u_5[25];
            154: chip_output_data <= u_5[26];
            155: chip_output_data <= u_5[27];
            156: chip_output_data <= u_5[28];
            157: chip_output_data <= u_5[29];
            158: chip_output_data <= u_5[30];
            159: chip_output_data <= u_5[31];

            160: chip_output_data <= u_6[0];
            161: chip_output_data <= u_6[1];
            162: chip_output_data <= u_6[2];
            163: chip_output_data <= u_6[3];
            164: chip_output_data <= u_6[4];
            165: chip_output_data <= u_6[5];
            166: chip_output_data <= u_6[6];
            167: chip_output_data <= u_6[7];
            168: chip_output_data <= u_6[8];
            169: chip_output_data <= u_6[9];
            170: chip_output_data <= u_6[10];
            171: chip_output_data <= u_6[11];
            172: chip_output_data <= u_6[12];
            173: chip_output_data <= u_6[13];
            174: chip_output_data <= u_6[14];
            175: chip_output_data <= u_6[15];
            176: chip_output_data <= u_6[16];
            177: chip_output_data <= u_6[17];
            178: chip_output_data <= u_6[18];
            179: chip_output_data <= u_6[19];
            180: chip_output_data <= u_6[20];
            181: chip_output_data <= u_6[21];
            182: chip_output_data <= u_6[22];
            183: chip_output_data <= u_6[23];
            184: chip_output_data <= u_6[24];
            185: chip_output_data <= u_6[25];
            186: chip_output_data <= u_6[26];
            187: chip_output_data <= u_6[27];
            188: chip_output_data <= u_6[28];
            189: chip_output_data <= u_6[29];
            190: chip_output_data <= u_6[30];
            191: chip_output_data <= u_6[31];

            192: chip_output_data <= u_adapt[0];
            193: chip_output_data <= u_adapt[1];
            194: chip_output_data <= u_adapt[2];
            195: chip_output_data <= u_adapt[3];
            196: chip_output_data <= u_adapt[4];
            197: chip_output_data <= u_adapt[5];
            198: chip_output_data <= u_adapt[6];
            199: chip_output_data <= u_adapt[7];
            200: chip_output_data <= u_adapt[8];
            201: chip_output_data <= u_adapt[9];
            202: chip_output_data <= u_adapt[10];
            203: chip_output_data <= u_adapt[11];
            204: chip_output_data <= u_adapt[12];
            205: chip_output_data <= u_adapt[13];
            206: chip_output_data <= u_adapt[14];
            207: chip_output_data <= u_adapt[15];
            208: chip_output_data <= u_adapt[16];
            209: chip_output_data <= u_adapt[17];
            210: chip_output_data <= u_adapt[18];
            211: chip_output_data <= u_adapt[19];
            212: chip_output_data <= u_adapt[20];
            213: chip_output_data <= u_adapt[21];
            214: chip_output_data <= u_adapt[22];
            215: chip_output_data <= u_adapt[23];
            216: chip_output_data <= u_adapt[24];
            217: chip_output_data <= u_adapt[25];
            218: chip_output_data <= u_adapt[26];
            219: chip_output_data <= u_adapt[27];
            220: chip_output_data <= u_adapt[28];
            221: chip_output_data <= u_adapt[29];
            222: chip_output_data <= u_adapt[30];
            223: chip_output_data <= u_adapt[31];

            224: chip_output_data <= u_adapt[32];
            225: chip_output_data <= u_adapt[33];
            226: chip_output_data <= u_adapt[34];
            227: chip_output_data <= u_adapt[35];
            228: chip_output_data <= u_adapt[36];
            229: chip_output_data <= u_adapt[37];
            230: chip_output_data <= u_adapt[38];
            231: chip_output_data <= u_adapt[39];
            232: chip_output_data <= u_adapt[40];
            233: chip_output_data <= u_adapt[41];
            234: chip_output_data <= u_adapt[42];
            235: chip_output_data <= u_adapt[43];
            236: chip_output_data <= u_adapt[44];
            237: chip_output_data <= u_adapt[45];
            238: chip_output_data <= u_adapt[46];
            239: chip_output_data <= u_adapt[47];
            240: chip_output_data <= u_adapt[48];
            241: chip_output_data <= u_adapt[49];
            242: chip_output_data <= u_adapt[50];
            243: chip_output_data <= u_adapt[51];
            244: chip_output_data <= u_adapt[52];
            245: chip_output_data <= u_adapt[53];
            246: chip_output_data <= u_adapt[54];
            247: chip_output_data <= u_adapt[55];
            248: chip_output_data <= u_adapt[56];
            249: chip_output_data <= u_adapt[57];
            250: chip_output_data <= u_adapt[58];
            251: chip_output_data <= u_adapt[59];
            252: chip_output_data <= u_adapt[60];
            253: chip_output_data <= u_adapt[61];
            254: chip_output_data <= u_adapt[62];
            255: chip_output_data <= u_adapt[63];

            256: chip_output_data <= u_adapt[64];
            257: chip_output_data <= u_adapt[65];
            258: chip_output_data <= u_adapt[66];
            259: chip_output_data <= u_adapt[67];
            260: chip_output_data <= u_adapt[68];
            261: chip_output_data <= u_adapt[69];
            262: chip_output_data <= u_adapt[70];
            263: chip_output_data <= u_adapt[71];
            264: chip_output_data <= u_adapt[72];
            265: chip_output_data <= u_adapt[73];
            266: chip_output_data <= u_adapt[74];
            267: chip_output_data <= u_adapt[75];
            268: chip_output_data <= u_adapt[76];
            269: chip_output_data <= u_adapt[77];
            270: chip_output_data <= u_adapt[78];
            271: chip_output_data <= u_adapt[79];
            272: chip_output_data <= u_adapt[80];
            273: chip_output_data <= u_adapt[81];
            274: chip_output_data <= u_adapt[82];
            275: chip_output_data <= u_adapt[83];
            276: chip_output_data <= u_adapt[84];
            277: chip_output_data <= u_adapt[85];
            278: chip_output_data <= u_adapt[86];
            279: chip_output_data <= u_adapt[87];
            280: chip_output_data <= u_adapt[88];
            281: chip_output_data <= u_adapt[89];
            282: chip_output_data <= u_adapt[90];
            283: chip_output_data <= u_adapt[91];
            284: chip_output_data <= u_adapt[92];
            285: chip_output_data <= u_adapt[93];
            286: chip_output_data <= u_adapt[94];
            287: chip_output_data <= u_adapt[95];

            288: chip_output_data <= u_adapt[96];
            289: chip_output_data <= u_adapt[97];
            290: chip_output_data <= u_adapt[98];
            291: chip_output_data <= u_adapt[99];
            292: chip_output_data <= u_adapt[100];
            293: chip_output_data <= u_adapt[101];
            294: chip_output_data <= u_adapt[102];
            295: chip_output_data <= u_adapt[103];
            296: chip_output_data <= u_adapt[104];
            297: chip_output_data <= u_adapt[105];
            298: chip_output_data <= u_adapt[106];
            299: chip_output_data <= u_adapt[107];
            300: chip_output_data <= u_adapt[108];
            301: chip_output_data <= u_adapt[109];
            302: chip_output_data <= u_adapt[110];
            303: chip_output_data <= u_adapt[111];
            304: chip_output_data <= u_adapt[112];
            305: chip_output_data <= u_adapt[113];
            306: chip_output_data <= u_adapt[114];
            307: chip_output_data <= u_adapt[115];
            308: chip_output_data <= u_adapt[116];
            309: chip_output_data <= u_adapt[117];
            310: chip_output_data <= u_adapt[118];
            311: chip_output_data <= u_adapt[119];
            312: chip_output_data <= u_adapt[120];
            313: chip_output_data <= u_adapt[121];
            314: chip_output_data <= u_adapt[122];
            315: chip_output_data <= u_adapt[123];
            316: chip_output_data <= u_adapt[124];
            317: chip_output_data <= u_adapt[125];
            318: chip_output_data <= u_adapt[126];
            319: chip_output_data <= u_adapt[127];

            320: chip_output_data <= u_adapt[128];
            321: chip_output_data <= u_adapt[129];
            322: chip_output_data <= u_adapt[130];
            323: chip_output_data <= u_adapt[131];
            324: chip_output_data <= u_adapt[132];
            325: chip_output_data <= u_adapt[133];
            326: chip_output_data <= u_adapt[134];
            327: chip_output_data <= u_adapt[135];
            328: chip_output_data <= u_adapt[136];
            329: chip_output_data <= u_adapt[137];
            330: chip_output_data <= u_adapt[138];
            331: chip_output_data <= u_adapt[139];
            332: chip_output_data <= u_adapt[140];
            333: chip_output_data <= u_adapt[141];
            334: chip_output_data <= u_adapt[142];
            335: chip_output_data <= u_adapt[143];
            336: chip_output_data <= u_adapt[144];
            337: chip_output_data <= u_adapt[145];
            338: chip_output_data <= u_adapt[146];
            339: chip_output_data <= u_adapt[147];
            340: chip_output_data <= u_adapt[148];
            341: chip_output_data <= u_adapt[149];
            342: chip_output_data <= u_adapt[150];
            343: chip_output_data <= u_adapt[151];
            344: chip_output_data <= u_adapt[152];
            345: chip_output_data <= u_adapt[153];
            346: chip_output_data <= u_adapt[154];
            347: chip_output_data <= u_adapt[155];
            348: chip_output_data <= u_adapt[156];
            349: chip_output_data <= u_adapt[157];
            350: chip_output_data <= u_adapt[158];
            351: chip_output_data <= u_adapt[159];

            default:
                begin
                    chip_output_data <= 0;
                end
        endcase
    end


/**************************************
        for check
**************************************/


/**************************************
        Instance
**************************************/
    // Instance of SNN_Processing_Core 
    SNN_Processing_Core u_SNN_Processing_Core(
        .clk               ( clk               ),
        .rst               ( rst               ),
        .start_snn_compute ( start_snn_compute ),
        .training_signal_1 ( training_signal_1 ),
        .training_signal_2 ( training_signal_2 ),
        .training_signal_3 ( training_signal_3 ),
        .training_signal_4 ( training_signal_4 ),
        .training_signal_5 ( training_signal_5 ),
        .sram_initial_mode ( sram_initial_mode ),
        .input_value_snn   ( input_value_snn   ),
        .input_address_snn ( input_address_snn ),
        .snn_output_valid  ( snn_output_valid  ),
        .u_adapt           ( u_adapt           )
        //.SNN_ip_error      ( SNN_ip_error      )
    );

    // Instance of OSC
    OSC u_OSC(
        .rstn           ( rst            ),
        .clk            ( clk            ),
        .parameter_Kv           ( parameter_Kv           ),
        .parameter_lamb           ( parameter_lamb           ),
        .parameter_scale_xyz(parameter_scale_xyz),
        .step0          ( step0          ),
        .dq_1           ( dq_1           ),
        .dq_2           ( dq_2           ),
        .dq_3           ( dq_3           ),
        .dq_4           ( dq_4           ),
        .dq_5           ( dq_5           ),
        .dq_6           ( dq_6           ),
        .target_1       ( target_1       ),
        .target_2       ( target_2       ),
        .target_3       ( target_3       ),
        .EE_position_1  ( EE_position_1  ),
        .EE_position_2  ( EE_position_2  ),
        .EE_position_3  ( EE_position_3  ),
        .J_1_1          ( J_1_1          ),
        .J_2_1          ( J_2_1          ),
        .J_3_1          ( J_3_1          ),
        .J_1_2          ( J_1_2          ),
        .J_2_2          ( J_2_2          ),
        .J_3_2          ( J_3_2          ),
        .J_1_3          ( J_1_3          ),
        .J_2_3          ( J_2_3          ),
        .J_3_3          ( J_3_3          ),
        .J_1_4          ( J_1_4          ),
        .J_2_4          ( J_2_4          ),
        .J_3_4          ( J_3_4          ),
        .J_1_5          ( J_1_5          ),
        .J_2_5          ( J_2_5          ),
        .J_3_5          ( J_3_5          ),
        .J_1_6          ( J_1_6          ),
        .J_2_6          ( J_2_6          ),
        .J_3_6          ( J_3_6          ),
        .M_1_1          ( M_1_1          ),
        .M_2_1          ( M_2_1          ),
        .M_3_1          ( M_3_1          ),
        .M_4_1          ( M_4_1          ),
        .M_5_1          ( M_5_1          ),
        .M_6_1          ( M_6_1          ),
        .M_1_2          ( M_1_2          ),
        .M_2_2          ( M_2_2          ),
        .M_3_2          ( M_3_2          ),
        .M_4_2          ( M_4_2          ),
        .M_5_2          ( M_5_2          ),
        .M_6_2          ( M_6_2          ),
        .M_1_3          ( M_1_3          ),
        .M_2_3          ( M_2_3          ),
        .M_3_3          ( M_3_3          ),
        .M_4_3          ( M_4_3          ),
        .M_5_3          ( M_5_3          ),
        .M_6_3          ( M_6_3          ),
        .M_1_4          ( M_1_4          ),
        .M_2_4          ( M_2_4          ),
        .M_3_4          ( M_3_4          ),
        .M_4_4          ( M_4_4          ),
        .M_5_4          ( M_5_4          ),
        .M_6_4          ( M_6_4          ),
        .M_1_5          ( M_1_5          ),
        .M_2_5          ( M_2_5          ),
        .M_3_5          ( M_3_5          ),
        .M_4_5          ( M_4_5          ),
        .M_5_5          ( M_5_5          ),
        .M_6_5          ( M_6_5          ),
        .M_1_6          ( M_1_6          ),
        .M_2_6          ( M_2_6          ),
        .M_3_6          ( M_3_6          ),
        .M_4_6          ( M_4_6          ),
        .M_5_6          ( M_5_6          ),
        .M_6_6          ( M_6_6          ),
        .Mx_1_1         ( Mx_1_1         ),
        .Mx_1_2         ( Mx_1_2         ),
        .Mx_1_3         ( Mx_1_3         ),
        .Mx_2_1         ( Mx_2_1         ),
        .Mx_2_2         ( Mx_2_2         ),
        .Mx_2_3         ( Mx_2_3         ),
        .Mx_3_1         ( Mx_3_1         ),
        .Mx_3_2         ( Mx_3_2         ),
        .Mx_3_3         ( Mx_3_3         ),
        .gravity_bias_1 ( gravity_bias_1 ),
        .gravity_bias_2 ( gravity_bias_2 ),
        .gravity_bias_3 ( gravity_bias_3 ),
        .gravity_bias_4 ( gravity_bias_4 ),
        .gravity_bias_5 ( gravity_bias_5 ),
        .gravity_bias_6 ( gravity_bias_6 ),
        .u_1            ( u_1            ),
        .u_2            ( u_2            ),
        .u_3            ( u_3            ),
        .u_4            ( u_4            ),
        .u_5            ( u_5            ),
        .u_6            ( u_6            ),
        .valid          ( output_valid_osc          )
);
     
    
    uart_bytes_rx #(
	.BYTES				(BYTES				),
	.BPS				(BPS				),		
	.CLK_FRE			(CLK_FRE			)		
)			
    uart_bytes_rx_inst(			
	.clk			    (clk			),			
	.rstn			    (rstn			),
		
	.uart_bytes_data	(data_input	),			
	.uart_bytes_vld		(uart_bytes_vld		),
	
	.uart_rxd			(uart_rxd			)	
);




endmodule