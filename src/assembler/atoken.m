:- module atoken.
:- interface.
:- import_module int, char, list, string, pair, integer, float, bool.

:- type keyword_t ---> mov ; arch ; reg(char,int).

:- type id == string. % identifier

:- type constant_t --->
		integer(integer,string) ; float(float,string) ;
		string(string) ; char(char) ; bool(bool).

:- type token ---> name(id) ; k(keyword_t) ; c(constant_t) ; comma ; dot ; colon ; semicolon ; open_brace ; close_brace ; minus ; move ; backslash ; move_delay ; eol ; t(char) ; junk(char).

%:- type sl ---> sl(char, token, list(sl)).

:- type token_context == int.		% line number
:- type token_pair == pair(token, token_context).
:- type token_list == list(token_pair).

:- pred get_token_list(token_list::out, token_context::in, list(char)::in, list(char)::out) is det.
%		Read a list of tokens from the current input stream.
%		Keep reading until either we encounter the end-of-file.

:- pred token_to_string(token::in, string::out) is det.
%		Convert a token to a human-readable string describing the token.

:- pred keyword_to_string(keyword_t::in,string::out) is det.
:- pred keyword_from_string(keyword_t::out,string::in) is semidet.

:- pred token_pair_to_string(pair(token,token_context), string).
:- mode token_pair_to_string(in, out) is det.

:- pred token_from_string(token::out, string::in) is det.

:- func string_to_integer(string) = integer.
:- func string_to_int(string) = int.

%-----------------------------------------------------------------------------%
:- implementation.
:- import_module list, int, exception.
%-----------------------------------------------------------------------------%

:- pred do_special(char::in, token::out, list(char)::in, list(char)::out) is semidet.
do_special(',',comma,!L).
do_special('.',dot,!L).
do_special('{',open_brace,!L).
do_special('}',close_brace,!L).
do_special(':',colon,!L).
do_special(';',semicolon,!L).
do_special('-',Tok,Lin,Lout) :-
	( ['>'|L2]=Lin -> Lout=L2,Tok=move
	; Lout=Lin,Tok=minus).
do_special('\\',Tok,Lin,Lout) :-
	( ['>'|L2]=Lin -> Lout=L2,Tok=move_delay
	; Lout=Lin,Tok=move_delay).

:- pred keyword(keyword_t,string).
:- mode keyword(in, out) is semidet.
:- mode keyword(out, in) is semidet.
keyword(arch,"architecture").

keyword_to_string(Keyword,String) :-
	(keyword(Keyword,S) -> String = S
	; Keyword=reg(C,N) -> String=char_to_string(C)++S, int_to_string(N,S)
	; throw("Unrecognised token")).

keyword_from_string(Keyword,String) :-
	(keyword(K,String) -> Keyword = K
	;	split(String,1,Base,Num),
		to_int(Num,N),
		N>=0,
		(Base="r",Keyword=reg('r',N);Base="s",Keyword=reg('s',N))).

:- pred putback_char(char::in, list(char)::in, list(char)::out).
putback_char(C,L,[C|L]).

token_to_string(T,S) :- token_to_string_aux(T,S). % ->S=S1;error("Illegal token in token_to_string").

:- pred token_to_string_aux(token::in, string::out) is det.
token_to_string_aux(name(Name), Name).
token_to_string_aux(k(Keyword), String) :- keyword_to_string(Keyword,String).
token_to_string_aux(c(integer(_Int, IString)), IString).
token_to_string_aux(c(float(_Float,FString)), FString).
token_to_string_aux(c(string(Token)), "string """ ++ Token ++ """").
token_to_string_aux(c(char(Char)), String) :- char_to_string(Char,String).
token_to_string_aux(c(bool(yes)), "true").
token_to_string_aux(c(bool(no)), "false").
token_to_string_aux(junk(C), _String) :- string.from_char_list([C],CC),throw("Illegal character:" ++ CC).
token_to_string_aux(comma,",").
token_to_string_aux(dot,".").
token_to_string_aux(colon,":").
token_to_string_aux(semicolon,";").
token_to_string_aux(open_brace,"{").
token_to_string_aux(close_brace,"}").
token_to_string_aux(minus,"-").
token_to_string_aux(move,"->").
token_to_string_aux(backslash,"\\").
token_to_string_aux(move_delay,"\\>").
token_to_string_aux(eol,"\n").
token_to_string_aux(t(C),S) :- char_to_string(C,S).

%-----------------------------------------------------------------------------%

token_from_string(Tok,S) :- (get_token(T,0,_,to_char_list(S),[]) -> Tok=T ; throw("Token expected:"++S)).

get_token_list(Tokens, CIn, !L) :-
	( get_token(Token,CIn,COut,!L) ->
		Tokens=[pair(Token,COut)|Tokens1],get_token_list(Tokens1,COut,!L)
	; Tokens=[]).

:- pred get_token(token::out, token_context::in,token_context::out, list(char)::in, list(char)::out) is semidet.
get_token(Token, CIn, COut) -->
	( eol -> {COut=CIn+1},{Token=eol}
	; [Char],{is_whitespace(Char)} -> get_token(Token, CIn, COut)
	; [';'] -> skip_to_eol,{COut=CIn+1},{Token=eol}
	; ['/','*'] -> to_end_comment(1,CIn,C2),get_token(Token,C2,COut)
	; {COut=CIn},
		( [Char],{is_alpha(Char);Char = '_'} -> get_name([Char], Token)
		; get_number_part(Int, IntString) -> {Token=c(integer(Int,IntString))}
%		; ['0'] -> get_zero(Token)
%		; get_decimal_number(Token2) -> {Token=Token2}
		; [Char], (do_special(Char,Tok1) -> {Token=Tok1} 
				; {to_int(Char)>=33},{to_int(Char)=<126} -> {Token=t(Char)}
				; {Token=junk(Char)}))).

:- pred skip_to_eol(list(char)::in, list(char)::out) is det.
skip_to_eol --> ( eol -> [] ; [_] -> skip_to_eol ; []).

:- pred to_end_comment(int::in,token_context::in,token_context::out, list(char)::in, list(char)::out) is det.
to_end_comment(Level,In,Out) -->
	( ['*','/'] -> ({Level=1}->{In=Out};to_end_comment(Level-1,In,Out))
	; ['/','*'] -> to_end_comment(Level+1,In,Out)
	; eol -> to_end_comment(Level,In+1,Out)
	; [_] -> to_end_comment(Level,In,Out)
	; {throw("End of file found during comment")}).

:- pred eol(list(char)::in, list(char)::out) is semidet.
eol -->
	( [Char1,Char2],{to_int(Char1,13)},{to_int(Char2,10)} -> []
	; [Char],{to_int(Char,13)} -> []
	; [Char],{to_int(Char,10)}).

%-----------------------------------------------------------------------------%

% names and variables

:- pred get_name(list(char)::in, token::out, list(char)::in, list(char)::out) is det.
get_name(Chars, Token) -->
	( [Char] ->
		( {is_alnum_or_underscore(Char) } ->
			get_name([Char | Chars], Token)
		; putback_char(Char),
			{get_name_aux(Chars,Token)})
	; {get_name_aux(Chars,Token)}).

:- pred get_name_aux(list(char)::in, token::out) is det.
get_name_aux(Chars, Token) :-
	string.from_rev_char_list(Chars, Name),
	( Name="true" -> Token=c(bool(yes))
	; Name="false" -> Token=c(bool(no))
	; keyword_from_string(Key, Name) -> Token = k(Key)
	; Token = name(Name)).

string_to_integer(String)=Result :-
	(   get_number_part(Resultx,_,to_char_list(String),[]) -> Result=Resultx
	;	throw("Invalid number: '"++String++"'")).

string_to_int(String)=int(string_to_integer(String)).

:- pred get_number_part(integer::out, string::out, list(char)::in, list(char)::out) is semidet.
get_number_part(Result, ResultString) -->
	(	['0'] -> get_zero(Result, ResultString)
	;	get_decimal_number(Result, ResultString)).

:- pred get_decimal_number(integer::out, string::out, list(char)::in, list(char)::out) is semidet.
get_decimal_number(Int,Intstring) -->
	get_base(10,integer(0),[],Int,Intstring),
	{length(Intstring,N)},{N>0}.

:- pred get_zero(integer::out, string::out, list(char)::in, list(char)::out) is det.
get_zero(Int,Intstring) -->
	( (['X'];['x']) -> get_base(16,integer(0),['0','x'],Int,Intstring)
	; (['B'];['b']) -> get_base(2,integer(0),['0','b'],Int,Intstring)
	; (['D'];['d']) -> get_base(10,integer(0),['0','d'],Int,Intstring)
	; (['O'];['o']) -> get_base(8,integer(0),['0','o'],Int,Intstring)
	; [C1,C2],{is_digit(C1)},{is_digit(C2)} -> {throw("Error: leading zero disallowed due to possible ambiguity")}
	; [Char],{is_digit(Char)} -> get_base(10,integer(0),['0','d'],Int,Intstring)
	; {Int=integer(0)},{Intstring="0"}).

:- pred get_base(int::in, integer::in, list(char)::in, integer::out, string::out, list(char)::in, list(char)::out) is det.
get_base(Base,Value,Chars,Int,Intstring) -->
	( [Char],{digit_to_int(Char,X)},{X<Base} ->
		get_base(Base,Value*integer(Base)+integer(X),Chars ++ [Char],Int,Intstring)
	; {Int=Value},{Intstring=List},{from_char_list(Chars,List)}).

token_pair_to_string(Token-_Context,S) :-
	token_to_string(Token,S).
