:- module prettyprint.
:- interface.
:- import_module string, list.

:- type style_t ---> pretty ; flat.

:- type spaced_t ---> space; nospace.
:- type pr_state ---> s(style_t, spaced_t, int, list(int), int, string).

:- pred print(string::in, spaced_t::in, pr_state::in, pr_state::out) is det.
:- pred pS(string::in, pr_state::in, pr_state::out) is det.
:- pred pN(string::in, pr_state::in, pr_state::out) is det.
:- pred force_space(pr_state::in, pr_state::out) is det.
:- pred force_nospace(pr_state::in, pr_state::out) is det.

:- pred fromstring(pr_state::out,string::in,style_t::in) is det.
:- pred tostring(pr_state::in,string::out) is det.

:- pred newline(pr_state::in, pr_state::out) is det.

:- pred entab(int::in,pr_state::in, pr_state::out) is det.

:- pred detab(pr_state::in, pr_state::out) is det.

:- pred print_with_sep(string,pred(X,pr_state,pr_state),list(X),pr_state,pr_state).
:- mode print_with_sep(in, pred(in, in, out) is det, in, in, out) is det.

:- pred print_with_pred_sep(pred(pr_state,pr_state),pred(X,pr_state,pr_state),list(X),pr_state,pr_state).
:- mode print_with_pred_sep(pred(in, out) is det, pred(in, in, out) is det,
in, in, out) is det.

:- pred isempty(pr_state::in) is semidet.

:- pred print_int(int::in, pr_state::in, pr_state::out) is det.

%-----------------------------------------------------------------------------%
:- implementation.
:- import_module list,int.
%-----------------------------------------------------------------------------%

print_with_sep(_,_,[]) --> {true}.
print_with_sep(_,Pred,[H]) --> Pred(H).
print_with_sep(Sep,Pred,[H|[H2|T]]) --> Pred(H),pN(Sep),print_with_sep(Sep,Pred,[H2|T]).

print_with_pred_sep(_,_,[]) --> {true}.
print_with_pred_sep(Sep,Pred,[H|T],!S) :- Pred(H,!S),foldl((pred(X::in,Y::in,Z::out) is det :- Sep(Y,Y1),Pred(X,Y1,Z)),T,!S).
%print_with_pred_sep(Sep,Pred,[H|[H2|T]],) --> Pred(H),Sep,print_with_pred_sep(Sep,Pred,[H2|T]).

entab(Add,s(X,Sp,T1,Tabs,Nl,In),s(X,Sp,T0,[T1|Tabs],Nl,In)) :- T0 is T1+Add.

detab(s(X,Sp,T0,[],Nl,In),s(X,Sp,T0,[],Nl,In)).
detab(s(X,Sp,_,[T1|Tabs],Nl,In),s(X,Sp,T1,Tabs,Nl,In)).

newline(s(flat,Sp,T1,Tabs,Nl,In),s(flat,Sp,T1,Tabs,Nl,In)).
newline(s(pretty,Sp,T1,Tabs,Nl,In),s(pretty,Sp,T1,Tabs,Nl+1,In)).

print(S,Sp1,s(Style,Sp2,T1,Tabs,Nl,In),s(Style,Sp1,T1,Tabs,0,Out)) :-
	( Nl=0 ->
		Pad1 = "", Pad2 = ""
	; string.pad_right("",'\n',Nl,Pad1),string.pad_right("",' ',T1,Pad2)),
	( Sp1=space,Sp2=space,Nl=0 -> Space=" " ; Space=""),
	Out = In ++ Pad1 ++ Pad2 ++ Space ++ S.

pS(S) --> print(S,space).
pN(S) --> print(S,nospace).
force_space --> print(" ",nospace).
force_nospace --> print("",nospace).

fromstring(P,S,State) :- P=s(State,nospace,0,[],0,S).

tostring(State,S) :- pN("",State,s(_,_,_,_,_,S)).

isempty(s(_,_,_,_,_,"")).

print_int(N) --> pS(int_to_string(N)).