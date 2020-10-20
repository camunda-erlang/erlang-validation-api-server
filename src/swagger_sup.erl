-module(swagger_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
	    supervisor:start_link(swagger_sup, []).

init(_Args) ->
 Opts = #{ip => {0, 0, 0, 0}, port => 8001, net_opts => []},
 ListenerSpec = swagger_server:child_spec(1, Opts),
 {ok, {{one_for_one, 10, 10}, [ListenerSpec]}}.
