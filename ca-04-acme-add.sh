#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo -e "you must provide a name for the ACME provisioner"
	exit 1
fi

docker container exec -ti step-ca \
	step \
		ca \
		provisioner \
		add "$1" \
		--type ACME
