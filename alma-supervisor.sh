#!/usr/bin/env bash
yum -y install epel-release supervisor
systemctl enable supervisord
systemctl start supervisord
