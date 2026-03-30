resource "helm_release" "kompass" {
  name             = "kompass"
  repository       = "https://zesty-co.github.io/kompass"
  chart            = "kompass"
  namespace        = "zesty-system"
  cleanup_on_fail  = true
  create_namespace = true

  values = [var.kompass_values_yaml]
}
