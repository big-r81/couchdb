%% -------------------------------------------------------------------
%%
%% riaknostic - automated diagnostic tools for Riak
%%
%% Copyright (c) 2011 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc Diagnostic that checks Riak's current memory usage. If memory
%% usage is high, a warning message will be sent, otherwise only
%% informational messages.
-module(riaknostic_check_memory_use).
-behaviour(riaknostic_check).

-export([description/0,
         valid/0,
         check/0,
         format/1]).

-spec description() -> iodata().
description() ->
    "Measure memory usage".

-spec valid() -> boolean().
valid() ->
    riaknostic_node:can_connect().

-spec check() -> [{lager:log_level(), term()}].
check() ->
    Pid = riaknostic_node:pid(),
    Output = riaknostic_util:run_command("ps -o pmem,rss -p " ++ Pid),
    [_,_,Percent, RealSize| _] = re:split(Output, "[ ]+"),
    Messages = [
                {info, {process_usage, Percent, RealSize}}
               ],
    case riaknostic_util:binary_to_float(Percent) >= 90 of
        false ->
            Messages;
        true ->
            [{critical, {high_memory, Percent}} | Messages]
    end.

-spec format(term()) -> iodata() | {io:format(), [term()]}.
format({high_memory, Percent}) ->
    {"Riak memory usage is HIGH: ~s% of available RAM", [Percent]};
format({process_usage, Percent, Real}) ->
    {"Riak process is using ~s% of available RAM, totalling ~s KB of real memory.", [Percent, Real]}.
