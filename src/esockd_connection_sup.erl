%%%-----------------------------------------------------------------------------
%%% @Copyright (C) 2014-2015, Feng Lee <feng@emqtt.io>
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%%-----------------------------------------------------------------------------
%%% @doc
%%% eSockd connection supervisor.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(esockd_connection_sup).

-author('feng@emqtt.io').

-behaviour(gen_server).

%% API
-export([start_link/1, start_connection/2, count_connection/1]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


start_link(Callback) ->
	gen_server:start_link(?MODULE, [Callback], []).

start_connection(Sup, SockArgs) ->
	gen_server:call(Sup, {start_child, SockArgs}).

count_connection(Sup) ->
	gen_server:call(Sup, count_connection).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init([Callback]) ->
	process_flag(trap_exit, true),
    {ok, {0, Callback}}.

handle_call({start_child, SockArgs}, _From, {Count, Callback}) ->
	case esockd_connection:start_link(Callback, SockArgs) of
		{ok, Pid} -> 
			{reply, {ok, Pid}, {Count+1, Callback}};
		Error ->
			{reply, Error, {Count, Callback}}
	end;

handle_call(count_connection, _From, {Count, Callback}) ->
    {reply, Count, {Count, Callback}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'EXIT', _PID, _Reason}, {Count, Callback}) ->
    {noreply, {Count-1, Callback}};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

