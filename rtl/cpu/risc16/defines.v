//---------------------------------------------------------------------------
// Optional configuration settings:
//
// Allow MSRs to be read as well as written.
// TODO: This is still a little slow and incomplete.
// `define __use_readable_MSR
//
// Explicitly instantiate a Xilinx BRAM for simulation and synthesis?
// This is needed to load the BRAM with initial values.
`define __use_bram
//
//---------------------------------------------------------------------------

// OPs
`define	RR	3'b000
`define	RI	3'b001
`define	SUBI	3'b010
`define	_free0_	3'b011
`define	LW	3'b100
`define	SW	3'b101
`define	BX	3'b110
`define	I12	3'b111

// FNs
`define	SUB	3'b000
`define	SBB	3'b001
`define	MUL	3'b010
`define	MSR	3'b011
`define	AND	3'b100
`define	BR	3'b101
`define	OR	3'b110
`define	XOR	3'b111

// CNDs
`define	JNE	3'b000
`define	JE	3'b001
`define	JL	3'b010
`define	JG	3'b011
`define	JB	3'b100
`define	JBE	3'b101
`define	JA	3'b110
`define	JAE	3'b111

`define	NF	1'b0
`define	SF	1'b1
`define	NC	1'b0
`define	CR	1'b1
`define	R0	4'h0
`define	R1	4'h1
`define	R2	4'h2
`define	R3	4'h3
`define	R4	4'h4
`define	R5	4'h5
`define	R6	4'h6
`define	R7	4'h7
`define	R8	4'h8
`define	R9	4'h9
`define	RA	4'ha
`define	RB	4'hb
`define	RC	4'hc
`define	RD	4'hd
`define	RE	4'he
`define	RF	4'hf
`define	ZERO	4'h0
`define	ONE	4'h1
`define	ONE_	4'hf
