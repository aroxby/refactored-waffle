resource "kubernetes_deployment" "deployment" {
  metadata {
    name = var.deployment_name
    labels = {
      App = "${var.deployment_name}-app"
    }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        App = "${var.deployment_name}-app"
      }
    }
    template {
      metadata {
        labels = {
          App = "${var.deployment_name}-app"
        }
      }
      spec {
        container {
          image = var.image
          name  = "${var.deployment_name}-container"

          dynamic "env" {
            for_each = var.env
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = var.service_name
  }
  spec {
    selector = {
      App = kubernetes_deployment.deployment.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = var.load_balancer_port
      target_port = var.container_port
    }

    type = "LoadBalancer"
  }
}
