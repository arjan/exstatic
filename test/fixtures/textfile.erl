-module(textfile).

-export([contents/0, size/0]).

size() ->
    5.

contents() ->
    <<23,34,23>>.
