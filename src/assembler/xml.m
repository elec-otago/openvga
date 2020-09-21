:- module xml.
:- interface.
:- import_module string, list, pair.

:- type xml_t ---> xml(prolog,element).

:- type prolog ---> empty.

:- type element ---> e(tag,list(content)).

:- type content ---> c(string) ; e(element).

:- type tag ---> t(string,list(pair(string,string))).
