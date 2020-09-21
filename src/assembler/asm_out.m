:- module asm_out.
:- interface.
:- import_module int, list, pair, integer, asm, config_asm, prettyprint.

:- type asm_out == list(pair(int,integer)).

:- pred asm_to_out(config::in, asm::in, asm_out::out) is det.
:- pred print_out(config::in, asm_out::in, pr_state::in, pr_state::out) is det.
:- pred sort_out(asm_out::in, asm_out::out) is det.
:- pred pack(int::in,int::in,asm_out::in, asm_out::out) is det.

:- implementation.
:- import_module string,exception.

asm_to_out(_,[],[]).
asm_to_out(Conf,[_-label(_)|T],Res) :- asm_to_out(Conf,T,Res).
asm_to_out(Conf,[A-i(_,_,D,_)|T],[A-D|Res]) :- asm_to_out(Conf,T,Res).

print_out(Config,Code) --> print_with_pred_sep(newline,pred(X::in,Y::in,Z::out) is det :- print_outval(Config,X,Y,Z),Code),newline.

:- pred print_outval(config::in, pair(int,integer)::in, pr_state::in, pr_state::out) is det.
print_outval(Config,Addr-Instr) --> pN(pad_left(int_to_base_string(Addr,16),'0',(Config^model^pc_width+3)>>2)++":"),write_integer((Config^model^instruction_width+3)>>2,16,Instr).

sort_out(X,Y) :- list.sort(X,Y).

pack(Sofar,Max,[],Asm) :- (Sofar>=Max -> Asm=[] ; pack(Sofar+1,Max,[],A),Asm=[Sofar-zero|A]).
pack(Sofar,Max,X@[Addr-D|T],Asm) :-
	( Addr<Sofar -> throw("Pack: instruction stream out of order")
	; Addr=Sofar -> pack(Sofar+1,Max,T,A),Asm=[Addr-D|A]
	; pack(Sofar+1,Max,X,A),Asm=[Sofar-zero|A]).