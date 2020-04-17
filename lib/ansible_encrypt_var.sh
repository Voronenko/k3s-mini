#!/bin/bash

# vault id expected in ANSIBLE_VAULT_IDENTITY_LIST

if [ -z "$ANSIBLE_VAULT_IDENTITY_LIST" ]
then
      echo "Please export path to vault id via ANSIBLE_VAULT_IDENTITY_LIST"
      exit 1
fi

ansible-vault encrypt_string --stdin-name ${1:-new_encrypted_variable}

