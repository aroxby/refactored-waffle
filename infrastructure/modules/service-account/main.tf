resource "kubernetes_service_account" "service_account" {
  metadata {
    name = var.name
  }
}

resource "kubernetes_role" "role" {
  metadata {
    name = var.name
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_role_binding" "role_binding" {
  metadata {
    name      = var.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.service_account.metadata[0].name
  }
}
