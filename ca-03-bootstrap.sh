#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo -e "you must provide CA URL"
	exit 1
fi
if [ -z "$2" ]; then
	echo -e "you must provide CA fingerprint"
	exit 1
fi

step ca bootstrap --ca-url "$1" --fingerprint "$2"
