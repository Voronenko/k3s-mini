export INFRASTRUCTURE_ROOT_DIR=${INFRASTRUCTURE_ROOT_DIR:-$PWD}
export REMOTE_HOST=$INFRASTRUCTURE_ROOT_DIR/provisioners/shared/inventory/esx-extended.yml
export ENV_INVENTORY=$INFRASTRUCTURE_ROOT_DIR/provisioners/shared/inventory/esx-extended.yml
export ANSIBLE_INVENTORY=$ENV_INVENTORY
export REMOTE_USER_INITIAL=slavko
export REMOTE_PASSWORD_INITIAL=
export BOX_DEPLOY_USER=slavko
export ENVIRONMENT=default
export BOX_PROVIDER=esx
# if you use sudo
export BOX_DEPLOY_PASS=
#export ANSIBLE_VAULT_IDENTITY=@$HOME/PASSHERE/vault_pass.txt
echo # first import envvars if needed ...
