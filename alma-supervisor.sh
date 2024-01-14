#!/usr/bin/env bash
yum -y install epel-release supervisor
systemctl start supervisord
systemctl enable supervisord
