#!/bin/bash
set -e
/entrypoint.sh /etc/docker/registry/config.yml &
exec httpd -DFOREGROUND