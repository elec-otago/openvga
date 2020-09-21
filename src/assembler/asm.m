:- module asm.
:- interface.
:- import_module int, list, string, integer, prettyprint, pair,config_asm, atoken.

:- type asm == list(extended_instruction).

:- type extended_instruction == pair(int,instruction).

:- type instruction ---> label(string) ; i(int, integer, integer, list(token_list)).

:- pred print_program(config::in, asm::in, pr_state::in, pr_state::out) is det.
%:- pred number_lines(config::in, asm::in, asm::out, int::in, map(string,int)::in, map(string,int)::out) is det.
%:- pred encode(config::in, asm::in, asm::out, map(string,int)::in) is det.
:- pred write_integer(int::in,int::in,integer::in, pr_state::in, pr_state::out) is det.
:- pred increment(config::in, int::in, int::out) is det.

:- implementation.
:- import_module exception.

%-----------------------------------------------------------------------------%

print_program(Config,Code) --> print_with_pred_sep(newline,pred(X::in,Y::in,Z::out) is det :- print_instruction(Config,X,Y,Z),Code),newline.

:- pred print_instruction(config::in, extended_instruction::in, pr_state::in, pr_state::out) is det.
print_instruction(Config,Addr-Instr) -->
	pN(pad_left(int_to_base_string(Addr,16),'0',max((Config^model^pc_width+3)>>2,4))++": "),
	print_instr(Config,Instr).

:- pred print_instr(config::in,instruction::in, pr_state::in, pr_state::out) is det.
print_instr(_,label(Label)) --> pN(Label++":").
print_instr(Config,i(_,Mask,Word,Bundle)) -->
	write_integer((Config^model^instruction_width+3)>>2,16,Mask),
	pN(" "),
	write_integer((Config^model^instruction_width+3)>>2,16,Word),
	write_blocks(Config^bit_breaks,2,Word),
	pN(" "),
	{map((pred(X::in,Y::out) is det :- map(token_pair_to_string,X,XX),Y=join_list("",XX)),Bundle,S)},
	pS(join_list(",",S)).

:- pred write_blocks(list(int)::in,int::in,integer::in, pr_state::in, pr_state::out) is det.
write_blocks(Breaks,Base,Word,!S) :-
	(Breaks=[X,Y|Rest],pN(" ",!S),write_integer(X-Y,Base,(Word>>Y)/\((one<<(X-Y))-one),!S),write_blocks([Y|Rest],Base,Word,!S)
	; Breaks=[_X] ; Breaks=[]).

%  :- pred print_src(src::in, pr_state::in, pr_state::out) is det.
%  print_src(i(Imm)) --> print_imm(Imm).
%  print_src(r(Reg)) --> print_reg(Reg).
%  
%  :- pred print_imm(imm::in, pr_state::in, pr_state::out) is det.
%  print_imm(ii(Imm,Min,Max)) --> print_imm(Imm),pN("["),pN(int_to_string(Max)),pN(":"),pN(int_to_string(Min)),pN("]").
%  print_imm(label(Label)) --> pN(Label).
%  print_imm(const(Int)) --> pN("0x"),write_integer(1,16,Int).
%  
%  :- pred print_reg(reg::in, pr_state::in, pr_state::out) is det.
%  print_reg(rr(I,no)) --> pN("r"),pN(int_to_string(I)).
%  print_reg(rr(I,yes(Name))) --> pN("r"),pN(int_to_string(I)),pN("("),pN(Name),pN(")").

write_integer(Min,Base,X,!S) :-
	(X=zero -> pN(pad_left("",'0',Min),!S) ; write_integer(Min-1,Base,X // integer(Base),!S),pN(int_to_base_string(int(X rem integer(Base)),Base),!S)).

%-----------------------------------------------------------------------------%

%  number_lines(_Config,[],[],_,L,L).
%  number_lines(Config,[H1|T1],[H2|T2],Line,LabelsIn,LabelsOut) :-
%  	( H1=_-label(Label) -> (insert(LabelsIn,Label,Line,L1) -> NewLine=Line,L2=L1,H2=Line-label(Label) ; throw("Duplicate label: " ++ Label))
%  	; H1=_-Instr,increment(Config,Line,NewLine),L2=LabelsIn,H2=Line-Instr),
%  	number_lines(Config,T1,T2,NewLine,L2,LabelsOut).

increment(Config,X,Y) :-
	( Config^model^pc_type=base2(Sz), Y=(X+1)/\((1<<Sz)-1)
	; Config^model^pc_type=mfsr(Sz,Xors) , do_xors(Sz, X,((X<<1)/\((1<<Sz)-1))+(X>>(Sz-1)),Xors,Y)
	; Config^model^pc_type=mfsr_base2_hybrid(Sz,BinSz,Xors),
		XX=(X+1)/\((1<<BinSz)-1),
		YY=X>>BinSz,
		(XX=0 -> do_xors(Sz-BinSz, YY, ((YY<<1)/\((1<<(Sz-BinSz))-1))+(YY>>(Sz-BinSz-1)),Xors,YY2) ; YY2=YY),
		Y=XX+(YY2<<BinSz)).

:- pred do_xors(int::in, int::in, int::in, list(pair(int,int))::in, int::out).
do_xors(_,_,Y,[],Y).
do_xors(Sz,X,Y,[T-F|Rest],Yout) :- NewY=Y/\(((1<<Sz)-1)-(1<<(T+1)))+ ((xor(X>>T,X>>F)/\1) <<(T+1)), do_xors(Sz,X,NewY,Rest,Yout).

%-----------------------------------------------------------------------------%

%  encode(_,[],[],_).
%  encode(Config,[H1|T1],[H2|T2],Labels) :-
%  	( H1=A-label(Label),H2=A-label(Label)
%  	; H1=A-i(II,Bundle),H2=A-i(II,Bundle)),
%  	encode(Config,T1,T2,Labels).

%  :- pred decode_imm(map(string,int)::in,imm::in,integer::out).
%  decode_imm(Labels,ii(Imm,Min,Max),I) :- decode_imm(Labels,Imm,T),I=(T>>Min)/\((one<<(Max+1-Min))-one).
%  decode_imm(_Labels,const(I),I).
%  decode_imm(Labels,label(L),I) :- (search(Labels,L,II) -> I=integer(II) ; throw("Label not found: " ++ L)).

		