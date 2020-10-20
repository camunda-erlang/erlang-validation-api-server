-module(swagger_default_logic_handler).

-behaviour(swagger_logic_handler).

-export([handle_request/3]).
-export([handle_response/2]).


-spec handle_request(
    OperationID :: dnd_server_api:operation_id(),
    Req :: cowboy_req:req(),
    Context :: #{}
) ->
    {Status :: cowboy:http_status(), Headers :: cowboy:http_headers(), Body :: #{}}.

handle_request('validateSubscription', Req, Context) ->
    error_logger:info_msg(
        "Request to process: ~p~n",
        [{'validateSubscription', Req, Context}]
    ),
	Variables = maps:get(variables, Req, {}),
	BusinessKey = integer_to_binary(os:system_time(), 16),
	case (catch openapi_process_definition_api:start_process_instance_by_key(#{}, "service-list-validation", #{body => #{<<"variables">> => Variables, <<"businessKey">> => BusinessKey}})) of
		{ok, _ProcessData, _} ->
			% io:fwrite("[~p|~p] ~p~n",[?MODULE, ?LINE, ProcessData]),
			io:fwrite("Id : ~p~n",[BusinessKey]),
			catch swagger_utils:add_process_id_cache(BusinessKey, self()),
			receive
				{ok, Status} ->
					{200, [], #{status => Status}};
				Error ->
					io:fwrite("[~p|~p] LookupBlacklist Error : ~p~n",[?MODULE, ?LINE, Error]),
					{400, [], #{}}
				after 60000 ->
					io:fwrite("[~p|~p] LookupBlacklist Error : ~p~n",[?MODULE, ?LINE, timeout]),
					{400, [], #{}}
			end;
		Error ->
			io:fwrite(" openapi_process_definition_api:start_process_instance_by_key Error : ~p~n",[Error]),
			{400, [], #{}}
	end;

	
handle_request(OperationID, Req, Context) ->
    error_logger:error_msg(
        "Got not implemented request to process: ~p~n",
        [{OperationID, Req, Context}]
    ),
    {501, [], #{}}.

handle_response('Response', {BusinessKey, Status}) ->
    error_logger:info_msg(
        "Response to process: ~p~n",
        [{'Response', BusinessKey, Status}]
    ),
	case catch swagger_utils:get_process_id_cache(BusinessKey) of
		Pid when is_pid(Pid) ->
			Pid ! {ok, Status},
			swagger_utils:del_process_id_cache(BusinessKey),
			{200, [], #{}};
		_ ->
			{400, [], #{}}
	end.