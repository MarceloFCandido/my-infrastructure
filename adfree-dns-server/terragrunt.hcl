include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_env("MODULES_PATH", "git::ssh://git@github.com/MarceloFCandido")}/adfree-dns-server"

  extra_arguments "common_apply" {
    commands  = ["apply"]
    arguments = ["-auto-approve"]
  }
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "${local.secrets.tfc_organization}"
    workspaces {
      name = "${local.project_name}"
    }
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "oci" {
  fingerprint      = "bd:4c:94:c3:b9:b5:67:44:98:c5:c6:56:e5:0a:07:3d"
  private_key_path = "/home/marcelofcandido/Desktop/oci.pem"
  region           = "${local.region}"
  tenancy_ocid     = "${local.secrets.oc_tenancy_id}"
  user_ocid        = "${local.secrets.user_id}" 
}
EOF
}

locals {
  region              = "sa-vinhedo-1"
  project_name        = "adfree-dns-server"
  secrets             = yamldecode(sops_decrypt_file("secrets.yml"))
}

inputs = merge(
  local.secrets, 
  {
    number_of_servers   = 2
    project_name        = local.project_name
  }
)
