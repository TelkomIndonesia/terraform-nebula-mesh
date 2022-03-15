output "configurations" {
  value       = local.nebula_node_configs
  sensitive   = true
  description = "Base configs for each nebula nodes. Note that in order to be converted to a valid nebula YAML configuration, key with null value should be removed."
}
