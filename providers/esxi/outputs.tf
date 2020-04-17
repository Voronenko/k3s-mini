output "cluster_master" {
  value = esxi_guest.cluster_master.ip_address
}


locals {

  env = "default"

  ansible_common_vars = <<ANSIBLECOMMONVARS
---
ANSIBLECOMMONVARS

  inventory_esx = <<INVENTORYESX
[cluster_master]
${esxi_guest.cluster_master.ip_address}

[all:vars]
ansible_user=slavko
box_deploy_pass=

INVENTORYESX

  envvars = <<ENVVARS
export REMOTE_HOST=$INFRASTRUCTURE_ROOT_DIR/provisioners/shared/inventory/esx
export ENV_INVENTORY=$INFRASTRUCTURE_ROOT_DIR/provisioners/shared/inventory/esx
export ANSIBLE_INVENTORY=$ENV_INVENTORY
export REMOTE_USER_INITIAL=slavko
export REMOTE_PASSWORD_INITIAL=
export BOX_DEPLOY_USER=slavko
export ENVIRONMENT=${local.env}
export BOX_PROVIDER=esx
# if you use sudo
export BOX_DEPLOY_PASS=
#export ANSIBLE_VAULT_IDENTITY=@$HOME/PASSHERE/vault_pass.txt
echo # first import envvars if needed ...
ENVVARS

  help = <<HELP
terraform output inventory_esx
terraform output ansible_common_vars
terraform output envvars
HELP

}

resource "local_file" "shared_provider_vars" {
  filename = "${path.root}/../../provisioners/shared/providers/esx-${local.env}-vars.yml"
  content     = "${local.ansible_common_vars}"
}

resource "local_file" "shared_inventory" {
  content     = "${local.inventory_esx}"
  filename = "${path.root}/../../provisioners/shared/inventory/esx"
}

resource "local_file" "shared_envvars" {
  content     = "${local.envvars}"
  filename = "${path.root}/../../local_esx.sh"
}
