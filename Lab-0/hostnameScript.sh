#!/bin/sh
# Bonjour Hostname Configuration
# Changes the hostname of the device to the one specified.

# Author: Xavier Merino
# Date: June 9th, 2016

OPTIND=1

usage() { echo "Usage: $0 -n <newHostname>"; exit 1; }

while getopts "n:" opt; do
    case "$opt" in
    n)
        s=${OPTARG}
        apt-get update
        apt-get install libnss-mdns -y
        hostname "$(eval echo ${s})"
        echo "$s" | sudo tee /etc/hostname
        OUTPUT="$(cat /etc/hosts | awk '$1=="127.0.1.1"{$2="\t'$(eval echo ${s})'"}1')"
        echo "${OUTPUT}" | sudo tee /etc/hosts
        clear
        /etc/init.d/hostname.sh
        reboot -h now
        exit 0
        ;;
    *)
        usage
        ;;
    esac
done
