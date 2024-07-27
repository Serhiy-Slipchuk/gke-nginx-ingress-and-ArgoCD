resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}


resource "helm_release" "argocd" {
  depends_on = [ kubernetes_namespace.argocd ]
  name             = "argo-cd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  values = [
    <<EOF
server:
  ingress:
    enabled: true
    hosts:
      - gke-argo-cd.slipchuk.website
    tls:
      - hosts:
          - gke-argo-cd.slipchuk.website
        secretName: argocd-server-tls
  config:
    repositories: |
      kind: ConfigMap
      apiVersion: v1
      metadata:
        name: argocd-cm
        labels:
          app.kubernetes.io/name: argocd-cm
          app.kubernetes.io/part-of: argocd
        annotations:
          meta.helm.sh/release-name: argo-cd
          meta.helm.sh/release-namespace: argocd
      data:
        admin.enabled: "true"
        application.instanceLabelKey: argocd.argoproj.io/instance
        exec.enabled: "false"
        server.rbac.log.enforce.enable: "false"
        timeout.hard.reconciliation: "0"
        timeout.reconciliation: 180s
EOF
  ]
}

resource "kubernetes_manifest" "argocd_ingress" {
  depends_on = [helm_release.argocd]
  manifest = {
    "apiVersion" : "networking.k8s.io/v1",
    "kind" : "Ingress",
    "metadata" : {
      "name" : "argocd-ingress",
      "namespace" : "argocd",
      "annotations" : {
        "kubernetes.io/ingress.class" : "nginx",
        "cert-manager.io/cluster-issuer" : "letsencrypt-prod",
        "nginx.ingress.kubernetes.io/backend-protocol" : "HTTPS"
      }
    },
    "spec" : {
      "rules" : [
        {
          "host" : "gke-argo-cd.slipchuk.website",
          "http" : {
            "paths" : [
              {
                "path" : "/",
                "pathType" : "Prefix",
                "backend" : {
                  "service" : {
                    "name" : "argo-cd-argocd-server",
                    "port" : {
                      "number" : 80
                    }
                  }
                }
              }
            ]
          }
        }
      ],
      "tls" : [
        {
          "hosts" : ["gke-argo-cd.slipchuk.website"],
          "secretName" : "argocd-server-tls"
        }
      ]
    }
  }
}
