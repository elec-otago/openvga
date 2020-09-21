:- module aparse.
:- interface.
:- import_module atoken, io, asm, config_asm.

:- pred parse_program(config::out, string::in, asm::out, io__state::di, io__state::uo, token_list::in, token_list::out) is det.

%-----------------------------------------------------------------------------%
:- implementation.
:- import_module list, int, prettyprint, bool, string, pair, maybe, exception, xml, xml_util, map, integer, assoc_list.
%-----------------------------------------------------------------------------%

:- type instrmap == map(int,pair(integer,integer)).

:- type extended_instruction2 ---> t(int,int,instruction2).

:- type instruction2 ---> label(string) ; i(int, instrmap, list(token_list)).

parse_program(Config,_Name,Program,!S) -->
	ignore_eols,
	([k(arch)-_,colon-_,name(Arch)-_,eol-_] ->
		{get_config(Config,Arch++".xml",!S)},
		ignore_eols,
		parse(Config,Program)
	; {throw("Architecture expected at start of file")}).

:- pred get_config(config::out, string::in, io__state::di, io__state::uo) is det.	% get and parse arch file
get_config(Config,ProcessorFilename,!S) :-
	io.open_input(ProcessorFilename, ProcessorFile,!S),
	( ProcessorFile = ok(PS) -> ProcessorStream=PS ; throw("Error reading Processor file" ++ ProcessorFilename)),
	io.set_input_stream(ProcessorStream,_OldProcessorStream,!S),
	io.read_file(ProcessorSt,!S),
	( ProcessorSt = ok(ProcessorString); ProcessorSt = error(ProcessorString,_Error2)),
	xml_util.parse_charlist(ProcessorXml,ProcessorString),
	xml_to_config(ProcessorXml,Config).

:- pred ignore_eols(token_list::in, token_list::out) is det.
ignore_eols -->
	([eol-_] -> ignore_eols ; []).

:- pred parse(config::in,asm::out,token_list::in,token_list::out) is det.
parse(Config,Aout,!Tokens) :-
	parse_aux(Config,[],Atemp,pc_start(Config^model^pc_type),0,init,Labels,!Tokens),
	map(pred(X::in,Y::out) is det :- encode(Config,Labels,X,Y),Atemp,Aout2),
	foldl(coalesce_addparts,Aout2,init,FinalMap),
	coalesce_instructions(FinalMap,Aout2,Aout).

:- pred coalesce_instructions(instrmap::in, list(extended_instruction2)::in, list(extended_instruction)::out) is det.
coalesce_instructions(FinalMap, ExtInstr, Instr) :-
	Instr=map(func(X)=coalesce_getbase(FinalMap,X),ExtInstr).

:- func coalesce_getbase(instrmap,extended_instruction2) = extended_instruction is det.
coalesce_getbase(_,t(_,I,label(S))) = I-label(S).
coalesce_getbase(M,t(Ln,I,i(N,_,T))) = I-i(N,Mask,Inst,T) :- (search(M,Ln,V) -> V=Mask-Inst ; Mask=zero,Inst=zero).

:- pred coalesce_addparts(extended_instruction2::in,instrmap::in,instrmap::out) is det.
coalesce_addparts(t(_,_,label(_)),X,X).
coalesce_addparts(t(N,_,i(Ln,Map,_)),X,Y) :-
	foldl(pred(K::in,V::in,M1::in,M2::out) is det :- M2=mask_instr_join_aux(Ln,0,M1,[pair(K+N,V)]),Map,X,Y).

:- func pc_start(pc_type) = int.
pc_start(base2(_)) = 0.
pc_start(mfsr(_,_)) = 1.
pc_start(mfsr_base2_hybrid(_,N,_)) = 1<<N.

:- pred encode(config::in,map(string,int)::in,extended_instruction2::in,extended_instruction2::out) is det.
encode(_Config,_Labels,t(Ln,Addr,label(L)),t(Ln,Addr,label(L))).
encode(Config,Labels,t(Ln,Addr,i(SrcLine,_,Bundles)),t(Ln,Addr,i(SrcLine,Instr,Bundles))) :-
%	parse_instr(Config,Labels,map_corresponding(pair,Bundles,map(func(XX)=XX^iselect,Config^instructions)),SrcLine,_,1,_,zero,_,zero,Instr).
	foldl3(pred(X0::in,X1::in,X2::out,X3::in,X4::out,X5::in,X6::out) is det :- parse_instr(Config,Labels,X0,X1,X2,X3,X4,X5,X6),
		map_corresponding(pair,Bundles,map(func(XX)=XX^iselect,Config^instructions)),SrcLine,_,1,_,init,Instr).

:- pred parse_aux(config::in,list(extended_instruction2)::in,list(extended_instruction2)::out,
		int::in,int::in,map(string,int)::in,map(string,int)::out,token_list::in,token_list::out) is det.
parse_aux(Config,Pin,Pout,Line,Ln,!Map) --> 
	(	( [name(Label)-_,colon-_] -> {P1=Pin++[t(-1000,Line,label(Label))]},{Line=L2},{Ln=Ln2},{det_insert(!.Map,Label,Line,!:Map)}
		; [open_brace-L] ->
			{Config^pflags=pf(Sep)},
			split_line(Sep,[],Bundles,[]),
			({same_length(Bundles,Config^instructions)} -> [] ; {throw("Wrong number of streams on line "++int_to_string(L))}),
			{P1=Pin++[t(Ln,Line,i(L,init,Bundles))]},
			{increment(Config,Line,L2)},
			{Ln2=Ln+1}
		; [X-L],{token_to_string(X,S)},{throw("Syntax error on line "++int_to_string(L)++"  "++S)}) ->
		ignore_eols,
		parse_aux(Config,P1,Pout,L2,Ln2,!Map)
	; {Pout=Pin}).

:- pred split_line(token::in,list(token_list)::in,list(token_list)::out, token_list::in, token_list::in, token_list::out) is det.
split_line(Sep,Iin,Iout,P) -->
	(	[close_brace-_] -> {Iin++[P]=Iout}
	;	[minus-_,c(integer(I,Name))-L] -> split_line(Sep,Iin,Iout,P++[c(integer(-I,"-"++Name))-L])
	;	[Sep-_] -> split_line(Sep,Iin++[P],Iout,[])
	;	[X-L] -> split_line(Sep,Iin,Iout,P++[X-L])
	;	{throw("Unexpected end of tokens")}).

:- pred parse_instr(config::in,map(string,int)::in,pair(token_list,list(instruction_select))::in,
		int::in,int::out,int::in,int::out,instrmap::in,instrmap::out) is det.
parse_instr(Config,Labels,Toks-Options,!Line,!Stream,!MaskInst) :-
	(	Options=[],
		map(token_pair_to_string,Toks,TokStrings),
		throw("Cannot match instruction "++join_list(",",TokStrings)++" at "++int_to_string(!.Line)++","++int_to_string(!.Stream))
	;	Options=[H|T],
		(Toks=[name(_)-_,colon-_|Rest] -> Toks2=Rest ; Toks=[c(_)-_,colon-_|Rest] -> Toks2=Rest ; Toks2=Toks),
		( parse_instr_try(Config,Labels,Toks2,H,Imaskbits) ->
			!:MaskInst=mask_instr_join(!.Line,!.Stream,!.MaskInst,Imaskbits),
			!.Stream+1 = !:Stream,
			!.Line = !:Line
		; parse_instr(Config,Labels,Toks-T,!Line,!Stream,!MaskInst))).

:- pred parse_instr_try(config::in,map(string,int)::in,token_list::in,list(instruction_part)::in,instrmap::out) is semidet.
% done
parse_instr_try(_,_,[],[],init).
% match token
parse_instr_try(Config,Labels,[Tok-_|Trest],[token(Tok)|Irest],MaskIns) :- parse_instr_try(Config,Labels,Trest,Irest,MaskIns).
% match empty string before token
%  parse_instr_try([Tok-_|Trest],[ip(Bits,Options),token(Tok)|Irest],Mask\/M1,Ins\/I1) :-
%  	parse_option_try(name(""),Bits,Options,M1,I1),parse_instr_try(Trest,Irest,Mask,Ins).
% match empty string at end
parse_instr_try(Config,Labels,[],[ip(Bits,Options)],MI1) :- parse_option_try(Config,Labels,name(""),Bits,Options,MI1).
% match register name or empty string before token
parse_instr_try(Config,Labels,[Tok-_|Trest],[ip(Bits,Options)|Irest],MI2) :-
	(parse_option_try(Config,Labels,Tok,Bits,Options,MI1x) -> MI1=MI1x,parse_instr_try(Config,Labels,Trest,Irest,MaskIns)
	;	Irest=[token(Tok)|Irest2],parse_option_try(Config,Labels,name(""),Bits,Options,MI1),parse_instr_try(Config,Labels,Trest,Irest2,MaskIns)),
	MI2=mask_instr_join(0,0,MaskIns,MI1).
parse_instr_try(Config,Labels,[name(Name)-_|Trest],[tp(Bits,MapName)|Irest],MI2) :-
	_WW-Map=search(Config^token_maps,MapName),V=search(Map,Name),insert_bits(V,Bits,MI1,0),parse_instr_try(Config,Labels,Trest,Irest,MaskIns),
    MI2=mask_instr_join(0,0,MaskIns,MI1).

:- func mask_instr_join(int, int, instrmap, instrmap) = instrmap is det.
% for efficiency, put the big one first
mask_instr_join(L,S,X,Y) = mask_instr_join_aux(L,S,X,to_assoc_list(Y)).

:- func mask_instr_join_aux(int,int,instrmap, assoc_list(int,pair(integer,integer))) = instrmap is det.
% for efficiency, put the big one first
mask_instr_join_aux(_,_,X,[])=X.
mask_instr_join_aux(L,S,X,[K-(M1-I1)|T]) = mask_instr_join_aux(L,S,R,T) :- 
	(search(X,K,M2-I2) -> R=det_update(X,K,MR-IR),mask_instr_ll(L,S,M1,I1,M2,I2,MR,IR) ; R=det_insert(X,K,M1-I1)).

:- pred mask_instr_ll(int::in, int::in, integer::in, integer::in, integer::in, integer::in, integer::out, integer::out) is det.
mask_instr_ll(L,S,M1,I1,M2,I2,MR,IR) :- ((M1/\M2)/\I1=(M1/\M2)/\I2 -> MR=M1\/M2,IR=(I1/\M1)\/(I2/\M2) ; throw("Opcode conflict at "++
	int_to_string(L)++","++int_to_string(S)++" :M1="++to_string(M1)++" I1="++to_string(I1)++" M2="++to_string(M2)++" I2="++to_string(I2))).

:- pred parse_option_try(config::in,map(string,int)::in,token::in,bit_range::in,list(mux_select)::in,instrmap::out) is semidet.
parse_option_try(Config,Labels,Name,BitRange,[H|T],MI) :-
	(Name=name(Id),H=ms(V,o(Id)) -> insert_bits(V,BitRange,MI,0)
	;	Name=name(Id),H=ms(V,reg(label,[File])) -> insert_bits(V,BitRange,MI1,0),
		(search(Labels,Id,L2) -> integer(L2)=L ; throw("Label not found: " ++ Id)),
		lookup(Config^regs,File)=r(_Min,Max,BitRange2,_,Offset),zero=<L,L=<Max,insert_bits(L,BitRange2,MI2,Offset),
		MI=mask_instr_join(0,0,MI1,MI2)
	;	Name=c(integer(L,_IntName)),H=ms(V,reg(immediate,[File])) -> insert_bits(V,BitRange,MI1,0),
		lookup(Config^regs,File)=r(Min,Max,BitRange2,_,Offset),
			(	zero=<L,L=<Max->insert_bits(L,BitRange2,MI2,Offset)
			;	Min=<L,L<zero->Pow=pow(integer(2),integer(width(BitRange2))),insert_bits(L+Pow,BitRange2,MI2,Offset)
			;	fail),
		MI=mask_instr_join(0,0,MI1,MI2)
	;	Name=k(reg(C,N)),H=ms(V,reg(register(C),[File])) -> insert_bits(V,BitRange,MI1,0),
		Ni=integer(N),
		lookup(Config^regs,File)=r(_Min,Max,BitRange2,_,Offset),zero=<Ni,Ni=<Max,insert_bits(integer(N),BitRange2,MI2,Offset),
		MI=mask_instr_join(0,0,MI1,MI2)
	;	parse_option_try(Config,Labels,Name,BitRange,T,MI)).

:- func width(bit_range)=int.
width(rr(Num,_)) = Num.
width(rlist(L)) = length(L).

:- pred insert_bits(integer::in,bit_range::in,instrmap::out,int::in) is det.
insert_bits(V,rr(Num,Offset),MI,Offset1) :-
	(V < one<<Num -> true ; throw("Value way too large")),
	I=V<<Offset,
	M=((one<<Num)-one)<<Offset,
	MI=det_insert(init,Offset1,M-I).
insert_bits(V,rlist(Bits),MI,Offset1) :-
	insert_bitlist(bitsplit(length(Bits),V),Bits,I),
	insert_bitlist(duplicate(length(Bits),one),Bits,M),
	MI=det_insert(init,Offset1,M-I).

:- func bitsplit(int,integer)=list(integer).
bitsplit(N,V)=L :-
	(	N=0 -> L=[]
	;	N<0 -> throw("Internal error in bitsplit")
	;	L=[(V /\ one) | bitsplit(N-1,V>>1)]).

:- pred insert_bitlist(list(integer)::in,list(int)::in,integer::out) is det.
insert_bitlist(Vlist,Bits,V) :-
	foldl_corresponding((pred(VV::in,Offset::in,X::in,Y::out) is det :- Y=X \/ (VV<<Offset)), Vlist, Bits, zero, V).

%  :- pred check_imm(config::in,src::in,reg::in,int::in) is det.
%  check_imm(Conf,Src,rr(R,_),L) :-
%  	(member(R,Conf^regs^imm) ->
%  		(Src=i(_) -> true ; throw("Illegal immediate source on line "++int_to_string(L)))
%  	;	(Src=r(_) -> true ; throw("Illegal register source on line "++int_to_string(L)))).

%  :- pred parse_dst(config::in,reg::out,token_list::in, token_list::out) is det.
%  parse_dst(Config,Reg) -->
%  	( [k(reg(R))-_],{R=<Config^regs^dest_range^max} -> {Reg=rr(R,no)}
%  	; [name(Name)-L] -> ({search(Config^regs^dst,Name,R)} -> {Reg=rr(R,yes(Name))} ; {throw("Unknown register: " ++ Name ++ " on line "++int_to_string(L))})
%  	; [_-L] -> {throw("Unknown dest register on line "++int_to_string(L))}
%  	; {throw("Unexpected end of file")}).
%  
%  :- pred parse_src(config::in,src::out,token_list::in,token_list::out) is det.
%  parse_src(Config,Reg) -->
%  	( [k(reg(R))-_],{R=<Config^regs^source_range^max} -> {Reg=r(rr(R,no))}
%  	; [name(Name)-_] -> ({search(Config^regs^src,Name,R)} -> {Reg=r(rr(R,yes(Name)))} ; do_dot(Config,label(Name),Reg))
%  	; [c(integer(I,_))-_] -> do_dot(Config,const(I),Reg)
%  	; [_-L] -> {throw("Unknown dest register on line "++int_to_string(L))}
%  	; {throw("Unexpected end of file")}).
%  
%  :- pred do_dot(config::in,imm::in, src::out,token_list::in,token_list::out) is det.
%  do_dot(Config,Imm0,Src) -->
%  	( [dot-_,name(Suffix)-L] -> ({search(Config^sufficies,Suffix,Min-Max)} -> {Src=i(ii(Imm0,Min,Max))} ; {throw("Unknown Suffix: " ++ Suffix ++ " on line "++int_to_string(L))})
%  	; {Src=i(Imm0)}).
