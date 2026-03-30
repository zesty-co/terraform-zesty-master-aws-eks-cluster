output "kompass_values_yaml" {
  description = "Kompass Helm values YAML returned by the Zesty account registration"
  value       = module.zesty.kompass_values_yaml
  sensitive   = true
}
