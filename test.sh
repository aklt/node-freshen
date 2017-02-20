#!/usr/bin/env bash

if ! [ -e './node_modules/http-proxy' ]; then
    npm install http-proxy
fi

npm test

