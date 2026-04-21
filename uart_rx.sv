

module uart_rx (
    input clk,
    input rx,
    output reg rx_ready,
    output reg [7:0] rx_data
);

parameter SRC_FREQ = 76800;
parameter BAUDRATE = 9600;

// STATES: State of the state machine
localparam DATA_BITS = 8;
localparam 
    INIT = 0, 
    IDLE = 1,
    RX_DATA = 2,
    STOP = 3;

// CLOCK MULTIPLIER: Instantiate the clock multiplier

wire out_clk; 

clock_mul #(.SRC_FREQ(SRC_FREQ), .OUT_FREQ(BAUDRATE)) clock_mul_inst(
    .src_clk(clk), 
    .out_clk(out_clk)

);



// internal vars
    // current bits [0-7]
    reg [7:0] bit_storage;

    // track bits [0-7]
    reg [2:0] current_bit_index;

    // state tracks which state we're in 
    integer state = INIT;

    // use as flag 
    reg done = 0;


// CROSS CLOCK DOMAIN: The rx_ready flag should only be set 1 one for one source 
// clock cycle. Use the cross clock domain technique discussed in class to handle this.

// detect when out_clk rises and pulse rx_ready for 1 clk cycle 
reg prev_rx_clk = 0; 
always @(posedge clk) begin
    prev_rx_clk <= out_clk; 

    // use done as a flag to show i finished a byte 
    if (out_clk && !prev_rx_clk && done == 1) begin
        rx_ready <= 1;
        done <= 0;
    end else begin
        rx_ready <= 0;
    end
    
    
end

// STATE MACHINE: Use the UART clock to drive that state machine that receves a byte from the rx signal


    always @(posedge out_clk) begin
        case (state)
            
            INIT: begin
                current_bit_index <= 0; 
                bit_storage <= 0; 
                state <= IDLE; 
            end


            
            IDLE: begin
                // if start bit detected, trggier trans in idle state
                if (rx == 0) begin
                    current_bit_index <= 0; 
                    state <= RX_DATA;
                end 
            end

            
            RX_DATA: begin
                // wait 1 full bit time 
                bit_storage[current_bit_index] <= rx; 
                current_bit_index <= current_bit_index + 1; 
                if (current_bit_index == 7) begin
                    state <= STOP;
                end
            end

            STOP: begin
                // wait 1 bit time smple rx=high
                if (rx == 1) begin // check if stop bit is valid 
                    rx_data <= bit_storage;    
                    done <= 1;  
                end
                state <= IDLE;
                
            end

            default: state <= INIT;
        endcase
    end

endmodule