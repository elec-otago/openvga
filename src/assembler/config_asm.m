:- module config_asm.
:- interface.
:- import_module atoken, int, list, string, map, pair, xml, assoc_list, integer,char.

:- type config ---> c(
	pflags :: parse_flags,
	model :: processor_model,
	regs :: map(string,reg_model),
	token_maps :: map(string,pair(int,map(string,integer))),
	instructions :: list(instruction_model),
	bit_breaks :: list(int)).

:- type parse_flags ---> pf(token).

:- type processor_model ---> p(
	data_width::int,
	pc_width::int,
	program_output_min_size::int,
	pc_type::pc_type,
	instruction_width::int).

:- type pc_type ---> base2(int) ; mfsr(int,assoc_list(int,int))
		; mfsr_base2_hybrid(total::int,base2_part::int,assoc_list(int,int)).

:- type reg_model ---> r(
	min::integer,
	max::integer,
	rrange::bit_range,
	id::string,
	ioffset::int).

:- type bit_range ---> rr(bits::int, offset::int) ; rlist(bitrange::list(int)).

:- type instruction_model ---> im(
	name::string,
	iselect::list(instruction_select)).

:- type instruction_select == list(instruction_part).

:- type instruction_part --->
	ip(irange::bit_range, options::list(mux_select)) ;
	tp(trange::bit_range, tname::string) ;
	token(token).

:- type mux_select ---> ms(
	value::integer,
	field::mux_field).

:- type register_type ---> register(char) ; label ; immediate.

:- type mux_field ---> reg(tp::register_type,ext_bit_field::list(string)) ; o(string).

:- pred xml_to_config(xml_t::in, config::out) is det.

:- implementation.
:- import_module exception, bool, xml_util.

:- pred extract_element(element::in,string::in,element::out) is semidet.
:- pred extract_tag(element::in,string::in,string::out) is semidet.
:- func extract_element_det(element,string) = element.
:- func extract_tag_det(element,string) = string.
:- func extract_child_elements(element) = list(element).
:- func extract_header(element) = string.

extract_element(e(T,[C|Rest]),S,Out) :- (C=e(X@e(t(S,_),_)) -> Out=X; extract_element(e(T,Rest),S,Out)).
extract_element_det(E@e(t(T,_),_),S) = X :- (extract_element(E,S,Out) -> Out=X ; throw("Element tag " ++ T ++ " expected to contain " ++ S)).

extract_tag(e(t(_,Tags),_),S,Out) :- search(Tags,S,Out).
extract_tag_det(E@e(t(T,_),_),S) = X :- (extract_tag(E,S,Out) -> Out=X ; throw("Element tag " ++ T ++ " expected to contain " ++ S)).

% version of extract_child_elements that doesn't like content
%extract_child_elements(e(t(Name,_),C)) = Out :- map(pred(X::in,Y::out) is det :- (X=e(Y) ; X=c(T), throw("Illegal content " ++ T ++ " in " ++ Name)),C,Out).
extract_child_elements(e(_,C)) = Out :- foldl(pred(Elt::in,X::in,Y::out) is det :- (Elt=e(T) -> Y=X++[T] ; Y=X), C, [], Out).

extract_header(e(t(T,_),_)) = T.

xml_to_config(xml(_,E),Config) :-
% parse flags
	ParseFlags=extract_element_det(E,"parse_flags"),
	Sep=extract_tag_det(ParseFlags,"separator"),
% processor model
	ProcessorModel=extract_element_det(E,"processor_model"),
	Data_width=string_to_int(extract_tag_det(extract_element_det(ProcessorModel,"data"),"width")),
	I_width=string_to_int(extract_tag_det(extract_element_det(ProcessorModel,"instruction"),"width")),
	PC_Model=extract_element_det(ProcessorModel,"pc"),
	PC_width=string_to_int(extract_tag_det(PC_Model,"width")),
		(extract_tag(PC_Model,"program_output_min_size",Ds) -> DisplaySize=string_to_int(Ds) ; DisplaySize=pow(2,PC_width)),
	Type=extract_tag_det(PC_Model,"type"),
% reg model
	Regs=extract_child_elements(extract_element_det(E,"reg_model")),
% token map model
	TokenMap=extract_child_elements(extract_element_det(E,"token_maps")),
% instruction model
	Instructions=extract_child_elements(extract_element_det(E,"instruction_model")),
	token_from_string(Tok,Sep),
	(Type="base2" -> PcT=base2(PC_width)
	; Type="mfsr" -> PcT=mfsr(PC_width,XorList),map(conv_xor,extract_child_elements(PC_Model),XorList)
	; Type="mfsr_base2_hybrid" ->
		PcT=mfsr_base2_hybrid(PC_width,det_to_int(extract_tag_det(PC_Model,"base2_width")),XorList),
		map(conv_xor,extract_child_elements(PC_Model),XorList)
	; throw("Unknown PC type: " ++ Type ++ ", base2 or mfsr expected")),
	map_foldl(reg_model,Regs,RegList,[0,I_width],BitBreak1),
	map_foldl(instruction,Instructions,InstructionList,BitBreak1,BitBreak2),
	map(get_token_map,TokenMap,TokenMap_assoc),det_insert_from_assoc_list(init,TokenMap_assoc,TokenMap_list),
	Config=c(pf(Tok),p(Data_width,PC_width,DisplaySize,PcT,I_width),
		set_from_assoc_list(init,RegList),
		TokenMap_list,
		InstructionList,
		reverse(BitBreak2)).

:- pred reg_model(element::in,pair(string,reg_model)::out,list(int)::in,list(int)::out) is det.
reg_model(X,Y,!BitBreaks) :-
	Id=extract_tag_det(X,"id"),
	bitfields(X,Bits,BW,!BitBreaks),
	(extract_tag(X,"max",M) -> Max=string_to_integer(M) ; Max=pow(integer(2),integer(BW))-one),
	(extract_tag(X,"min",M2) -> Min=string_to_integer(M2) ; Min=zero-pow(integer(2),integer(BW)-one)),
	(extract_tag(X,"offset",O1) -> Off=det_to_int(O1) ; Off=0),
	Y=Id-r(Min,Max,Bits,Id,Off).

:- pred bitfields(element::in, bit_range::out, int::out, list(int)::in, list(int)::out) is det.
bitfields(X,Bits,MWid,!BitBreaks) :-
	(extract_tag(X,"start",Start), extract_tag(X,"width",Width) ->
		BS=string_to_int(Start),
		BW=string_to_int(Width),
		MWid=BW,
		merge_and_remove_dups(!.BitBreaks,[BS,BS+BW],!:BitBreaks),
		Bits=rr(BW,BS)
	;	extract_tag(X,"bits",StringBits) ->
		CommaBits=string.words(is_comma,StringBits),
		CommaDashBits=map(func(YY)=ZZ :- ZZ=string.words(is_dash,YY),CommaBits),
		map(create_range,CommaDashBits,Ranges),
		condense(Ranges,Range),
		MWid=length(Range),
		Bits=rlist(Range),
		find_breakpoints(-1,Range,Breakpoints),
		merge_and_remove_dups(!.BitBreaks,sort(Breakpoints),!:BitBreaks)
	; throw("'start' and 'width', or 'bits' tags expected")).

:- pred is_comma(char::in) is semidet.
is_comma(',').

:- pred is_dash(char::in) is semidet.
is_dash('-').

:- pred find_breakpoints(int::in,list(int)::in, list(int)::out) is det.
find_breakpoints(X,[],Out) :- (X= -1 -> Out=[] ; Out=[X+1]).
find_breakpoints(X,[Y|Rest],Out) :-
	(	X=Y -> find_breakpoints(Y+1,Rest,Out)
	;	X= -1 -> find_breakpoints(Y+1,Rest,Out2), Out=[Y|Out2]
	;	find_breakpoints(Y+1,Rest,Out2), Out=[X,Y|Out2]).

:- pred create_range(list(string)::in,list(int)::out) is det.
create_range(L,R) :-
	(	L=[X] -> R=[string_to_int(X)]
	;	L=[X,Y] -> YY=string_to_int(Y),R=series(string_to_int(X),pred(XX::in) is semidet :- XX=<YY, func(XX)=XX+1)
	;	throw("Illegally formatted range")).

:- pred instruction(element::in,instruction_model::out,list(int)::in,list(int)::out) is det.
instruction(X,Y,!BitBreaks) :-
	Name=extract_tag_det(X,"name"),
	map_foldl(instruction_select,extract_child_elements(X),SelectList,!BitBreaks),
	Y=im(Name,SelectList).

:- pred instruction_select(element::in,instruction_select::out,list(int)::in,list(int)::out) is det.
instruction_select(X,Y,!BitBreaks) :-
	Name=extract_header(X),
	(Name="option" -> map_foldl(instruction_part,extract_child_elements(X),PartsList,!BitBreaks),Y=PartsList
	; throw("Problem parsing instruction select")).

:- pred instruction_part(element::in,instruction_part::out,list(int)::in,list(int)::out) is det.
instruction_part(X,Y,!BitBreaks) :- 
	Tag=extract_header(X),
	(Tag="part" ->
		bitfields(X,Bits,_,!BitBreaks),
		Options=extract_child_elements(X),
		map(mux_select,Options,OptionsList),Y=ip(Bits,OptionsList)
	; Tag="token" ->
		token_from_string(Tok,extract_tag_det(X,"value")),Y=token(Tok)
	; Tag="token_map" ->
		bitfields(X,Bits,_,!BitBreaks),
		Name=extract_tag_det(X,"name"),
		Y=tp(Bits,Name)
	; throw("Problem parsing instruction part: " ++ to_string(e(X)))).

:- pred mux_select(element::in,mux_select::out) is det.
mux_select(X,Y) :-
	Tag=extract_header(X),
	(Tag="value" ->
		Name=extract_tag_det(X,"name"),
		(Name="RREG" -> (extract_tag(X,"ext_field",R) -> T=reg(register('r'),[R]) ; throw("Register File expected"))
		;Name="SREG" -> (extract_tag(X,"ext_field",R) -> T=reg(register('s'),[R]) ; throw("Register File expected"))
		;Name="LABEL" -> (extract_tag(X,"ext_field",R) -> T=reg(label,[R]) ; throw("Register File expected"))
		;Name="IMMEDIATE" -> (extract_tag(X,"ext_field",R) -> T=reg(immediate,[R]) ; throw("Register File expected"))
		;T=o(Name)),
		Y=ms(string_to_integer(extract_tag_det(X,"value")),T)
	; throw("Problem parsing mux select" ++ to_string(e(X)))).

:- pred conv_xor(element::in, pair(int,int)::out) is det.
conv_xor(X,T) :-
	Name=extract_header(X),
	(Name="xor" -> T=string_to_int(extract_tag_det(X,"to"))-string_to_int(extract_tag_det(X,"from"))
	; throw("Tag '" ++ Name ++ "' found where 'xor' expected")).

:- pred get_token_map(element::in,pair(string,pair(int,map(string,integer)))::out) is det.
get_token_map(X,Name-(BW-Res)) :-
	Name=extract_tag_det(X,"name"),
	BW=string_to_int(extract_tag_det(X,"width")),
	map(pred(XX::in,YY::out) is det :- YY=extract_tag_det(XX,"name")-string_to_integer(extract_tag_det(XX,"value")),extract_child_elements(X),Res0),
	det_insert_from_assoc_list(init,Res0,Res).
