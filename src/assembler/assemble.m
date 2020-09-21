:- module assemble.
:- interface.
:- import_module io.

:- pred main(io__state::di, io__state::uo) is det.

:- implementation.

:- import_module io, xml, xml_util, exception, string, atoken, aparse, list, asm, prettyprint, map, asm_out, char,config_asm.

main(!S) :-
	% get command line args
	io__command_line_arguments(Args,!S),
	( Args = [SS] -> Sarg=SS; throw("Usage: ./assemble <input>")),
	io.write_string("Reading file\n",!S),
	io.open_input(Sarg, ResultArg,!S),
	( ResultArg = ok(ST) -> Stream=ST ; throw("Error reading input file" ++ Sarg)),
	io.set_input_stream(Stream,_OldStream,!S),
	io.read_file(Contentx,!S),
	( Contentx = ok(Content); Contentx = error(Content,_Error3), throw("Error reading input file" ++ Sarg)),
	io.close_input(Stream,!S),
	io.write_string("Getting tokens\n",!S),
	atoken.get_token_list(Tokens,1,Content,_),
	%list.map(token_pair_to_string,Tokens,S1),
	%io.write_strings(S1,!S),
	io.write_string("Parsing program\n",!S),
	parse_program(Config,Sarg,Program,!S,Tokens,_),
	%number_lines(Config,Program,P2,1,init,Labels),
	%encode(Config,P2,P3,Labels),
	P3=Program,
	io.write_string("Parsed program\n",!S),

	DebugName=rstrip(is_alnum,Sarg)++"debug",
	fromstring(Sti,"",pretty),
	io.write_string("Printing debug file\n",!S),
	print_program(Config,P3,Sti,Sto),
	tostring(Sto,So),
	io.open_output(DebugName, DebugArg,!S),
	( DebugArg = ok(SD) -> DebugStream=SD ; throw("Error writing debug file" ++ DebugName)),
	io.set_output_stream(DebugStream,Old1,!S),
	io.write_string(So,!S),
	io.close_output(DebugStream,!S),
	io.set_output_stream(Old1,_,!S),

	OutName=rstrip(is_alnum,Sarg)++"out",
	asm_to_out(Config,P3,Out1),
	sort_out(Out1,Out2),
	io.write_string("Packing\n",!S),
	pack(0,Config^model^program_output_min_size,Out2,Out3),
	fromstring(Sti2,"",pretty),
	io.write_string("Printing out file\n",!S),
	io.write_string("Printing out 1\n",!S),
	print_out(Config,Out3,Sti2,Sto2),
	io.write_string("Printing out 2\n",!S),
	tostring(Sto2,So2),
	io.open_output(OutName, OutArg,!S),
	( OutArg = ok(SA) -> OutStream=SA ; throw("Error writing debug file" ++ OutName)),
	io.set_output_stream(OutStream,Old2,!S),
	io.write_string(So2,!S),
	io.close_output(OutStream,!S),
	io.set_output_stream(Old2,_,!S),

	io.write_string("Done\n",!S).

