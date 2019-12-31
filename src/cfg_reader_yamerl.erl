%%% ----------------------------------------------------------------------------
%%% @author <pouriya.jahanbakhsh@gmail.com>
%%% @doc
%%%         High level API module.
%%% @end

%% -----------------------------------------------------------------------------
-module(cfg_reader_yamerl).
-author('pouriya.jahanbakhsh@gmail.com').
%% -----------------------------------------------------------------------------
%% Exports:

%% API:
-export([read_config/1]).

%% -----------------------------------------------------------------------------
%% Records & Macros & Includes:

-include_lib("yamerl/include/yamerl_errors.hrl").

%% -----------------------------------------------------------------------------
%% API:

read_config(Filename) ->
    case file:read_file(Filename) of
        {ok, Data} ->
            case parse_yaml(Data) of
                {ok, Terms} ->
                    {ok, normalize(Terms)};
                {_, ErrParams} ->
                    {error, {yamerl, ErrParams#{filename => Filename}}}
            end;
        {_, Reason} ->
            {
                error,
                {
                    yamerl,
                    #{
                        filename => Filename,
                        reason => Reason,
                        info => file:format_error(Reason)
                    }
                }
            }
    end.


parse_yaml(Data) ->
    try yamerl:decode(Data) of
        [Terms] ->
            {ok, Terms};
        Other ->
            {error, #{returned_value => Other}}
    catch
        _:#yamerl_exception{errors = Errs} ->
            case lists:keyfind(yamerl_parsing_error, 1, Errs) of
                #yamerl_parsing_error{line = Line} ->
                    {error, #{line => Line}};
                _ ->
                    {error, #{reason => Errs}}
            end;
        _:Reason ->
            {error, #{reason => Reason, s => erlang:get_stacktrace()}}
    end.


normalize([{Key, Value} | Rest]) ->
    [{normalize({key, to_list(Key)}), normalize(Value)} | normalize(Rest)];

normalize({key, Key}) ->
    erlang:list_to_atom(Key);

normalize(L) when erlang:length(L) > 0 ->
    case io_lib:printable_unicode_list(L) of
        true ->
            erlang:iolist_to_binary(L);
        _ ->
            [normalize(X) || X <- L]
    end;

normalize(X) ->
    X.


to_list([_|_]=L) ->
    L;

to_list(Int) when erlang:is_integer(Int) ->
    erlang:integer_to_list(Int);

to_list(Float) when erlang:is_float(Float) ->
    erlang:float_to_list(Float).
