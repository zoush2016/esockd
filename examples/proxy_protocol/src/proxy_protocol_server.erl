%% Copyright (c) 2018 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

%%% @doc Proxy protcol -> Echo server.
-module(proxy_protocol_server).

-include("../../../include/esockd.hrl").

-behaviour(gen_server).

-export([start/0, start/1]).

%% esockd callback
-export([start_link/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
         code_change/3]).

-record(state, {transport, socket}).

start() -> start(5000).
%% shell
start([Port]) when is_atom(Port) ->
    start(list_to_integer(atom_to_list(Port)));
start(Port) when is_integer(Port) ->
    ok = application:start(sasl),
    ok = esockd:start(),
    Options = [{tcp_options, [binary, {packet, raw}]},
               proxy_protocol,
               {proxy_protocol_timeout, 1000}],
    esockd:open(echo, Port, Options, {?MODULE, start_link, []}).

start_link(Transport, Sock) ->
	{ok, proc_lib:spawn_link(?MODULE, init, [[Transport, Sock]])}.

init([Transport, Sock]) ->
    case Transport:wait(Sock) of
        {ok, NewSock} ->
            io:format("Proxy Sock: ~p~n", [NewSock]),
            Transport:setopts(Sock, [{active, once}]),
            gen_server:enter_loop(?MODULE, [], #state{transport = Transport, socket = NewSock});
        {error, Reason} ->
            io:format("Proxy Sock Error: ~p~n", [Reason]),
            {stop, Reason}
    end.

handle_call(_Request, _From, State) ->
    {reply, ignore, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({tcp, _Sock, Data}, State = #state{transport = Transport, socket = Sock}) ->
	{ok, Peername} = Transport:peername(Sock),
    io:format("Data from ~s: ~s~n", [esockd_net:format(peername, Peername), Data]),
	Transport:send(Sock, Data),
	Transport:setopts(Sock, [{active, once}]),
    {noreply, State};

handle_info({tcp_error, _Sock, Reason}, State) ->
	io:format("TCP Error: ~s~n", [Reason]),
    {stop, {shutdown, Reason}, State};

handle_info({tcp_closed, _Sock}, State) ->
	io:format("TCP closed~n"),
	{stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

