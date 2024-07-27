resource "kubernetes_namespace" "sealed_secrets" {
  metadata {
    name = "sealed-secrets"
  }
}

resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.7.4"

  namespace = kubernetes_namespace.sealed_secrets.metadata[0].name

  set {
    name  = "controller.replicaCount"
    value = "1"
  }
}