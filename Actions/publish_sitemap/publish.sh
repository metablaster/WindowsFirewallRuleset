#!/usr/bin/env bash

# -- Standard Header --
echoerr() { printf "%s\n" "$*" >&2; }
node Actions/publish_sitemap/publish.js

# NOTE: This file should have LF end of line because it's run in UNIX environment
