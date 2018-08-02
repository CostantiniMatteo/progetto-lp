%%      Matteo Colella - 794028
%%      Matteo Angelo Costantini - 795125
%%      Dario Gerosa - 793636

%jsonparse

jsonparse(JSONString, Object) :-
	atom_codes(JSONString, List),
	phrase(json(Object), List).



%jsonget

jsonget(JSON_obj, Field, Result) :-
	atom(Field),
	jsonget_aux(JSON_obj, [Field], Result),
	!.

jsonget(JSON_obj, Field, Result) :-
	jsonget_aux(JSON_obj, Field, Result),
	!.

jsonget_aux(Value ,[], Value) :- !.

jsonget_aux(jsonarray(Elements), [Num | Fields], Result) :-
	number(Num),
	nth0(Num, Elements, Value),
	jsonget_aux(Value, Fields, Result),
	!.

jsonget_aux(jsonobj(Members), [Key | Fields], Result) :-
	member((Key, Value), Members),
	jsonget_aux(Value, Fields, Result),
	!.



%jsonload

jsonload(FileName, JSON) :-
	exists_file(FileName),
	open(FileName, read, In, []),
	read_string(In, _, JSONString),
	close(In),
	jsonparse(JSONString, JSON).



%jsonwrite

jsonwrite(JSON, FileName) :-
	phrase(json_inv(JSON), JsonCodes),
	atom_codes(Output, JsonCodes),
	open(FileName, write, Stream),
	write(Stream, Output),
	nl(Stream),
	close(Stream).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DCG JSONPARSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
%Json
%
%JSON --> Obj | Array
%

json(jsonobj(Json)) -->
	ws,
	object(Json),
	ws,
	{!}.

json(jsonarray(Json)) -->
	ws,
	array(Json),
	ws.



%
%Object
%
%Object ->  '{}' | '{' Members '}'
%

object(Members) -->
	ws, "{", ws,
	members(Memb),
	ws, "}", ws, {!}, {remove_occurrences(Memb, Members)}.

object([]) -->
	ws, "{",
	ws, "}", ws.



%
%Member+
%
%Members --> Pair | Pair ',' Members
%

members([Pair | Members]) -->
	ws, pair(Pair), ws,
	",",
	{!},
	ws, members(Members), ws.

members([Pair]) -->
	ws,
	pair(Pair),
	ws.



%
%Pair
%
%Pair --> String ':' Value
%Pair --> Identifier ':' Value
%
%Key --> String | Identifier
%

pair((KeyA, Val)) -->
	ws, key(Key),
	ws, ":", ws,
	value(Val), ws,
	{atom_codes(KeyA, Key)}.

key(Key) -->
	string(Key).

key(Key) -->
	identifier(Key).



%
%Array
%
%Array --> '[]' | '[' Elements ']'
%

array(Array) -->
	ws, "[", ws,
	elements(Array),
	ws, "]", ws,
	{!}.

array([]) -->
	ws, "[",
	ws,
	"]", ws.



%
%Element+  (Values)
%
%Elements --> Value | Value ',' Elements
%

elements([Ele | Eles]) -->
	ws, value(Ele),
	ws, ",", ws,
	{!},
	elements(Eles), ws.

elements([Ele]) -->
	ws,
	value(Ele),
	ws.



%
%Value
%
%Value --> JSON | Number | String
%

value(ValS) -->
	string(Val),
	{!},
	{string_codes(ValS, Val)}.

value(Val) -->
	number(Val),
	{!}.

value(Val) -->
	json(Val),
	{!}.



%
%Number (int, float)
%
%Number --> Digit+ | Digit+ '.' Digit+
%

number(Num) -->
	digits(Int),
	".",
	{!},
	digits(Dec),
	{append(Int, [0'.| Dec], FloatNumber)},
	{number_codes(Num, FloatNumber)}.

number(Num) -->
	digits(Int),
	{number_codes(Num, Int)}.



%
%Digit, Digit+
%
%Digit --> 0 | 1 | .. | 9
%Digits --> Digit | Digit Digits (Digit+)
%

digits([Dig | Digs]) -->
	digit(Dig),
	digits(Digs),
	{!}.

digits([Dig]) -->
	digit(Dig).

digit(Dig) -->
	[Dig],
	{Dig >= 0'0, Dig =< 0'9},
	{!}.



%
%String
%
%String --> '"' AnyChar* '"' | '\'' AnyChar* '\''
%

string(Val) -->
	"\"",
	anyCharsD(Val),
	"\"",
	{!}.

string(Val) -->
	"\'",
	anyCharsS(Val),
	"\'",
	{!}.



%
%AnyChar, AnyChar+
%
%AnyChar --> (carattere diverso da '"' e da '\'') | '\"' | '\''
%AnyChars --> AnyChar | AnyChar AnyChars   (AnyChar+)

%Le clausule che hanno come suffisso la D sono quelle che 
%utilizzano come delimitatore di stringa il Doppio Apice.

%Le clausule che hanno come suffisso la S sono quelle che 
%utilizzano come delimitatore di stringa il Singolo Apice.

anyCharsD([Char | Chars]) -->
	[0'\\, Char],
	anyCharsD(Chars).

anyCharsD([Char | Chars]) -->
	anyCharD(Char),
	anyCharsD(Chars).

anyCharsD([]) -->
	[],
	{!}.
	
anyCharD(Char) -->
	[Char],
	{Char \= 0'"}.

anyCharsS([Char | Chars]) -->
	[0'\\, Char],
	anyCharsS(Chars).

anyCharsS([Char | Chars]) -->
	anyCharS(Char),
	anyCharsS(Chars).

anyCharsS([]) -->
	[],
	{!}.
	
anyCharS(Char) -->
	[Char],
	{Char \= 0'\'}.



%
%Identifier
%
%Identifier --> Char | Char ( Digit | Char )*
%

identifier([Char | DigChars]) -->
	char(Char),
	char_dig(DigChars),
	{!}.

identifier([Char]) -->
	char(Char).

% char_dig equivale a (Dig + Char)*

char_dig([Char | DigChars]) -->
	char(Char),
	char_dig(DigChars),
	{!}.

char_dig([Dig | DigChars]) -->
	digit(Dig),
	char_dig(DigChars).

char_dig([Char]) -->
	char(Char),
	{!}.

char_dig([Dig]) -->
	digit(Dig).



%
%Char, Char+
%
%Char --> a | b | .. | z | A | B | .. | Z
%

char(Char) -->
	[Char],
	{Char >= 0'a, Char =< 0'z},
	{!}.

char(Char) -->
	[Char],
	{Char >= 0'A, Char =< 0'Z}.



%White Space

ws --> wsChar, ws, {!}.
ws --> [].
wsChar --> [Ws], {char_type(Ws, space)}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DCG JSONWRITE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%json

json_inv(Obj) -->
	object_inv(Obj),
	{!}.

json_inv(Array) -->
	array_inv(Array),
	{!}.



% object

object_inv(jsonobj(Members)) -->
	"{",
	members_inv(Members),
	"}",
	{!}.

object_inv(jsonobj([])) -->
	"{",
	"}",
	{!}.



% member

members_inv([Pair | Pairs]) -->
	pair_inv(Pair),
	", ",
	members_inv(Pairs),
	{!}.

members_inv([Pair]) -->
	pair_inv(Pair),
	{!}.



% pair

pair_inv((Key, Val)) -->
	key_inv(Key),
	" : ",
	value_inv(Val).

key_inv(Key) -->
	string_inv(Key),
	{!}.



% array

array_inv(jsonarray(Elements)) -->
	"[",
	elements_inv(Elements),
	"]",
	{!}.

array_inv(jsonarray([])) -->
	"[",
	"]",
	{!}.



% elements

elements_inv([Val | Vals]) -->
	value_inv(Val),
	", ",
	elements_inv(Vals),
	{!}.

elements_inv([Val]) -->
	value_inv(Val),
	{!}.



% value

value_inv(Val) -->
	json_inv(Val),
	{!}.

value_inv(Val) -->
	number_inv(Val),
	{!}.

value_inv(Val) -->
	string_inv(Val),
	{!}.



% number

number_inv(Num) -->
	{number(Num)},
	{number_codes(Num, Codes)},
	Codes,
	{!}.



% string

string_inv(String) -->
	{atom_codes(String, Codes)},
	"\"",
	anyChar_inv(Codes),
	"\"",
	{!}.

anyChar_inv([]) -->
	[],
	{!}.

anyChar_inv([Char | Chars]) -->
	{Char \= 0'"},
	[Char],
	anyChar_inv(Chars),
	{!}.

anyChar_inv([Char | Chars]) -->
	{Char = 0'"},
	[92, Char],
	anyChar_inv(Chars).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UTILITIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%Rimuove tutte le occorrenze della stessa key tranne l'ultima

remove_occurrences(Json, JsonR) :-
	reverse(Json, Reverse),
	remove_occ_aux(Reverse, Result),
	reverse(Result, JsonR).

remove_occ_aux([(Key, Value) | List], Result) :-
	delete(List, (Key, _Value), List2),
	remove_occ_aux(List2, List3),
	append([(Key, Value)], List3, Result),
	!.

remove_occ_aux([],[]) :- !.
