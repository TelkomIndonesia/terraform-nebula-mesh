terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    nebula = {
      source  = "telkomindonesia/nebula"
      version = "0.3.0"
    }
  }
  experiments = [module_variable_optional_attrs]
}
