#!/bin/bash

export DOMAIN_NAME="k.voronenko.net"

export TARGET=$PWD

source ~/.acme.sh/acme.sh.env

~/.acme.sh/acme.sh --install-cert -d "${DOMAIN_NAME}" \
        --cert-file $TARGET/cert.pem \
        --key-file  $TARGET/privkey.pem \
        --fullchain-file $TARGET/fullchain.pem
