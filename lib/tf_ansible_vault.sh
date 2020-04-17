#!/bin/bash

set -ef -o pipefail
# Keep environment clean
export LC_ALL="C"
# Set variables
readonly TMP_DIR="/tmp"
readonly TMP_OUTPUT="${TMP_DIR}/$$.out"
readonly BASE_DIR="$(dirname "$(realpath "$0")")"
readonly MY_NAME="${0##*/}"
# Cleanup on exit
trap 'rm -rf ${TMP_OUTPUT}' \
  EXIT SIGHUP SIGINT SIGQUIT SIGPIPE SIGTERM

if [[ -z "$ANSIBLE_VAULT_IDENTITY_LIST" ]]
then
      echo "Please export path to vault id via ANSIBLE_VAULT_IDENTITY_LIST"
      exit 1
fi

if [[ -z "$1" ]]
then
      echo "Please provide path to secrets file"
      exit 1
fi

#echo cp $1 $TMP_OUTPUT
cp $1 $TMP_OUTPUT

ansible-vault decrypt $TMP_OUTPUT > /dev/null

python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < $TMP_OUTPUT

rm $TMP_OUTPUT

