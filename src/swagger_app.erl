-module(swagger_app).
-behaviour(application).
-export([start/2, stop/1]).

start(_Type, _Args) ->
	swagger_utils:create_process_id_cache(),
	swagger_sup:start_link().

stop(_State) ->
  ok.
