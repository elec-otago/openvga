:- module xml_util.
:- interface.
:- import_module string, prettyprint, xml, pair, list, char.

:- pred print(style_t::in, xml_t::in, string::in, string::out) is det.
:- func to_string(content) = string.

:- pred parse(xml_t::out, string::in) is det.

:- pred parse_charlist(xml_t::out, list(char)::in) is det.

% some primitives for using prettyprint to build mixed text and content.

:- type buildcontent ==	pair(pr_state,list(content)).
:- pred new_content(buildcontent::out) is det.
:- pred get_content(buildcontent::in,list(content)::out) is det.
:- pred add_content(content::in,buildcontent::in,buildcontent::out) is det.
:- pred pS(string::in,buildcontent::in,buildcontent::out) is det.
:- pred pN(string::in,buildcontent::in,buildcontent::out) is det.

:- pred load_attribute(list(string)::out, list(string)::in, list(pair(string,string))::in) is det.

%-----------------------------------------------------------------------------%
:- implementation.
:- import_module list, std_util, exception.
%-----------------------------------------------------------------------------%

to_string(E) = S :- print_content(E,Inx,Outx),fromstring(Inx,"",flat),tostring(Outx,S).

parse(X,In) :-
	to_char_list(In,InChars1),
	parse_charlist(X,InChars1).

parse_charlist(xml(empty,Content),InChars1) :-
	parse_prolog(InChars,OutChars),
	parse_elt(Content,OutChars,_),
	rem_white(InChars1,InChars).

:- pred parse_prolog(list(char)::in,list(char)::out) is det.
parse_prolog -->
	( ['<','?'] ->
		(get_string_aux('?',_),['?','>'] -> rem_white,parse_prolog; {throw("XML Error - '?>' expected in prolog")})
	; ( ['<','!'] ->
			(get_string_aux('>',_),['>'] -> rem_white,parse_prolog; {throw("XML Error - '>' expected in prolog")})
		; [])).

:- pred parse_elt(element::out,list(char)::in,list(char)::out) is det.
parse_elt(e(t(Name,Attributes),Contents)) -->
	(	['<'] ->
		(	['!','-','-'] -> parse_comment,parse_elt(e(t(Name,Attributes),Contents))
		;	get_name(Namex) -> {Name=Namex},parse_attr(Attributes),rem_white,
			(	['/','>'] -> {Contents=[]}
			;	['>'] -> parse_contents(Name,Contents)
			;	{throw("XML Error - '>' or '/>' expected")})
		;	=(XX),{throw("XML Error - name expected "++from_char_list(XX))})
	;	{throw("XML Error - '<' expected")}).

:- pred parse_comment(list(char)::in,list(char)::out) is det.
parse_comment --> ( ['-','-','>'] -> rem_white ; [_] -> parse_comment ; {throw("XML Error - unterminated comment")}).

:- pred parse_attr(list(pair(string,string))::out,list(char)::in,list(char)::out) is det.
parse_attr(Attr) -->
	( get_name(Name),['='],get_string(Value) ->
		parse_attr(Attr1),{Attr=[Name-Value|Attr1]}
	; {Attr=[]}).

:- pred parse_contents(string::in,list(content)::out,list(char)::in,list(char)::out) is det.
parse_contents(Name,Contents) -->
	( ['<','!','-','-'] -> parse_comment,parse_contents(Name,Contents)
	;	get_string_aux('<',Chars),
		( ['<','/'] -> (get_name(Name),['>'] -> {Cont1=[]} ; {throw("XML Error - error closing: " ++ Name)})
		; parse_elt(Elt),parse_contents(Name,Cont2),{Cont1=[e(Elt)|Cont2]}),
		( {rem_white(Chars,[])} -> {Contents=Cont1}
		; {from_char_list(Chars,String)},{Contents=[c(String)|Cont1]})).

:- pred get_string(string::out,list(char)::in,list(char)::out) is det.
get_string(Name) --> rem_white,
	(['"'],get_string_aux('"',Out),['"'] -> {from_char_list(Out,Name)} ; {throw("XML Error - error getting attribute")}).

:- pred get_string_aux(char::in,list(char)::out,list(char)::in,list(char)::out) is det.
get_string_aux(C,Out) -->
	( ['&'],get_string_alpha(Alpha),{from_char_list(Alpha,AlphaS)},{special(Ch,AlphaS)},[';'] ->
		get_string_aux(C,Out2),{Out=[Ch|Out2]}
	; [X],{X\=C} -> 
		get_string_aux(C,Out2),{Out=[X|Out2]}
	; {Out=[]}).

:- pred get_string_alpha(list(char)::out,list(char)::in,list(char)::out) is det.
get_string_alpha(Out) -->
	( [X], {is_alpha(X)} -> 
		get_string_alpha(Out2),{Out=[X|Out2]}
	; {Out=[]}).

:- pred get_name(string::out,list(char)::in,list(char)::out) is semidet.
get_name(Name) -->
	rem_white,[X],{is_lead_name_char(X)},get_name_aux(Out), {from_char_list([X|Out],Name)}.

:- pred get_name_aux(list(char)::out,list(char)::in,list(char)::out) is det.
get_name_aux(Out) -->
	([X],{is_name_char(X)} -> get_name_aux(Out2),{Out=[X|Out2]} ; {Out=[]}).

:- pred rem_white(list(char)::in,list(char)::out) is det.
rem_white --> ([X],{is_whitespace(X)} -> rem_white;[]).

:- pred put_back(char::in,list(char)::in,list(char)::out) is det.
put_back(C,In,[C|In]).

%-----------------------------------------------------------------------------%

:- pred is_lead_name_char(char::in) is semidet.
is_lead_name_char(X) :- is_alpha_or_underscore(X).
%is_lead_name_char('_').
is_lead_name_char(':').

:- pred is_name_char(char::in) is semidet.
is_name_char(X) :- is_alnum_or_underscore(X).
is_name_char('-').
is_name_char('.').
is_name_char(':').

:- pred special(char,string).
:- mode special(in,out) is semidet.
:- mode special(out,in) is semidet.
special('<',"lt").
special('>',"gt").
special('"',"quot").
special('&',"amp").
special('\'',"apos").

%-----------------------------------------------------------------------------%

print(Style,Prog,In,Out) :- print_aux(Prog,Inx,Outx),fromstring(Inx,In,Style),tostring(Outx,Out).

:- pred print_aux(xml_t::in, pr_state::in, pr_state::out) is det.
print_aux(xml(_,Elt)) --> print_elt(Elt).

:- pred print_elt(element::in, pr_state::in, pr_state::out) is det.
print_elt(e(Tag,Content)) --> 
	( {Content=[]} ->
		{Tag=t(Name,Attribs)},
		pN("<"),pS(Name),print_with_sep(" ",print_attrib,Attribs),pN("/>")
	; {Content=[c(H)]} ->
		print_tag(Tag),entab(2),print_with_pred_sep(newline,print_content,[c(H)]),detab,print_end(Tag)
	; print_tag(Tag),entab(2),newline,print_with_pred_sep(newline,print_content,Content),detab,newline,print_end(Tag)).

:- pred print_tag(tag::in, pr_state::in, pr_state::out) is det.
print_tag(t(Tag,Attribs)) --> pN("<"),pS(Tag),print_with_sep(" ",print_attrib,Attribs),pN(">").

:- pred print_attrib(pair(string,string)::in, pr_state::in, pr_state::out) is det.
print_attrib(S-V) --> pS(S),pN("=\""),pN(V),pN("\"").

:- pred print_end(tag::in, pr_state::in, pr_state::out) is det.
print_end(t(Tag,_)) --> pN("</"),pS(Tag),pN(">").

:- pred print_content(content::in, pr_state::in, pr_state::out) is det.
print_content(e(Elt)) --> print_elt(Elt).
print_content(c(S)) --> {do_special(S,SS)},print(SS,nospace).

:- pred do_special(string::in,string::out) is det.
do_special(InS,OutS) :- to_char_list(InS,InC),map(ctos,InC,Out),append_list(Out,OutS).

:- pred ctos(char::in,string::out) is det.
ctos(C,S) :- (special(C,S1) -> S = "&" ++ S1 ++ ";" ; char_to_string(C,S)).

%-----------------------------------------------------------------------------%

new_content(S-[]) :- fromstring(S,"",flat).

get_content(Si-Ci,Co) :-
	(isempty(Si) -> Co=Ci
	; append(Ci,[c(Sii)],Co),tostring(Si,Sii)).

pS(S,Si-C,So-C) :- pS(S,Si,So).
pN(S,Si-C,So-C) :- pN(S,Si,So).

add_content(Cont,Si-Ci,So-Co) :-
	(isempty(Si) -> C2=Ci
	; append(Ci,[c(Sii)],C2),tostring(Si,Sii)),
	append(C2,[Cont],Co),
	fromstring(So,"",flat).

%-----------------------------------------------------------------------------%

load_attribute(Out,Fields,[]) :- length(Fields,N),duplicate(N,"",Out).
load_attribute(Out,Fields,[Name-Val|T]) :-
	load_attribute(Out1,Fields,T),
	load_attr_aux(Out,Out1,Fields,Name,Val).

:- pred load_attr_aux(list(string)::out, list(string)::in, list(string)::in, string::in, string::in) is det.
load_attr_aux([Ho|To],I,F,Name,Val) :-
	(I=[Hi|Ti],F=[Hf|Tf] ->
		( Hf=Name -> To=Ti,Ho=Val
		; Ho=Hi, load_attr_aux(To,Ti,Tf,Name,Val))
	; throw("XML Error - failed to find attribute")).


