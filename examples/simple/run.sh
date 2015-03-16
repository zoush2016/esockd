#!/bin/sh
# -*- tab-width:4;indent-tabs-mode:nil -*-
# ex: ts=4 sw=4 et

erl -name echo@127.0.0.1 -setcookie public -pa ebin -pa ../../ebin -pa ../../deps/*/ebin -smp true +K true +A 32 +P 1000000 -env ERL_MAX_PORTS 1000000 -env ERTS_MAX_PORTS 1000000 -config app -boot start_sasl -s echo_server

