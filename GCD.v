//Always do it in this form , so that it will not create unnecessary confusion inside the circuit and this 
// would eliminate the confusion and occurs step by step. 
// And also declare the default values so that it will not create unnecessary latches.

module GCD_datapath (gt , lt , eq , ldA , ldB , sel1 , sel2 , sel_in , data_in , clk);
input ldA , ldB , sel1 , sel2 , sel_in , clk;
input [15:0] data_in;
output gt , lt , eq;
wire [15:0] Aout , Bout , X ,Y , Bus , SubOut;

PIPO A (Aout , Bus , ldA , clk);
PIPO B (Bout , Bus , ldB , clk);
MUX MUX_in1 (X , Aout , Bout , sel1);
MUX MUX_in2 (Y , Aout , Bout , sel2);
MUX MUX_load (Bus , SubOut , data_in , sel_in);
SUB SB (SubOut , X , Y);
COMPARE COMP (lt , gt , eq , Aout , Bout);
endmodule 

module PIPO (data_out , data_in , load , clk);
input [15:0] data_in;
input load , clk;
output reg [15:0] data_out;

always @(posedge clk)
if (load) data_out <= data_in;
endmodule

module SUB (out , in1 , in2);
input [15:0] in1 , in2;
output reg [15:0] out;

always @(*)
out = in1 - in2;
endmodule

module COMPARE (lt , gt , eq , data1 , data2);
input [15:0] data1 , data2;
output lt , gt , eq;

assign lt = data1 < data2;
assign gt = data1 > data2;
assign eq = data1 == data2;
endmodule

module MUX (out , in0 , in1 , sel);
input [15:0] in0 , in1;
input sel;
output [15:0] out;

assign out = sel ? in1 : in0;
endmodule

//Now control input

module controller (
    ldA, ldB, sel1, sel2, sel_in, done,
    clk, reset, lt, gt, eq, start
);

input clk, reset, lt, gt, eq, start;
output reg ldA, ldB, sel1, sel2, sel_in, done;

reg [2:0] state, next_state;

// State encoding
parameter s0 = 3'b000,
          s1 = 3'b001,
          s2 = 3'b010,
          s3 = 3'b011,
          s4 = 3'b100,
          s5 = 3'b101;

// STATE REGISTER
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= s0;
    else
        state <= next_state;
end


// NEXT STATE LOGIC

always @(*) begin
    case (state)
        s0: if (start) next_state = s1;
            else next_state = s0;

        s1: next_state = s2;

        s2: if (eq) next_state = s5;
            else if (lt) next_state = s3;
            else if (gt) next_state = s4;
            else next_state = s2;

        s3: if (eq) next_state = s5;
            else if (lt) next_state = s3;
            else if (gt) next_state = s4;
            else next_state = s3;

        s4: if (eq) next_state = s5;
            else if (lt) next_state = s3;
            else if (gt) next_state = s4;
            else next_state = s4;

        s5: next_state = s5;

        default: next_state = s0;
    endcase
end

// OUTPUT LOGIC
always @(*) begin
    // Default values (to avoid latches)
    ldA = 0; ldB = 0;
    sel1 = 0; sel2 = 0;
    sel_in = 0;
    done = 0;

    case (state)
        s0: begin
            sel_in = 1;
            ldA = 1;
        end

        s1: begin
            sel_in = 1;
            ldB = 1;
        end

        s2, s3, s4: begin
            if (eq) begin
                done = 1;
            end
            else if (lt) begin
                sel1 = 1;
                sel2 = 0;
                ldB = 1;
            end
            else if (gt) begin
                sel1 = 0;
                sel2 = 1;
                ldA = 1;
            end
        end

        s5: begin
            done = 1;
        end
    endcase
end

endmodule