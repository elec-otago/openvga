`timescale 1ns/100ps
module RAMB36_tb;

reg	clock	= 1;
always	#5	clock	<= ~clock;

reg	clockb	= 1;
always	#10 clockb	<= ~clockb;

reg	reset	= 0;

reg	[3:0]	writes	= 0;
reg	[15:0]	addr	= 0;
reg	[35:0]	data_to	= 0;

wire	[35:0]	data_from;


// Port B signals.
reg	[3:0]	webs	= 0;
reg	[17:0]	datab;
reg	[10:0]	addrb	= 0;
wire	[31:0]	dob_36;
wire	[3:0]	dopb_4;



initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#5
	reset	<= 1;
	
	#20
	reset	<= 0;
	
	#20
	webs	<= 4'b1111;
	addrb	<= 11'h001;
	datab	<= 18'h3_7F2A;
	
	#20
	webs	<= 4'b0;
	
	#60
	$finish;
end	// Sim



RAMB36 #(
 .DOA_REG	(1),  // Optional output registers on A port (0 or 1)
 .DOB_REG	(0),  // Optional output registers on B port (0 or 1)
 .INIT_A	(36'h000000000),  // Initial values on A output port
 .INIT_B	(36'h000000000),  // Initial values on B output port
 .RAM_EXTENSION_A("NONE"),  // "UPPER", "LOWER" or "NONE" when
 .RAM_EXTENSION_B("NONE"),  // cascaded
 .READ_WIDTH_A	(36),  // Valid values are 1, 2, 4, 9, 18, or 36
 .READ_WIDTH_B	(18),  // Valid values are 1, 2, 4, 9, 18, or 36
 .SIM_COLLISION_CHECK("ALL"),  // Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE".
 .SRVAL_A	(36'h000000000), // Set/Reset value for A port output
 .SRVAL_B	(36'h000000000),  // Set/Reset value for B port output
 .WRITE_MODE_A	("WRITE_FIRST"),  // "WRITE_FIRST", "READ_FIRST", or
 .WRITE_MODE_B	("WRITE_FIRST"),  // "NO_CHANGE"
 .WRITE_WIDTH_A	(0),  // Valid values are 1, 2, 4, 9, 18, or 36
 .WRITE_WIDTH_B	(18),  // Valid values are 1, 2, 4, 9, 18, or 36

// The following INIT_xx declarations specify the initial contents of the RAM
 .INIT_00(256'h000000000000000000000000000000000000000000000000000000000000F030),
 .INIT_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_10(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_11(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_12(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_13(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_14(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_15(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_16(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_17(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_18(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_19(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_1A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_1B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_1C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_1D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_1E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_1F(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_20(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_21(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_22(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_23(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_24(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_25(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_26(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_27(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_28(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_29(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_2A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_2B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_2C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_2D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_2E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_2F(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_30(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_31(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_32(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_33(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_34(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_35(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_36(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_37(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_38(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_39(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_3A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_3B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_3C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_3D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_3E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_3F(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_40(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_41(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_42(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_43(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_44(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_45(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_46(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_47(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_48(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_49(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_4A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_4B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_4C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_4D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_4E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_4F(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_50(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_51(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_52(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_53(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_54(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_55(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_56(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_57(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_58(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_59(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_5A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_5B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_5C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_5D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_5E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_5F(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_60(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_61(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_62(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_63(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_64(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_65(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_66(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_67(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_68(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_69(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_6A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_6B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_6C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_6D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_6E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_6F(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_70(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_71(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_72(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_73(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_74(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_75(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_76(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_77(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_78(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_79(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_7A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_7B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_7C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_7D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_7E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INIT_7F(256'h0000000000000000000000000000000000000000000000000000000000000000),

// The next set of INITP_xx are for the parity bits
 .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000009),
 .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
 .INITP_0F(256'h0000000000000000000000000000000000000000000000000000000000000000)
) TESTRAM0 (
	.CLKA	(clock),	// 1-bit A port clock input
	.SSRA	(reset),	// 1-bit A port set/reset input
	
	.ENA	(1'b1),		// 1-bit A port enable input
	.WEA	(writes),	// 4-bit A port write enable input
	.REGCEA	(1'b1),		// 1-bit A port register enable input
	.ADDRA	(addr),		// 16-bit A port address input
	
	.DIA	(data_to [31:0]),	// 32-bit A port data input
	.DIPA	(data_to [35:32]),	// 4-bit A port parity data input
	.DOA	(data_from [31:0]),	// 32-bit A port data output
	.DOPA	(data_from [35:32]),	// 4-bit A port parity data output
	
	.CLKB	(clockb),     // 1-bit B port clock input
	.SSRB	(reset),     // 1-bit B port set/reset input
	.ENB	(1'b1),       // 1-bit B port enable input
	.WEB	(webs),        // 4-bit B port write enable input
	.REGCEB	(1'b0), // 1-bit B port register enable input
	.ADDRB	({1'b0, addrb, 4'b0}),  // 16-bit B port address input
	.DIB	({16'b0, datab [15:0]}),       // 32-bit B port data input
	.DIPB	({2'b0, datab [17:16]}),     // 4-bit B port parity data input
	.DOB	(dob_36),      // 32-bit B port data output
	.DOPB	(dopb_4),    // 4-bit B port parity data output
	
	.CASCADEINLATA	('b0),
	.CASCADEINLATB	('b0),
	.CASCADEINREGA	('b0),
	.CASCADEINREGB	('b0)
);


endmodule	// RAMB36_tb