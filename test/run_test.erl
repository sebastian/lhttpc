%%% ----------------------------------------------------------------------------
%%% Copyright (c) 2009, Erlang Training and Consulting Ltd.
%%% All rights reserved.
%%% 
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%    * Redistributions of source code must retain the above copyright
%%%      notice, this list of conditions and the following disclaimer.
%%%    * Redistributions in binary form must reproduce the above copyright
%%%      notice, this list of conditions and the following disclaimer in the
%%%      documentation and/or other materials provided with the distribution.
%%%    * Neither the name of Erlang Training and Consulting Ltd. nor the
%%%      names of its contributors may be used to endorse or promote products
%%%      derived from this software without specific prior written permission.
%%% 
%%% THIS SOFTWARE IS PROVIDED BY Erlang Training and Consulting Ltd. ''AS IS''
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL Erlang Training and Consulting Ltd. BE
%%% LIABLE SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
%%% BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
%%% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
%%% OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
%%% ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%% ----------------------------------------------------------------------------

%%% @author Oscar Hellström <oscar@erlang-consulting.com>
-module(run_test).
-export([run/0]).

-include_lib("eunit/include/eunit.hrl").

-define(FILE_NAME(MODULE),
	"cover_report/" ++ atom_to_list(MODULE) ++ ".html").

run() ->
	Modules = get_modules(),
	ok = cover_compile(Modules),
	eunit:test(?MODULE),
	filelib:ensure_dir("cover_report/index.html"),
	html_report(Modules),
	write_report(Modules),
	io:format("Cover report in cover_report/index.html~n").

html_report([Module | Modules]) ->
	cover:analyse_to_file(Module, ?FILE_NAME(Module), [html]),
	html_report(Modules);
html_report([]) ->
	ok.

write_report(Modules) ->
	{TotalPercentage, ModulesPersentage} = percentage(Modules, []),
	file:write_file("cover_report/index.html",
		[
			"<html>\n<head><title>Cover report index</title></head>\n"
			"<body>\n"
			"<h1>Cover report for lhttpc</h1>"
			"Total coverage: ", integer_to_list(TotalPercentage), "%"
			"<h2>Cover for individual modules</h2>\n"
			"<ul>\n\t",
			lists:foldl(fun({Module, Percentage}, Acc) ->
						Name = atom_to_list(Module),
						[
							"<li>"
							"<a href=\"", Name ++ ".html" "\">",
							Name,
							"</a> ", integer_to_list(Percentage), "%"
							"</li>\n\t" |
							Acc
						]
				end, [], ModulesPersentage),
			"</ul></body></html>"
		]).

percentage([Module | Modules], Percentages) ->
	{ok, Lines} = cover:analyse(Module, coverage, line),
	Covered = lists:foldl(fun({_, {Covered, _}}, Acc) ->
				Covered + Acc
		end, 0, Lines),
	Percent = (Covered * 100) div length(Lines),
	percentage(Modules, [{Module, Percent} | Percentages]);
percentage([], Percentages) ->
	{total_percentage(Percentages), Percentages}.

total_percentage(Percentages) ->
	Total = lists:foldl(fun({_, Percent}, Acc) ->
				Acc + Percent
		end, 0, Percentages),
	Total div length(Percentages). 

get_modules() ->
	application:load(lhttpc),
	{ok, Modules} = application:get_key(lhttpc, modules),
	Modules.

cover_compile([Module | Modules]) ->
	{ok, Module} = cover:compile_beam(Module),
	cover_compile(Modules);
cover_compile([]) ->
	ok.

%%% Eunit functions
application_test_() ->
    {application, lhttpc}.
