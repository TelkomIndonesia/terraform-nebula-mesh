output "configurations" {
  value       = local.nebula_node_configs
  sensitive   = true
  description = "Base configs for each nebula nodes"
}
